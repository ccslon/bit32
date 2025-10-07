# -*- coding: utf-8 -*-
"""
Created on Fri Sep  6 14:09:48 2024

@author: ccslon
"""
from bit32 import Size, Op, Reg, Cond, negative, int_to_float, unescape
from .cnodes import Expression, Variable, Constant, Unary, Binary, Access, Statement
from .ctypes import Char, Int, Float, Pointer, Array


class Local(Variable):
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


class Attribute(Variable):
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


class Global(Variable):
    """Class for global variables."""

    def address(self, emitter, n):
        """Generate address code for global variables."""
        return self.type.global_address(emitter, n, self)

    def reduce(self, emitter, n):
        """Generate code for global variables."""
        return self.type.global_reduce(emitter, n, self)

    def store(self, emitter, n):
        """Generate code for storing a global variable."""
        return self.type.global_store(emitter, n, self)

    def global_generate(self, emitter):
        """Generate code to allocate space for global variable."""
        if self.type.size > 0:
            emitter.emit_space(self.token.lexeme, self.type.size)


class NumberBase(Constant):
    """Base class for number literals."""

    def __init__(self, token):
        super().__init__(Int(), token)

    def data(self, _):
        """Get data representation of node."""
        return self.value

    def reduce(self, emitter, n):
        """Generate code for numbers."""
        if 0 <= self.value < 256:
            emitter.emit_binary(Op.MOV, self.width, Reg(n), self.value)
        else:
            emitter.emit_load_immediate(Reg(n), self.value)
        return Reg(n)

    def reduce_number(self, emitter, n):
        """Reduce to number constant if applicable. See Expression class."""
        if 0 <= self.value < 256:
            return self.value
        emitter.emit_load_immediate(Reg(n), self.value)  # TODO test this branch
        return Reg(n)

    def reduce_subscript(self, emitter, n, size):
        """Generate special reduction case for subscript nodes."""
        mul = size*self.value
        if 0 <= mul < 256:
            return mul
        # TODO
        return super().reduce_subscript(emitter, n, size)


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
            emitter.emit_binary(Op.MVN, self.width, Reg(n), self.value)
        else:
            emitter.emit_load_immediate(Reg(n), negative(-self.value, 32))  # TODO test
        return Reg(n)

    def reduce_number(self, emitter, n):
        """Reduce to number constant if applicable. See Expression class."""
        if 0 <= self.value <= 128:
            return -self.value
        emitter.emit_load_immediate(Reg(n), negative(-self.value, 32))  # TODO test this branch
        return Reg(n)


class SizeOf(NumberBase):
    """Class for sizeof operator."""

    def __init__(self, ctype, token):
        super().__init__(token)
        self.value = int(ctype.size)


class Decimal(Constant):
    """Class for basic decimal numbers found anywhere in C code."""

    def __init__(self, token):
        super().__init__(Float(), token)
        self.value = int_to_float(token.lexeme)

    def data(self, _):
        """Get data representation of decimal."""
        return self.value

    def reduce(self, emitter, n):
        """Generate code for decimals."""
        emitter.emit_load_immediate(Reg(n), self.value, self.token.lexeme)
        return Reg(n)


class NegativeDecimal(Decimal):
    """Class for negative decimals."""

    def __init__(self, token):
        super().__init__(token)
        self.value = int_to_float(f'-{token.lexeme}')


class Character(Constant):
    """Class for character literals."""

    def __init__(self, token):
        super().__init__(Char(), token)
        self.value = ord(unescape(token.lexeme.strip('\'')))

    def data(self, _):
        """Get data representation of character."""
        return self.token.lexeme

    def reduce(self, emitter, n):
        """Generate code for character."""
        emitter.emit_binary(Op.MOV, self.width, Reg(n), self.data(emitter))
        return Reg(n)

    def reduce_number(self, emitter, n):
        """Reduce to number constant if applicable. See Expression class."""
        return self.data(emitter)


class String(Constant):
    """Class for string literals."""

    def __init__(self, token):
        super().__init__(Pointer(Char()), token)
        self.value = unescape(token.lexeme)

    def data(self, emitter):
        """Get data representation of string."""
        return emitter.emit_string_ptr(self.token.lexeme)

    def reduce(self, emitter, n):
        """Generate code for string."""
        emitter.emit_load_global(Reg(n), self.data(emitter))
        return Reg(n)


class UnaryOp(Unary):
    """Class for unary operators."""

    def __init__(self, op, value):
        super().__init__(value.type, op, value)
        if not value.type.cast(Int()):
            op.error(f'Cannot {op.lexeme} {value.type}')
        self.op = self.type.get_unary_op(op)

    def reduce(self, emitter, n):
        """Generate code for a unary operator."""
        emitter.emit_unary(self.op, self.width, self.value.reduce(emitter, n))
        return Reg(n)


