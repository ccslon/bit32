# -*- coding: utf-8 -*-
"""
Created on Sat Mar  1 11:43:13 2025

@author: Colin
"""
from collections import UserDict, UserList
from bit32 import Op, Cond, Size, Reg


REG_ARGS = 4  # first 4 arguments are passed in the first 4 registers


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
        self.size += obj.type.size()
        super().__setitem__(name, obj)


class CNode:
    """Base class for nodes representing C programs."""

    def generate(self, emitter):
        """Generate target code."""
        pass

    def branch(self, emitter, _):
        """Handle branch for if statements."""
        self.generate(emitter)


class Statement(CNode):
    """Base class for C statements."""

    def last_is_return(self):
        """Determine if the last instruction is a return."""
        return False


class Expression(CNode):
    """Base class for C expressions."""

    def __init__(self, ctype):
        self.type = ctype
        self.width = ctype.width

    def is_constant(self):
        """
        Determine if subexpression is constant.

        Recurse property of expressions.
        This is used to determine if a subtree only contains constant values.
        Subtrees that are constant can be evaluated at compile time. They also
        allow for other compile time optimizations.
        """
        return False  # default is false

    def reduce(self, emitter):
        """Generate code to "reduce" the expression into a single register."""
        raise NotImplementedError(self.__class__.__name__)

    def compare(self, emitter, label):
        """Generate code for comparing nodes. Default is comparing to 0."""
        emitter.emit_compare(self.type.CMP, self.width, self.reduce(emitter), 0)
        emitter.emit_jump(Cond.EQ, label)

    def inverse_compare(self, emitter, label):
        """Generate code for inverse comparing nodes."""
        emitter.emit_compare(self.type.CMP, self.width, self.reduce(emitter), 0)
        emitter.emit_jump(Cond.NE, label)

    def reduce_branch(self, emitter, _):
        """Reduce expression for ternary condition operator."""
        return self.reduce(emitter)

    def reduce_number(self, emitter):
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
        if self.is_constant():
            return self.fold().reduce_number(emitter)
        return self.reduce(emitter)

    def reduce_float(self, emitter):
        """Reduce to float (convert if applicable)."""
        target = self.reduce(emitter)
        return self.type.itf(emitter, target)

    def reduce_subscript(self, emitter, size):
        """
        Generate special reduction case for subscript nodes.

        Used especially when the index is a constant.
        """
        index = self.reduce(emitter)
        if size > 1:
            return emitter.emit_binary(Op.MUL, Size.WORD, index, int(size))
        return index


class Variable(Expression):
    """Base class for variable nodes."""

    def __init__(self, ctype, name):
        super().__init__(ctype)
        self.name = name
        self.marked = False

    def call(self, emitter, args):
        """Generate default call behavior."""
        emitter.emit_call(self.name, args)


class Constant(Expression):
    """Class for constant nodes."""

    def __init__(self, ctype, value):
        super().__init__(ctype)
        self.value = value

    def is_constant(self):
        """Constants are constant."""
        return True

    def evaluate(self):
        """Evaluate this node in the case of a constant expression."""
        return self.value  # default is the constant node's value

    def fold(self):
        """Fold this sub expression into a single constant node."""
        return self  # default is no folding (just return self)


class Unary(Expression):
    """Base class for unary nodes."""

    def __init__(self, ctype, value):
        super().__init__(ctype)
        self.value = value

    def is_constant(self):
        """Determine if subtree is constant."""
        return self.value.is_constant()

    def fold(self):
        """Fold this unary operator into a single constant node."""
        return self.type.get_node(self.evaluate())


class Binary(Expression):
    """Base class for binary nodes."""

    def __init__(self, ctype, left, right):
        super().__init__(ctype)
        self.left = left
        self.right = right

    def is_constant(self):
        """Determine if subtree is const."""
        return self.left.is_constant() and self.right.is_constant()

    def fold(self):
        """Fold this binary operator into a single constant node."""
        return self.type.get_node(self.evaluate())


