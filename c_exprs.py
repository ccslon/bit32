# -*- coding: utf-8 -*-
"""
Created on Fri Sep  6 14:09:48 2024

@author: ccslon
"""
from collections import UserList
from struct import pack

from bit32 import Size, Op, Reg, Cond, negative, escape, unescape
from c_visitors import Visitor, Emitter
from c_nodes import CNode, Expr, Var, Const, Unary, OpExpr, Binary, Access
from c_types import Char, Int, Float, Pointer, Array, Void

class Local(Var):
    def __init__(self, c_type, name):
        super().__init__(c_type, name)
        self.location = None
    def address(self, vstr, n):
        return self.type.address(vstr, n, self, Reg.SP)
    def reduce(self, vstr, n):
        return self.type.reduce(vstr, n, self, Reg.SP)
    def store(self, vstr, n):
        return self.type.store(vstr, n, self, Reg.SP)
    def call(self, vstr, n):
        self.type.call(vstr, n, self, Reg.SP)
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
    def call(self, vstr, n):
        self.type.call(vstr, n, self, n)
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
    def store(self, vstr, n): #TODO test
        return self.type.glob_store(vstr, n, self)
    def call(self, vstr, n):
        self.type.glob_call(vstr, n, self)
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
        self.value = None
    def data(self, vstr):
        return self.value
    def reduce(self, vstr, n):
        if 0 <= self.value < 256:
            vstr.binary(Op.MOV, self.width, Reg(n), self.value)
        else:
            vstr.imm(self.width, Reg(n), self.value)
        return Reg(n)
    def num_reduce(self, vstr, n):
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
    def num_reduce(self, vstr, n):
        if 0 <= self.value <= 128:
            return -self.value
        vstr.imm(self.width, Reg(n), negative(-self.value, 32)) #TODO test this branch
        return Reg(n)

class SizeOf(NumberBase):
    def __init__(self, c_type, token):
        super().__init__(token)
        self.value = c_type.size

def itf(i):
    return int.from_bytes(pack('>f', float(i)), 'big')

class Decimal(Const):
    def __init__(self, token):
        super().__init__(Float(), token)
        self.value = itf(token.lexeme)
    def data(self, vstr): #TODO test
        return self.value
    def reduce(self, vstr, n):
        vstr.imm(self.width, Reg(n), self.value)
        return Reg(n)

class NegDecimal(Decimal):
    def __init__(self, token): #TODO test
        super().__init__(token)
        self.value = -self.value

class Character(Const):
    def __init__(self, token):
        super().__init__(Char(), token)
    def data(self, _):
        return self.token.lexeme
    def reduce(self, vstr, n):
        vstr.binary(Op.MOV, self.width, Reg(n), self.data(vstr))
        return Reg(n)
    def num_reduce(self, vstr, n):
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

class UnaryOp(Unary, OpExpr):
    OP = {'-':Op.NEG,
          '~':Op.NOT}
    OPF = {'-':Op.NEGF}
    def __init__(self, op, expr):
        super().__init__(expr.type, op, expr)
        assert expr.type.cast(Int()), self.error(f'Cannot {op.lexeme} {expr.type}')
        self.init_op(op)
    def reduce(self, vstr, n):
        vstr.unary(self.op, self.width, self.expr.reduce(vstr, n))
        return Reg(n)

class Pre(UnaryOp): #TODO test
    OP = {'++':Op.ADD,
          '--':Op.SUB}
    OPF = {'++':Op.ADDF,
           '--':Op.SUBF}
    def reduce(self, vstr, n):
        self.expr.reduce(vstr, n)
        if self.type.is_float():
            vstr.imm(self.width, Reg(n+1), itf(1))
            vstr.binay(self.op, self.width, Reg(n), Reg(n+1))
        else:
            vstr.binary(self.op, self.width, Reg(n), self.type.inc)
        self.expr.store(vstr, n)
        return Reg(n)
    def generate(self, vstr, n):
        self.reduce(vstr, 0)

class Post(UnaryOp):
    OP = {'++':Op.ADD,
          '--':Op.SUB}
    OPF = {'++':Op.ADDF,
           '--':Op.SUBF}
    def reduce(self, vstr, n):
        self.expr.reduce(vstr, n)
        if self.type.is_float(): #TODO test
            vstr.imm(self.width, Reg(n+2), itf(1))
            vstr.ternary(self.op, self.width, Reg(n+1), Reg(n), Reg(n+2))
        else:
            vstr.ternary(self.op, self.width, Reg(n+1), Reg(n), self.type.inc)
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
        assert hasattr(expr.type, 'to'), self.error(f'Cannot {token.lexeme} {expr.type}')
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
        self.expr.call(vstr, n)

