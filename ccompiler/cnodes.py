# -*- coding: utf-8 -*-
"""
Created on Sat Mar  1 11:43:13 2025

@author: Colin
"""
from collections import UserDict, UserList
from bit32 import Op, Cond, Size, Reg
from .cemitter import Emitter


class Frame(UserDict):
    """
    Class for frames.

    Frames represent the layout of a block of memory. For example stack frames
    or structs.
    """

    def __init__(self):
        super().__init__()
        self.size = 0

    def __setitem__(self, name, obj):
        """
        Override __setitem__.

        Give variable offset and insert into frame.
        """
        obj.offset = self.size
        self.size += obj.type.size
        super().__setitem__(name, obj)


class CNode:
    """Base class for nodes representing C programs."""

    def generate(self, emitter, n):
        """Generate target code."""
        pass

    def branch(self, emitter, n, _):
        """Handle branch for if statements."""
        self.generate(emitter, n)


class Statement(CNode):
    """Base class for C statements."""

    def last_is_return(self):
        """D if the last instruction is a return."""
        return False


class Expr(CNode):
    """Base class for C expressions."""

    def __init__(self, ctype, token):
        self.type = ctype
        self.width = ctype.width
        self.token = token

    def is_const(self):
        """
        Determine if subexpression is constant.

        Recurse property of expressions.
        This is used to determine if a subtree only contains constant values.
        Subtrees that are constant can be evaluated at compile time. They also
        and other allow for other compile time optimizations.
        """
        return False  # default is false

    def hard_calls(self):
        """
        Determine if subexpression "hard calls".

        Recurse property of expressions.
        This is used in register allocation. The rules of register allocation
        change when a subexpression involves calling a function.
        A "hard call" is when there is any instances of call nodes in the
        subexpression.
        """
        raise NotImplementedError(self.__class__.__name__)

    def soft_calls(self):
        """
        Determine if subexpression "soft calls".

        Recurse property of expressions.
        This is used in register allocation. A "soft call" is when the subtree
        involves calling a function but in a way that does not break the
        calling convention and this compiler's rules of register allocation.
        The criteria for a node to soft call is based on the node.
        """
        raise NotImplementedError(self.__class__.__name__)

    def reduce(self, emitter, n):
        """
        "Reduce" the expression and generate code.

        "Reduce" is probably not the best verb...
        """
        raise NotImplementedError(self.__class__.__name__)

    def compare(self, emitter, n, label):
        """Generate code for comparing nodes. Default is comparing to 0."""
        emitter.binary(self.type.CMP, self.width, self.reduce(emitter, n), 0)
        emitter.jump(Cond.EQ, label)

    def compare_inv(self, emitter, n, label):
        """Generate code for inverse comparing nodes."""
        emitter.binary(self.type.CMP, self.width, self.reduce(emitter, n), 0)
        emitter.jump(Cond.NE, label)

    def reduce_branch(self, emitter, n, _):
        """Reduce expression for ternary condition operator."""
        self.reduce(emitter, n)

    def reduce_num(self, emitter, n):
        """
        Reduce to number constant if applicable.

        This generates less code if the right side of a binary node is a
        constant. Instead of:
            MOV A, 3
            MOV B, 76
            ADD A, B
        this will be generated:
            MOV A, 3
            ADD A, 76
        """
        return self.reduce(emitter, n)

    def reduce_float(self, emitter, n):
        """Similar to reduce_num but for floats."""
        self.reduce(emitter, n)
        self.type.itf(emitter, n)
        return Reg(n)

    def reduce_subscr(self, emitter, n, size):
        """
        Generate special reduction case for subscript nodes.

        Used especially when the index is a constant.
        """
        self.reduce(emitter, n)
        if size > 1:
            emitter.binary(Op.MUL, Size.WORD, Reg(n), int(size))
        return Reg(n)


class Var(Expr):
    """Base class for variable nodes."""

    def name(self):
        """Get variable name."""
        return self.token.lexeme

    def hard_calls(self):
        """Variables do not hard call."""
        return False

    def soft_calls(self):
        """Variables do not soft call."""
        return False

    def call(self, emitter, _):
        """Generate default call behavior."""
        emitter.call(self.token.lexeme)


class Const(Expr):
    """Class for constant nodes."""

    def is_const(self):
        """Constants are constant."""
        return True

    def hard_calls(self):
        """Constants do not hard call."""
        return False

    def soft_calls(self):
        """Constants do not soft call."""
        return False


class Unary(Expr):
    """Base class for unary nodes."""

    def __init__(self, ctype, token, expr):
        super().__init__(ctype, token)
        self.expr = expr

    def is_const(self):
        """Determine if subtree is const."""
        return self.expr.is_const()

    def hard_calls(self):
        """Determine if subtree hard calls."""
        return self.expr.hard_calls()

    def soft_calls(self):
        """Determine if subtree soft calls."""
        return self.expr.soft_calls()


