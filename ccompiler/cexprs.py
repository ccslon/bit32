# -*- coding: utf-8 -*-
"""
Created on Fri Sep  6 14:09:48 2024

@author: ccslon
"""
from bit32 import Size, Op, Reg, Cond, negative, int_to_float, unescape
from .cnodes import Expr, Var, Const, Unary, Binary, Access, Statement
from .ctypes import Char, Int, Float, Pointer, Array


class Local(Var):
    """Class for local variables and parameters."""

    def address(self, emitter, n):
        """Generate address code for local variable."""
        return self.type.address(emitter, n, self, Reg.SP)

    def reduce(self, emitter, n):
        """Generate code for local variable."""
        return self.type.reduce(emitter, n, self, Reg.SP)

    def store(self, emitter, n):
        """Generate code for storing a variable."""
        return self.type.store(emitter, n, self, Reg.SP)


class Attribute(Var):
    """Class for attributes found in structs or unions."""

    def name(self):
        """Get attribute name. Excludes attributes from offset adjustment."""
        return f'.{super().name()}'

    def address(self, emitter, n):
        """Generate address code for attributes."""
        return self.type.address(emitter, n, self, n)  # TODO test

    def reduce(self, emitter, n):
        """Generate code for attributes."""
        return self.type.reduce(emitter, n, self, n)

    def store(self, emitter, n):
        """Generate code for storing an attribute."""
        return self.type.store(emitter, n, self, n+1)


class Global(Var):
    """Class for global variables."""

    def address(self, emitter, n):
        """Generate address code for global variables."""
        return self.type.glob_address(emitter, n, self)

    def reduce(self, emitter, n):
        """Generate code for global variables."""
        return self.type.glob_reduce(emitter, n, self)

    def store(self, emitter, n):
        """Generate code for storing a global variable."""
        return self.type.glob_store(emitter, n, self)

    def glob_generate(self, emitter):
        """Generate code to allocate space for global variable."""
        if self.type.size > 0:
            emitter.space(self.token.lexeme, self.type.size)


class NumberBase(Const):
    """Base class for number literals."""

    def __init__(self, token):
        super().__init__(Int(), token)

    def data(self, _):
        """Get data representation of node."""
        return self.value

    def reduce(self, emitter, n):
        """Generate code for numbers."""
        if 0 <= self.value < 256:
            emitter.binary(Op.MOV, self.width, Reg(n), self.value)
        else:
            emitter.imm(Reg(n), self.value)
        return Reg(n)

    def reduce_num(self, emitter, n):
        """Reduce to number constant if applicable. See Expr class."""
        if 0 <= self.value < 256:
            return self.value
        emitter.imm(Reg(n), self.value)  # TODO test this branch
        return Reg(n)

    def reduce_subscr(self, emitter, n, size):
        """Generate special reduction case for subscript nodes."""
        mul = size*self.value
        if 0 <= mul < 256:
            return mul
        # TODO
        return super().reduce_subscr(emitter, n, size)


class EnumNumber(NumberBase):
    """Class for enum numbers."""

    def __init__(self, token, value):
        super().__init__(token)
        self.value = value


class Number(NumberBase):
    """Class for basic number nodes found anywhere in C code."""

    def __init__(self, token):
        super().__init__(token)
        if token.lexeme.startswith('0x'):
            self.value = int(token.lexeme, base=16)
        elif token.lexeme.startswith('0b'):
            self.value = int(token.lexeme, base=2)
        else:
            self.value = int(token.lexeme)


class Negative(Number):
    """Class for negative number nodes."""

    def reduce(self, emitter, n):
        """Generate code for negative numbers."""
        if 0 <= self.value < 256:
            emitter.binary(Op.MVN, self.width, Reg(n), self.value)
        else:
            emitter.imm(Reg(n), negative(-self.value, 32))  # TODO test
        return Reg(n)

    def reduce_num(self, emitter, n):
        """Reduce to number constant if applicable. See Expr class."""
        if 0 <= self.value <= 128:
            return -self.value
        emitter.imm(Reg(n), negative(-self.value, 32))  # TODO test this branch
        return Reg(n)


class SizeOf(NumberBase):
    """Class for sizeof operator."""

    def __init__(self, ctype, token):
        super().__init__(token)
        self.value = int(ctype.size)


