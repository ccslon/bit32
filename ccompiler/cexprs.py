# -*- coding: utf-8 -*-
"""
Created on Fri Sep  6 14:09:48 2024

@author: ccslon
"""
from bit32 import Size, Op, Reg, Cond, negative, itf, unescape
from .cnodes import Expr, Var, Const, Unary, Binary, Access, Statement
from .ctypes import Char, Int, Float, Pointer, Array

class Local(Var):
    def __init__(self, ctype, name):
        super().__init__(ctype, name)
        self.location = None
    def address(self, vstr, n):
        return self.type.address(vstr, n, self, Reg.SP)
    def reduce(self, vstr, n):
        return self.type.reduce(vstr, n, self, Reg.SP)
    def store(self, vstr, n):
        return self.type.store(vstr, n, self, Reg.SP)
    def union(self, attr):
        new = Local(attr.type, attr.token)
        new.location = self.location
        return new
    def ptr_union(self, attr): #TODO test
        new = Local(Pointer(attr.type), attr.token)
        new.location = self.location
        return new

class Attr(Var):
    def address(self, vstr, n):
        return self.type.address(vstr, n, self, n) #TODO test
    def reduce(self, vstr, n):
        return self.type.reduce(vstr, n, self, n)
    def store(self, vstr, n):
        return self.type.store(vstr, n, self, n+1)
    def union(self, attr):
        new = Attr(attr.type, attr.token)
        new.location = self.location
        return new
    def ptr_union(self, attr): #TODO test
        new = Attr(Pointer(attr.type), attr.token)
        new.location = self.location
        return new

class Glob(Var):
    def reduce(self, vstr, n):
        return self.type.glob_reduce(vstr, n, self)
    def address(self, vstr, n):
        return self.type.glob_address(vstr, n, self)
    def store(self, vstr, n):
        return self.type.glob_store(vstr, n, self)
    def glob_generate(self, vstr):
        if self.type.size > 0:
            vstr.space(self.token.lexeme, self.type.size)
    def union(self, attr): #TODO test
        new = Glob(attr.type, self.token)
        return new
    def ptr_union(self, attr): #TODO test
        new = Glob(Pointer(attr.type), self.token)
        return new

class NumberBase(Const):
    def __init__(self, token):
        super().__init__(Int(), token)
    def data(self, vstr):
        return self.value
    def reduce(self, vstr, n):
        if 0 <= self.value < 256:
            vstr.binary(Op.MOV, self.width, Reg(n), self.value)
        else:
            vstr.imm(self.width, Reg(n), self.value)
        return Reg(n)
    def reduce_num(self, vstr, n):
        if 0 <= self.value < 256:
            return self.value
        vstr.imm(self.width, Reg(n), self.value) #TODO test this branch
        return Reg(n)

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
    def reduce(self, vstr, n):
        if 0 <= self.value < 256:
            vstr.binary(Op.MVN, self.width, Reg(n), self.value)
        else:
            vstr.imm(self.width, Reg(n), negative(-self.value, 32)) #TODO test this branch
        return Reg(n)
    def reduce_num(self, vstr, n):
        if 0 <= self.value <= 128:
            return -self.value
        vstr.imm(self.width, Reg(n), negative(-self.value, 32)) #TODO test this branch
        return Reg(n)

class SizeOf(NumberBase):
    def __init__(self, ctype, token):
        super().__init__(token)
        self.value = ctype.size

class Decimal(Const):
    def __init__(self, token):
        super().__init__(Float(), token)
        self.value = itf(token.lexeme)
    def data(self, vstr):
        return self.value
    def reduce(self, vstr, n):
        vstr.imm(self.width, Reg(n), self.value)
        return Reg(n)

class NegDecimal(Decimal):
    def __init__(self, token):
        super().__init__(token)
        self.value = itf(f'-{token.lexeme}')

class Character(Const):
    def __init__(self, token):
        super().__init__(Char(), token)
    def data(self, _):
        return self.token.lexeme
    def reduce(self, vstr, n):
        vstr.binary(Op.MOV, self.width, Reg(n), self.data(vstr))
        return Reg(n)
    def reduce_num(self, vstr, n):
        return self.data(vstr)

class String(Const):
    def __init__(self, token):
        super().__init__(Pointer(Char()), token)
        self.value = unescape(token.lexeme)
    def data(self, vstr):
        return vstr.string_ptr(self.token.lexeme)
    def reduce(self, vstr, n):
        vstr.load_glob(Reg(n), self.data(vstr))
        return Reg(n)

