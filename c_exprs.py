# -*- coding: utf-8 -*-
"""
Created on Fri Sep  6 14:09:48 2024

@author: ccslon
"""
from collections import UserList
from struct import pack

from bit32 import Size, Op, Reg, Cond, negative, escape, unescape
from c_utils import CNode, Visitor, Emitter, regs
from c_types import Char, Int, Float, Pointer, Array, Void

class Expr(CNode):
    def __init__(self, type, token):
        self.type = type
        self.size = type.size
        self.token = token
    def branch(self, vstr, n, _):
        self.generate(vstr, n)
    def compare(self, vstr, n, label):
        vstr.binary(Op.CMPF if self.is_float() else Op.CMP, self.size, self.reduce(vstr, n), 0)
        vstr.jump(Cond.EQ, f'.L{label}')
    def compare_inv(self, vstr, n, label):
        vstr.binary(Op.CMPF if self.is_float() else Op.CMP, self.size, self.reduce(vstr, n), 0)
        vstr.jump(Cond.NE, f'.L{label}')
    def branch_reduce(self, vstr, n, _):
        self.reduce(vstr, n)
    def num_reduce(self, vstr, n):
        return self.reduce(vstr, n)
    def float_reduce(self, vstr, n):
        self.reduce(vstr, n)
        if not self.is_float():
            vstr.binary(Op.ITF, self.size, regs[n], regs[n])
        return regs[n]
    def list_reduce(self, vstr, n, _):
        return self.reduce(vstr, n)
    def convert(self, vstr, reg, other):
        self.type.convert(vstr, reg, other)
    def is_signed(self):
        return self.type.is_signed()
    def is_float(self):
        return self.type.is_float()

class Local(Expr):
    def store(self, vstr, n):
        return self.type.store(vstr, n, self, Reg.FP)
    def reduce(self, vstr, n):
        return self.type.reduce(vstr, n, self, Reg.FP)
    def address(self, vstr, n):
        return self.type.address(vstr, n, self, Reg.FP)
    def call(self, vstr, n):
        self.reduce(vstr, n)
        vstr.call(regs[n])
    def union(self, attr):
        new = Local(attr.type, attr.token)
        new.location = self.location
        return new

class Attr(Local):
    def store(self, vstr, n):
        return self.type.store(vstr, n, self, n+1)
    def reduce(self, vstr, n):
        return self.type.reduce(vstr, n, self, n)
    def address(self, vstr, n):
        return self.type.address(vstr, n, self, n)
    def call(self, vstr, n):
        self.reduce(vstr, n)
        vstr.call(regs[n])
    def union(self, attr):
        new = Attr(attr.type, attr.token)
        new.location = self.location
        return new

class Glob(Local):
    def __init__(self, type, token):
        super().__init__(type, token)
        self.init = None
    def store(self, vstr, n):
        return self.type.glob_store(vstr, n, self)
    def reduce(self, vstr, n):
        return self.type.glob_reduce(vstr, n, self)
    def address(self, vstr, n):
        return self.type.glob_address(vstr, n, self)
    def generate(self, vstr):
        self.type.glob(vstr, self)
    def call(self, vstr, n):
        vstr.call(self.token.lexeme)
    def union(self, attr):
        new = Glob(attr.type, attr.token)
        # new.init = attr.init
        return new
    
def itf(i):
    return int.from_bytes(pack('>f', float(i)), 'big')
    
class Decimal(Expr):
    def __init__(self, token):
        super().__init__(Float(), token)
        self.value = itf(token.lexeme)
    def data(self, vstr):
        return self.value
    def reduce(self, vstr, n):
        vstr.imm(self.size, regs[n], self.value)
        return regs[n]

class NumBase(Expr):
    def __init__(self, token):
        super().__init__(Int(), token)
    def data(self, vstr):
        return self.value
    def reduce(self, vstr, n):
        if 0 <= self.value < 256:
            vstr.binary(Op.MOV, self.size, regs[n], self.value)
        else:
            vstr.imm(self.size, regs[n], self.value)
        return regs[n]
    def num_reduce(self, vstr, n):
        if 0 <= self.value < 256:
            return self.value
        else:
            vstr.imm(self.size, regs[n], self.value)
        return regs[n]

