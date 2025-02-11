# -*- coding: utf-8 -*-
"""
Created on Fri Sep  6 14:05:50 2024

@author: ccslon
"""
from collections import UserDict
from bit32 import Op, Size, Reg
from c_utils import CNode, Frame

class Type(CNode):
    def is_float(self):
        return False
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
    def convert(self, vstr, n, other):
        pass
    def address(self, vstr, n, var, base):
        vstr.ternary(Op.ADD, Size.WORD, Reg(n), Reg(base), var.location)
        return Reg(n)
    def reduce(self, vstr, n, var, base):
        vstr.load(self.width, Reg(n), Reg(base), var.location, var.token.lexeme)
        return Reg(n)
    def store(self, vstr, n, var, base):
        vstr.store(self.width, Reg(n), Reg(base), var.location, var.token.lexeme)
        return Reg(n)
    def list_generate(self, vstr, n, expr, loc):
        expr.reduce(vstr, n+1)
        self.convert(vstr, n+1, expr.type)
        vstr.store(self.width, Reg(n+1), Reg(n), loc)
    def glob_address(self, vstr, n, glob):
        vstr.load_glob(Reg(n), glob.token.lexeme)
        return Reg(n)
    def glob_reduce(self, vstr, n, glob):
        self.glob_address(vstr, n, glob)
        vstr.load(self.width, Reg(n), Reg(n))
        return Reg(n)
    def glob_store(self, vstr, n, glob):
        vstr.load_glob(Reg(n+1), glob.token.lexeme)
        vstr.store(self.width, Reg(n), Reg(n+1))
        return Reg(n)
    def glob_data(self, vstr, expr, data):
        data.append((self.width, expr.data(vstr)))
    def glob_generate(self, vstr, glob):
        if glob.init:
            vstr.glob(glob.token.lexeme, self.width, glob.init.data(vstr))
        else:
            vstr.space(glob.token.lexeme, self.width)

class Bin(Value):
    def __init__(self, signed):
        super().__init__()
        self.signed = signed
    def is_signed(self):
        return self.signed
    def convert(self, vstr, n, other):
        if other.is_float():
            vstr.binary(Op.FTI, Size.WORD, Reg(n), Reg(n))
    def __eq__(self, other):
        return isinstance(other, (Bin,Float))

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

class Float(Value):
    def __init__(self):
        super().__init__()
        self.size = self.width = Size.WORD
    def is_float(self):
        return True
    def convert(self, vstr, n, other):
        if not other.is_float():
            vstr.binary(Op.ITF, Size.WORD, Reg(n), Reg(n))
    def __eq__(self, other):
        return isinstance(other, (Float,Bin))
    def __str__(self):
        return 'float'

class Pointer(Int):
    def __init__(self, type):
        super().__init__(False)
        self.to = self.of = type
        self.inc = self.to.size
    def call(self, vstr, n, var, base):
        self.reduce(vstr, n, var, base)
        vstr.call(Reg(n))
    def glob_call(self, vstr, n, glob):
        self.glob_reduce(vstr, n, glob)
        vstr.call(Reg(n))
    def cast(self, other):
        return isinstance(other, Bin) or isinstance(other, Array)
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
    def list_generate(self, vstr, n, right, loc):
        vstr.ternary(Op.ADD, Size.WORD, Reg(n+1), Reg(n), loc)
        for i, (loc, type) in enumerate(self):
            type.list_generate(vstr, n+1, right[i], loc)
    def glob_data(self, vstr, expr, data):
        for i, (_, type) in enumerate(self):
            type.glob_data(vstr, expr[i], data)
        return data
    def glob_generate(self, vstr, glob):
        if glob.init:
            vstr.datas(glob.token.lexeme, self.glob_data(vstr, glob.init, []))
        else:
            vstr.space(glob.token.lexeme, self.size)

class Struct(Frame, List):
    def __init__(self, name):
        super().__init__()
        self.const = False
        self.name = name.lexeme if name is not None else name
        self.width = Size.WORD
    def reduce(self, vstr, n, var, base):
        return self.address(vstr, n, var, base)
    def store(self, vstr, n, var, base):
        self.address(vstr, n+1, var, base)
        for loc, type in self:
            vstr.load(type.width, Reg(n+2), Reg(n), loc)
            vstr.store(type.width, Reg(n+2), Reg(n+1), loc)
    def __iter__(self):
        for attr in self.data.values():
            yield attr.location, attr.type
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
    def glob_reduce(self, vstr, n, glob):
        self.glob_address(vstr, n, glob)
    def __iter__(self):
        for i in range(self.length):
            yield i*self.of.size, self.of
    def reduce(self, vstr, n, var, base):
        return self.address(vstr, n, var, base)
    def __eq__(self, other):
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
    def __setitem__(self, name, attr):
        attr.location = 0
        self.size = max(self.size, attr.type.size)
        super().__setitem__(name, attr)

class Func(Value):
    def __init__(self, ret, params, variable):
        self.ret, self.params, self.variable = ret, params, variable
        self.size = 0
        self.width = Size.WORD
    def call(self, vstr, n, var, _):
        vstr.call(var.token.lexeme)
    def glob_reduce(self, vstr, n, glob):
        return self.glob_address(vstr, n, glob)
    def glob_call(self, vstr, n, glob):
        vstr.call(glob.token.lexeme)
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