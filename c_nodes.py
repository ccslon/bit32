# -*- coding: utf-8 -*-
"""
Created on Sat Mar  1 11:43:13 2025

@author: Colin
"""
from collections import UserDict, UserList
from bit32 import Op, Cond, Size, Reg
from c_visitors import Emitter, Visitor

class Frame(UserDict):
    def __init__(self):
        super().__init__()
        self.size = 0
    def add(self, var_type, c_type, name):
        self[name.lexeme] = var = var_type(c_type, name, self.size)
        self.size += c_type.size
        return var
    def __setitem__(self, name, obj):
        obj.location = self.size
        self.size += obj.type.size
        super().__setitem__(name, obj)

class CNode:
    def generate(self, vstr, n):
        pass
    def branch(self, vstr, n, _):
        self.generate(vstr, n)

class Statement(CNode):
    def last_is_return(self):
        return False

class Expr(CNode):
    def __init__(self, c_type, token):
        self.type = c_type
        self.width = c_type.width
        self.token = token
    def is_const(self):
        return False
    def hard_calls(self):
        raise NotImplementedError(self.__class__.__name__)
    def soft_calls(self):
        raise NotImplementedError(self.__class__.__name__)
    def reduce(self, vstr, n):
        raise NotImplementedError(self.__class__.__name__)
    def compare(self, vstr, n, label):
        vstr.binary(self.type.CMP, self.width, self.reduce(vstr, n), 0)
        vstr.jump(Cond.EQ, label)
    def compare_inv(self, vstr, n, label):
        vstr.binary(self.type.CMP, self.width, self.reduce(vstr, n), 0)
        vstr.jump(Cond.NE, label)
    def reduce_branch(self, vstr, n, _):
        self.reduce(vstr, n)
    def reduce_num(self, vstr, n):
        return self.reduce(vstr, n)
    def reduce_float(self, vstr, n):
        self.reduce(vstr, n)
        self.type.itf(vstr, n)
        return Reg(n)

class Var(Expr):
    def hard_calls(self):
        return False
    def soft_calls(self):
        return False
    def call(self, vstr, _):
        vstr.call(self.token.lexeme)

class Const(Expr):
    def is_const(self):
        return True
    def hard_calls(self):
        return False
    def soft_calls(self):
        return False

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

class FuncDefn(CNode):
    def __init__(self, c_type, name, block, info):
        self.type, self.name = c_type, name
        self.params, self.block = c_type.params, block
        self.returns, self.calls, self.max_args, self.space = info.returns, info.calls, info.max_args, info.space
    def glob_generate(self, vstr):
        preview = Visitor()
        preview.begin_func(self)
        self.block.generate(preview, self.max_args)
        push = list(map(Reg, range(max(bool(self.type.ret.width), len(self.params)), preview.max_reg+1)))
        vstr.begin_func(self)
        #start
        vstr.append_label(self.name.lexeme)
        #prologue
        self.prologue(vstr, push)
        #body
        self.block.generate(vstr, max(self.calls, self.max_args))
        #epilogue
        if self.returns or self.type.ret.width:
            vstr.append_label(vstr.return_label)
        if self.returns and self.type.ret.width and max(self.calls, self.max_args):
            vstr.binary(Op.MOV, Size.WORD, Reg.A, Reg(max(self.calls, self.max_args)))
        if self.space:
            vstr.binary(Op.ADD, Size.WORD, Reg.SP, self.space)
        self.ret(vstr, push)
    def prologue(self, vstr, push):
        if len(self.params) > 4:
            offset = self.space + Size.WORD*self.calls + Size.WORD*len(push)
            for param in self.params[4:]:
                param.location += offset
        if self.calls:
            vstr.pushm(*push, Reg.LR)
        else:
            vstr.pushm(*push)
        if self.space:
            vstr.binary(Op.SUB, Size.WORD, Reg.SP, self.space)
        for i, param in enumerate(self.params[:4]):
            vstr.store(param.width, Reg(i), Reg.SP, param.location)
    def ret(self, vstr, push):        
        if self.calls:
            vstr.popm(*push, Reg.PC)
        else:
            vstr.popm(*push)
            vstr.ret()

class VarFuncDefn(FuncDefn): #TODO test
    def prologue(self, vstr, push):
        offset = self.space + Size.WORD*self.calls + Size.WORD*len(push)
        for param in self.params:
            param.location += offset
        vstr.pushm(*list(map(Reg, range(4))))
        if self.calls:
            vstr.pushm(*push, Reg.LR)
        else:
            vstr.pushm(*push)
        if self.space:
            vstr.binary(Op.SUB, Size.WORD, Reg.SP, self.space)
    def ret(self, vstr, push):
        if self.calls:
            vstr.popm(*push, Reg.LR)
        else:
            vstr.popm(*push)
        vstr.binary(Op.ADD, Size.WORD, Reg.SP, 4*Size.WORD)
        vstr.ret()

class Translation(UserList, CNode):
    def generate(self):
        emitter = Emitter()
        for trans in self:
            trans.glob_generate(emitter)
        return '\n'.join(emitter.data + emitter.asm)