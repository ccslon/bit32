# -*- coding: utf-8 -*-
"""
Created on Fri Sep  6 14:09:48 2024

@author: ccslon
"""
from operator import (add, sub, mul, floordiv, truediv, mod,
                      lshift, rshift, neg, or_, xor, and_,
                      eq, ne, gt, lt, ge, le)
from bit32 import WORD_MASK, Size, Op, Reg, Cond, twos_compliment, floating_point, escape_chr
from .cnodes import Expression, Variable, Constant, Unary, Binary, Access, Statement
from .ctypes import Type, Void, Char, Int, Float, Pointer, Array, Function


class Local(Variable):
    """Class for local variables and parameters."""

    def address(self, emitter):
        """Generate address code for local variable."""
        return self.type.address(emitter, Reg.SP, self)

    def reduce(self, emitter):
        """Generate code for local variable."""
        return self.type.reduce(emitter, Reg.SP, self)

    def store(self, emitter, source):
        """Generate code for storing a variable."""
        return self.type.store(emitter, source, Reg.SP, self)

class Register(Variable):

    def address(self, emitter):
        """Generate address code for local variable."""
        raise SyntaxError('Register varaibles are not addressable')

    def reduce(self, emitter):
        """Generate code for local variable."""
        return emitter.get_register_variable(self.name)

    def store(self, emitter, source):
        """Generate code for storing a variable."""
        # emitter.table.clear()
        return emitter.emit_left_move(self.type.width, self.reduce(emitter), source)

class Attribute(Variable):
    """Class for attributes found in structs or unions."""

    def __init__(self, ctype, name):
        super().__init__(ctype, f'.{name}')

    def address(self, emitter):
        """Generate address code for attributes."""
        return self.type.address(emitter, self)  # TODO test

    def reduce(self, emitter, base):
        """Generate code for attributes."""
        return self.type.reduce(emitter, base, self)

    def store(self, emitter, source, base):
        """Generate code for storing an attribute."""
        return self.type.store(emitter, source, base, self)


class Global(Variable):
    """Class for global variables."""

    def is_constant(self):
        """Statically defined variables are considered constant."""
        return isinstance(self.type, Function | Array)  # Struct | Union | Pointer?

    def fold(self):
        """Fold this global into its address."""
        return self

    def data(self, _):
        """Get this global's address as data."""
        return self.name

    def address(self, emitter):
        """Generate address code for global variables."""
        return self.type.global_address(emitter, self)

    def reduce(self, emitter):
        """Generate code for global variables."""
        return self.type.global_reduce(emitter, self)

    def store(self, emitter, source):
        """Generate code for storing a global variable."""
        return self.type.global_store(emitter, source, self)

    def global_generate(self, emitter):
        """Generate code to allocate space for global variable."""
        size = self.type.size()
        if size > 0:
            if isinstance(size, Size):
                emitter.emit_global(self.name, size, 0)
            else:
                emitter.emit_space(self.name, size)


class Number(Constant):
    """Class for basic number nodes found anywhere in C code."""

    def __init__(self, value, ctype=Int()):
        super().__init__(ctype, int(value))

    def data(self, _):
        """Get data representation of node."""
        return self.value

    def reduce(self, emitter):
        """Generate code for numbers."""
        if -128 <= self.value < 256:
            return emitter.emit_unary(Op.MOV, self.width, self.value)
        return emitter.emit_load_immediate(twos_compliment(self.value, 32))

    def reduce_number(self, emitter):
        """Reduce to number constant if applicable. See Expression class."""
        if -128 <= self.value < 256:
            return self.value
        return emitter.emit_load_immediate(twos_compliment(self.value, 32))  # TODO test this branch

    def reduce_subscript(self, emitter, size):
        """Generate special reduction case for subscript nodes."""
        mul = size*self.value
        if 0 <= mul < 256:
            return mul
        return super().reduce_subscript(emitter, size)


class SizeOf(Number):
    """Class for sizeof operator."""

    def __init__(self, ctype):
        super().__init__(ctype.size(), Int(signed=False))


class Decimal(Constant):
    """Class for basic decimal numbers found anywhere in C code."""

    def __init__(self, value):
        super().__init__(Float(), float(value))

    def data(self, _):
        """Get data representation of decimal."""
        return floating_point(self.value)

    def reduce(self, emitter):
        """Generate code for decimals."""
        return emitter.emit_load_immediate(self.data(emitter), str(self.value))

    def reduce_float(self, emitter):
        """Reduce to float."""
        return self.reduce(emitter)


class Character(Constant):
    """Class for character literals."""

    def __init__(self, value):
        super().__init__(Char(), ord(value))
        self.char = value

    def data(self, _):
        """Get data representation of character."""
        return f"'{escape_chr(self.char)}'"

    def reduce(self, emitter):
        """Generate code for character."""
        return emitter.emit_unary(Op.MOV, self.width, self.data(emitter))

    def reduce_number(self, emitter):
        """Reduce to number constant if applicable. See Expression class."""
        return self.data(emitter)


