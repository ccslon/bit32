# -*- coding: utf-8 -*-
"""
Created on Fri Sep  6 14:09:48 2024

@author: ccslon
"""
from bit32 import Size, Op, Reg, Cond, negative, itf, unescape
from .cnodes import Expr, Var, Const, Unary, Binary, Access, Statement
from .ctypes import Char, Int, Float, Pointer, Array

class Local(Var):
    def address(self, emitter, n):
        return self.type.address(emitter, n, self, Reg.SP)
    def reduce(self, emitter, n):
        return self.type.reduce(emitter, n, self, Reg.SP)
    def store(self, emitter, n):
        return self.type.store(emitter, n, self, Reg.SP)

class Attr(Var):
    def name(self):
        return f'.{super().name()}'
    def address(self, emitter, n):
        return self.type.address(emitter, n, self, n) #TODO test
    def reduce(self, emitter, n):
        return self.type.reduce(emitter, n, self, n)
    def store(self, emitter, n):
        return self.type.store(emitter, n, self, n+1)

class Glob(Var):
    def reduce(self, emitter, n):
        return self.type.glob_reduce(emitter, n, self)
    def address(self, emitter, n):
        return self.type.glob_address(emitter, n, self)
    def store(self, emitter, n):
        return self.type.glob_store(emitter, n, self)
    def glob_generate(self, emitter):
        if self.type.size > 0:
            emitter.space(self.token.lexeme, self.type.size)

class NumberBase(Const):
    def __init__(self, token):
        super().__init__(Int(), token)
    def data(self, _):
        return self.value
    def reduce(self, emitter, n):
        if 0 <= self.value < 256:
            emitter.binary(Op.MOV, self.width, Reg(n), self.value)
        else:
            emitter.imm(self.width, Reg(n), self.value)
        return Reg(n)
    def reduce_num(self, emitter, n):
        if 0 <= self.value < 256:
            return self.value
        emitter.imm(self.width, Reg(n), self.value) #TODO test this branch
        return Reg(n)
    def reduce_subscr(self, emitter, n, size):
        mul = size*self.value
        if 0 <= mul < 256:
            return mul
        #TODO
        return super().reduce_subscr(emitter, n, size)        

class EnumNumber(NumberBase):
    def __init__(self, token, value):
        super().__init__(token)
        self.value = value

class Number(NumberBase):
    def __init__(self, token):
        super().__init__(token)
        if token.lexeme.startswith('0x'):
            self.value = int(token.lexeme, base=16)
        elif token.lexeme.startswith('0b'):
            self.value = int(token.lexeme, base=2)
        else:
            self.value = int(token.lexeme)

class NegNumber(Number):
    def reduce(self, emitter, n):
        if 0 <= self.value < 256:
            emitter.binary(Op.MVN, self.width, Reg(n), self.value)
        else:
            emitter.imm(self.width, Reg(n), negative(-self.value, 32)) #TODO test this branch
        return Reg(n)
    def reduce_num(self, emitter, n):
        if 0 <= self.value <= 128:
            return -self.value
        emitter.imm(self.width, Reg(n), negative(-self.value, 32)) #TODO test this branch
        return Reg(n)

class SizeOf(NumberBase):
    def __init__(self, ctype, token):
        super().__init__(token)
        self.value = int(ctype.size)

class Decimal(Const):
    def __init__(self, token):
        super().__init__(Float(), token)
        self.value = itf(token.lexeme)
    def data(self, _):
        return self.value
    def reduce(self, emitter, n):
        emitter.imm(self.width, Reg(n), self.value)
        return Reg(n)

class NegDecimal(Decimal):
    def __init__(self, token):
        super().__init__(token)
        self.value = itf(f'-{token.lexeme}')

class Character(Const):
    def __init__(self, token):
        super().__init__(Char(), token)
        self.value = ord(token.lexeme.strip('\''))
    def data(self, _):
        return self.token.lexeme
    def reduce(self, emitter, n):
        emitter.binary(Op.MOV, self.width, Reg(n), self.data(emitter))
        return Reg(n)
    def reduce_num(self, emitter, n):
        return self.data(emitter)

