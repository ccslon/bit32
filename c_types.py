# -*- coding: utf-8 -*-
"""
Created on Fri Sep  6 14:05:50 2024

@author: ccslon
"""
from collections import UserDict
from bit32 import Op, Size
from c_utils import CNode, regs, Frame

class Void(CNode):
    def __init__(self):
        self.size = self.width = 0
    def __eq__(self, other):
        return isinstance(other, Void)
    def __str__(self):
        return 'void'

class Type(CNode):
    def __init__(self):
        self.const = False
        self.inc = 1
    def list_store(self, vstr, n, expr, loc):
        expr.reduce(vstr, n+1)
        #expr.convert(...) #TODO
        vstr.store(self.width, regs[n+1], regs[n], loc)
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
        vstr.store(local.width, regs[n], regs[base], local.location, local.token.lexeme)
        return regs[n]
    @staticmethod
    def glob_store(vstr, n, glob):
        vstr.load_glob(regs[n+1], glob.token.lexeme)
        vstr.store(glob.width, regs[n], regs[n+1])
        return regs[n]
    @staticmethod
    def reduce(vstr, n, local, base):
        vstr.load(local.width, regs[n], regs[base], local.location, local.token.lexeme)
        return regs[n]
    @staticmethod
    def glob_reduce(vstr, reg, glob):
        vstr.load_glob(regs[reg], glob.token.lexeme)
        vstr.load(glob.width, regs[reg], regs[reg])
        return regs[reg]
    def as_data(self, vstr, expr, frame):
        frame.append((self.width, expr.data(vstr)))
    @staticmethod
    def glob(vstr, glob):
        if glob.init:
            vstr.glob(glob.token.lexeme, glob.width, glob.init.data(vstr))
        else:
            vstr.space(glob.token.lexeme, glob.width)

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
        if other.type.is_float(): #isinstance(other.type, Float):
            vstr.binary(Op.FTI, Size.WORD, regs[reg], regs[reg])
    def cast(self, other):
        return #TODO
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
        
class Float(Type):
    def __init__(self):
        super().__init__()
        self.size = self.width = Size.WORD
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
    def glob_call(self, vstr, n, glob):
        self.glob_reduce(vstr, n, glob)
        vstr.call(regs[n])
    def call(self, vstr, n, local, base):
        self.reduce(vstr, n, local, base)
        vstr.call(regs[n])
    def cast(self, other):
        return isinstance(other, Int)
    def __eq__(self, other):
        return isinstance(other, Pointer) and (self.to == other.to \
                                               or isinstance(self.to, Void) \
                                               or isinstance(other.to, Void)) \
            or isinstance(other, Array) and self.of == other.of
    def __str__(self):
        return f'ptr({self.to})'

class Struct(Frame, Type):
    def __init__(self, name):
        super().__init__()
        self.const = False
        self.name = name.lexeme
        self.width = Size.WORD
    def __iter__(self):
        for attr in self.data.values():
            yield attr.location, attr.type
    def list_store(self, vstr, n, right, loc):
        vstr.ternary(Op.ADD, Size.WORD, regs[n+1], regs[n], loc)
        for i, (loc, type) in enumerate(self):
            type.list_store(vstr, n+1, right[i], loc)
    def as_data(self, vstr, expr, frame):
        for i, (_, type) in enumerate(self):
            type.as_data(vstr, expr[i], frame)        
        return frame
    @staticmethod
    def convert(vstr, reg, other):
        pass #TODO DELETE FUNC
    @staticmethod
    def store(vstr, n, local, base):
        Struct.address(vstr, n+1, local, base)
        for loc, type in local.type:
            vstr.load(type.width, regs[n+2], regs[n], loc)
            vstr.store(type.width, regs[n+2], regs[n+1], loc)
    @staticmethod
    def reduce(vstr, n, local, base):
        return Struct.address(vstr, n, local, base)
    @staticmethod
    def glob(vstr, glob):
        if glob.init:
            vstr.datas(glob.token.lexeme, glob.type.as_data(vstr, glob.init, []))
        else:
            vstr.space(glob.token.lexeme, glob.type.size)
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
        self.width = Size.WORD
        self.name = name
    def __setitem__(self, name, attr):
        attr.location = 0
        self.size = max(self.size, attr.type.size)
        super().__setitem__(name, attr)

class Array(Type):
    def __init__(self, of, length):
        super().__init__()
        if length is None:
            self.length = length
        else:            
            self.size = of.size * length.value
            self.length = length.value
        self.of = of        
        self.width = Size.WORD
    def __iter__(self):
        for i in range(self.length):
            yield i*self.of.size, self.of
    def list_store(self, vstr, n, right, loc):
        vstr.ternary(Op.ADD, Size.WORD, regs[n+1], regs[n], loc)
        for i, (loc, type) in enumerate(self):
            type.list_store(vstr, n+1, right[i], loc)
    def as_data(self, vstr, expr, frame):
        for i, (_, type) in enumerate(self):
            type.as_data(vstr, expr[i], frame)        
        return frame
    @staticmethod
    def glob_reduce(vstr, n, glob):
        Type.glob_address(vstr, n, glob)
    @staticmethod
    def reduce(vstr, n, local, base):
        return Array.address(vstr, n, local, base)
    @staticmethod
    def glob(vstr, glob):
        if glob.init:
            vstr.datas(glob.token.lexeme, glob.type.as_data(vstr, glob.init, []))
        else:
            vstr.space(glob.token.lexeme, glob.type.size)
    def cast(self, other):
        return self == other
    def __eq__(self, other):
        return isinstance(other, (Array,Pointer)) and self.of == other.of
    def __str__(self):
        return f'array({self.of})'

class Func(Type):
    def __init__(self, ret, params, variable):
        self.ret, self.params, self.variable = ret, params, variable
        self.size = 0
        self.width = ret.width
    @staticmethod
    def glob_reduce(vstr, n, glob):
        return Func.glob_address(vstr, n, glob)
    def glob_call(self, vstr, n, glob):
        vstr.call(glob.token.lexeme)
    def call(self, vstr, n, local, _):
        vstr.call(local.token.lexeme)
    def cast(self, other):
        return False
    def __eq__(self, other):
        return isinstance(other, Func) and self.ret == other.ret #TODO
    def __str__(self):
        return f'{self.ret}('+','.join(map(str, self.params))+')'