class Decimal(Const):
    """Class for basic decimal numbers found anywhere in C code."""

    def __init__(self, token):
        super().__init__(Float(), token)
        self.value = int_to_float(token.lexeme)

    def data(self, _):
        """Get data representation of decimal."""
        return self.value

    def reduce(self, emitter, n):
        """Generate code for decimals."""
        emitter.imm(Reg(n), self.value, self.token.lexeme)
        return Reg(n)


class NegativeDecimal(Decimal):
    """Class for negative decimals."""

    def __init__(self, token):
        super().__init__(token)
        self.value = int_to_float(f'-{token.lexeme}')


class Character(Const):
    """Class for character literals."""

    def __init__(self, token):
        super().__init__(Char(), token)
        self.value = ord(unescape(token.lexeme.strip('\'')))

    def data(self, _):
        """Get data representation of character."""
        return self.token.lexeme

    def reduce(self, emitter, n):
        """Generate code for character."""
        emitter.binary(Op.MOV, self.width, Reg(n), self.data(emitter))
        return Reg(n)

    def reduce_num(self, emitter, n):
        """Reduce to number constant if applicable. See Expr class."""
        return self.data(emitter)


class String(Const):
    """Class for string literals."""

    def __init__(self, token):
        super().__init__(Pointer(Char()), token)
        self.value = unescape(token.lexeme)

    def data(self, emitter):
        """Get data representation of string."""
        return emitter.string_ptr(self.token.lexeme)

    def reduce(self, emitter, n):
        """Generate code for string."""
        emitter.load_glob(Reg(n), self.data(emitter))
        return Reg(n)


class UnaryOp(Unary):
    """Class for unary operators."""

    def __init__(self, op, expr):
        super().__init__(expr.type, op, expr)
        if not expr.type.cast(Int()):
            op.error(f'Cannot {op.lexeme} {expr.type}')
        self.op = self.type.get_unary_op(op)

    def reduce(self, emitter, n):
        """Generate code for a unary operator."""
        emitter.unary(self.op, self.width, self.expr.reduce(emitter, n))
        return Reg(n)


class Pre(UnaryOp, Statement):
    """Class for pre increment/decrement operators."""

    def reduce(self, emitter, n):
        """Generate code for operator."""
        self.expr.reduce(emitter, n)
        self.type.reduce_pre(emitter, n, self.op)
        self.expr.store(emitter, n)
        return Reg(n)

    def generate(self, emitter, n):
        """Generate code for operator as if it where a statement."""
        self.reduce(emitter, 0)


class Post(UnaryOp, Statement):
    """Class for post increment/decrement operators."""

    def reduce(self, emitter, n):
        """Generate code for operator."""
        self.expr.reduce(emitter, n)
        self.type.reduce_post(emitter, n, self.op)
        self.expr.store(emitter, n+1)
        return Reg(n)

    def generate(self, emitter, n):
        """Generate code for operator as if it where a statement."""
        self.reduce(emitter, 0)


class AddressOf(Unary):
    """Class for address-of operator."""

    def __init__(self, token, expr):
        super().__init__(Pointer(expr.type), token, expr)

    def reduce(self, emitter, n):
        """Generate code for address-of operator."""
        return self.expr.address(emitter, n)


class Dereference(Unary):
    """Class for dereference operator."""

    def __init__(self, token, expr):
        super().__init__(expr.type.to, token, expr)
        if not isinstance(expr.type, (Array, Pointer)):
            token.error(f'Cannot {token.lexeme} {expr.type}')

    def address(self, emitter, n):
        """Generate address code for dereference."""
        return self.expr.reduce(emitter, n)

    def reduce(self, emitter, n):
        """Generate code for dereference."""
        self.address(emitter, n)
        emitter.load(self.width, Reg(n), Reg(n))
        return Reg(n)

    def store(self, emitter, n):
        """Generate code for storing a dereference."""
        self.address(emitter, n+1)
        emitter.store(self.width, Reg(n), Reg(n+1))
        return Reg(n)

    def call(self, emitter, n):
        """Generate code for function pointers."""
        emitter.call(self.address(emitter, n))


