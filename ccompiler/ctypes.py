# -*- coding: utf-8 -*-
"""
Created on Fri Sep  6 14:05:50 2024

@author: ccslon
"""
from collections import UserDict
from bit32 import Op, Size, Reg, Cond, itf
from .cnodes import Frame
from . import cexprs

class Type:
    def cast(self, other):
        return self == other

class Void(Type):
    def __init__(self):
        self.size = self.width = 0
    def __eq__(self, other):
        return isinstance(other, Void)
    def __str__(self):
        return 'void'

class Value(Type):
    def __init__(self):
        self.const = False
        self.inc = 1
        self.width = 0
    def convert(self, emitter, n, other):
        pass
    def fti(self, emitter, n):
        pass
    def itf(self, emitter, n):
        pass
    def address(self, emitter, n, var, base):
        emitter.address(Reg(n), Reg(base), var.offset, var.name())
        return Reg(n)
    def reduce(self, emitter, n, var, base):
        emitter.load(self.width, Reg(n), Reg(base), var.offset, var.name())
        return Reg(n)
    def store(self, emitter, n, var, base):
        emitter.store(self.width, Reg(n), Reg(base), var.offset, var.name())
        return Reg(n)
    def reduce_pre(self, emitter, n, op):
        emitter.binary(op, self.width, Reg(n), self.inc)
    def reduce_post(self, emitter, n, op):
        emitter.ternary(op, self.width, Reg(n+1), Reg(n), self.inc)
    def reduce_binary(self, emitter, n, op, left, right):
        emitter.binary(op, self.width, left.reduce(emitter, n), right.reduce_num(emitter, n+1))
    def reduce_compare(self, emitter, n, left, right):
        emitter.binary(Op.CMP, self.width, left.reduce(emitter, n), right.reduce_num(emitter, n+1))
    def list_generate(self, emitter, n, right, loc):
        right.reduce(emitter, n+1)
        self.convert(emitter, n+1, right.type)
        emitter.store(self.width, Reg(n+1), Reg(n), loc)
    def glob_address(self, emitter, n, glob):
        emitter.load_glob(Reg(n), glob.token.lexeme)
        return Reg(n)
    def glob_reduce(self, emitter, n, glob):
        self.glob_address(emitter, n, glob)
        emitter.load(self.width, Reg(n), Reg(n))
        return Reg(n)
    def glob_store(self, emitter, n, glob): #TODO test
        emitter.load_glob(Reg(n+1), glob.token.lexeme)
        emitter.store(self.width, Reg(n), Reg(n+1))
        return Reg(n)
    def glob_data(self, emitter, expr, data):
        data.append((self.width, expr.data(emitter)))

class Bin(Value):
    BINARY_OP = {
        '+' :Op.ADD,
        '+=':Op.ADD,
        '++':Op.ADD,
        '-' :Op.SUB,
        '-=':Op.SUB,
        '--':Op.SUB,
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
        '||':Op.OR,
        '&': Op.AND,
        '&=':Op.AND,
        '&&':Op.AND,
        '/': Op.DIV,
        '/=':Op.DIV,
        '%': Op.MOD,
        '%=':Op.MOD
    }
    UNARY_OP = {
        '++':Op.ADD,
        '--':Op.SUB,
        '-':Op.NEG,
        '~':Op.NOT
    }
    CMP = Op.CMP
    SCMP_OP = {     # Signed compare op
        '==':Cond.EQ,
        '!=':Cond.NE,
        '>': Cond.GT,
        '<': Cond.LT,
        '>=':Cond.GE,
        '<=':Cond.LE
    }
    INV_SCMP_OP = { # inverse signed compare op
        '==':Cond.NE,
        '!=':Cond.EQ,
        '>': Cond.LE,
        '<': Cond.GE,
        '>=':Cond.LT,
        '<=':Cond.GT
    }
    UCMP_OP = {     # unsigned compare op
        '>': Cond.HI,
        '<': Cond.LO,
        '>=':Cond.HS,
        '<=':Cond.LS
    }
    INV_UCMP_OP = { # inverse unsigned compare op
        '>': Cond.LS,
        '<': Cond.HS,
        '>=':Cond.LO,
        '<=':Cond.HI
    }
    def __init__(self, signed):
        super().__init__()
        self.signed = signed
    def convert(self, emitter, n, other):
        other.fti(emitter, n)
    def fti(self, emitter, n):
        pass
    def itf(self, emitter, n):
        emitter.binary(Op.ITF, Size.WORD, Reg(n), Reg(n))
    def get_unary_op(self, op):
        return self.UNARY_OP[op.lexeme]
    def get_binary_op(self, op):
        return self.BINARY_OP[op.lexeme]
    def get_cmp_op(self, op):
        if self.signed:
            return self.SCMP_OP[op.lexeme]
        return self.UCMP_OP.get(op.lexeme, self.SCMP_OP[op.lexeme])
    def get_inv_cmp_op(self, op):
        if self.signed:
            return self.INV_SCMP_OP[op.lexeme]
        return self.INV_UCMP_OP.get(op.lexeme, self.INV_SCMP_OP[op.lexeme])
    def __eq__(self, other):
        return isinstance(other, Bin)