class UnaryOp(Unary):
    def __init__(self, op, expr):
        super().__init__(expr.type, op, expr)
        if not expr.type.cast(Int()):
            op.error(f'Cannot {op.lexeme} {expr.type}')
        self.op = self.type.get_unary_op(op)
    def reduce(self, vstr, n):
        vstr.unary(self.op, self.width, self.expr.reduce(vstr, n))
        return Reg(n)

class Pre(UnaryOp, Statement):
    def reduce(self, vstr, n):
        self.expr.reduce(vstr, n)
        self.type.reduce_pre(vstr, n, self.op)
        self.expr.store(vstr, n)
        return Reg(n)
    def generate(self, vstr, n):
        self.reduce(vstr, 0)

class Post(UnaryOp, Statement):
    def reduce(self, vstr, n):
        self.expr.reduce(vstr, n)
        self.type.reduce_post(vstr, n, self.op)
        self.expr.store(vstr, n+1)
        return Reg(n)
    def generate(self, vstr, n):
        self.reduce(vstr, 0)

class AddrOf(Unary):
    def __init__(self, token, expr):
        super().__init__(Pointer(expr.type), token, expr)
    def reduce(self, vstr, n):
        return self.expr.address(vstr, n)

class Deref(Unary):
    def __init__(self, token, expr):
        super().__init__(expr.type.to, token, expr)
        if not isinstance(expr.type, (Array,Pointer)):
            token.error(f'Cannot {token.lexeme} {expr.type}')
    def address(self, vstr, n):
        return self.expr.reduce(vstr, n)
    def reduce(self, vstr, n):
        self.address(vstr, n)
        vstr.load(self.width, Reg(n), Reg(n))
        return Reg(n)
    def store(self, vstr, n):
        self.address(vstr, n+1)
        vstr.store(self.width, Reg(n), Reg(n+1))
        return Reg(n)
    def call(self, vstr, n):
        vstr.call(self.address(vstr, n))

class Cast(Unary):
    def __init__(self, token, cast_type, expr):
        super().__init__(cast_type, token, expr)
        if not cast_type.cast(expr.type):
            token.error(f'Cannot cast {expr.type} to {cast_type}')
    def reduce(self, vstr, n):
        self.expr.reduce(vstr, n)
        self.type.convert(vstr, n, self.expr.type)
        return Reg(n)
    def data(self, vstr): #TODO test
        return self.expr.data(vstr)

class Not(Unary):
    def __init__(self, token, expr):
        super().__init__(expr.type, token, expr)
    def compare(self, vstr, n, label):
        vstr.binary(self.type.CMP, self.width, self.expr.reduce(vstr, n), 0)
        vstr.jump(Cond.NE, label)
    def compare_inv(self, vstr, n, label):
        vstr.binary(self.type.CMP, self.width, self.expr.reduce(vstr, n), 0)
        vstr.jump(Cond.EQ, label)
    def reduce(self, vstr, n):
        vstr.binary(self.type.CMP, self.width, self.expr.reduce(vstr, n), 0)
        vstr.mov(Cond.EQ, Reg(n), 1)
        vstr.mov(Cond.NE, Reg(n), 0)
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
    def reduce(self, vstr, n):
        self.type.reduce_binary(vstr, n, self.op, self.left, self.right)
        return Reg(n)

class Compare(Binary):
    def __init__(self, op, left, right):
        super().__init__(max_type(left.type, right.type), op, left, right)        
        self.op = self.type.get_cmp_op(op)
        self.inv = self.type.get_inv_cmp_op(op)
    def compare(self, vstr, n, label):
        self.type.reduce_compare(vstr, n, self.left, self.right)
        vstr.jump(self.inv, label)
    def compare_inv(self, vstr, n, label): #TODO test
        self.type.reduce_compare(vstr, n, self.left, self.right)
        vstr.jump(self.op, label)
    def reduce(self, vstr, n):
        self.type.reduce_compare(vstr, n, self.left, self.right)
        vstr.mov(self.op, Reg(n), 1)
        vstr.mov(self.inv, Reg(n), 0)
        return Reg(n)

