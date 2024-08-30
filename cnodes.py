
# -*- coding: utf-8 -*-
"""
Created on Mon Jul  3 19:48:36 2023

@author: Colin
"""
from collections import UserList, UserDict
from struct import pack
from bit32 import Size, Reg, Op, Cond, escape, unescape, negative

class Loop(UserList):
    def start(self):
        return self[-1][0]
    def end(self):
        return self[-1][1]

class Regs:
    def clear(self):
        self.max = -1
    def __getitem__(self, reg):
        if reg == Reg.FP:
            return reg
        elif reg > Reg.L:
            raise SyntaxError('Not enough registers =(')
        self.max = max(self.max, reg)
        return Reg(reg)

regs = Regs()

class Frame(UserDict):
    def __init__(self):
        super().__init__()
        self.size = 0
    def __setitem__(self, name, obj):
        obj.location = self.size
        self.size += obj.size
        super().__setitem__(name, obj)

class Visitor:
    def __init__(self):
        self.clear()
    def clear(self):
        self.n_labels = 0
        self.if_jump_end = False
        self.loop = Loop()
    def begin_func(self, defn):
        if defn.size or defn.returns:
            self.return_label = self.next_label()
        self.defn = defn
    def begin_loop(self):
        self.loop.append((self.next_label(), self.next_label()))
    def end_loop(self):
        self.loop.pop()
    def next_label(self):
        label = self.n_labels
        self.n_labels += 1
        return label
    def append_label(self, label):
        pass
    def string(self, string):
        pass
    def add(self, asm):
        pass
    def space(self, name, size):
        pass
    def glob(self, name, value):
        pass
    def datas(self, label, datas):
        pass
    def push(self, size, reg):
        pass
    def pop(self, size, reg):
        pass
    def pushm(self, calls, *regs):
        pass
    def popm(self, calls, *regs):
        pass
    def call(self, proc):
        pass
    def ret(self):
        pass
    def load_glob(self, rd, name):
        pass
    def load(self, size, rd, rb, offset=None, name=None):
        pass
    def store(self, size, rd, rb, offset=None, name=None):
        pass
    def imm(self, size, rd, value):
        pass
    def unary(self, op, size, rd):
        pass
    def binary(self, op, size, rd, src):
        pass
    def ternary(self, op, size, rd, rs, src):
        pass
    def jump(self, cond, target):
        pass
    def mov(self, cond, rd, value):
        pass
    

class Emitter(Visitor):
    def clear(self):
        super().clear()
        self.labels = []
        self.asm = []
        self.data = []
        self.strings = []
    def append_label(self, label):
        self.labels.append(label)
    def string(self, string):
        if string not in self.strings:
            self.strings.append(string)
            self.data.append(rf'.S{self.strings.index(string)}: "{string}\0"')
        return f'.S{self.strings.index(string)}'
    def add(self, asm):
        for label in self.labels:
            self.asm.append(f'{label}:')
        self.asm.append(f'  {asm}')
        self.labels.clear()
    def space(self, name, size):
        self.data.append(f'{name}: space {size}')
    def glob(self, name, size, value):
        self.data.append(f'{name}: {size.name} {value}')
    def datas(self, label, datas):
        self.data.append(f'{label}:')
        for data in datas:
            self.data.append(f'  {data}')
    def push(self, size, reg):
        self.add(f'PUSH{size.display()} {reg.name}')
    def pop(self, size, reg):
        self.add(f'POP{size.display()} {reg.name}')
    def pushm(self, *regs):
        self.add('PUSH '+', '.join(reg.name for reg in regs))
    def popm(self, *regs):
        self.add('POP '+', '.join(reg.name for reg in regs))
    def call(self, proc):
        if isinstance(proc, str):
            self.add(f'CALL {proc}')
        else:
            self.add(f'CALL {proc.name}')
    def ret(self):
        self.add('RET')
    def load_glob(self, rd, name):
        self.add(f'LD {rd.name}, ={name}')
    def load(self, size, rd, rb, offset=None, name=None):
        self.add(f'LD{size.display()} {rd.name}, [{rb.name}'+(f', {offset}' if offset is not None else '')+']'+(f' ; {name}' if name else ''))
    def store(self, size, rd, rb, offset=None, name=None):
        self.add(f'LD{size.display()} [{rb.name}'+(f', {offset}' if offset is not None else '')+f'], {rd.name}'+(f' ; {name}' if name else ''))
    def imm(self, size, rd, value):
        self.add(f'LD{size.display()} {rd.name}, {value}')
    def unary(self, op, size, rd):
        self.add(f'{op.name}{size.display()} {rd.name}')
    def binary(self, op, size, rd, src):
        self.add(f'{op.name}{size.display()} {rd.name}, {src.name if isinstance(src, Reg) else src}')
    def ternary(self, op, size, rd, rs, src):
        self.add(f'{op.name}{size.display()} {rd.name}, {rs.name}, {src.name if isinstance(src, Reg) else src}')
    def jump(self, cond, target):
        self.add(f'J{cond.display_jump()} {target}')
    def mov(self, cond, rd, value):
        self.add(f'MOV{cond.display()} {rd.name}, {value}')