class EnumConst(NumBase):
    def __init__(self, token, value):
        super().__init__(token)
        self.value = value

class Num(NumBase):
    def __init__(self, token):
        super().__init__(token)
        if token.lexeme.startswith('0x'):
            self.value = int(token.lexeme, base=16)
        elif token.lexeme.startswith('0b'):
            self.value = int(token.lexeme, base=2)
        else:
            self.value = int(token.lexeme)   

class NegNum(Num):
    def reduce(self, vstr, n):
        if 0 <= self.value < 256:
            vstr.binary(Op.MVN, self.size, regs[n], self.value)
        else:
            vstr.imm(self.size, regs[n], negative(-self.value, 32))
        return regs[n]
    def num_reduce(self, vstr, n):
        return self.reduce(vstr, n)

class SizeOf(NumBase):
    def __init__(self, token, type):
        super().__init__(token)
        self.value = type.size

class Letter(Expr):
    def __init__(self, token):
        super().__init__(Char(), token)
    def data(self, _):
        return self.token.lexeme
    def reduce(self, vstr, n):
        vstr.binary(Op.MOV, self.size, regs[n], self.data(vstr))
        return regs[n]
    def num_reduce(self, vstr, n):
        return self.data(vstr)

class String(Expr):
    class Char:
        def __init__(self, char):
            self.char = char
        def data(self, _):
            return f"'{self.char}'"
    def __init__(self, token):
        super().__init__(Pointer(Char()), token)
        self.value = unescape(token.lexeme)
    def __iter__(self):
        for c in self.value:
            yield self.Char(escape(c))
        yield self.Char(r'\0')
    def __len__(self):
        return len(self.value)
    def data(self, vstr):
        return vstr.string(self.token.lexeme)
    def reduce(self, vstr, n):
        vstr.load_glob(regs[n], self.data(vstr))
        return regs[n]

class OpExpr(Expr):
    def __init__(self, type, op):
        super().__init__(type, op)
        self.op = self.OPF[op.lexeme] if self.is_float() else self.OP[op.lexeme]

class Unary(OpExpr):
    OP = {'-':Op.NEG,
          '~':Op.NOT}
    OPF = {'-':Op.NEGF}
    def __init__(self, op, unary):
        # assert unary.type.cast(Word('int')), f'Line {op.line}: Cannot {op.lexeme} {unary.type}'
        super().__init__(unary.type, op)
        self.unary = unary
    def reduce(self, vstr, n):
        vstr.unary(self.op, self.size, self.unary.reduce(vstr, n))
        return regs[n]

class Pre(Unary):
    OP = {'++':Op.ADD,
          '--':Op.SUB}
    OPF = {'++':Op.ADDF,
           '--':Op.SUBF}
    def reduce(self, vstr, n):
        self.generate(vstr, n)
        return regs[n]
    def generate(self, vstr, n):
        self.unary.reduce(vstr, n)
        if self.is_float():
            vstr.imm(self.size, regs[n+1], itf(1))
            vstr.binay(self.op, self.size, regs[n], regs[n+1])
        else:
            vstr.binary(self.op, self.size, regs[n], self.type.inc)
        self.unary.store(vstr, n)

class AddrOf(Expr):
    def __init__(self, token, unary):
        super().__init__(Pointer(unary.type), token)
        self.unary = unary
    def reduce(self, vstr, n):
        return self.unary.address(vstr, n)

class Deref(Expr):
    def __init__(self, token, unary):
        assert hasattr(unary.type, 'to'), f'Line {token.line}: Cannot {token.lexeme} {unary.type}'
        super().__init__(unary.type.to, token)
        self.unary = unary
    def store(self, vstr, n):
        self.unary.reduce(vstr, n+1)
        vstr.store(self.size, regs[n], regs[n+1])
        return regs[n]
    def reduce(self, vstr, n):
        self.unary.reduce(vstr, n)
        vstr.load(self.size, regs[n], regs[n])
        return regs[n]
    def call(self, vstr, n):
        self.unary.call(vstr, n)