class Pre(UnaryOp, Statement):
    """Class for pre increment/decrement operators."""

    def reduce(self, emitter, n):
        """Generate code for operator."""
        self.value.reduce(emitter, n)
        self.type.reduce_pre(emitter, n, self.op)
        self.value.store(emitter, n)
        return Reg(n)

    def generate(self, emitter, n):
        """Generate code for operator as if it where a statement."""
        self.reduce(emitter, 0)


class Post(UnaryOp, Statement):
    """Class for post increment/decrement operators."""

    def reduce(self, emitter, n):
        """Generate code for operator."""
        self.value.reduce(emitter, n)
        self.type.reduce_post(emitter, n, self.op)
        self.value.store(emitter, n+1)
        return Reg(n)

    def generate(self, emitter, n):
        """Generate code for operator as if it where a statement."""
        self.reduce(emitter, 0)


class AddressOf(Unary):
    """Class for address-of operator."""

    def __init__(self, token, value):
        super().__init__(Pointer(value.type), token, value)

    def reduce(self, emitter, n):
        """Generate code for address-of operator."""
        return self.value.address(emitter, n)


class Dereference(Unary):
    """Class for dereference operator."""

    def __init__(self, token, value):
        super().__init__(value.type.to, token, value)
        if not isinstance(value.type, (Array, Pointer)):
            token.error(f'Cannot {token.lexeme} {value.type}')

    def address(self, emitter, n):
        """Generate address code for dereference."""
        return self.value.reduce(emitter, n)

    def reduce(self, emitter, n):
        """Generate code for dereference."""
        self.address(emitter, n)
        emitter.emit_load(self.width, Reg(n), Reg(n))
        return Reg(n)

    def store(self, emitter, n):
        """Generate code for storing a dereference."""
        self.address(emitter, n+1)
        emitter.emit_store(self.width, Reg(n), Reg(n+1))
        return Reg(n)

    def call(self, emitter, n):
        """Generate code for function pointers."""
        emitter.emit_call(self.address(emitter, n))


class Cast(Unary):
    """Class for casting."""

    def __init__(self, token, cast_type, value):
        super().__init__(cast_type, token, value)
        if not cast_type.cast(value.type):
            token.error(f'Cannot cast {value.type} to {cast_type}')

    def data(self, emitter):  # TODO test
        """Get data representation of cast."""
        return self.value.data(emitter)

    def reduce(self, emitter, n):
        """Generate code for casting."""
        self.value.reduce(emitter, n)
        self.type.convert(emitter, n, self.value.type)
        return Reg(n)


class Not(Unary):
    """Class for logical not operator."""

    def __init__(self, token, value):
        super().__init__(value.type, token, value)

    def compare(self, emitter, n, label):
        """Generate code for comparing nodes with logical not."""
        emitter.emit_binary(self.type.CMP, self.width, self.value.reduce(emitter, n), 0)
        emitter.emit_jump(Cond.NE, label)

    def inverse_compare(self, emitter, n, label):
        """Generate code for inverse comparing nodes with logical not."""
        emitter.emit_binary(self.type.CMP, self.width, self.value.reduce(emitter, n), 0)
        emitter.emit_jump(Cond.EQ, label)

    def reduce(self, emitter, n):
        """Generate code for logical not."""
        emitter.emit_binary(self.type.CMP, self.width, self.value.reduce(emitter, n), 0)
        emitter.emit_cmov(Cond.EQ, Reg(n), 1)
        emitter.emit_cmov(Cond.NE, Reg(n), 0)
        return Reg(n)