class String(Constant):
    """Class for string literals."""

    def __init__(self, value):
        super().__init__(Array(Char(), len(value)+1), value)

    def data(self, emitter):
        """Get data representation of string."""
        return emitter.emit_string_ptr(self.value)

    def address(self, emitter):
        """Generate address code for string."""
        return self.reduce(emitter)

    def reduce(self, emitter):
        """Generate code for string."""
        return emitter.emit_load_global(self.data(emitter))


class UnaryOp(Unary):
    """Class for unary operators."""

    def __init__(self, op, value):
        if not value.type.cast(Int()):
            op.error(f'Cannot {op.lexeme} {value.type}')
        super().__init__(value.type, value)
        self.op = self.type.get_unary_op(op)

    def evaluate(self):
        """Evaluate unary operator."""
        return {Op.NEG: neg,
                Op.NEGF: neg,
                Op.NOT: lambda n: n ^ WORD_MASK}[self.op](self.value.evaluate())

    def reduce(self, emitter):
        """Generate code for a unary operator."""
        if self.is_constant():
            return self.fold().reduce(emitter)
        return emitter.emit_unary(self.op, self.width, self.value.reduce(emitter))


class Pre(UnaryOp, Statement):
    """Class for pre increment/decrement operators."""

    def evaluate(self):
        """Evaluate pre operator."""
        return {Op.ADD: add, Op.ADDF: add,
                Op.SUB: sub, Op.SUBF: sub}[self.op](self.value.evaluate(), 1)

    def reduce(self, emitter):
        """Generate code for operator."""
        if self.is_constant():
            return self.fold().reduce(emitter)
        target = self.value.reduce(emitter)
        pre = self.type.reduce_pre(emitter, self.op, target)
        self.value.store(emitter, pre)
        return pre

    def generate(self, emitter):
        """Generate code for operator as if it where a statement."""
        self.reduce(emitter)


class Post(UnaryOp, Statement):
    """Class for post increment/decrement operators."""

    def evaluate(self):
        """Evaluate post operator."""
        return self.value.evaluate()

    def reduce(self, emitter):
        """Generate code for operator."""
        if self.is_constant():
            return self.fold().reduce(emitter)
        target = self.value.reduce(emitter)
        post = self.type.reduce_post(emitter, self.op, target)
        self.value.store(emitter, post)
        return target

    def generate(self, emitter):
        """Generate code for operator as if it where a statement."""
        self.reduce(emitter)


class AddressOf(Unary):
    """Class for address-of operator."""

    def __init__(self, token, value):
        if not hasattr(value, 'address'):
            token.error('Cannot take the address of rvalue')
        super().__init__(Pointer(value.type), value)

    def reduce(self, emitter):
        """Generate code for address-of operator."""
        return self.value.address(emitter)


class Dereference(Unary):
    """Class for dereference operator."""

    def __init__(self, token, value):
        if not isinstance(value.type, (Array, Pointer)):
            token.error(f'Cannot {token.lexeme} {value.type}')
        if isinstance(value.type, Void):
            token.error('Cannot dereference a void pointer')
        super().__init__(value.type.to, value)

    def address(self, emitter):
        """Generate address code for dereference."""
        return self.value.reduce(emitter)

    def reduce(self, emitter):
        """Generate code for dereference."""
        base = self.address(emitter)
        return emitter.emit_load(self.width, base)

    def store(self, emitter, source):
        """Generate code for storing a dereference."""
        base = self.address(emitter)
        return emitter.emit_store(self.width, source, base)

    def call(self, emitter, args):
        """Generate code for function pointers."""
        emitter.emit_call(self.address(emitter), args)


class Cast(Unary):
    """Class for casting."""

    def __init__(self, token, cast_type, value):
        if not cast_type.cast(value.type):
            token.error(f'Cannot cast {value.type} to {cast_type}')
        super().__init__(cast_type, value)

    def data(self, emitter):  # TODO test
        """Get data representation of cast."""
        return self.value.data(emitter)

    def evaluate(self):
        """Evaluate cast operator."""
        return self.value.evaluate()

    def reduce(self, emitter):
        """Generate code for casting."""
        if self.is_constant():
            return self.fold().reduce(emitter)
        source = self.value.reduce(emitter)
        return self.type.convert(emitter, source, self.value.type)