class Cast(Unary):
    def __init__(self, token, cast_type, expr):
        super().__init__(cast_type, token, expr)
        assert cast_type.cast(expr.type), self.error(f'Cannot cast {expr.type} to {cast_type}')
    def reduce(self, vstr, n):
        self.expr.reduce(vstr, n)
        self.type.convert(vstr, n, self.expr.type)
        return Reg(n)
    def data(self, vstr): #TODO test
        return self.expr.data(vstr)

class Not(Unary):  #TODO test
    def __init__(self, token, expr):
        super().__init__(expr.type, token, expr)
    def compare(self, vstr, n, label):
        vstr.binary(self.cmp_op(), self.width, self.expr.reduce(vstr, n), 0)
        vstr.jump(Cond.NE, label)
    def compare_inv(self, vstr, n, label):
        vstr.binary(self.cmp_op(), self.width, self.expr.reduce(vstr, n), 0)
        vstr.jump(Cond.EQ, label)
    def reduce(self, vstr, n):
        vstr.binary(self.cmp_op(), self.width, self.expr.reduce(vstr, n), 0)
        vstr.mov(Cond.EQ, Reg(n), 1)
        vstr.mov(Cond.NE, Reg(n), 0)
        return Reg(n)

def max_type(left, right):
    if left.is_float():
        return left
    if right.is_float():
        return right
    return right if right.width > left.width else left

class BinaryOp(Binary, OpExpr):
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
        super().__init__(max_type(left.type, right.type), op, left, right)
        assert not isinstance(left, String) or not isinstance(right, String)
        assert left.type.cast(right.type), self.error(f'Cannot {left.type} {op.lexeme} {right.type}')
        self.init_op(op)
    def reduce(self, vstr, n):
        if self.type.is_float():
            vstr.binary(self.op, self.width, self.left.float_reduce(vstr, n), self.right.float_reduce(vstr, n+1))
        elif isinstance(self.left.type, Pointer) and self.left.type.to.size > 1:
            self.left.reduce(vstr, n)
            self.right.reduce(vstr, n+1)
            vstr.binary(Op.MUL, Size.WORD, Reg(n+1), self.left.type.of.size)
            vstr.binary(self.op, Size.WORD, Reg(n), Reg(n+1))
        else:
            vstr.binary(self.op, self.width, self.left.reduce(vstr, n), self.right.num_reduce(vstr, n+1))
        return Reg(n)

class Compare(BinaryOp):
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
        if self.type.is_float(): #TODO test
            vstr.binary(Op.CMPF, self.width, self.left.float_reduce(vstr, n), self.right.float_reduce(vstr, n+1))
        else:
            vstr.binary(Op.CMP, self.width, self.left.reduce(vstr, n), self.right.num_reduce(vstr, n+1))
    def compare(self, vstr, n, label):
        self.cmp(vstr, n)
        vstr.jump(self.inv, label)
    def compare_inv(self, vstr, n, label): #TODO test
        self.cmp(vstr, n)
        vstr.jump(self.op, label)
    def reduce(self, vstr, n):
        self.cmp(vstr, n)
        vstr.mov(self.op, Reg(n), 1)
        vstr.mov(self.inv, Reg(n), 0)
        return Reg(n)

class Logic(BinaryOp):
    OP = {'&&':Op.AND,
          '||':Op.OR}
    OPF = {'&&':Op.AND,
           '||':Op.OR}
    def cmp(self, vstr, n, expr): #TODO test
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
        sublabel = vstr.next_label() if self.false else label
        self.cond.compare(vstr, n, sublabel)
        self.true.reduce(vstr, n)
        vstr.jump(Cond.AL, label)
        vstr.append_label(sublabel)
        self.false.branch_reduce(vstr, n, label)
        vstr.append_label(label)
        return Reg(n)
    def branch_reduce(self, vstr, n, root): #TODO test
        sublabel = vstr.next_label()
        self.cond.compare(vstr, n, sublabel)
        self.true.reduce(vstr, n)
        vstr.jump(Cond.AL, root)
        vstr.append_label(sublabel)
        self.false.branch_reduce(vstr, n, root)

class InitAssign(Binary):
    def __init__(self, token, left, right):
        super().__init__(left.type, token, left, right)
        assert left.type == right.type, self.error(f'{left.type} != {right.type}')
    def soft_calls(self):
        return self.left.hard_calls() or self.right.soft_calls()
    def reduce(self, vstr, n):
        self.right.reduce(vstr, n)
        self.type.convert(vstr, n, self.right.type)
        self.left.store(vstr, n)
        return Reg(n)
    def generate(self, vstr, n):
        self.reduce(vstr, n*self.soft_calls())
    def glob_generate(self, vstr):
        vstr.glob(self.left.token.lexeme, self.width, self.right.data(vstr))

