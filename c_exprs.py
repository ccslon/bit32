# -*- coding: utf-8 -*-
"""
Created on Fri Sep  6 14:09:48 2024

@author: ccslon
"""
from collections import UserList
from struct import pack

from bit32 import Size, Op, Reg, Cond, negative, escape, unescape
from c_utils import CNode, Visitor, Emitter, reg
from c_types import Char, Int, Float, Pointer, Array, Void

class Expr(CNode):
    def __init__(self, type, token):
        self.type = type
        self.width = type.width
        self.token = token
    def is_signed(self):
        return self.type.is_signed()
    def cmp(self):
        return Op.CMPF if self.type.is_float() else Op.CMP
    def compare(self, vstr, n, label):
        vstr.binary(self.cmp(), self.width, self.reduce(vstr, n), 0)
        vstr.jump(Cond.EQ, f'.L{label}')
    def compare_inv(self, vstr, n, label):
        vstr.binary(self.cmp(), self.width, self.reduce(vstr, n), 0)
        vstr.jump(Cond.NE, f'.L{label}')
    def branch_reduce(self, vstr, n, _):
        self.reduce(vstr, n)
    def branch(self, vstr, n, _):
        self.generate(vstr, n)
    def num_reduce(self, vstr, n):
        return self.reduce(vstr, n)
    def float_reduce(self, vstr, n):
        self.reduce(vstr, n)
        if not self.type.is_float():
            vstr.binary(Op.ITF, Size.WORD, reg[n], reg[n])
        return reg[n]
    def error(self, msg):
        raise SyntaxError(f'Line {self.token.line}: {msg}')

class Local(Expr):
    def address(self, vstr, n):
        return self.type.address(vstr, n, self, Reg.FP)
    def reduce(self, vstr, n):
        return self.type.reduce(vstr, n, self, Reg.FP)
    def store(self, vstr, n):
        return self.type.store(vstr, n, self, Reg.FP)
    def call(self, vstr, n):
        self.type.call(vstr, n, self, Reg.FP)
    def union(self, attr):
        new = Local(attr.type, attr.token)
        new.location = self.location
        return new
    def ptr_union(self, attr):
        new = Local(Pointer(attr.type), attr.token)
        new.location = self.location
        return new

class Attr(Local):
    def address(self, vstr, n):
        return self.type.address(vstr, n, self, n)
    def reduce(self, vstr, n):
        return self.type.reduce(vstr, n, self, n)
    def store(self, vstr, n):
        return self.type.store(vstr, n, self, n+1)
    def call(self, vstr, n):
        self.type.call(vstr, n, self, n)
    def union(self, attr):
        new = Attr(attr.type, attr.token)
        new.location = self.location
        return new
    def ptr_union(self, attr):
        new = Attr(Pointer(attr.type), attr.token)
        new.location = self.location
        return new

class Glob(Local):
    def __init__(self, type, token):
        super().__init__(type, token)
        self.init = None
    def reduce(self, vstr, n):
        return self.type.glob_reduce(vstr, n, self)
    def address(self, vstr, n):
        return self.type.glob_address(vstr, n, self)
    def store(self, vstr, n):
        return self.type.glob_store(vstr, n, self)
    def call(self, vstr, n):
        self.type.glob_call(vstr, n, self)
    def generate(self, vstr):
        self.type.glob_generate(vstr, self)
    def union(self, attr):
        new = Glob(attr.type, self.token)
        return new
    def ptr_union(self, attr):
        new = Glob(Pointer(attr.type), self.token)
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
        vstr.imm(self.width, reg[n], self.value)
        return reg[n]

class NumBase(Expr):
    def __init__(self, token):
        super().__init__(Int(), token)
    def data(self, vstr):
        return self.value
    def reduce(self, vstr, n):
        if 0 <= self.value < 256:
            vstr.binary(Op.MOV, self.width, reg[n], self.value)
        else:
            vstr.imm(self.width, reg[n], self.value)
        return reg[n]
    def num_reduce(self, vstr, n):
        if 0 <= self.value < 256:
            return self.value
        else:
            vstr.imm(self.width, reg[n], self.value)
        return reg[n]

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
            vstr.binary(Op.MVN, self.width, reg[n], self.value)
        else:
            vstr.imm(self.width, reg[n], negative(-self.value, 32))
        return reg[n]
    def num_reduce(self, vstr, n):
        if 0 <= self.value <= 128:
            return -self.value
        else:
            vstr.imm(self.width, reg[n], negative(-self.value, 32))
            return reg[n]