class Cast(Unary):
    """Class for casting."""

    def __init__(self, token, cast_type, expr):
        super().__init__(cast_type, token, expr)
        if not cast_type.cast(expr.type):
            token.error(f'Cannot cast {expr.type} to {cast_type}')

    def data(self, emitter):  # TODO test
        """Get data representation of cast."""
        return self.expr.data(emitter)

    def reduce(self, emitter, n):
        """Generate code for casting."""
        self.expr.reduce(emitter, n)
        self.type.convert(emitter, n, self.expr.type)
        return Reg(n)


class Not(Unary):
    """Class for logical not operator."""

    def __init__(self, token, expr):
        super().__init__(expr.type, token, expr)

    def compare(self, emitter, n, label):
        """Generate code for comparing nodes with logical not."""
        emitter.binary(self.type.CMP, self.width, self.expr.reduce(emitter, n), 0)
        emitter.jump(Cond.NE, label)

    def compare_inv(self, emitter, n, label):
        """Generate code for inverse comparing nodes with logical not."""
        emitter.binary(self.type.CMP, self.width, self.expr.reduce(emitter, n), 0)
        emitter.jump(Cond.EQ, label)

    def reduce(self, emitter, n):
        """Generate code for logical not."""
        emitter.binary(self.type.CMP, self.width, self.expr.reduce(emitter, n), 0)
        emitter.mov(Cond.EQ, Reg(n), 1)
        emitter.mov(Cond.NE, Reg(n), 0)
        return Reg(n)


def max_type(left, right):
    """Widening 2 given C types."""
    if isinstance(left, (Float, Pointer)):
        return left
    if isinstance(right, (Float, Pointer)):
        return right
    return type(left if left.width >= right.width else right)(left.signed and right.signed)


class BinaryOp(Binary):
    """Class for binary operators."""

    def __init__(self, op, left, right):
        super().__init__(max_type(left.type, right.type), op, left, right)
        if isinstance(left, String) or isinstance(right, String) or not left.type.cast(right.type):
            op.error(f'Cannot {left.type} {op.lexeme} {right.type}')
        self.op = self.type.get_binary_op(op)

    def reduce(self, emitter, n):
        """Generate code for binary operator."""
        self.type.reduce_binary(emitter, n, self.op, self.left, self.right)
        return Reg(n)


class Compare(Binary):
    """Class for binary copare operators."""

    def __init__(self, op, left, right):
        super().__init__(max_type(left.type, right.type), op, left, right)
        self.op = self.type.get_cmp_op(op)
        self.inv = self.type.get_inv_cmp_op(op)

    def compare(self, emitter, n, label):
        """Generate code for comparing with equality/relational operators."""
        self.type.reduce_compare(emitter, n, self.left, self.right)
        emitter.jump(self.inv, label)

    def compare_inv(self, emitter, n, label):  # TODO test
        """Generate code for inverse comparing with equality/relational operators."""
        self.type.reduce_compare(emitter, n, self.left, self.right)
        emitter.jump(self.op, label)

    def reduce(self, emitter, n):
        """Generate code for compare operator."""
        self.type.reduce_compare(emitter, n, self.left, self.right)
        emitter.mov(self.op, Reg(n), 1)
        emitter.mov(self.inv, Reg(n), 0)
        return Reg(n)


class Logic(BinaryOp):
    """Class for logical operators."""

    def compare(self, emitter, n, label):
        """Generate code for comparing with logical operators."""
        if self.op == Op.AND:
            self.left.compare(emitter, n, label)
            self.right.compare(emitter, n, label)
        elif self.op == Op.OR:
            sublabel = emitter.next_label()
            self.left.compare_inv(emitter, n, sublabel)
            self.right.compare(emitter, n, label)
            emitter.append_label(sublabel)

    def compare_inv(self, emitter, n, label):
        """Generate code for inverse comparing with logical operators."""
        if self.op == Op.AND:
            sublabel = emitter.next_label()
            self.left.compare(emitter, n, sublabel)
            self.right.compare_inv(emitter, n, label)
            emitter.append_label(sublabel)
        elif self.op == Op.OR:
            self.left.compare_inv(emitter, n, label)
            self.right.compare_inv(emitter, n, label)

    def reduce(self, emitter, n):
        """Generate code for logical operator."""
        if self.op == Op.AND:
            label = emitter.next_label()
            sublabel = emitter.next_label()
            self.left.compare(emitter, n, label)
            self.right.compare(emitter, n, label)
            emitter.binary(Op.MOV, Size.WORD, Reg(n), 1)
            emitter.jump(Cond.AL, sublabel)
            emitter.append_label(label)
            emitter.binary(Op.MOV, Size.WORD, Reg(n), 0)
            emitter.append_label(sublabel)
        elif self.op == Op.OR:
            label = emitter.next_label()
            sublabel = emitter.next_label()
            subsublabel = emitter.next_label()
            self.left.compare_inv(emitter, n, label)
            self.right.compare(emitter, n, sublabel)
            emitter.append_label(label)
            emitter.binary(Op.MOV, Size.WORD, Reg(n), 1)
            emitter.jump(Cond.AL, subsublabel)
            emitter.append_label(sublabel)
            emitter.binary(Op.MOV, Size.WORD, Reg(n), 0)
            emitter.append_label(subsublabel)
        return Reg(n)