class Cast(Expr):
    def __init__(self, type, token, cast):
        # assert type.cast(cast.type), f'Line {token.line}: Cannot cast {cast.type} to {type}'
        super().__init__(type, token)
        self.cast = cast
    def reduce(self, vstr, n):
        self.cast.reduce(vstr, n)
        if self.type.is_float() and not self.cast.is_float():
            vstr.binary(Op.ITF, self.size, regs[n], regs[n])
        return regs[n]
    def data(self, vstr):
        return self.cast.data(vstr)

class Not(Expr):
    def __init__(self, token, unary):
        super().__init__(unary.type, token)
        self.unary = unary
    def compare(self, vstr, n, label):
        vstr.binary(Op.CMPF if self.is_float() else Op.CMP, self.size, self.unary.reduce(vstr, n), 0)
        vstr.jump(Cond.NE, f'.L{label}')
    def compare_inv(self, vstr, n, label):
        vstr.binary(Op.CMPF if self.is_float() else Op.CMP, self.size, self.unary.reduce(vstr, n), 0)
        vstr.jump(Cond.EQ, f'.L{label}')
    def reduce(self, vstr, n):
        vstr.binary(Op.CMP, self.size, self.unary.reduce(vstr, n), 0)
        vstr.mov(Cond.EQ, regs[n], 1)
        vstr.mov(Cond.NE, regs[n], 0)
        return regs[n]

def max_type(left, right):
    if left.is_float():
        return left
    elif right.is_float():
        return right
    else:
        return right if right.size > left.size else left

class Binary(OpExpr):
    OP = {'+' :Op.ADD,
          '+=':Op.ADD,
          '-' :Op.SUB,
          '-=':Op.SUB,
          '*' :Op.MUL,
          '*=':Op.MUL,
          '<<':Op.SHL,
          '<<=':Op.SHL,
          '>>':Op.SHR,
          '>>=':Op.SHR,
          '^' :Op.XOR,
          '^=':Op.XOR,
          '|' :Op.OR,
          '|=':Op.OR,
          '&': Op.AND,
          '&=':Op.AND,
          '/': Op.DIV,
          '/=':Op.DIV,
          '%': Op.MOD,
          '%=':Op.MOD}
    OPF = {'+': Op.ADDF,
           '+=':Op.ADDF,
           '-' :Op.SUBF,
           '-=':Op.SUBF,
           '*' :Op.MULF,
           '*=':Op.MULF,
           '/': Op.DIVF,
           '/=':Op.DIVF,
           '<<':Op.SHL,
           '<<=':Op.SHL,
           '>>':Op.SHR,
           '>>=':Op.SHR,
           '^' :Op.XOR,
           '^=':Op.XOR,
           '|' :Op.OR,
           '|=':Op.OR,
           '&': Op.AND,
           '&=':Op.AND}
    def __init__(self, op, left, right):
        # assert not isinstance(left, String) or not isinstance(right, String)
        # assert left.type.cast(right.type), f'Line {op.line}: Cannot {left.type} {op.lexeme} {right.type}'
        self.left, self.right = left, right
        super().__init__(max_type(left.type, right.type), op)
    def is_signed(self):
        return self.left.is_signed() and self.right.is_signed()
    def is_float(self):
        return self.left.is_float() or self.right.is_float()
    def reduce(self, vstr, n):
        if self.is_float():
            vstr.binary(self.op, self.size, self.left.float_reduce(vstr, n), self.right.float_reduce(vstr, n+1))
        else:
            vstr.binary(self.op, self.size, self.left.reduce(vstr, n), self.right.num_reduce(vstr, n+1))
        return regs[n]