class SizeOf(NumBase):
    def __init__(self, type, token):
        super().__init__(token)
        self.value = type.size

class Letter(Expr):
    def __init__(self, token):
        super().__init__(Char(), token)
    def data(self, _):
        return self.token.lexeme
    def reduce(self, vstr, n):
        vstr.binary(Op.MOV, self.width, reg[n], self.data(vstr))
        return reg[n]
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
    def __getitem__(self, item):
        if item == len(self.value):
            return self.Char(r'\0')
        return self.Char(escape(self.value[item]))
    def data(self, vstr):
        return vstr.string(self.token.lexeme)
    def reduce(self, vstr, n):
        vstr.load_glob(reg[n], self.data(vstr))
        return reg[n]

class OpExpr(Expr):
    def __init__(self, type, op):
        super().__init__(type, op)
        self.op = self.OPF[op.lexeme] if self.type.is_float() else self.OP[op.lexeme]

class Unary(OpExpr):
    OP = {'-':Op.NEG,
          '~':Op.NOT}
    OPF = {'-':Op.NEGF}
    def __init__(self, op, expr):
        super().__init__(expr.type, op)
        assert expr.type.cast(Int()), self.error(f'Cannot {op.lexeme} {expr.type}')
        self.expr = expr
    def reduce(self, vstr, n):
        vstr.unary(self.op, self.width, self.expr.reduce(vstr, n))
        return reg[n]

class Pre(Unary):
    OP = {'++':Op.ADD,
          '--':Op.SUB}
    OPF = {'++':Op.ADDF,
           '--':Op.SUBF}
    def reduce(self, vstr, n):
        self.generate(vstr, n)
        return reg[n]
    def generate(self, vstr, n):
        self.expr.reduce(vstr, n)
        if self.type.is_float():
            vstr.imm(self.width, reg[n+1], itf(1))
            vstr.binay(self.op, self.width, reg[n], reg[n+1])
        else:
            vstr.binary(self.op, self.width, reg[n], self.type.inc)
        self.expr.store(vstr, n)

class AddrOf(Expr):
    def __init__(self, token, expr):
        super().__init__(Pointer(expr.type), token)
        self.expr = expr
    def reduce(self, vstr, n):
        return self.expr.address(vstr, n)

class Deref(Expr):
    def __init__(self, token, expr):
        super().__init__(expr.type.to, token)
        assert hasattr(expr.type, 'to'), self.error(f'Cannot {token.lexeme} {expr.type}')
        self.expr = expr
    def address(self, vstr, n):
        return self.expr.reduce(vstr, n)
    def reduce(self, vstr, n):
        self.address(vstr, n)
        vstr.load(self.width, reg[n], reg[n])
        return reg[n]
    def store(self, vstr, n):
        self.address(vstr, n+1)
        vstr.store(self.width, reg[n], reg[n+1])
        return reg[n]
    def call(self, vstr, n):
        self.expr.call(vstr, n)

class Cast(Expr):
    def __init__(self, token, cast_type, expr):
        super().__init__(cast_type, token)
        assert cast_type.cast(expr.type), self.error(f'Cannot cast {expr.type} to {type}')
        self.expr = expr
    def reduce(self, vstr, n):
        self.expr.reduce(vstr, n)
        if self.type.is_float() and not self.expr.is_float():
            vstr.binary(Op.ITF, Size.WORD, reg[n], reg[n])
        return reg[n]
    def data(self, vstr):
        return self.expr.data(vstr)

class Not(Expr):
    def __init__(self, token, expr):
        super().__init__(expr.type, token)
        self.expr = expr
    def compare(self, vstr, n, label):
        vstr.binary(self.cmp(), self.width, self.expr.reduce(vstr, n), 0)
        vstr.jump(Cond.NE, f'.L{label}')
    def compare_inv(self, vstr, n, label):
        vstr.binary(self.cmp(), self.width, self.expr.reduce(vstr, n), 0)
        vstr.jump(Cond.EQ, f'.L{label}')
    def reduce(self, vstr, n):
        vstr.binary(self.cmp(), self.width, self.expr.reduce(vstr, n), 0)
        vstr.mov(Cond.EQ, reg[n], 1)
        vstr.mov(Cond.NE, reg[n], 0)
        return reg[n]