class Logic(BinaryOp):
    def compare(self, vstr, n, label):
        if self.op == Op.AND:
            self.left.compare(vstr, n, label)
            self.right.compare(vstr, n, label)
        elif self.op == Op.OR:
            sublabel = vstr.next_label()
            self.left.compare_inv(vstr, n, sublabel)
            self.right.compare(vstr, n, label)
            vstr.append_label(sublabel)
    def compare_inv(self, vstr, n, label):
        if self.op == Op.AND:
            sublabel = vstr.next_label()
            self.left.compare(vstr, n, sublabel)
            self.right.compare_inv(vstr, n, label)
            vstr.append_label(sublabel)
        elif self.op == Op.OR:
            self.left.compare_inv(vstr, n, label)
            self.right.compare_inv(vstr, n, label)
    def reduce(self, vstr, n):
        if self.op == Op.AND:
            label = vstr.next_label()
            sublabel = vstr.next_label()
            self.left.compare(vstr, n, label)
            self.right.compare(vstr, n, label)
            vstr.binary(Op.MOV, Size.WORD, Reg(n), 1)
            vstr.jump(Cond.AL, sublabel)
            vstr.append_label(label)
            vstr.binary(Op.MOV, Size.WORD, Reg(n), 0)
            vstr.append_label(sublabel)
        elif self.op == Op.OR:
            label = vstr.next_label()
            sublabel = vstr.next_label()
            subsublabel = vstr.next_label()
            self.left.compare_inv(vstr, n, label)
            self.right.compare(vstr, n, sublabel)
            vstr.append_label(label)
            vstr.binary(Op.MOV, Size.WORD, Reg(n), 1)
            vstr.jump(Cond.AL, subsublabel)
            vstr.append_label(sublabel)
            vstr.binary(Op.MOV, Size.WORD, Reg(n), 0)
            vstr.append_label(subsublabel)
        return Reg(n)

class Condition(Expr):
    def __init__(self, token, cond, true, false):
        super().__init__(true.type, token)
        self.cond, self.true, self.false = cond, true, false
    def hard_calls(self):
        return self.cond.hard_calls() or self.true.hard_calls() or self.false.hard_calls()
    def soft_calls(self):
        return self.cond.soft_calls() or self.true.soft_calls() or self.false.soft_calls()
    def reduce(self, vstr, n):
        label = vstr.next_label()
        sublabel = vstr.next_label()
        self.cond.compare(vstr, n, sublabel)
        self.true.reduce(vstr, n)
        vstr.jump(Cond.AL, label)
        vstr.append_label(sublabel)
        self.false.reduce_branch(vstr, n, label)
        vstr.append_label(label)
        return Reg(n)
    def reduce_branch(self, vstr, n, root): #TODO test
        sublabel = vstr.next_label()
        self.cond.compare(vstr, n, sublabel)
        self.true.reduce(vstr, n)
        vstr.jump(Cond.AL, root)
        vstr.append_label(sublabel)
        self.false.reduce_branch(vstr, n, root)

class Dot(Access):
    def address(self, vstr, n):
        vstr.binary(Op.ADD, Size.WORD, self.struct.address(vstr, n), self.attr.location)
        return Reg(n)
    def reduce(self, vstr, n):
        self.struct.address(vstr, n)
        return self.attr.reduce(vstr, n)
    def store(self, vstr, n):
        self.struct.address(vstr, n+1)
        return self.attr.store(vstr, n)
    def union(self, attr):
        return Dot(self.token, self.struct, self.attr.union(attr))
    def ptr_union(self, attr):
        return Dot(self.token, self.struct, self.attr.ptr_union(attr))

class Arrow(Access):
    def address(self, vstr, n):
        vstr.binary(Op.ADD, Size.WORD, self.struct.reduce(vstr, n), self.attr.location)
        return Reg(n)
    def reduce(self, vstr, n):
        self.struct.reduce(vstr, n)
        return self.attr.reduce(vstr, n)
    def store(self, vstr, n):
        self.struct.reduce(vstr, n+1)
        return self.attr.store(vstr, n)
    def union(self, attr):
        return Arrow(self.token, self.struct, self.attr.union(attr))
    def ptr_union(self, attr):
        return Arrow(self.token, self.struct, self.attr.ptr_union(attr))

class SubScr(Binary):
    def __init__(self, token, left, right):
        super().__init__(left.type.of, token, left, right)
    def address(self, vstr, n):
        self.left.type.reduce_subscr_left(vstr, n, self.left)
        self.left.type.reduce_subscr_right(vstr, n , self.right)
        return Reg(n)
    def reduce(self, vstr, n):
        vstr.load(self.width, self.address(vstr, n), Reg(n))
        return Reg(n)
    def store(self, vstr, n):
        vstr.store(self.width, Reg(n), self.address(vstr, n+1))
        return Reg(n)
    def union(self, attr):
        self.type = attr.type
        self.width = attr.width
        return self
    def ptr_union(self, attr):
        self.type = Pointer(attr.type)
        self.width = Size.WORD
        return self