class Compare(Binary):
    OP = {'==':Cond.EQ,
          '!=':Cond.NE,
          '>': Cond.GT,
          '<': Cond.LT,
          '>=':Cond.GE,
          '<=':Cond.LE}
    INV = {'==':Cond.NE,
           '!=':Cond.EQ,
           '>': Cond.LE,
           '<': Cond.GE,
           '>=':Cond.LT,
           '<=':Cond.GT}
    UOP = {'>': Cond.HI,
           '<': Cond.LO,
           '>=':Cond.HS,
           '<=':Cond.LS}
    UINV = {'>': Cond.LS,
            '<': Cond.HS,
            '>=':Cond.LO,
            '<=':Cond.HI}
    OPF = OP
    def __init__(self, op, left, right):
        super().__init__(op, left, right)
        if self.is_float() or self.is_signed():
            self.op = self.OP[op.lexeme]
            self.inv = self.INV[op.lexeme]
        else:
            self.op = self.UOP.get(op.lexeme, self.OP[op.lexeme])
            self.inv = self.UINV.get(op.lexeme, self.INV[op.lexeme])
    def cmp(self, vstr, n):
        if self.is_float():
            vstr.binary(Op.CMPF, self.size, self.left.float_reduce(vstr, n), self.right.float_reduce(vstr, n+1))
        else:
            vstr.binary(Op.CMP, self.size, self.left.reduce(vstr, n), self.right.num_reduce(vstr, n+1))
    def compare(self, vstr, n, label):
        self.cmp(vstr, n)
        vstr.jump(self.inv, f'.L{label}')
    def compare_inv(self, vstr, n, label):
        self.cmp(vstr, n)
        vstr.jump(self.op, f'.L{label}')
    def reduce(self, vstr, n):
        self.cmp(vstr, n)
        vstr.mov(self.op, regs[n], 1)
        vstr.mov(self.inv, regs[n], 0)
        return regs[n]

class Logic(Binary):
    OP = {'&&':Op.AND,
          '||':Op.OR}
    OPF = {'&&':Op.AND,
           '||':Op.OR}
    def cmp(self, vstr, n, expr):
        if self.is_float():
            vstr.binary(Op.CMPF, self.size, expr.float_reduce(vstr, n), 0)
        else:
            vstr.binary(Op.CMP, self.size, expr.reduce(vstr, n), 0)
    def compare(self, vstr, n, label):
        if self.op == Op.AND:
            self.cmp(vstr, n, self.left)
            vstr.jump(Cond.EQ, f'.L{label}')
            self.cmp(vstr, n, self.right)
            vstr.jump(Cond.EQ, f'.L{label}')
        elif self.op == Op.OR:
            sublabel = vstr.next_label()
            self.cmp(vstr, n, self.left)
            vstr.jump(Cond.NE, f'.L{sublabel}')
            self.cmp(vstr, n, self.right)
            vstr.jump(Cond.EQ, f'.L{label}')
            vstr.append_label(f'.L{sublabel}')
    def compare_inv(self, vstr, n, label): 
        if self.op == Op.AND:
            sublabel = vstr.next_label()
            self.cmp(vstr, n, self.left)
            vstr.jump(Cond.EQ, f'.L{sublabel}')
            self.cmp(vstr, n, self.right)
            vstr.jump(Cond.NE, f'.L{label}')
            vstr.append_label(f'.L{sublabel}')
        elif self.op == Op.OR:
            self.cmp(vstr, n, self.left)
            vstr.jump(Cond.NE, f'.L{label}')
            self.cmp(vstr, n, self.right)
            vstr.jump(Cond.NE, f'.L{label}')
    def reduce(self, vstr, n):
        if self.op == Op.AND:
            label = vstr.next_label()
            sublabel = vstr.next_label()
            self.cmp(vstr, n, self.left)
            vstr.jump(Cond.EQ, f'.L{label}')
            self.cmp(vstr, n, self.right)
            vstr.jump(Cond.EQ, f'.L{label}')
            vstr.binary(Op.MOV, Size.WORD, regs[n], 1)
            vstr.jump(Cond.AL, f'.L{sublabel}')
            vstr.append_label(f'.L{label}')
            vstr.binary(Op.MOV, Size.WORD, regs[n], 0)
            vstr.append_label(f'.L{sublabel}') 
        elif self.op == Op.OR:
            label = vstr.next_label()
            sublabel = vstr.next_label()
            subsublabel = vstr.next_label()
            self.cmp(vstr, n, self.left)
            vstr.jump(Cond.NE, f'.L{label}')            
            self.cmp(vstr, n, self.right)
            vstr.jump(Cond.EQ, f'.L{sublabel}')
            vstr.append_label(f'.L{label}')
            vstr.binary(Op.MOV, Size.WORD, regs[n], 1)
            vstr.jump(Cond.AL, f'.L{subsublabel}')
            vstr.append_label(f'.L{sublabel}')
            vstr.binary(Op.MOV, Size.WORD, regs[n], 0)
            vstr.append_label(f'.L{subsublabel}')
        return regs[n]

