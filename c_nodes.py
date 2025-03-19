# -*- coding: utf-8 -*-
"""
Created on Sat Mar  1 11:43:13 2025

@author: Colin
"""
from collections import UserDict
from bit32 import Op, Cond, Size, Reg

class Frame(UserDict):
    def __init__(self):
        super().__init__()
        self.size = 0
    def __setitem__(self, name, obj):
        obj.location = self.size
        self.size += obj.type.size
        super().__setitem__(name, obj)

class CNode:
    def generate(self, vstr, n):
        pass

class Expr(CNode):
    def __init__(self, c_type, token):
        self.type = c_type
        self.width = c_type.width
        self.token = token
    def is_signed(self):
        return self.type.is_signed()
    def is_const(self):
        return False
    def cmp_op(self):
        return Op.CMPF if self.type.is_float() else Op.CMP
    def reduce(self, vstr, n):
        raise NotImplementedError(self.__class__.__name__)
    def compare(self, vstr, n, label):
        vstr.binary(self.cmp_op(), self.width, self.reduce(vstr, n), 0)
        vstr.jump(Cond.EQ, label)
    def compare_inv(self, vstr, n, label):
        vstr.binary(self.cmp_op(), self.width, self.reduce(vstr, n), 0)
        vstr.jump(Cond.NE, label)
    def branch_reduce(self, vstr, n, _):
        self.reduce(vstr, n)
    def branch(self, vstr, n, _):
        self.generate(vstr, n)
    def num_reduce(self, vstr, n):
        return self.reduce(vstr, n)
    def float_reduce(self, vstr, n):
        self.reduce(vstr, n)
        if not self.type.is_float():
            vstr.binary(Op.ITF, Size.WORD, Reg(n), Reg(n))
        return Reg(n)
    def error(self, msg):
        raise SyntaxError(f'Line {self.token.line}: {msg}')

class Var(Expr):
    def hard_calls(self):
        return False
    def soft_calls(self):
        return False

class Statement(CNode):
    pass

class Const(Expr):
    def is_const(self):
        return True
    def hard_calls(self):
        return False
    def soft_calls(self):
        return False

class OpExpr(Expr):
    OP = {}
    OPF = {}
    def init_op(self, op):
        self.op = self.OPF[op.lexeme] if self.type.is_float() else self.OP[op.lexeme]

class Unary(Expr):
    def __init__(self, c_type, token, expr):
        super().__init__(c_type, token)
        self.expr = expr
    def is_const(self):
        return self.expr.is_const()
    def hard_calls(self):
        return self.expr.hard_calls()
    def soft_calls(self):
        return self.expr.soft_calls()

class Binary(Expr):
    def __init__(self, c_type, token, left, right):
        super().__init__(c_type, token)
        self.left, self.right = left, right
    def is_signed(self):
        return self.left.is_signed() and self.right.is_signed()
    def is_const(self):
        return self.left.is_const() and self.right.is_const()
    def hard_calls(self):
        return self.left.hard_calls() or self.right.hard_calls()
    def soft_calls(self):
        return self.left.hard_calls() or self.right.hard_calls() # self.left.soft_calls() ?

class Access(Expr):
    def __init__(self, token, struct, attr):
        super().__init__(attr.type, token)
        self.struct, self.attr = struct, attr
    def hard_calls(self):
        return self.struct.hard_calls()
    def soft_calls(self):
        return self.struct.soft_calls()