class Binary(Expr):
    """Base class for binary nodes."""

    def __init__(self, ctype, token, left, right):
        super().__init__(ctype, token)
        self.left, self.right = left, right

    def is_const(self):
        """Determine if subtree is const."""
        return self.left.is_const() and self.right.is_const()

    def hard_calls(self):
        """Determine if subtree hard calls."""
        return self.left.hard_calls() or self.right.hard_calls()

    def soft_calls(self):
        """Determine if subtree soft calls."""
        return self.left.hard_calls() or self.right.hard_calls()  # self.left.soft_calls() ?


class Access(Expr):
    """Base class for array access nodes."""

    def __init__(self, token, struct, attr):
        super().__init__(attr.type, token)
        self.struct, self.attr = struct, attr

    def hard_calls(self):
        """Determine if subtree hard calls."""
        return self.struct.hard_calls()

    def soft_calls(self):
        """Determine if subtree soft calls."""
        return self.struct.soft_calls()


class FuncDefn(CNode):
    """Class for function definition nodes."""

    def __init__(self, ctype, name, block, info):
        self.type, self.name = ctype, name
        self.params, self.block = ctype.params, block
        self.returns, self.calls, self.max_args, self.space = info

    def glob_generate(self, emitter):
        """Generate all of the code for the function."""
        max_args = max(self.calls, self.max_args)
        emitter.begin_body(self)
        # generate function body
        self.block.generate(emitter, max_args)
        # peephole optimize
        emitter.optimize_body()
        # find max register used in body
        max_reg = -1
        for inst in emitter.instructions:
            max_reg = max(max_reg, inst.max_reg())

        # calculate list of register to push onto the stack
        push = list(map(Reg, range(max(bool(self.type.ret.width),
                                       len(self.params)), max_reg+1)))
        pop = push.copy()

        self.adjust_offsets(emitter, push)
        emitter.end_body()
        emitter.append_label(self.name.lexeme)
        self.prologue(emitter, push)
        emitter.add_body()
        # epilogue
        if self.returns or self.type.ret.width:
            emitter.append_label(emitter.return_label)
        if self.returns and self.type.ret.width and max_args:
            emitter.binary(Op.MOV, Size.WORD, Reg.A, Reg(max_args))
        if self.space:
            emitter.binary(Op.ADD, Size.WORD, Reg.SP, self.space)
        self.ret(emitter, pop)

    def prologue(self, emitter, push):
        """Generate prologue code specific to regular functions."""
        if self.calls:
            emitter.push(push + [Reg.LR])
        else:
            emitter.push(push)
        if self.space:
            emitter.binary(Op.SUB, Size.WORD, Reg.SP, self.space)
        for i, param in enumerate(self.params[:4]):
            emitter.store(param.width, Reg(i), Reg.SP, param.offset, param.token.lexeme)

    def ret(self, emitter, pop):
        """Generate return code specific to regular functions."""
        if self.calls:
            emitter.pop(pop + [Reg.PC])
        else:
            emitter.pop(pop)
            emitter.ret()

    def adjust_offsets(self, emitter, push):
        """Adjust offsets of variable found on the call stack."""
        if len(self.params) > 4:
            offset = self.space + Size.WORD*(self.calls + len(push))
            stack_params = {param.token.lexeme for param in self.params[4:]}
            for inst in emitter.instructions:
                if inst.var in stack_params:
                    inst.offset += offset


class VarFuncDefn(FuncDefn): #TODO test
    """Class for variadic function definition nodes."""

    def prologue(self, emitter, push):
        """Generate prologue code specific to variadic functions."""
        emitter.push(list(map(Reg, range(4))))
        if self.calls:
            emitter.push(push + [Reg.LR])
        else:
            emitter.push(push)
        if self.space:
            emitter.binary(Op.SUB, Size.WORD, Reg.SP, self.space)

    def ret(self, emitter, push):
        """Generate return code specific to variadic functions."""
        if self.calls:
            emitter.pop(push + [Reg.LR])
        else:
            emitter.pop(push)
        emitter.binary(Op.ADD, Size.WORD, Reg.SP, 4*Size.WORD)
        emitter.ret()

    def adjust_offsets(self, emitter, push):
        """Adjust offsets of variables found on the call stack."""
        offset = self.space + Size.WORD*(self.calls + len(push))
        stack_params = {param.token.lexeme for param in self.params}
        for inst in emitter.instructions:
            if inst.var in stack_params:
                inst.offset += offset


class Translation(UserList, CNode):
    """Class for translations. This node represents the whole C program."""

    def generate(self):
        """Generate code for the whole C program."""
        emitter = Emitter()
        for trans in self:
            trans.glob_generate(emitter)
        emitter.optimize()
        return str(emitter)