class CNode:
    def generate(self, vstr, n):
        pass

class Void(CNode):
    def __init__(self):
        self.size = 0
    def __eq__(self, other):
        return isinstance(other, Void)
    def __str__(self):
        return 'void'

class Type(CNode):
    def __init__(self):
        self.const = False
        self.inc = 1
    @staticmethod
    def address(vstr, n, local, base):
        vstr.ternary(Op.ADD, Size.WORD, regs[n], regs[base], local.location)
        return regs[n]
    @staticmethod
    def glob_address(vstr, n, glob):
        vstr.load_glob(regs[n], glob.token.lexeme)
        return regs[n]
    @staticmethod
    def store(vstr, n, local, base):
        vstr.store(local.size, regs[n], regs[base], local.location, local.token.lexeme)
        return regs[n]
    @staticmethod
    def glob_store(vstr, n, glob):
        vstr.load_glob(regs[n+1], glob.token.lexeme)
        vstr.store(regs[n], regs[n+1])
        return regs[n]
    @staticmethod
    def reduce(vstr, n, local, base):
        vstr.load(local.size, regs[n], regs[base], local.location, local.token.lexeme)
        return regs[n]
    @staticmethod
    def glob_reduce(vstr, reg, glob):
        vstr.load_glob(regs[reg], glob.token.lexeme)
        vstr.load(glob.size, regs[reg], regs[reg])
        return regs[reg]
    @staticmethod
    def glob(vstr, glob):
        if glob.init:
            vstr.glob(glob.token.lexeme, glob.size, glob.init.data(vstr))
        else:
            vstr.space(glob.token.lexeme, glob.size)

class Bin(Type):
    def __init__(self, signed):
        super().__init__()
        self.signed = signed
    def is_signed(self):
        return self.signed
    def is_float(self):
        return False
    @staticmethod
    def convert(vstr, reg, other):
        if not isinstance(other.type, Bin):
            vstr.binary(Op.FTI, Size.WORD, regs[reg], regs[reg])
    def cast(self, other):
        return #TODO
    def __eq__(self, other):
        return isinstance(other, Bin)

class Char(Bin):
    def __init__(self, signed=True):
        super().__init__(signed)
        self.size = Size.BYTE
    def __str__(self):
        return 'char'

class Short(Bin):
    def __init__(self, signed=True):
        super().__init__(signed)
        self.size = Size.HALF
    def __str__(self):
        return 'short'

class Int(Bin):
    def __init__(self, signed=True):
        super().__init__(signed)
        self.size = Size.WORD
    def __str__(self):
        return 'int'
        
class Float(Type):
    def __init__(self):
        super().__init__()
        self.size = Size.WORD
    def is_float(self):
        return True
    @staticmethod
    def convert(vstr, reg, other):
        if not other.is_float():
            vstr.binary(Op.ITF, Size.WORD, regs[reg], regs[reg])
    def __eq__(self, other):
        return isinstance(other, Float)
    def __str__(self):
        return 'float'