class String(Const):
    def __init__(self, token):
        super().__init__(Pointer(Char()), token)
        self.value = unescape(token.lexeme)
    def data(self, emitter):
        return emitter.string_ptr(self.token.lexeme)
    def reduce(self, emitter, n):
        emitter.load_glob(Reg(n), self.data(emitter))
        return Reg(n)

class UnaryOp(Unary):
    def __init__(self, op, expr):
        super().__init__(expr.type, op, expr)
        if not expr.type.cast(Int()):
            op.error(f'Cannot {op.lexeme} {expr.type}')
        self.op = self.type.get_unary_op(op)
    def reduce(self, emitter, n):
        emitter.unary(self.op, self.width, self.expr.reduce(emitter, n))
        return Reg(n)

class Pre(UnaryOp, Statement):
    def reduce(self, emitter, n):
        self.expr.reduce(emitter, n)
        self.type.reduce_pre(emitter, n, self.op)
        self.expr.store(emitter, n)
        return Reg(n)
    def generate(self, emitter, n):
        self.reduce(emitter, 0)

class Post(UnaryOp, Statement):
    def reduce(self, emitter, n):
        self.expr.reduce(emitter, n)
        self.type.reduce_post(emitter, n, self.op)
        self.expr.store(emitter, n+1)
        return Reg(n)
    def generate(self, emitter, n):
        self.reduce(emitter, 0)

class AddrOf(Unary):
    def __init__(self, token, expr):
        super().__init__(Pointer(expr.type), token, expr)
    def reduce(self, emitter, n):
        return self.expr.address(emitter, n)

class Deref(Unary):
    def __init__(self, token, expr):
        super().__init__(expr.type.to, token, expr)
        if not isinstance(expr.type, (Array,Pointer)):
            token.error(f'Cannot {token.lexeme} {expr.type}')
    def address(self, emitter, n):
        return self.expr.reduce(emitter, n)
    def reduce(self, emitter, n):
        self.address(emitter, n)
        emitter.load(self.width, Reg(n), Reg(n))
        return Reg(n)
    def store(self, emitter, n):
        self.address(emitter, n+1)
        emitter.store(self.width, Reg(n), Reg(n+1))
        return Reg(n)
    def call(self, emitter, n):
        emitter.call(self.address(emitter, n))

class Cast(Unary):
    def __init__(self, token, cast_type, expr):
        super().__init__(cast_type, token, expr)
        if not cast_type.cast(expr.type):
            token.error(f'Cannot cast {expr.type} to {cast_type}')
    def reduce(self, emitter, n):
        self.expr.reduce(emitter, n)
        self.type.convert(emitter, n, self.expr.type)
        return Reg(n)
    def data(self, emitter): #TODO test
        return self.expr.data(emitter)

class Not(Unary):
    def __init__(self, token, expr):
        super().__init__(expr.type, token, expr)
    def compare(self, emitter, n, label):
        emitter.binary(self.type.CMP, self.width, self.expr.reduce(emitter, n), 0)
        emitter.jump(Cond.NE, label)
    def compare_inv(self, emitter, n, label):
        emitter.binary(self.type.CMP, self.width, self.expr.reduce(emitter, n), 0)
        emitter.jump(Cond.EQ, label)
    def reduce(self, emitter, n):
        emitter.binary(self.type.CMP, self.width, self.expr.reduce(emitter, n), 0)
        emitter.mov(Cond.EQ, Reg(n), 1)
        emitter.mov(Cond.NE, Reg(n), 0)
        return Reg(n)

def max_type(left, right):
    if isinstance(left, (Float,Pointer)):
        return left
    if isinstance(right, (Float,Pointer)):
        return right
    return type(left if left.width >= right.width else right)(left.signed and right.signed)

class BinaryOp(Binary):
    def __init__(self, op, left, right):
        super().__init__(max_type(left.type, right.type), op, left, right)
        if isinstance(left, String) or isinstance(right, String) or not left.type.cast(right.type):
            op.error(f'Cannot {left.type} {op.lexeme} {right.type}')
        self.op = self.type.get_binary_op(op)
    def reduce(self, emitter, n):
        self.type.reduce_binary(emitter, n, self.op, self.left, self.right)
        return Reg(n)