class Char(Bin):
    def __init__(self, signed=True):
        super().__init__(signed)
        self.size = self.width = Size.BYTE
    def __str__(self):
        return 'char'

class Short(Bin):
    def __init__(self, signed=True):
        super().__init__(signed)
        self.size = self.width = Size.HALF
    def __str__(self):
        return 'short'

class Int(Bin):
    def __init__(self, signed=True):
        super().__init__(signed)
        self.size = self.width = Size.WORD
    def __str__(self):
        return 'int'

class Float(Bin):
    BINARY_OP = {
        '+':Op.ADDF,
        '+=':Op.ADDF,
        '++':Op.ADDF,
        '-':Op.SUBF,
        '-=':Op.SUBF,
        '--':Op.SUBF,
        '*':Op.MULF,
        '*=':Op.MULF,
        '/': Op.DIVF,
        '/=':Op.DIVF,
        '<<':Op.SHL,
        '<<=':Op.SHL,
        '>>':Op.SHR,
        '>>=':Op.SHR,
        '^':Op.XOR,
        '^=':Op.XOR,
        '|' :Op.OR,
        '|=':Op.OR,
        '&':Op.AND,
        '&=':Op.AND
    }
    UNARY_OP = {
        '++':Op.ADDF,
        '--':Op.SUBF,
        '-':Op.NEGF,
        '~':Op.NOT
    }
    CMP = Op.CMPF
    def __init__(self):
        super().__init__(True)
        self.size = self.width = Size.WORD
    def convert(self, emitter, n, other): #TODO test
        other.itf(emitter, n)
    def fti(self, emitter, n):
        emitter.binary(Op.FTI, Size.WORD, Reg(n), Reg(n))
    def itf(self, emitter, n):
        pass
    def reduce_pre(self, emitter, n, op):
        emitter.imm(Reg(n+1), itf(1))
        emitter.binary(op, self.width, Reg(n), Reg(n+1))
    def reduce_post(self, emitter, n, op):
        emitter.imm(Reg(n+2), itf(1))
        emitter.ternary(op, self.width, Reg(n+1), Reg(n), Reg(n+2))
    def reduce_binary(self, emitter, n, op, left, right):
        emitter.binary(op, self.width, left.reduce_float(emitter, n), right.reduce_float(emitter, n+1))
    def reduce_compare(self, emitter, n, left, right):
        emitter.binary(Op.CMPF, self.width, left.reduce_float(emitter, n), right.reduce_float(emitter, n+1))
    def __eq__(self, other):
        return isinstance(other, (Float,Bin))
    def __str__(self):
        return 'float'

class Pointer(Int):
    def __init__(self, ctype):
        super().__init__(False)
        self.to = self.of = ctype
        self.inc = int(self.to.size)
    def reduce_binary(self, emitter, n, op, left, right):
        if self.to.size > 1:
            left.reduce(emitter, n)
            right.reduce(emitter, n+1)
            emitter.binary(Op.MUL, Size.WORD, Reg(n+1), int(self.to.size))
            emitter.binary(op, Size.WORD, Reg(n), Reg(n+1))
        else:
            super().reduce_binary(emitter, n, op, left, right)
    def reduce_array(self, emitter, n, array):
        return array.reduce(emitter, n)
    def cast(self, other): #TODO test
        return isinstance(other, (Bin,Array))
    def __eq__(self, other):
        return isinstance(other, Pointer) and (self.to == other.to \
                                               or isinstance(self.to, Void) \
                                               or isinstance(other.to, Void)) \
            or isinstance(other, Array) and (self.of == other.of \
                                             or isinstance(self.to, Void)) \
            or isinstance(other, Func) and self.to == other
    def __str__(self):
        return f'ptr({self.to})'