class Not(Unary):
    """Class for logical not operator."""

    def __init__(self, value):
        super().__init__(value.type, value)

    def evaluate(self):
        """Evaluate not operator."""
        return not self.value.evaluate()

    def reduce(self, emitter):
        """Generate code for logical not."""
        if self.is_constant():
            return self.fold().reduce(emitter)
        emitter.emit_binary(self.type.CMP, self.width, self.value.reduce(emitter), 0)
        return emitter.emit_cmov(Cond.EQ, Cond.NE)

    def compare(self, emitter, label):
        """Generate code for comparing nodes with logical not."""
        self.value.inverse_compare(emitter, label)

    def inverse_compare(self, emitter, label):
        """Generate code for inverse comparing nodes with logical not."""
        self.value.compare(emitter, label)


class BinaryOp(Binary):
    """Class for binary operators."""

    def __init__(self, op, left, right):
        if isinstance(left, String) or isinstance(right, String) or not left.type.cast(right.type):
            op.error(f'Cannot {left.type} {op.lexeme} {right.type}')
        super().__init__(Type.max_type(left.type, right.type), left, right)
        self.op = self.type.get_binary_op(op)

    def evaluate(self):
        """Evaluate binary operator."""
        return {Op.ADD: add,
                Op.ADDF: add,
                Op.SUB: sub,
                Op.ADDF: sub,
                Op.MUL: mul,
                Op.MULF: mul,
                Op.DIV: floordiv,
                Op.DIVF: truediv,
                Op.MOD: mod,
                Op.SHR: rshift,
                Op.SHL: lshift,
                Op.OR: or_,
                Op.XOR: xor,
                Op.AND: and_}[self.op](self.left.evaluate(), self.right.evaluate())

    def reduce(self, emitter):
        """Generate code for binary operator."""
        if self.is_constant():
            return self.fold().reduce(emitter)
        if self.left.is_constant() and self.op in {Op.ADD, Op.ADDF, Op.MUL, Op.MULF, Op.AND, Op.OR, Op.XOR}:
            self.left, self.right = self.right, self.left
        return self.type.reduce_binary(emitter, self.op, self.left, self.right)


MIRRORED = {
    Cond.EQ: Cond.EQ, Cond.NE: Cond.NE,
    Cond.GT: Cond.LT, Cond.HI: Cond.LO,
    Cond.LT: Cond.GT, Cond.LO: Cond.HI,
    Cond.GE: Cond.LE, Cond.HS: Cond.LS,
    Cond.LE: Cond.GE, Cond.LS: Cond.HS
}


class Compare(Binary):
    """Class for binary compare operators."""

    def __init__(self, op, left, right):
        super().__init__(Type.max_type(left.type, right.type), left, right)
        self.op = self.type.get_cmp_op(op)
        self.inverse_op = self.type.get_inv_cmp_op(op)

    def evaluate(self):
        """Evaluate compare operator."""
        return {Cond.EQ: eq, Cond.NE: ne,
                Cond.GT: gt, Cond.HI: gt,
                Cond.LT: lt, Cond.LO: lt,
                Cond.GE: ge, Cond.HS: ge,
                Cond.LE: le, Cond.LS: le}[self.op](self.left.evaluate(), self.right.evaluate())

    def mirror(self):
        """Mirror the node to put the constant on the right side."""        
        self.left, self.right = self.right, self.left
        self.op = MIRRORED[self.op]
        self.inverse_op = MIRRORED[self.inverse_op]

    def reduce(self, emitter):
        """Generate code for compare operator."""
        if self.is_constant():
            return self.fold().reduce(emitter)
        if self.left.is_constant():
            self.mirror()
        self.type.reduce_compare(emitter, self.left, self.right)
        return emitter.emit_cmov(self.op, self.inverse_op)

    def compare(self, emitter, label):
        """Generate code for comparing with equality/relational operators."""
        if self.left.is_constant():
            self.mirror()
        self.type.reduce_compare(emitter, self.left, self.right)
        emitter.emit_jump(self.inverse_op, label)

    def inverse_compare(self, emitter, label):  # TODO test
        """Generate code for inverse comparing with equality/relational operators."""
        if self.left.is_constant():
            self.mirror()
        self.type.reduce_compare(emitter, self.left, self.right)
        emitter.emit_jump(self.op, label)