class Condition(Expr):
    def __init__(self, cond, true, false):
        self.type = true.type
        self.cond, self.true, self.false = cond, true, false
    def reduce(self, vstr, n):
        vstr.if_jump_end = False
        label = vstr.next_label()
        sublabel = vstr.next_label() if self.false else label
        self.cond.compare(vstr, n, sublabel)
        self.true.reduce(vstr, n)
        vstr.jump(Cond.AL, f'.L{label}')
        vstr.append_label(f'.L{sublabel}')
        self.false.branch_reduce(vstr, n, label)
        vstr.append_label(f'.L{label}')
        return regs[n]
    def branch(self, vstr, n, root):
        sublabel = vstr.next_label()
        self.cond.compare(vstr, n, sublabel)
        self.true.reduce(vstr, n)
        vstr.jump(Cond.AL, f'.L{root}')
        vstr.append_label(f'.L{sublabel}')
        self.false.branch_reduce(vstr, n, root)

class InitAssign(Expr):
    def __init__(self, token, left, right):
        # assert left.type == right.type, f'Line {token.line}: {left.type} != {right.type}'
        super().__init__(left.type, token)
        self.left, self.right = left, right
    def reduce(self, vstr, n):
        return self.generate(vstr, n)
    def generate(self, vstr, n):
        self.right.reduce(vstr, n)
        self.left.convert(vstr, n, self.right)
        return self.left.store(vstr, n)

class Assign(InitAssign):
    def __init__(self, token, left, right):
        assert not left.type.const, 'Line {token.line}: Left is const'
        super().__init__(token, left, right)

class InitListAssign(Expr):
    def __init__(self, token, left, right):
        super().__init__(left.type, token)
        self.left, self.right = left, right
    def generate(self, vstr, n):
        self.left.address(vstr, n)
        for i, (loc, type) in enumerate(self.left.type):
            type.list_store(vstr, n, self.right[i], loc)

class InitArrayString(Expr):
    def __init__(self, token, array, string):
        if array.type.length is None:
            array.type.size = len(string) + 1
        else:
            assert array.type.size >= len(string) + 1
        self.array = array
        self.string = string
    def generate(self, vstr, n):
        self.array.address(vstr, n)
        for i, c in enumerate(self.string):
            vstr.binary(Op.MOV, self.size, regs[n+1], c.data(vstr))
            vstr.store(self.size, regs[n+1], regs[n], i)

class Block(UserList, Expr):
    def generate(self, vstr, n):
        for statement in self:
            statement.generate(vstr, n)

class Defn(Expr):
    def __init__(self, type, id, params, block, returns, calls, max_args, space):
        super().__init__(type, id)
        self.params, self.block, self.returns, self.calls, self.max_args, self.space = params, block, returns, calls, max_args, space
    def generate(self, vstr):
        regs.clear()
        preview = Visitor()
        preview.begin_func(self)
        self.block.generate(preview, self.max_args)
        push = list(map(Reg, range(max(bool(self.size), len(self.params)), regs.max+1))) + [Reg.FP]
        
        vstr.begin_func(self)
        #start
        vstr.append_label(self.token.lexeme)
        #prologue
        if len(self.params) > 4:
            offset = self.space + 4*self.calls + 4*len(push)
            for param in self.params[4:]:
                param.location += offset
        if self.calls:
            vstr.pushm(Reg.LR, *push)
        else:
            vstr.pushm(*push)
        if self.space:
            vstr.binary(Op.SUB, Size.WORD, Reg.SP, self.space)
        vstr.binary(Op.MOV, Size.WORD, Reg.FP, Reg.SP)
        for i, param in enumerate(self.params[:4]):
            vstr.store(param.size, regs[i], Reg.FP, param.location)            
        #body
        self.block.generate(vstr, self.max_args)
        #epilogue
        if self.size or self.returns:
            vstr.append_label(f'.L{vstr.return_label}')
        if self.max_args and self.size:
            vstr.binary(Op.MOV, self.size, Reg.A, regs[self.max_args])
        vstr.binary(Op.MOV, Size.WORD, Reg.SP, Reg.FP)
        if self.space:
            vstr.binary(Op.ADD, Size.WORD, Reg.SP, self.space)
        if self.calls:
            vstr.popm(Reg.PC, *push)
        else:
            vstr.popm(*push)
            vstr.ret()