class Pointer(Int):
    def __init__(self, type):
        super().__init__(False)
        self.to = self.of = type
        self.inc = self.to.size
    def cast(self, other):
        return isinstance(other, Int)
    def __eq__(self, other):
        return isinstance(other, Pointer) and (self.to == other.to \
                                               or isinstance(self.to, Void) \
                                               or isinstance(other.to, Void)) \
            or isinstance(other, Array) and self.of == other.of
    def __str__(self):
        return f'{self.to}*'

class Struct(Frame, Type):
    def __init__(self, name):
        super().__init__()
        self.const = False
        self.name = name
    @staticmethod
    def store(vstr, n, local, base):
        Struct.address(vstr, n+1, local, base)
        for i in range(local.size):
            vstr.load(regs[n+2], regs[n], i)
            vstr.store(regs[n+2], regs[n+1], i)
    @staticmethod
    def reduce(vstr, n, local, base):
        return Struct.address(vstr, n, local, base)
    @staticmethod
    def glob(vstr, glob):
        if glob.init:
            vstr.datas(glob.token.lexeme, [expr.data(vstr) for expr in glob.init])
        else:
            vstr.space(glob.token.lexeme, glob.size)
    def cast(self, other):
        return self == other
    def __eq__(self, other):
        return isinstance(other, Struct) and self.name == other.name
    def __str__(self):
        return f'struct {self.name}'

class Union(UserDict, Type): #TODO
    def __init__(self, name):
        super().__init__()
        self.const = False
        self.size = 0
        self.name = name
    def __setitem__(self, name, attr):
        attr.location = 0
        self.size = max(self.size, attr.size)
        super().__setitem__(name, attr)

class Array(Type):
    def __init__(self, of, length):
        super().__init__()
        if length is not None:
            self.size = of.size * length.value
        self.of = of
        self.length = length
    @staticmethod
    def reduce(vstr, n, local, base):
        return Array.address(vstr, n, local, base)
    @staticmethod
    def glob(vstr, glob):
        if glob.init:
            vstr.datas(glob.token.lexeme, [expr.data(vstr) for expr in glob.init])
        else:
            vstr.space(glob.token.lexeme, glob.size)
    def cast(self, other):
        return self == other
    def __eq__(self, other):
        return isinstance(other, (Array,Pointer)) and self.of == other.of
    def __str__(self):
        return f'{self.of}[]'

class Func(Type):
    def __init__(self, ret, params, variable):
        self.ret, self.params, self.variable = ret, params, variable
        self.size = ret.size
    def cast(self, other):
        return False
    def __eq__(self, other):
        return isinstance(other, Func) and self.ret == other.ret #TODO
    def __str__(self):
        return f'{self.ret}('+','.join(map(str, self.params))+')'

def max_type(left, right):
    if left.is_float():
        return left
    elif right.is_float():
        return right
    else:
        return right if right.size > left.size else left

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
    def convert(self, vstr, reg, other):
        self.type.convert(vstr, reg, other)
    def is_signed(self):
        return self.type.is_signed()
    def is_float(self):
        return self.type.is_float()
    
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
           '/=':Op.DIVF}
    def __init__(self, op, left, right):
        # assert not isinstance(left, String) or not isinstance(right, String)
        # assert left.type.cast(right.type), f'Line {op.line}: Cannot {left.type} {op.lexeme} {right.type}'
        self.left, self.right = left, right
        super().__init__(max_type(left.type, right.type), op)
    def is_signed(self):
        return self.left.is_signed() or self.right.is_signed()
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
    def __init__(self, op, left, right):
        super().__init__(op, left, right)
        if self.is_signed() or self.is_float():
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
        for i in range(self.left.type.size):
            self.right[i].reduce(vstr, n+1)
            vstr.store(self.right[i].size, regs[n+1], regs[n], i)

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

class Local(Expr):
    def store(self, vstr, n):
        return self.type.store(vstr, n, self, Reg.FP)
    def reduce(self, vstr, n):
        return self.type.reduce(vstr, n, self, Reg.FP)
    def address(self, vstr, n):
        return self.type.address(vstr, n, self, Reg.FP)
    def call(self, vstr, n):
        self.reduce(vstr, n, self, Reg.FP)
        vstr.call(regs[n])