class Compare(Binary):
    def __init__(self, op, left, right):
        super().__init__(max_type(left.type, right.type), op, left, right)        
        self.op = self.type.get_cmp_op(op)
        self.inv = self.type.get_inv_cmp_op(op)
    def compare(self, emitter, n, label):
        self.type.reduce_compare(emitter, n, self.left, self.right)
        emitter.jump(self.inv, label)
    def compare_inv(self, emitter, n, label): #TODO test
        self.type.reduce_compare(emitter, n, self.left, self.right)
        emitter.jump(self.op, label)
    def reduce(self, emitter, n):
        self.type.reduce_compare(emitter, n, self.left, self.right)
        emitter.mov(self.op, Reg(n), 1)
        emitter.mov(self.inv, Reg(n), 0)
        return Reg(n)

class Logic(BinaryOp):
    def compare(self, emitter, n, label):
        if self.op == Op.AND:
            self.left.compare(emitter, n, label)
            self.right.compare(emitter, n, label)
        elif self.op == Op.OR:
            sublabel = emitter.next_label()
            self.left.compare_inv(emitter, n, sublabel)
            self.right.compare(emitter, n, label)
            emitter.append_label(sublabel)
    def compare_inv(self, emitter, n, label):
        if self.op == Op.AND:
            sublabel = emitter.next_label()
            self.left.compare(emitter, n, sublabel)
            self.right.compare_inv(emitter, n, label)
            emitter.append_label(sublabel)
        elif self.op == Op.OR:
            self.left.compare_inv(emitter, n, label)
            self.right.compare_inv(emitter, n, label)
    def reduce(self, emitter, n):
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
    def __init__(self, token, cond, true, false):
        super().__init__(true.type, token)
        self.cond, self.true, self.false = cond, true, false
    def hard_calls(self):
        return self.cond.hard_calls() or self.true.hard_calls() or self.false.hard_calls()
    def soft_calls(self):
        return self.cond.soft_calls() or self.true.soft_calls() or self.false.soft_calls()
    def reduce(self, emitter, n):
        label = emitter.next_label()
        sublabel = emitter.next_label()
        self.cond.compare(emitter, n, sublabel)
        self.true.reduce(emitter, n)
        emitter.jump(Cond.AL, label)
        emitter.append_label(sublabel)
        self.false.reduce_branch(emitter, n, label)
        emitter.append_label(label)
        return Reg(n)
    def reduce_branch(self, emitter, n, root): #TODO test
        sublabel = emitter.next_label()
        self.cond.compare(emitter, n, sublabel)
        self.true.reduce(emitter, n)
        emitter.jump(Cond.AL, root)
        emitter.append_label(sublabel)
        self.false.reduce_branch(emitter, n, root)

class Dot(Access):
    def address(self, emitter, n):
        emitter.attr(self.struct.address(emitter, n), self.attr)
        return Reg(n)
    def reduce(self, emitter, n):
        self.struct.address(emitter, n)
        return self.attr.reduce(emitter, n)
    def store(self, emitter, n):
        self.struct.address(emitter, n+1)
        return self.attr.store(emitter, n)

class Arrow(Access):
    def address(self, emitter, n):
        emitter.attr(self.struct.reduce(emitter, n), self.attr)
        return Reg(n)
    def reduce(self, emitter, n):
        self.struct.reduce(emitter, n)
        return self.attr.reduce(emitter, n)
    def store(self, emitter, n):
        self.struct.reduce(emitter, n+1)
        return self.attr.store(emitter, n)

class SubScr(Binary):
    def __init__(self, token, left, right):
        super().__init__(left.type.of, token, left, right)
    def address(self, emitter, n):
        emitter.binary(Op.ADD, Size.WORD, self.left.type.reduce_array(emitter, n, self.left), self.right.reduce_subscr(emitter, n+1, self.left.type.of.size))
        return Reg(n)
    def reduce(self, emitter, n):       
        emitter.load(self.width, Reg(n), self.left.type.reduce_array(emitter, n, self.left), self.right.reduce_subscr(emitter, n+1, self.left.type.of.size))
        return Reg(n)
    def store(self, emitter, n):
        emitter.store(self.width, Reg(n), self.left.type.reduce_array(emitter, n+1, self.left), self.right.reduce_subscr(emitter, n+2, self.left.type.of.size))
        return Reg(n)