class List(Value):
    def list_generate(self, emitter, n, right, loc):
        # can't be address
        emitter.ternary(Op.ADD, Size.WORD, Reg(n+1), Reg(n), loc)
        for i, (loc, ctype) in enumerate(self):
            ctype.list_generate(emitter, n+1, right[i], loc)
    def glob_data(self, emitter, expr, data):
        for i, (_, ctype) in enumerate(self):
            ctype.glob_data(emitter, expr[i], data)
        return data

class Struct(Frame, List):
    def __init__(self, name):
        super().__init__()
        self.const = False
        self.name = name.lexeme if name is not None else name
        self.width = Size.WORD
    def dot(self, name, struct, attr):
        return cexprs.Dot(name, struct, attr)
    def arrow(self, name, struct, attr):
        return cexprs.Arrow(name, struct, attr)
    def reduce(self, emitter, n, var, base):
        return self.address(emitter, n, var, base)
    def store(self, emitter, n, var, base):
        self.address(emitter, n+1, var, base)
        frame = {}
        for loc, ctype in self:
            if loc in frame:
                if ctype.size > frame[loc].size:
                    frame[loc] = ctype
            else:
                frame[loc] = ctype
        for loc, ctype in frame.items():
            if ctype.size in [Size.WORD, Size.BYTE, Size.HALF]:
                emitter.load(ctype.width, Reg(n+2), Reg(n), loc)
                emitter.store(ctype.width, Reg(n+2), Reg(n+1), loc)
            else:
                for i in range(ctype.size // Size.WORD):
                    emitter.load(Size.WORD, Reg(n+2), Reg(n), loc + Size.WORD*i)
                    emitter.store(Size.WORD, Reg(n+2), Reg(n+1), loc + Size.WORD*i)
                for j in range(ctype.size % Size.WORD):
                    emitter.load(Size.BYTE, Reg(n+2), Reg(n), loc + Size.WORD*(i+1)+j)
                    emitter.store(Size.BYTE, Reg(n+2), Reg(n+1), loc + Size.WORD*(i+1)+j)
    def __iter__(self):
        for attr in self.data.values():
            yield attr.offset, attr.type
    def __eq__(self, other):
        return isinstance(other, Struct) and self.name == other.name
    def __str__(self):
        return f'struct {self.name}'

class Array(List):
    def __init__(self, of, length):
        super().__init__()
        if length is None:
            self.length = length
        else:
            self.size = of.size * length.value
            self.length = length.value
        self.of = of
        self.width = Size.WORD
    def reduce_array(self, emitter, n, array):
        return array.address(emitter, n)
    def glob_reduce(self, emitter, n, glob):
        self.glob_address(emitter, n, glob)
    def __iter__(self):
        for i in range(self.length):
            yield i*self.of.size, self.of
    def reduce(self, emitter, n, var, base):
        return self.address(emitter, n, var, base)
    def __eq__(self, other): #TODO test
        return isinstance(other, (Array,Pointer)) and self.of == other.of
    def __str__(self):
        return f'array({self.of})'

class Union(UserDict, Value):
    def __init__(self, name):
        super().__init__()
        self.const = False
        self.size = 0
        self.width = Size.WORD
        self.name = name
    def arrow(self, name, postfix, attr):
        return cexprs.Deref(name, postfix.ptr_union(attr))
    def __setitem__(self, name, attr):
        attr.offset = 0
        self.size = max(self.size, attr.type.size)
        super().__setitem__(name, attr)

class Func(Value):
    def __init__(self, ret, params, variable):
        super().__init__()
        self.ret, self.params, self.variable = ret, params, variable
        self.size = 0
        self.width = Size.WORD
    def glob_reduce(self, emitter, n, glob):
        return self.glob_address(emitter, n, glob)
    def cast(self, other):
        return False
    def __eq__(self, other):
        return isinstance(other, Func) and self.ret == other.ret \
            and len(self.params) == len(other.params) \
                and self.variable == other.variable \
                    and all(param.type == other.params[i].type \
                            for i, param in enumerate(self.params))
    def __str__(self):
        return f'{self.ret} func('+','.join(map(str, (param.type for param in self.params)))+')'