class Attr(Local):
    def store(self, vstr, n):
        return self.type.store(vstr, n, self, n+1)
    def reduce(self, vstr, n):
        return self.type.reduce(vstr, n, self, n)
    def address(self, vstr, n):
        return self.type.address(vstr, n, self, n)
    def call(self, vstr, n):
        self.reduce(vstr, n, self, n)
        vstr.call(regs[n])

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
        for param in self.params[4:]:
            param.location += self.space + self.calls + 4*len(push)
        if self.calls:
            vstr.pushm(Reg.LR, *push)
        else:
            vstr.pushm(*push)
        if self.space:
            vstr.binary(Op.SUB, Size.WORD, Reg.SP, self.space)
        vstr.binary(Op.MOV, Size.WORD, Reg.FP, Reg.SP)
        for i, param in enumerate(self.params):
            vstr.store(param.size, regs[i], Reg.FP, param.location)            
        #body
        self.block.generate(vstr, self.max_args)
        #epilogue
        if self.size or self.returns:
            vstr.append_label(f'.L{vstr.return_label}')
        if self.calls and self.size:
            vstr.binary(Op.MOV, self.size, Reg.A, regs[self.calls])
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
        if self.calls and self.size:
            vstr.binary(Op.MOV, self.size, Reg.A, regs[self.calls])
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

class SubScr(Access):
    def __init__(self, token, postfix, sub):
        super().__init__(postfix.type.of, token, postfix)
        self.sub = sub
    def address(self, vstr, n):
        self.postfix.reduce(vstr, n)
        if isinstance(self.postfix.type, (Array,Pointer)) and self.postfix.type.of.size > 1:
            self.sub.reduce(vstr, n+1)
            vstr.binary(Op.MUL, Size.WORD, regs[n+1], self.postfix.type.of.size)
            vstr.binary(Op.ADD, Size.WORD, regs[n], regs[n+1])
        else:
            vstr.binary(Op.ADD, Size.BYTE, regs[n], self.sub.num_reduce(vstr, n+1))
        return regs[n]
    def store(self, vstr, n):
        vstr.store(self.sub.size, regs[n], self.address(vstr, n+1))
        return regs[n]
    def reduce(self, vstr, n):
        vstr.load(self.sub.size, self.address(vstr, n), regs[n])
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
        for i, arg in enumerate(self.args[:4]):
            vstr.binary(Op.MOV, arg.size, regs[i], regs[reg+i])
        for i, arg in reversed(list(enumerate(self.args[4:]))):
            vstr.push(arg.size, regs[4+i])
        self.primary.call(vstr, reg)
        if self.primary.type.variable and len(self.args) > len(self.primary.type.params):
            vstr.binary(Op.ADD, Size.WORD, Reg.SP, sum(arg.size for arg in self.args) - sum(param.size for param in self.primary.type.params))
        if reg > 0 and self.size:
            vstr.binary(Op.MOV, self.size, regs[reg], Reg.A)

class Return(Expr):
    def __init__(self, token, expr):
        super().__init__(Void() if expr is None else expr.type, token)
        self.expr = expr
    def generate(self, vstr, n):
        # assert vstr.defn.type.ret == self.type, f'Line {self.token.line}: {vstr.defn.type.ret} != {self.type} in {vstr.defn.token.lexeme}'
        if self.expr:
            self.expr.reduce(vstr, n)
        vstr.jump(Cond.AL, f'.L{vstr.return_label}')

class Statement(CNode):
    pass

class If(Statement):
    def __init__(self, cond, state):
        self.cond, self.true, self.false = cond, state, None
    def generate(self, vstr, n):
        vstr.if_jump_end = False
        label = vstr.next_label()
        sublabel = vstr.next_label() if self.false else label
        self.cond.compare(vstr, n, sublabel)
        self.true.generate(vstr, n)
        if self.false:
            if not (isinstance(self.true, Return) or (isinstance(self.true, Block) and self.true and isinstance(self.true[-1], Return))):
                vstr.jump(Cond.AL, f'.L{label}')
                vstr.if_jump_end = True
            vstr.append_label(f'.L{sublabel}')
            self.false.branch(vstr, n, label)
            if vstr.if_jump_end:
                vstr.append_label(f'.L{label}')
        else:
            vstr.append_label(f'.L{label}')
    def branch(self, vstr, n, root):
        sublabel = vstr.next_label()
        self.cond.compare(vstr, n, sublabel)
        self.true.generate(vstr, n)
        if self.false:
            if not (isinstance(self.true, Return) or (isinstance(self.true, Block) and self.true and isinstance(self.true[-1], Return))):
                vstr.jump(Cond.AL, f'.L{root}')
                vstr.if_jump_end = True
            vstr.append_label(f'.L{sublabel}')
            self.false.branch(vstr, n, root)