class VarDefn(Defn):
    def generate(self, vstr):
        regs.clear()
        preview = Visitor()
        preview.begin_func(self)
        self.block.generate(preview, self.max_args)
        push = list(map(Reg, range(4, regs.max+1))) + [Reg.FP]
        
        vstr.begin_func(self)
        #start
        vstr.append_label(self.token.lexeme)
        #prologue
        vstr.pushm(*reversed(list(map(Reg, range(4)))))
        for param in self.params:
            param.location += self.space + 4*self.calls + 4*len(push)
        if self.calls:
            vstr.pushm(Reg.LR, *push)
        else:
            vstr.pushm(*push)
        if self.space:
            vstr.binary(Op.SUB, Size.WORD, Reg.SP, self.space)
        vstr.binary(Op.MOV, Size.WORD, Reg.FP, Reg.SP)            
        #body
        self.block.generate(vstr, self.max_args)
        #epilogue
        if self.size or self.returns:
            vstr.append_label(f'.L{vstr.return_label}')
        if self.max_args and self.size:
            vstr.binary(Op.MOV, self.size, Reg.A, regs[self.max_args])
        vstr.binary(Op.MOV, Size.WORD, Reg.SP, Reg.FP)
        if self.space:
            vstr.binary(Op.ADD, Size.WORD, Reg.SP, self.space)        
        if self.calls:
            vstr.popm(Reg.LR, *push)
        else:
            vstr.popm(*push)
        vstr.binary(Op.ADD, Size.WORD, Reg.SP, 16)
        vstr.ret()

class Post(OpExpr):
    OP = {'++':Op.ADD,
          '--':Op.SUB}
    OPF = {'++':Op.ADDF,
           '--':Op.SUBF}
    def __init__(self, op, postfix):
        # assert postfix.type.cast(Int()), f'Line {op.line}: Cannot {op.lexeme} {postfix.type}'
        super().__init__(postfix.type, op)
        self.postfix = postfix
    def reduce(self, vstr, n):
        self.generate(vstr, n)
        return regs[n]
    def generate(self, vstr, n):
        self.postfix.reduce(vstr, n)
        if self.is_float():
            vstr.imm(self.size, regs[n+2], itf(1))
            vstr.ternary(self.op, self.size, regs[n+1], regs[n], regs[n+2])
        else:
            vstr.ternary(self.op, self.size, regs[n+1], regs[n], self.type.inc)
        self.postfix.store(vstr, n+1)

class Access(Expr):
    def __init__(self, type, token, postfix):
        super().__init__(type, token)
        self.postfix = postfix

class Dot(Access):
    def __init__(self, token, postfix, attr):
        super().__init__(attr.type, token, postfix)
        self.attr = attr
    def address(self, vstr, n):
        vstr.binary(Op.ADD, Size.WORD, self.postfix.address(vstr, n), self.attr.location)
        return regs[n]
    def store(self, vstr, n):
        self.postfix.address(vstr, n+1)
        return self.attr.store(vstr, n)
    def reduce(self, vstr, n):
        self.postfix.address(vstr, n)
        return self.attr.reduce(vstr, n)
    def call(self, vstr, n):
        self.postfix.address(vstr, n)
        self.attr.call(vstr, n)
    def union(self, attr):
        return Dot(self.token, self.postfix, self.attr.union(attr))
    