def max_type(left, right):
    if left.is_float():
        return left
    elif right.is_float():
        return right
    else:
        return right if right.width > left.width else left

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
        super().__init__(max_type(left.type, right.type), op)
        assert not isinstance(left, String) or not isinstance(right, String)
        assert left.type.cast(right.type), self.error(f'Cannot {left.type} {op.lexeme} {right.type}')
        self.left, self.right = left, right
    def is_signed(self):
        return self.left.is_signed() and self.right.is_signed()
    def reduce(self, vstr, n):
        if self.type.is_float():
            vstr.binary(self.op, self.width, self.left.float_reduce(vstr, n), self.right.float_reduce(vstr, n+1))
        else:
            vstr.binary(self.op, self.width, self.left.reduce(vstr, n), self.right.num_reduce(vstr, n+1))
        return reg[n]

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
        if self.type.is_float() or self.is_signed():
            self.op = self.OP[op.lexeme]
            self.inv = self.INV[op.lexeme]
        else:
            self.op = self.UOP.get(op.lexeme, self.OP[op.lexeme])
            self.inv = self.UINV.get(op.lexeme, self.INV[op.lexeme])
    def cmp(self, vstr, n):
        if self.type.is_float():
            vstr.binary(Op.CMPF, self.width, self.left.float_reduce(vstr, n), self.right.float_reduce(vstr, n+1))
        else:
            vstr.binary(Op.CMP, self.width, self.left.reduce(vstr, n), self.right.num_reduce(vstr, n+1))
    def compare(self, vstr, n, label):
        self.cmp(vstr, n)
        vstr.jump(self.inv, f'.L{label}')
    def compare_inv(self, vstr, n, label):
        self.cmp(vstr, n)
        vstr.jump(self.op, f'.L{label}')
    def reduce(self, vstr, n):
        self.cmp(vstr, n)
        vstr.mov(self.op, reg[n], 1)
        vstr.mov(self.inv, reg[n], 0)
        return reg[n]

class Logic(Binary):
    OP = {'&&':Op.AND,
          '||':Op.OR}
    OPF = {'&&':Op.AND,
           '||':Op.OR}
    def cmp(self, vstr, n, expr):
        if self.type.is_float():
            vstr.binary(Op.CMPF, self.width, expr.float_reduce(vstr, n), 0)
        else:
            vstr.binary(Op.CMP, self.width, expr.reduce(vstr, n), 0)
    def compare(self, vstr, n, label):
        if self.op == Op.AND:
            self.left.compare(vstr, n, label)
            self.right.compare(vstr, n, label)
        elif self.op == Op.OR:
            sublabel = vstr.next_label()
            self.left.compare_inv(vstr, n, sublabel)
            self.right.compare(vstr, n, label)
            vstr.append_label(f'.L{sublabel}')
    def compare_inv(self, vstr, n, label):
        if self.op == Op.AND:
            sublabel = vstr.next_label()
            self.left.compare(vstr, n, sublabel)
            self.right.compare_inv(vstr, n, label)
            vstr.append_label(f'.L{sublabel}')
        elif self.op == Op.OR:
            self.left.compare_inv(vstr, n, label)
            self.right.compare_inv(vstr, n, label)
    def reduce(self, vstr, n):
        if self.op == Op.AND:
            label = vstr.next_label()
            sublabel = vstr.next_label()
            self.left.compare(vstr, n, label)
            self.right.compare(vstr, n, label)   
            vstr.binary(Op.MOV, Size.WORD, reg[n], 1)
            vstr.jump(Cond.AL, f'.L{sublabel}')
            vstr.append_label(f'.L{label}')
            vstr.binary(Op.MOV, Size.WORD, reg[n], 0)
            vstr.append_label(f'.L{sublabel}')
        elif self.op == Op.OR:
            label = vstr.next_label()
            sublabel = vstr.next_label()
            subsublabel = vstr.next_label()
            self.left.compare_inv(vstr, n, label)
            self.right.compare(vstr, n, sublabel)
            vstr.append_label(f'.L{label}')
            vstr.binary(Op.MOV, Size.WORD, reg[n], 1)
            vstr.jump(Cond.AL, f'.L{subsublabel}')
            vstr.append_label(f'.L{sublabel}')
            vstr.binary(Op.MOV, Size.WORD, reg[n], 0)
            vstr.append_label(f'.L{subsublabel}')
        return reg[n]