class Logic(BinaryOp):
    """Class for logical operators."""

    def evaluate(self):
        """Evaluate logic operator."""
        return {Op.AND: lambda a, b: a and b,
                Op.OR: lambda a, b: a or b}[self.op](self.left.evaluate(), self.right.evaluate())

    def reduce(self, emitter):
        """Generate code for logical operator."""
        if self.is_constant():
            return self.fold().reduce(emitter)
        if self.op is Op.AND:
            label = emitter.next_label()
            sublabel = emitter.next_label()
            self.left.compare(emitter, label)
            self.right.compare(emitter, label)
            target = emitter.emit_logic(label, sublabel)
            emitter.append_label(sublabel)
            return target
        if self.op is Op.OR:
            label = emitter.next_label()
            sublabel = emitter.next_label()
            subsublabel = emitter.next_label()
            self.left.inverse_compare(emitter, label)
            self.right.compare(emitter, sublabel)
            emitter.append_label(label)
            target = emitter.emit_logic(sublabel, subsublabel)
            emitter.append_label(subsublabel)
            return target

    def compare(self, emitter, label):
        """Generate code for comparing with logical operators."""
        if self.op is Op.AND:
            self.left.compare(emitter, label)
            self.right.compare(emitter, label)
        elif self.op is Op.OR:
            sublabel = emitter.next_label()
            self.left.inverse_compare(emitter, sublabel)
            self.right.compare(emitter, label)
            emitter.append_label(sublabel)

    def inverse_compare(self, emitter, label):
        """Generate code for inverse comparing with logical operators."""
        if self.op is Op.AND:
            sublabel = emitter.next_label()
            self.left.compare(emitter, sublabel)
            self.right.inverse_compare(emitter, label)
            emitter.append_label(sublabel)
        elif self.op is Op.OR:
            self.left.inverse_compare(emitter, label)
            self.right.inverse_compare(emitter, label)


class Conditional(Expression):
    """Class for conditional ternary operator."""

    def __init__(self, test, true, false):
        super().__init__(true.type)
        self.test = test
        self.true = true
        self.false = false

    def is_constant(self):
        """Determine if conditional is constant."""
        return self.test.is_constant() and self.true.is_constant() and self.false.is_constant()

    def evaluate(self):
        """Evaluate conditional operator."""
        return self.true.evaluate() if self.test.evaluate() else self.false.evaluate()

    def fold(self):
        """Fold this conditional operator into a single constant node."""
        return self.true.fold() if self.test.evaluate() else self.false.fold()

    def reduce(self, emitter):
        """Generate code for conditional operator."""
        if self.is_constant():
            return self.fold().reduce(emitter)
        if self.test.is_constant():
            if self.test.evaluate():
                return self.true.reduce(emitter)
            return self.false.reduce(emitter)
        label = emitter.next_label()
        sublabel = emitter.next_label()
        self.test.compare(emitter, sublabel)
        true = self.true.reduce(emitter)
        emitter.emit_jump(Cond.AL, label)
        emitter.append_label(sublabel)
        false = self.false.reduce_branch(emitter, label)
        emitter.emit_left_move(self.width, true, false)
        emitter.append_label(label)
        return true

    def reduce_branch(self, emitter, root):  # TODO test
        """Generate code for special conditional case."""
        sublabel = emitter.next_label()
        self.test.compare(emitter, sublabel)
        true = self.true.reduce(emitter)
        emitter.emit_jump(Cond.AL, root)
        emitter.append_label(sublabel)
        false = self.false.reduce_branch(emitter, root)
        emitter.emit_left_move(self.width, true, false)
        return true


class Dot(Access):
    """Class for dot operator."""

    def address(self, emitter):
        """Generate address code for dot operator."""
        return emitter.emit_attribute(self.struct.address(emitter), self.attribute.offset, self.attribute.name)

    def reduce(self, emitter):
        """Generate code for dot operator."""
        base = self.struct.address(emitter)
        return self.attribute.reduce(emitter, base)

    def store(self, emitter, source):
        """Generate code for storing to a dot operator."""
        base = self.struct.address(emitter)
        return self.attribute.store(emitter, source, base)


class Arrow(Access):
    """Class for arrow operator."""

    def address(self, emitter):
        """Generate address code for arrow operator."""
        return emitter.emit_attribute(self.struct.reduce(emitter), self.attribute.offset, self.attribute.name)

    def reduce(self, emitter):
        """Generate code for arrow operator."""
        base = self.struct.reduce(emitter)
        return self.attribute.reduce(emitter, base)

    def store(self, emitter, source):
        """Generate code for storing to an arrow operator."""
        base = self.struct.reduce(emitter)
        return self.attribute.store(emitter, source, base)


class SubScript(Binary):
    """Class for array access."""

    def __init__(self, left, right):
        super().__init__(left.type.of, left, right)

    def address(self, emitter):
        """Generate address code for array access."""
        return emitter.emit_address(self.left.type.reduce_array(emitter, self.left),
                                    self.right.reduce_subscript(emitter, self.left.type.of.size()))

    def reduce(self, emitter):
        """Generate code for array access."""
        return emitter.emit_load(self.width,
                                 self.left.type.reduce_array(emitter, self.left),
                                 self.right.reduce_subscript(emitter, self.left.type.of.size()))

    def store(self, emitter, source):
        """Generate code for storing to an array."""
        return emitter.emit_store(self.width, source,
                                  self.left.type.reduce_array(emitter, self.left),
                                  self.right.reduce_subscript(emitter, self.left.type.of.size()))