class Case(Statement):
    def __init__(self, const, statement):
        self.const, self.statement = const, statement

class Switch(Statement):
    def __init__(self, test):
        self.test, self.cases, self.default = test, [], None
    def generate(self, vstr, n):
        vstr.begin_loop()
        self.test.reduce(vstr, n)
        labels = []
        for case in self.cases:
            labels.append(vstr.next_label())
            vstr.binary(Op.CMP, self.test.size, regs[n], case.const.num_reduce(vstr, n+1))
            vstr.jump(Cond.EQ, f'.L{labels[-1]}')
        if self.default:
            default = vstr.next_label()
            vstr.jump(Cond.AL, f'.L{default}')
        else:
            vstr.jump(Cond.AL, f'.L{vstr.loop.end()}')
        for i, case in enumerate(self.cases):
            vstr.append_label(f'.L{labels[i]}')
            case.statement.generate(vstr, n)
        if self.default:
            vstr.append_label(f'.L{default}')
            self.default.generate(vstr, n)
        vstr.append_label(f'.L{vstr.loop.end()}')
        vstr.end_loop()

class While(Statement):
    def __init__(self, cond, state):
        self.cond, self.state = cond, state
    def generate(self, vstr, n):
        vstr.begin_loop()
        vstr.append_label(f'.L{vstr.loop.start()}')
        self.cond.compare(vstr, n, vstr.loop.end())
        self.state.generate(vstr, n)
        vstr.jump(Cond.AL, f'.L{vstr.loop.start()}')
        vstr.append_label(f'.L{vstr.loop.end()}')
        vstr.end_loop()

class Do(Statement):
    def __init__(self, state, cond):
        self.state, self.cond = state, cond
    def generate(self, vstr, n):
        vstr.begin_loop()
        vstr.append_label(f'.L{vstr.loop.start()}')
        self.state.generate(vstr, n)
        self.cond.compare_inv(vstr, n, vstr.loop.start())
        vstr.append_label(f'.L{vstr.loop.end()}')
        vstr.end_loop()

class For(While):
    def __init__(self, inits, cond, steps, state):
        super().__init__(cond, state)
        self.inits, self.steps = inits, steps
    def generate(self, vstr, n):
        for init in self.inits:
            init.generate(vstr, n)
        loop = vstr.next_label()
        vstr.begin_loop()
        vstr.append_label(f'.L{loop}')
        self.cond.compare(vstr, n, vstr.loop.end())
        self.state.generate(vstr, n)
        vstr.append_label(f'.L{vstr.loop.start()}')
        for step in self.steps:
            step.generate(vstr, n)
        vstr.jump(Cond.AL, f'.L{loop}')
        vstr.append_label(f'.L{vstr.loop.end()}')
        vstr.end_loop()

class Continue(Statement):
    def generate(self, vstr, n):
        vstr.jump(Cond.AL, f'.L{vstr.loop.start()}')

class Break(Statement):
    def generate(self, vstr, n):
        vstr.jump(Cond.AL, f'.L{vstr.loop.end()}')

class Goto(Statement):
    def __init__(self, target):
        self.target = target
    def generate(self, vstr, n):
        vstr.jump(Cond.AL, self.target.lexeme)

class Label(Statement):
    def __init__(self, label):
        self.label = label
    def generate(self, vstr, n):
        vstr.append_label(self.label.lexeme)

class Program(UserList, CNode):
    def generate(self):
        regs.clear()
        emitter = Emitter()
        for statement in self:
            statement.generate(emitter)
        return '\n'.join(emitter.data + emitter.asm)