class Condition(Expr):
    """Class for condition ternary operator."""

    def __init__(self, token, cond, true, false):
        super().__init__(true.type, token)
        self.cond, self.true, self.false = cond, true, false

    def hard_calls(self):
        """Determmine if condition node "hard calls"."""
        return self.cond.hard_calls() or self.true.hard_calls() or self.false.hard_calls()

    def soft_calls(self):
        """Determmine if condition node "soft calls"."""
        return self.cond.soft_calls() or self.true.soft_calls() or self.false.soft_calls()

    def reduce(self, emitter, n):
        """Generate code for condition operator."""
        label = emitter.next_label()
        sublabel = emitter.next_label()
        self.cond.compare(emitter, n, sublabel)
        self.true.reduce(emitter, n)
        emitter.jump(Cond.AL, label)
        emitter.append_label(sublabel)
        self.false.reduce_branch(emitter, n, label)
        emitter.append_label(label)
        return Reg(n)

    def reduce_branch(self, emitter, n, root):  # TODO test
        """Generate code for special condition case."""
        sublabel = emitter.next_label()
        self.cond.compare(emitter, n, sublabel)
        self.true.reduce(emitter, n)
        emitter.jump(Cond.AL, root)
        emitter.append_label(sublabel)
        self.false.reduce_branch(emitter, n, root)


class Dot(Access):
    """Class for dot operator."""

    def address(self, emitter, n):
        """Generate address code for dot operator."""
        emitter.attr(self.struct.address(emitter, n), self.attr)
        return Reg(n)

    def reduce(self, emitter, n):
        """Generate code for dot operator."""
        self.struct.address(emitter, n)
        return self.attr.reduce(emitter, n)

    def store(self, emitter, n):
        """Generate code for storing to a dot operator."""
        self.struct.address(emitter, n+1)
        return self.attr.store(emitter, n)


class Arrow(Access):
    """Class for arrow operator."""

    def address(self, emitter, n):
        """Generate address code for arrow operator."""
        emitter.attr(self.struct.reduce(emitter, n), self.attr)
        return Reg(n)

    def reduce(self, emitter, n):
        """Generate code for arrow operator."""
        self.struct.reduce(emitter, n)
        return self.attr.reduce(emitter, n)

    def store(self, emitter, n):
        """Generate code for storing to an arrow operator."""
        self.struct.reduce(emitter, n+1)
        return self.attr.store(emitter, n)


class SubScript(Binary):
    """Class for array access."""

    def __init__(self, token, left, right):
        super().__init__(left.type.of, token, left, right)

    def address(self, emitter, n):
        """Generate address code for array access."""
        emitter.binary(Op.ADD, Size.WORD, self.left.type.reduce_array(emitter, n, self.left),self.right.reduce_subscr(emitter, n+1, self.left.type.of.size))
        return Reg(n)

    def reduce(self, emitter, n):
        """Generate code for array access."""
        emitter.load(self.width, Reg(n), self.left.type.reduce_array(emitter, n, self.left), self.right.reduce_subscr(emitter, n+1, self.left.type.of.size))
        return Reg(n)

    def store(self, emitter, n):
        """Generate code for storing to an array."""
        emitter.store(self.width, Reg(n), self.left.type.reduce_array(emitter, n+1, self.left), self.right.reduce_subscr(emitter, n+2, self.left.type.of.size))
        return Reg(n)