class Condition(Expr):
    def __init__(self, token, cond, true, false):
        super().__init__(true.type, token)
        self.cond, self.true, self.false = cond, true, false
    def reduce(self, vstr, n):
        label = vstr.next_label()
        sublabel = vstr.next_label() if self.false else label
        self.cond.compare(vstr, n, sublabel)
        self.true.reduce(vstr, n)
        vstr.jump(Cond.AL, f'.L{label}')
        vstr.append_label(f'.L{sublabel}')
        self.false.branch_reduce(vstr, n, label)
        vstr.append_label(f'.L{label}')
        return reg[n]
    def branch(self, vstr, n, root):
        sublabel = vstr.next_label()
        self.cond.compare(vstr, n, sublabel)
        self.true.reduce(vstr, n)
        vstr.jump(Cond.AL, f'.L{root}')
        vstr.append_label(f'.L{sublabel}')
        self.false.branch_reduce(vstr, n, root)

class InitAssign(Expr):
    def __init__(self, token, left, right):
        super().__init__(left.type, token)
        assert left.type == right.type, self.error(f'{left.type} != {right.type}')
        self.left, self.right = left, right
    def generate(self, vstr, n):
        self.right.reduce(vstr, n)
        self.type.convert(vstr, n, self.right.type)
        self.left.store(vstr, n)

class Assign(InitAssign):
    def __init__(self, token, left, right):
        super().__init__(token, left, right)
        assert not left.type.const, self.error('Cannot assign to a const')
    def reduce(self, vstr, n):
        self.generate(vstr, n)
        return reg[n]

class InitListAssign(Expr):
    def __init__(self, token, left, right):
        super().__init__(left.type, token)
        if isinstance(left.type, Array):
            if left.type.length is None:
                left.type.length = len(right)
                left.type.size =  len(right) * left.type.of.size
            else:
                assert left.type.length >= len(right), self.error('Not large enough')
        self.left, self.right = left, right
    def generate(self, vstr, n):
        self.left.address(vstr, n)
        for i, (loc, type) in enumerate(self.left.type):
            type.list_generate(vstr, n, self.right[i], loc)

class InitArrayString(Expr):
    def __init__(self, token, array, string):
        super().__init__(array.type, token)
        if array.type.length is None:
            array.type.size = array.type.length = len(string) + 1
        else:
            assert array.type.size >= len(string) + 1, self.error('Not large enough')
        self.array = array
        self.string = string
    def generate(self, vstr, n):
        self.array.address(vstr, n)
        for i, c in enumerate(self.string):
            vstr.binary(Op.MOV, Size.BYTE, reg[n+1], c.data(vstr))
            vstr.store(Size.BYTE, reg[n+1], reg[n], i)

class Block(UserList, Expr):
    def generate(self, vstr, n):
        for statement in self:
            statement.generate(vstr, n)

class Defn(Expr):
    def __init__(self, type, id, block, returns, calls, max_args, space):
        super().__init__(type, id)
        self.params, self.block, self.returns, self.calls, self.max_args, self.space = type.params, block, returns, calls, max_args, space
    def generate(self, vstr):
        reg.clear()
        preview = Visitor()
        preview.begin_func(self)
        self.block.generate(preview, self.max_args)
        push = list(map(Reg, range(max(bool(self.type.width), len(self.params)), reg.max+1))) + [Reg.FP]
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
            vstr.store(param.width, reg[i], Reg.FP, param.location)
        #body
        self.block.generate(vstr, self.max_args)
        #epilogue
        if self.type.width or self.returns:
            vstr.append_label(f'.L{vstr.return_label}')
        if self.max_args and self.type.width:
            vstr.binary(Op.MOV, Size.WORD, Reg.A, reg[self.max_args])
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
        reg.clear()
        preview = Visitor()
        preview.begin_func(self)
        self.block.generate(preview, self.max_args)
        push = list(map(Reg, range(4, reg.max+1))) + [Reg.FP]

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
        if self.type.width or self.returns:
            vstr.append_label(f'.L{vstr.return_label}')
        if self.max_args and self.type.width:
            vstr.binary(Op.MOV, Size.WORD, Reg.A, reg[self.max_args])
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
        assert postfix.type.cast(Int()), self.error(f'Cannot {op.lexeme} {postfix.type}')
        super().__init__(postfix.type, op)
        self.postfix = postfix
    def reduce(self, vstr, n):
        self.generate(vstr, n)
        return reg[n]
    def generate(self, vstr, n):
        self.postfix.reduce(vstr, n)
        if self.type.is_float():
            vstr.imm(self.width, reg[n+2], itf(1))
            vstr.ternary(self.op, self.width, reg[n+1], reg[n], reg[n+2])
        else:
            vstr.ternary(self.op, self.width, reg[n+1], reg[n], self.type.inc)
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
        return reg[n]
    def reduce(self, vstr, n):
        self.postfix.address(vstr, n)
        return self.attr.reduce(vstr, n)
    def store(self, vstr, n):
        self.postfix.address(vstr, n+1)
        return self.attr.store(vstr, n)
    def call(self, vstr, n):
        self.postfix.address(vstr, n)
        self.attr.call(vstr, n)
    def union(self, attr):
        return Dot(self.token, self.postfix, self.attr.union(attr))

