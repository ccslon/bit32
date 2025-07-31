# -*- coding: utf-8 -*-
"""
Created on Sat Mar  1 11:43:13 2025

@author: Colin
"""
from collections import UserDict, UserList
from bit32 import Op, Cond, Size, Reg
from .cemitter import Emitter

class Frame(UserDict):
    def __init__(self):
        super().__init__()
        self.size = 0
    def __setitem__(self, name, obj):
        obj.offset = self.size
        self.size += obj.type.size
        super().__setitem__(name, obj)

class CNode:
    def generate(self, emitter, n):
        pass
    def branch(self, emitter, n, _):
        self.generate(emitter, n)

class Statement(CNode):
    def last_is_return(self):
        return False

class Expr(CNode):
    def __init__(self, ctype, token):
        self.type = ctype
        self.width = ctype.width
        self.token = token
    def is_const(self):
        return False
    def hard_calls(self):
        raise NotImplementedError(self.__class__.__name__)
    def soft_calls(self):
        raise NotImplementedError(self.__class__.__name__)
    def reduce(self, emitter, n):
        raise NotImplementedError(self.__class__.__name__)
    def compare(self, emitter, n, label):
        emitter.binary(self.type.CMP, self.width, self.reduce(emitter, n), 0)
        emitter.jump(Cond.EQ, label)
    def compare_inv(self, emitter, n, label):
        emitter.binary(self.type.CMP, self.width, self.reduce(emitter, n), 0)
        emitter.jump(Cond.NE, label)
    def reduce_branch(self, emitter, n, _):
        self.reduce(emitter, n)
    def reduce_num(self, emitter, n):
        return self.reduce(emitter, n)
    def reduce_float(self, emitter, n):
        self.reduce(emitter, n)
        self.type.itf(emitter, n)
        return Reg(n)
    def reduce_subscr(self, emitter, n, size):
        self.reduce(emitter, n)
        if size > 1:
            emitter.binary(Op.MUL, Size.WORD, Reg(n), int(size))
        return Reg(n)

class Var(Expr):    
    def name(self):
        return self.token.lexeme
    def hard_calls(self):
        return False
    def soft_calls(self):
        return False
    def call(self, emitter, _):
        emitter.call(self.token.lexeme)

class Const(Expr):
    def is_const(self):
        return True
    def hard_calls(self):
        return False
    def soft_calls(self):
        return False

class Unary(Expr):
    def __init__(self, ctype, token, expr):
        super().__init__(ctype, token)
        self.expr = expr
    def is_const(self):
        return self.expr.is_const()
    def hard_calls(self):
        return self.expr.hard_calls()
    def soft_calls(self):
        return self.expr.soft_calls()

class Binary(Expr):
    def __init__(self, ctype, token, left, right):
        super().__init__(ctype, token)
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
    def __init__(self, ctype, name, block, info):
        self.type, self.name = ctype, name
        self.params, self.block = ctype.params, block
        self.returns, self.calls, self.max_args, self.space = info.returns, info.calls, info.max_args, info.space
    def glob_generate(self, emitter):        
        max_args = max(self.calls, self.max_args)
        emitter.begin_body(self)
        # generate function body
        self.block.generate(emitter, max_args)
        # peephole optimize
        emitter.optimize_body()        
        # find max register used in body
        max_reg = Reg.A
        for inst in emitter.instructions:
            max_reg = max(max_reg, inst.max_reg())
            
        # calculate list of register to push onto the stack
        push = list(map(Reg, range(max(bool(self.type.ret.width), len(self.params)), max_reg+1)))        
        pop = push.copy()
        
        self.adjust_offset(emitter, push)
        emitter.end_body()
        emitter.append_label(self.name.lexeme)
        self.prologue(emitter, push)        
        emitter.add_body()        
        #epilogue
        if self.returns or self.type.ret.width:
            emitter.append_label(emitter.return_label)
        if self.returns and self.type.ret.width and max_args:
            emitter.binary(Op.MOV, Size.WORD, Reg.A, Reg(max_args))
        if self.space:
            emitter.binary(Op.ADD, Size.WORD, Reg.SP, self.space)
        self.ret(emitter, pop)
    
    def prologue(self, emitter, push):        
        if self.calls:
            emitter.push(push + [Reg.LR])
        else:
            emitter.push(push)
        if self.space:
            emitter.binary(Op.SUB, Size.WORD, Reg.SP, self.space)
        for i, param in enumerate(self.params[:4]):
            emitter.store(param.width, Reg(i), Reg.SP, param.offset, param.token.lexeme)
    def ret(self, emitter, pop):        
        if self.calls:
            emitter.pop(pop + [Reg.PC])
        else:
            emitter.pop(pop)
            emitter.ret()
    def adjust_offset(self, emitter, push):
        if len(self.params) > 4:
            offset = self.space + Size.WORD*(self.calls + len(push))
            stack_params = {param.token.lexeme for param in self.params[4:]}
            for inst in emitter.instructions:
                if inst.var in stack_params:
                    inst.offset += offset

class VarFuncDefn(FuncDefn): #TODO test
    def prologue(self, emitter, push):
        emitter.push(list(map(Reg, range(4))))
        if self.calls:
            emitter.push(push + [Reg.LR])
        else:
            emitter.push(push)
        if self.space:
            emitter.binary(Op.SUB, Size.WORD, Reg.SP, self.space)
    def ret(self, emitter, push):
        if self.calls:
            emitter.pop(push + [Reg.LR])
        else:
            emitter.pop(push)
        emitter.binary(Op.ADD, Size.WORD, Reg.SP, 4*Size.WORD)
        emitter.ret()
    def adjust_offset(self, emitter, push):
        offset = self.space + Size.WORD*(self.calls + len(push))
        stack_params = {param.token.lexeme for param in self.params}
        for inst in emitter.instructions:
            if inst.var in stack_params:
                inst.offset += offset

class Translation(UserList, CNode):
    def generate(self):
        emitter = Emitter()
        for trans in self:
            trans.glob_generate(emitter)
        emitter.optimize()
        return str(emitter)