class Arrow(Dot):
    def address(self, vstr, n):
        vstr.binary(Op.ADD, Size.WORD, self.postfix.reduce(vstr, n), self.attr.location)
        return regs[n]
    def store(self, vstr, n):
        self.postfix.reduce(vstr, n+1)
        return self.attr.store(vstr, n)
    def reduce(self, vstr, n):
        self.postfix.reduce(vstr, n)
        return self.attr.reduce(vstr, n)
    def call(self, vstr, n):
        self.postfix.reduce(vstr, n)
        self.attr.call(vstr, n)
    def union(self, attr):
        return Arrow(self.token, self.postfix, self.attr.union(attr))

class SubScr(Access):
    def __init__(self, token, postfix, sub):
        super().__init__(postfix.type.of, token, postfix)
        self.sub = sub
    def address(self, vstr, n):
        if isinstance(self.postfix.type, Pointer): #Needs to be here because SubScr can't differentiate between actual array and pointer, unlike Dot and Arrow
            self.postfix.reduce(vstr, n)
        else:
            self.postfix.address(vstr, n)
        if isinstance(self.postfix.type, (Array,Pointer)) and self.postfix.type.of.size > 1:
            self.sub.reduce(vstr, n+1)
            vstr.binary(Op.MUL, Size.WORD, regs[n+1], self.postfix.type.of.size)
            vstr.binary(Op.ADD, Size.WORD, regs[n], regs[n+1])
        else:
            vstr.binary(Op.ADD, Size.WORD, regs[n], self.sub.num_reduce(vstr, n+1))
        return regs[n]
    def store(self, vstr, n):
        vstr.store(self.size, regs[n], self.address(vstr, n+1))
        return regs[n]
    def reduce(self, vstr, n):        
        vstr.load(self.size, self.address(vstr, n), regs[n])
        return regs[n]

class Call(Expr):
    def __init__(self, primary, args):
        # for i, param in enumerate(primary.type.params):
        #     assert param == args[i].type, f'Line {primary.token.line}: Argument #{i+1} of {primary.token.lexeme} {param} != {args[i].type}'
        super().__init__(primary.type.ret, primary.token)
        self.primary, self.args = primary, args
    def reduce(self, vstr, reg):
        self.generate(vstr, reg)
        return regs[reg]
    def generate(self, vstr, reg):
        for i, arg in enumerate(self.args):
            arg.reduce(vstr, reg+i)
            # self.primary.type.params[i].convert(vstr, reg+i, arg)
        for i, arg in enumerate(self.args[:4]):
            vstr.binary(Op.MOV, arg.size, regs[i], regs[reg+i])
        if self.primary.type.variable:
            for i, arg in reversed(list(enumerate(self.args[4:]))):
                vstr.push(Size.WORD, regs[reg+4+i])
        else:
            for i, arg in reversed(list(enumerate(self.args[4:]))):
                vstr.push(arg.size, regs[4+i])
        self.primary.call(vstr, reg)
        if self.primary.type.variable and len(self.args) > 4:
            vstr.binary(Op.ADD, Size.WORD, Reg.SP, sum(arg.size for arg in self.args) - sum(param.size for param in self.primary.type.params))
        if reg > 0 and self.size:
            vstr.binary(Op.MOV, Size.WORD, regs[reg], Reg.A)

class Return(Expr):
    def __init__(self, token, expr):
        super().__init__(Void() if expr is None else expr.type, token)
        self.expr = expr
    def generate(self, vstr, n):
        # assert vstr.defn.type.ret == self.type, f'Line {self.token.line}: {vstr.defn.type.ret} != {self.type} in {vstr.defn.token.lexeme}'
        if self.expr:
            self.expr.reduce(vstr, n)
        vstr.jump(Cond.AL, f'.L{vstr.return_label}')

class Program(UserList, CNode):
    def generate(self):
        regs.clear()
        emitter = Emitter()
        for statement in self:
            statement.generate(emitter)
        return '\n'.join(emitter.data + emitter.asm)