def max_type(left, right):
    """Widen 2 given C types."""
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
        emitter.emit_jump(self.inv, label)

    def inverse_compare(self, emitter, n, label):  # TODO test
        """Generate code for inverse comparing with equality/relational operators."""
        self.type.reduce_compare(emitter, n, self.left, self.right)
        emitter.emit_jump(self.op, label)

    def reduce(self, emitter, n):
        """Generate code for compare operator."""
        self.type.reduce_compare(emitter, n, self.left, self.right)
        emitter.emit_cmov(self.op, Reg(n), 1)
        emitter.emit_cmov(self.inv, Reg(n), 0)
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
            self.left.inverse_compare(emitter, n, sublabel)
            self.right.compare(emitter, n, label)
            emitter.append_label(sublabel)

    def inverse_compare(self, emitter, n, label):
        """Generate code for inverse comparing with logical operators."""
        if self.op == Op.AND:
            sublabel = emitter.next_label()
            self.left.compare(emitter, n, sublabel)
            self.right.inverse_compare(emitter, n, label)
            emitter.append_label(sublabel)
        elif self.op == Op.OR:
            self.left.inverse_compare(emitter, n, label)
            self.right.inverse_compare(emitter, n, label)

    def reduce(self, emitter, n):
        """Generate code for logical operator."""
        if self.op == Op.AND:
            label = emitter.next_label()
            sublabel = emitter.next_label()
            self.left.compare(emitter, n, label)
            self.right.compare(emitter, n, label)
            emitter.emit_binary(Op.MOV, Size.WORD, Reg(n), 1)
            emitter.emit_jump(Cond.AL, sublabel)
            emitter.append_label(label)
            emitter.emit_binary(Op.MOV, Size.WORD, Reg(n), 0)
            emitter.append_label(sublabel)
        elif self.op == Op.OR:
            label = emitter.next_label()
            sublabel = emitter.next_label()
            subsublabel = emitter.next_label()
            self.left.inverse_compare(emitter, n, label)
            self.right.compare(emitter, n, sublabel)
            emitter.append_label(label)
            emitter.emit_binary(Op.MOV, Size.WORD, Reg(n), 1)
            emitter.emit_jump(Cond.AL, subsublabel)
            emitter.append_label(sublabel)
            emitter.emit_binary(Op.MOV, Size.WORD, Reg(n), 0)
            emitter.append_label(subsublabel)
        return Reg(n)


class Conditional(Expression):
    """Class for conditional ternary operator."""

    def __init__(self, token, test, true, false):
        super().__init__(true.type, token)
        self.test = test
        self.true = true
        self.false = false

    def hard_calls(self):
        """Determmine if conditional node "hard calls"."""
        return self.test.hard_calls() or self.true.hard_calls() or self.false.hard_calls()

    def soft_calls(self):
        """Determmine if conditional node "soft calls"."""
        return self.test.soft_calls() or self.true.soft_calls() or self.false.soft_calls()

    def reduce(self, emitter, n):
        """Generate code for conditional operator."""
        label = emitter.next_label()
        sublabel = emitter.next_label()
        self.test.compare(emitter, n, sublabel)
        self.true.reduce(emitter, n)
        emitter.emit_jump(Cond.AL, label)
        emitter.append_label(sublabel)
        self.false.reduce_branch(emitter, n, label)
        emitter.append_label(label)
        return Reg(n)

    def reduce_branch(self, emitter, n, root):  # TODO test
        """Generate code for special conditional case."""
        sublabel = emitter.next_label()
        self.test.compare(emitter, n, sublabel)
        self.true.reduce(emitter, n)
        emitter.emit_jump(Cond.AL, root)
        emitter.append_label(sublabel)
        self.false.reduce_branch(emitter, n, root)


class Dot(Access):
    """Class for dot operator."""

    def address(self, emitter, n):
        """Generate address code for dot operator."""
        emitter.emit_attribute(self.struct.address(emitter, n), self.attribute)
        return Reg(n)

    def reduce(self, emitter, n):
        """Generate code for dot operator."""
        self.struct.address(emitter, n)
        return self.attribute.reduce(emitter, n)

    def store(self, emitter, n):
        """Generate code for storing to a dot operator."""
        self.struct.address(emitter, n+1)
        return self.attribute.store(emitter, n)


class Arrow(Access):
    """Class for arrow operator."""

    def address(self, emitter, n):
        """Generate address code for arrow operator."""
        emitter.emit_attribute(self.struct.reduce(emitter, n), self.attribute)
        return Reg(n)

    def reduce(self, emitter, n):
        """Generate code for arrow operator."""
        self.struct.reduce(emitter, n)
        return self.attribute.reduce(emitter, n)

    def store(self, emitter, n):
        """Generate code for storing to an arrow operator."""
        self.struct.reduce(emitter, n+1)
        return self.attribute.store(emitter, n)


class SubScript(Binary):
    """Class for array access."""

    def __init__(self, token, left, right):
        super().__init__(left.type.of, token, left, right)

    def address(self, emitter, n):
        """Generate address code for array access."""
        emitter.emit_binary(Op.ADD, Size.WORD,
                            self.left.type.reduce_array(emitter, n, self.left),
                            self.right.reduce_subscript(emitter, n+1, self.left.type.of.size))
        return Reg(n)

    def reduce(self, emitter, n):
        """Generate code for array access."""
        emitter.emit_load(self.width, Reg(n),
                          self.left.type.reduce_array(emitter, n, self.left),
                          self.right.reduce_subscript(emitter, n+1, self.left.type.of.size))
        return Reg(n)

    def store(self, emitter, n):
        """Generate code for storing to an array."""
        emitter.emit_store(self.width, Reg(n),
                           self.left.type.reduce_array(emitter, n+1, self.left),
                           self.right.reduce_subscript(emitter, n+2, self.left.type.of.size))
        return Reg(n)