class Assign(InitAssign):
    def __init__(self, token, left, right):
        super().__init__(token, left, right)
        assert not left.type.const, self.error('Cannot assign to a const')

class InitListAssign(Binary):
    def __init__(self, token, left, right):
        super().__init__(left.type, token, left, right)
        if isinstance(left.type, Array):
            if left.type.length is None:  #TODO test
                left.type.length = len(right)
                left.type.size =  len(right) * left.type.of.size
            else:
                assert left.type.length >= len(right), self.error('Not large enough')
    def generate(self, vstr, n):
        self.left.address(vstr, n)
        for i, (loc, c_type) in enumerate(self.left.type):
            c_type.list_generate(vstr, n, self.right[i], loc)
    def glob_generate(self, vstr):
        vstr.datas(self.left.token.lexeme, self.left.type.glob_data(vstr, self.right, []))

class InitArrayString(Expr): #TODO make Binary?
    def __init__(self, token, array, string):
        super().__init__(array.type, token)
        if array.type.length is None:
            array.type.size = array.type.length = len(string.value) + 1
        else:
            assert array.type.size >= len(string.value) + 1, self.error('Not large enough')
        self.array = array
        self.string = string
    def generate(self, vstr, n):
        self.array.address(vstr, n)
        for i, c in enumerate(self.string.value+'\0'):
            vstr.binary(Op.MOV, Size.BYTE, Reg(n+1), f"'{escape(c)}'")
            vstr.store(Size.BYTE, Reg(n+1), Reg(n), i)
    def glob_generate(self, vstr):
        vstr.string_array(self.array.token.lexeme, self.string.token.lexeme)

class Block(UserList, Expr):
    def generate(self, vstr, n):
        for statement in self:
            statement.generate(vstr, n)

class Defn(Expr):
    def __init__(self, c_type, name, block, info):
        super().__init__(c_type, name)
        self.params, self.block = c_type.params, block
        self.returns, self.calls, self.max_args, self.space = info.returns, info.calls, info.max_args, info.space
    def prologue(self, vstr, push):
        if len(self.params) > 4:
            offset = self.space + 4*self.calls + 4*len(push)
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
    def epilogue(self, vstr, push):
        if self.type.ret.width or self.returns:
            vstr.append_label(vstr.return_label)
        if self.max_args > 0 and self.type.ret.width and self.returns:
            vstr.binary(Op.MOV, Size.WORD, Reg.A, Reg(self.max_args))
        if self.space:
            vstr.binary(Op.ADD, Size.WORD, Reg.SP, self.space)
        if self.calls:
            vstr.popm(*push, Reg.PC)
        else:
            vstr.popm(*push)
            vstr.ret()
    def glob_generate(self, vstr):
        preview = Visitor()
        preview.begin_func(self)
        self.block.generate(preview, self.max_args)
        push = list(map(Reg, range(max(bool(self.type.ret.width), len(self.params)), preview.max_reg+1)))
        vstr.begin_func(self)
        #start
        vstr.append_label(self.token.lexeme)
        #prologue
        self.prologue(vstr, push)
        #body
        self.block.generate(vstr, self.max_args)
        #epilogue
        self.epilogue(vstr, push)

class VarDefn(Defn): #TODO test
    def prologue(self, vstr, push):
        vstr.pushm(*list(map(Reg, range(4))))
        offset = self.space + Size.WORD*self.calls + Size.WORD*len(push)
        for param in self.params:
            param.location += offset
        if self.calls:
            vstr.pushm(*push, Reg.LR)
        else:
            vstr.pushm(*push)
        if self.space:
            vstr.binary(Op.SUB, Size.WORD, Reg.SP, self.space)
    def epilogue(self, vstr, push):
        if self.type.ret.width or self.returns:
            vstr.append_label(vstr.return_label)
        if self.max_args > 0 and self.type.ret.width and self.returns:
            vstr.binary(Op.MOV, Size.WORD, Reg.A, Reg(self.max_args))
        if self.space:
            vstr.binary(Op.ADD, Size.WORD, Reg.SP, self.space)
        if self.calls:
            vstr.popm(*push, Reg.LR)
        else:
            vstr.popm(*push)
        vstr.binary(Op.ADD, Size.WORD, Reg.SP, 4*Size.WORD)
        vstr.ret()

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
    def call(self, vstr, n):
        self.struct.address(vstr, n)
        self.attr.call(vstr, n)
    def union(self, attr):
        return Dot(self.token, self.struct, self.attr.union(attr))

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
    def call(self, vstr, n): #TODO test
        self.struct.reduce(vstr, n)
        self.attr.call(vstr, n)
    def union(self, attr):
        return Arrow(self.token, self.struct, self.attr.union(attr))