class Arrow(Dot):
    def address(self, vstr, n):
        vstr.binary(Op.ADD, Size.WORD, self.postfix.reduce(vstr, n), self.attr.location)
        return reg[n]
    def reduce(self, vstr, n):
        self.postfix.reduce(vstr, n)
        return self.attr.reduce(vstr, n)
    def store(self, vstr, n):
        self.postfix.reduce(vstr, n+1)
        return self.attr.store(vstr, n)
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
            vstr.binary(Op.MUL, Size.WORD, reg[n+1], self.postfix.type.of.size)
            vstr.binary(Op.ADD, Size.WORD, reg[n], reg[n+1])
        else:
            vstr.binary(Op.ADD, Size.WORD, reg[n], self.sub.num_reduce(vstr, n+1))
        return reg[n]
    def reduce(self, vstr, n):
        vstr.load(self.width, self.address(vstr, n), reg[n])
        return reg[n]
    def store(self, vstr, n):
        vstr.store(self.width, reg[n], self.address(vstr, n+1))
        return reg[n]
    def call(self, vstr, n):
        vstr.call(self.reduce(vstr, n))

class Call(Expr):
    def __init__(self, token, primary, args):
        super().__init__(primary.type.ret, token)
        assert len(args) >= len(primary.type.params), self.error(f'Not enough arguments provided in function call "{primary.token.lexeme}"')
        for i, param in enumerate(primary.type.params):
            assert param.type == args[i].type, self.error(f'Argument #{i+1} of "{primary.token.lexeme}" {param.type} != {args[i].type}')
        self.primary, self.args, self.params = primary, args, primary.type.params
    def calls(self):
        return True
    def reduce(self, vstr, n):
        self.generate(vstr, n)
        if n > 0 and self.width:
            vstr.binary(Op.MOV, Size.WORD, reg[n], Reg.A)
        return reg[n]
    def generate(self, vstr, n):
        for i, arg in enumerate(self.args):
            arg.reduce(vstr, n+i)
            self.params[i].type.convert(vstr, n+i, arg.type)
        for i, arg in enumerate(self.args[:4]):
            vstr.binary(Op.MOV, arg.width, reg[i], reg[n+i])
        for i, arg in reversed(list(enumerate(self.args[4:]))):
            vstr.push(arg.width, reg[n+4+i])
        self.primary.call(vstr, n)

class VarCall(Call):
    def generate(self, vstr, n):
        for i, param in enumerate(self.params):
            self.args[i].reduce(vstr, n+i)
            self.params[i].type.convert(vstr, n+i, self.args[i].type)
        for i, arg in enumerate(self.args[len(self.params):]):
            arg.reduce(vstr, len(self.params)+n+i)
        for i, arg in enumerate(self.args[:4]):
            vstr.binary(Op.MOV, arg.width, reg[i], reg[n+i])
        for i, arg in reversed(list(enumerate(self.args[4:]))):
            vstr.push(Size.WORD, reg[n+4+i])
        self.primary.call(vstr, n)
        if len(self.args) > 4:
            vstr.binary(Op.ADD, Size.WORD, Reg.SP, len(self.args[4:]) * Size.WORD)

class Return(Expr):
    def __init__(self, token, ret, expr):
        if ret:
            super().__init__(ret, token)
            assert ret == expr.type, self.error(f'Return expression type {ret} != function type {expr.type}')
            if isinstance(expr, OpExpr):
                expr.width = ret.width
        else:
            super().__init__(Void(), token)
        self.expr = expr
    def generate(self, vstr, n):
        if self.expr:
            self.expr.reduce(vstr, n)
        vstr.jump(Cond.AL, f'.L{vstr.return_label}')

class Program(UserList, CNode):
    def generate(self):
        reg.clear()
        emitter = Emitter()
        for statement in self:
            statement.generate(emitter)
        return '\n'.join(emitter.data + emitter.asm)