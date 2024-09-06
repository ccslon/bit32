
# -*- coding: utf-8 -*-
"""
Created on Mon Jul  3 19:48:36 2023

@author: Colin
"""
from collections import UserList, UserDict

from bit32 import Size, Reg, Op

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
    def list_store(self, vstr, n, expr, loc):
        expr.reduce(vstr, n+1)
        #expr.convert(...) #TODO
        vstr.store(self.size, regs[n+1], regs[n], loc)
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
        if other.type.is_float(): #isinstance(other.type, Float):
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
        self.name = name.lexeme
    def __iter__(self):
        for attr in self.data.values():
            yield attr.location, attr.type
    def list_store(self, vstr, n, right, loc):
        vstr.ternary(Op.ADD, Size.WORD, regs[n+1], regs[n], loc)
        for i, (loc, type) in enumerate(self):
            type.list_store(vstr, n+1, right[i], loc)
    @staticmethod
    def convert(vstr, reg, other):
        pass #TODO DELETE FUNC
    @staticmethod
    def store(vstr, n, local, base):
        Struct.address(vstr, n+1, local, base)
        for attr in local.type.values():
            vstr.load(attr.size, regs[n+2], regs[n], attr.location)
            vstr.store(attr.size, regs[n+2], regs[n+1], attr.location)
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
        self.length = length.value
    def __iter__(self):
        for i in range(self.length):
            yield i*self.of.size, self.of
    def list_store(self, vstr, n, right, loc):
        vstr.ternary(Op.ADD, Size.WORD, regs[n+1], regs[n], loc)
        for i, (loc, type) in enumerate(self):
            type.list_store(vstr, n+1, right[i], loc)
            
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
    @staticmethod
    def glob_reduce(vstr, n, glob):
        return Func.glob_address(vstr, n, glob)
    def cast(self, other):
        return False
    def __eq__(self, other):
        return isinstance(other, Func) and self.ret == other.ret #TODO
    def __str__(self):
        return f'{self.ret}('+','.join(map(str, self.params))+')'