class SubScr(Binary):
    def __init__(self, token, left, right):
        super().__init__(left.type.of, token, left, right)
    def address(self, vstr, n):
        if isinstance(self.left.type, Pointer): #Needs to be here because SubScr can't differentiate between actual array and pointer, unlike Dot and Arrow
            self.left.reduce(vstr, n)
        else:
            self.left.address(vstr, n)
        if isinstance(self.left.type, (Array,Pointer)) and self.left.type.of.size > 1:
            self.right.reduce(vstr, n+1)
            vstr.binary(Op.MUL, Size.WORD, Reg(n+1), self.left.type.of.size)
            vstr.binary(Op.ADD, Size.WORD, Reg(n), Reg(n+1))
        else:
            vstr.binary(Op.ADD, Size.WORD, Reg(n), self.right.num_reduce(vstr, n+1))
        return Reg(n)
    def reduce(self, vstr, n):
        vstr.load(self.width, self.address(vstr, n), Reg(n))
        return Reg(n)
    def store(self, vstr, n):
        vstr.store(self.width, Reg(n), self.address(vstr, n+1))
        return Reg(n)
    def call(self, vstr, n): #TODO test
        vstr.call(self.reduce(vstr, n))

class Call(Expr):
    def __init__(self, token, func, args):
        super().__init__(func.type.ret, token)
        assert len(args) >= len(func.type.params), self.error(f'Not enough arguments provided in function call "{func.token.lexeme}"')
        for i, param in enumerate(func.type.params):
            assert param.type == args[i].type, self.error(f'Argument #{i+1} of "{func.token.lexeme}" {param.type} != {args[i].type}')
        self.func, self.args, self.params = func, args, func.type.params
    def hard_calls(self):
        return True
    def soft_calls(self):
        return self.func.hard_calls() or any(arg.hard_calls() for arg in self.args)
    def args_reduce(self, vstr, n):
        for i, arg in enumerate(self.args):
            arg.reduce(vstr, n+i)
            self.params[i].type.convert(vstr, n+i, arg.type)
        if n > 0:
            for i, arg in enumerate(self.args[:4]):
                vstr.binary(Op.MOV, arg.width, Reg(i), Reg(n+i))
        for i, arg in reversed(list(enumerate(self.args[4:]))): #TODO test thsi branch
            vstr.push(arg.width, Reg(n+4+i))
    def reduce(self, vstr, n):
        self.args_reduce(vstr, n)
        self.func.call(vstr, n if n else min(4, len(self.args)))
        if n > 0 and self.width:
            vstr.binary(Op.MOV, Size.WORD, Reg(n), Reg.A)
        return Reg(n)
    def generate(self, vstr, n):
        self.args_reduce(vstr, n*self.soft_calls())
        self.func.call(vstr, n)

class VarCall(Call):
    def args_reduce(self, vstr, n):
        for i, param in enumerate(self.params):
            self.args[i].reduce(vstr, n+i)
            param.type.convert(vstr, n+i, self.args[i].type)
        for i, arg in enumerate(self.args[len(self.params):]):
            arg.reduce(vstr, len(self.params)+n+i)
        if n > 0:
            for i, arg in enumerate(self.args[:4]):
                vstr.binary(Op.MOV, arg.width, Reg(i), Reg(n+i))
        for i, arg in reversed(list(enumerate(self.args[4:]))):
            vstr.push(Size.WORD, Reg(n+4+i)) #TODO test
    def adjust_stack(self, vstr):
        if len(self.args) > 4:
            vstr.binary(Op.ADD, Size.WORD, Reg.SP, len(self.args[4:]) * Size.WORD) #TODO test
    def reduce(self, vstr, n):
        self.args_reduce(vstr, n)
        self.func.call(vstr, n if n else min(4, len(self.args)))
        self.adjust_stack(vstr)
        if n > 0 and self.width:
            vstr.binary(Op.MOV, Size.WORD, Reg(n), Reg.A)
        return Reg(n)
    def generate(self, vstr, n):
        self.args_reduce(vstr, n*self.soft_calls())
        self.func.call(vstr, n)
        self.adjust_stack(vstr)

class Return(Expr):
    def __init__(self, token, ret, expr):
        if ret:
            super().__init__(ret, token)
            assert ret == expr.type, self.error(f'Return expression type {expr.type} != function return type {ret}')
            if isinstance(expr, OpExpr):
                expr.width = ret.width
        else:
            super().__init__(Void(), token) #TODO test
        self.ret, self.expr = ret, expr
    def generate(self, vstr, n):
        if self.expr:
            self.expr.reduce(vstr, n)
            self.ret.convert(vstr, n, self.expr.type)
        vstr.jump(Cond.AL, vstr.return_label)

class Program(UserList, CNode):
    def generate(self):
        emitter = Emitter()
        for statement in self:
            statement.glob_generate(emitter)
        return '\n'.join(emitter.data + emitter.asm)