class Access(Expression):
    """Base class for array access nodes."""

    def __init__(self, struct, attribute):
        super().__init__(attribute.type)
        self.struct = struct
        self.attribute = attribute


class Definition(CNode):
    """Class for function definition nodes."""

    def __init__(self, ctype, name, block, info):
        self.type = ctype
        self.name = name
        self.parameters = ctype.parameters
        self.block = block
        self.returns, self.calls, self.space = info

    def global_generate(self, emitter):
        """Generate all of the code for the function."""
        emitter.begin_body(self)
        # mark stack locals
        self.mark_stack_locals()
        # generate function body
        self.block.generate(emitter)
        # find max register used in body
        max_reg = emitter.allocate_registers()
        # calculate list of register to push onto the stack
        push = list(map(Reg, range(max(bool(self.type.return_type.width),
                                       len(self.parameters[:REG_ARGS])),
                                   max_reg+1)))
        self.adjust_offsets(emitter, push)
        emitter.end_body()
        emitter.append_label(self.name.lexeme)
        self.prologue(emitter, push)
        emitter.add_body()
        # epilogue
        if self.returns or self.type.return_type.width:
            emitter.append_label(emitter.return_label)
        if self.space:
            emitter.emit_stack_deallocation(self.space)
        self.ret(emitter, push)

    def mark_stack_locals(self):
        """Mark any params that live on the stack to be adjusted later."""
        for param in self.parameters[REG_ARGS:]:
            param.marked = True

    def prologue(self, emitter, push):
        """Generate prologue code specific to regular functions."""
        emitter.emit_push(push + [Reg.LR]*self.calls)
        if self.space:
            emitter.emit_stack_allocation(self.space)
        for i, param in enumerate(self.parameters[:REG_ARGS]):
            emitter.emit_store(param.width, Reg(i), Reg.SP, param.offset, False, param.name)

    def ret(self, emitter, pop):
        """Generate return code specific to regular functions."""
        if len(self.parameters) > REG_ARGS:
            emitter.emit_pop(pop + [Reg.LR]*self.calls)
            emitter.emit_stack_deallocation((len(self.parameters)-REG_ARGS) * Size.WORD)
            emitter.emit_ret()
        elif self.calls:
            emitter.emit_pop(pop + [Reg.PC])
        else:
            emitter.emit_pop(pop)
            emitter.emit_ret()

    def adjust_offsets(self, emitter, push):
        """Adjust offsets of variable found on the call stack."""
        if len(self.parameters) > REG_ARGS:
            adjustment = self.space + Size.WORD*(self.calls + len(push))
            for inst in emitter.instructions:
                inst.adjust_offset(adjustment)


class VariadicDefinition(Definition):  # TODO test
    """Class for variadic function definition nodes."""

    def mark_stack_locals(self):
        """Mark any params that live on the stack to be adjusted later."""
        for param in self.parameters:
            param.marked = True

    def prologue(self, emitter, push):
        """Generate prologue code specific to variadic functions."""
        emitter.emit_push(list(map(Reg, range(REG_ARGS))))
        emitter.emit_push(push + [Reg.LR]*self.calls)
        if self.space:
            emitter.emit_stack_allocation(self.space)

    def ret(self, emitter, push):
        """Generate return code specific to variadic functions."""
        emitter.emit_pop(push + [Reg.LR]*self.calls)
        emitter.emit_stack_deallocation((REG_ARGS+len(self.parameters[REG_ARGS:])) * Size.WORD)
        emitter.emit_ret()

    def adjust_offsets(self, emitter, push):
        """Adjust offsets of variables found on the call stack."""
        adjustment = self.space + Size.WORD*(self.calls + len(push))
        for inst in emitter.instructions:
            inst.adjust_offset(adjustment)


class Translation(UserList, CNode):
    """Class for translations. This node represents the whole C program."""

    def generate(self, emitter):
        """Generate code for the whole C program."""
        for trans in self:
            trans.global_generate(emitter)
        emitter.optimize()
