# -*- coding: utf-8 -*-
"""
Created on Sat Sep  7 01:02:16 2024

@author: Colin
"""

from enum import Enum
from bit32 import Reg, Size, Op
import bit32

class Code(Enum):
    JUMP = 0
    UNARY = 1
    BINARY = 2
    TERNARY = 3
    LOAD = 4
    STORE = 5
    IMM = 6
    GLOB = 7
    CALL = 8
    RET = 9
    PUSH = 10
    POP = 11
    ADDR = 12
    CMOV = 13
    
'''
[x] add CMovs
[x] finish data portion
[x] implement peep hole optim
[x] string output
[x] vardefns
[x] array reduce = [A, B]
[x] test
[] refactor
[x] vstr -> emit
[x] jump to next
[] object output
[] const eval
[] real case?
'''

class Object:
    def __init__(self, labels):
        self.labels = labels
    def __str__(self):
        return ''.join(f'{label}:\n' for label in self.labels) + f'  {self.display()}'

class Data(Object):
    def __init__(self, labels, size, value):
        super().__init__(labels)
        self.size = size
        self.value = value
    def display(self):
        return f'.{self.size.name.lower()} {self.value}'

class String(Data):
    def __init__(self, name, string):
        super().__init__([name], Size.WORD, string)
    def __str__(self):
        return rf'{self.labels[0]}: "{self.value}\0"'

class Space(Object):
    def __init__(self, name, size):
        super().__init__([name])
        self.size = int(size)
    def __str__(self):
        return f'{self.labels[0]}: .space {self.size}'

class Glob(Data):
    def __init__(self, name, size, value):
        super().__init__([name], size, value)
    def __str__(self):
        return f'{self.labels[0]}: .{self.size.name.lower()} {self.value}'

class Instruction(Object):
    def __init__(self, labels, code):
        super().__init__(labels)
        self.code = code
        self.var = None
    def max_reg(self):
        return 0

class CMov(Instruction):
    def __init__(self, labels, cond, target, value):
        super().__init__(labels, Code.CMOV)
        self.cond = cond
        self.target = target
        self.value = value
    def display(self):
        return f'MOV{str(self.cond): <3} {self.target}, {self.value}'
    def serialize(self):
        return self.labels, bit32.Binary, (self.cond, False, Size.WORD, True, Op.MOV, self.value, self.target)

class Push(Instruction):
    def __init__(self, labels, push):
        super().__init__(labels, Code.PUSH)
        self.push = push
    def display(self):
        return f'PUSH   {", ".join(reg.name for reg in self.push)}'

class Pop(Instruction):
    def __init__(self, labels, pop):
        super().__init__(labels, Code.POP)
        self.pop = pop
    def display(self):
        return f'POP    {", ".join(reg.name for reg in self.pop)}'

class Jump(Instruction):
    def __init__(self, labels, cond, target):
        super().__init__(labels, Code.JUMP)
        self.cond = cond
        self.target = target
    def display(self):
        return f'J{self.cond.jump(): <5} {self.target}'
    def serialize(self):
        return self.labels, bit32.Jump, (self.cond, self.target)

class Call(Instruction):
    def __init__(self, labels, target):
        super().__init__(labels, Code.CALL)
        self.target = target
    def max_reg(self):
        if isinstance(self.target, Reg):
            return self.target
        return 0
    def display(self):
        return f'CALL   {self.target}'

class Unary(Instruction):
    def __init__(self, labels, op, size, target):
        super().__init__(labels, Code.UNARY)
        self.op = op
        self.size = size
        self.target = target
    def max_reg(self):
        return self.target
    def display(self):
        return f'{self.op.name+str(self.size): <6} {self.target}'

class Binary(Unary):
    def __init__(self, labels, op, size, target, source):
        super().__init__(labels, op, size, target)
        self.code = Code.BINARY
        self.source = source
    def max_reg(self):
        if isinstance(self.source, Reg):
            return max(Reg.max_reg(self.target), Reg.max_reg(self.source))
        return Reg.max_reg(self.target)
    def display(self):
        return f'{self.op.name+str(self.size): <6} {self.target}, {self.source}'

class Ternary(Binary):
    def __init__(self, labels, op, size, target, rs, source):
        super().__init__(labels, op, size, target, rs)
        self.code = Code.TERNARY
        self.source2 = source
    def max_reg(self):
        if isinstance(self.source2, Reg):
            return max(self.target, Reg.max_reg(self.source), self.source2)
        return max(self.target, Reg.max_reg(self.source))
    def display(self):
        return f'{self.op.name+str(self.size): <6} {self.target}, {self.source}, {self.source2}'

class Address(Instruction):
    def __init__(self, labels, op, target, base, offset, var=None):
        super().__init__(labels, Code.ADDR)
        self.op = op
        self.target = target
        self.base = base
        self.offset = offset
        self.var = var
    def max_reg(self):
        return max(self.target, Reg.max_reg(self.base))
    def display(self):
        return f'{self.op.name: <6} {self.target}, {self.base}, {self.offset} ; {self.var}'

class Load(Instruction):
    def __init__(self, labels, code, size, target, base, offset, var=None):
        super().__init__(labels, code)
        self.size = size
        self.target = target
        self.base = base
        self.offset = offset
        self.var = var
    def max_reg(self):
        if isinstance(self.offset, Reg):
            return max(self.target, Reg.max_reg(self.base), self.offset)
        return max(self.target, Reg.max_reg(self.base))
    def display(self):
        if self.code == Code.STORE:
            return 'ST{: <4} [{}{}], {}{}'.format(self.size,
                                                  self.base.name,
                                                  f', {self.offset}' if self.offset is not None else '',
                                                  self.target.name,
                                                  f' ; {self.var}' if self.var else '')
        return 'LD{: <4} {}, [{}{}]{}'.format(self.size,
                                              self.target.name,
                                              self.base.name,
                                              f', {self.offset}' if self.offset is not None else '',
                                              f' ; {self.var}' if self.var else '')
class LoadImm(Instruction):
    def __init__(self, labels, size, target, value):
        super().__init__(labels, Code.IMM)
        self.size = size
        self.target = target
        self.value = value
    def max_reg(self):
        return self.target
    def display(self):
        return f'LDI    {self.target}, {self.value}'

class LoadGlob(Instruction):
    def __init__(self, labels, target, name):
        super().__init__(labels, Code.GLOB)
        self.target = target
        self.name = name
    def max_reg(self):
        return self.target
    def display(self):
        return f'LDI    {self.target}, ={self.name}'

class Ret(Instruction):
    def __init__(self, labels):
        super().__init__(labels, Code.RET)
    def display(self):
        return 'RET'

class Emitter:
    def __init__(self):
        self.clear()
    def clear(self):
        self.n_labels = 0
        self.if_jump_end = []
        self.loop = []
        self.labels = []
        self.instructions = []
        self.data = []
        self.strings = []
    def begin_loop(self):
        self.loop.append((self.next_label(), self.next_label()))
    def loop_head(self):
        return self.loop[-1][0]
    def loop_tail(self):
        return self.loop[-1][1]
    def end_loop(self):
        self.loop.pop()
    def next_label(self):
        label = self.n_labels
        self.n_labels += 1
        return f'.L{label}'
    def append_label(self, label):
        self.labels.append(label)
    def add(self, inst):
        self.instructions.append(inst)
        self.labels = []

    def optimize_body(self):
        i = 0
        while i < len(self.instructions)-1:
            #peephole size = 2
            #get labels and code
            inst1 = self.instructions[i]
            inst2 = self.instructions[i+1]
            
            if inst1.code == Code.BINARY:
                if inst2.code == Code.BINARY:
                    if inst1.op == Op.MOV and inst1.target == inst2.source:
                        '''
                        MOV A, B
                        ADD C, A
                        = ADD C, B
                        '''
                        self.instructions[i:i+2] = [Binary(inst1.labels+inst2.labels,
                                                           inst2.op,
                                                           inst2.size,
                                                           inst2.target,
                                                           inst1.source)]
                        continue                                           
                    elif inst2.op == Op.MOV and inst1.target == inst2.source:
                        '''
                        ADD A, B
                        MOV C, A
                        = ADD C, A, B
                        '''
                        self.instructions[i:i+2] = [Ternary(inst1.labels+inst2.labels,
                                                            inst1.op,
                                                            inst1.size,
                                                            inst2.target,
                                                            inst1.target,
                                                            inst1.source)]
                        continue
                elif inst2.code == Code.TERNARY and inst1.op == Op.MOV:
                    '''
                    MOV A, B
                    ADD C, A, D
                    = ADD C, B, D
                    '''
                    if inst1.target == inst2.source:
                        self.instructions[i:i+2] = [Ternary(inst1.labels+inst2.labels,
                                                            inst2.op,
                                                            inst2.size,
                                                            inst2.target,
                                                            inst1.source,
                                                            inst2.source2)]
                        continue
                    elif inst1.target == inst2.source2:
                        '''
                        MOV A, B
                        ADD C, D, A
                        = ADD C, D, B
                        '''
                        self.instructions[i:i+2] = [Ternary(inst1.labels+inst2.labels,
                                                            inst2.op,
                                                            inst2.size,
                                                            inst2.target,
                                                            inst2.source,
                                                            inst1.source2)]
                        continue
            elif inst1.code == Code.TERNARY and inst2.code == Code.BINARY and inst2.op == Op.MOV and inst1.target == inst2.source:
                '''
                ADD A, B, C
                MOV D, A
                = ADD D, B, C
                '''
                self.instructions[i:i+2] = [Ternary(inst1.labels+inst2.labels,
                                                    inst1.op,
                                                    inst1.size,
                                                    inst2.target,
                                                    inst1.source,
                                                    inst1.source2)]
                continue                
            elif inst1.code == Code.ADDR:
                if inst2.code == Code.ADDR and inst1.target == inst2.base:
                    '''
                    ADD A, B, n
                    ADD C, A, m
                    = ADD C, B, n+m
                    '''
                    self.instructions[i:i+2] = [Address(inst1.labels+inst2.labels,
                                                        Op.ADD,
                                                        inst2.target,
                                                        inst1.base,
                                                        inst1.offset+inst2.offset,
                                                        inst1.var)]
                    continue
                elif inst2.code == Code.BINARY and inst1.target == inst2.target and isinstance(inst2.source, int):
                    self.instructions[i:i+2] = [Address(inst1.labels+inst2.labels,
                                                        Op.ADD,
                                                        inst1.target,
                                                        inst1.base,
                                                        inst1.offset+inst2.source,
                                                        inst1.var)]
                    continue
                    
                elif inst2.code in [Code.LOAD, Code.STORE] and inst1.target == inst2.base:
                    '''
                    ADD A, B, n
                    LD C, [A, m]
                    = LD C, [B, n+m]
                    '''
                    self.instructions[i:i+2] = [Load(inst1.labels+inst2.labels,
                                                     inst2.code,
                                                     inst2.size,
                                                     inst2.target,
                                                     inst1.base,
                                                     inst1.offset+inst2.offset,
                                                     inst1.var)]
                    continue
            i += 1

    def optimize(self):
        i = 0
        while i < len(self.instructions)-1:
            #peephole size = 2
            #get labels and code
            inst1 = self.instructions[i]
            inst2 = self.instructions[i+1]
            '''
            JMP .Ln
            .Ln: ...
            '''
            if inst1.code == Code.JUMP and inst1.target in inst2.labels:
                inst2.labels += inst1.labels
                del self.instructions[i]
                continue
            i += 1

    def begin_body(self, defn):
        if defn.returns or defn.type.ret.width:
            self.return_label = self.next_label()
        self.temp = self.instructions
        self.instructions = []

    def end_body(self):
        self.body = self.labels, self.instructions
        self.labels = []
        self.instructions = self.temp

    def add_body(self):
        labels, body = self.body
        if body:
            body[0].labels += self.labels
        self.instructions += body
        self.labels = labels

    def string_array(self, name, string):
        self.data.append(String(name, string))
        
    def string_ptr(self, string):
        if string not in self.strings:
            self.strings.append(string)
            self.string_array(f'.S{self.strings.index(string)}', string)
        return f'.S{self.strings.index(string)}'

    def space(self, name, size):
        self.data.append(Space(name, size))
    def glob(self, name, size, value):
        self.data.append(Glob(name, size, value))
        
    def datas(self, label, datas):
        size, data = datas[0]
        self.data.append(Data([label], size, data))        
        for size, data in datas[1:]:
            self.data.append(Data([], size, data))

    def push(self, regs):
        if regs:
            self.add(Push(self.labels, regs))
    def pop(self, regs):
        if regs:
            self.add(Pop(self.labels, regs))
    def call(self, proc):
        self.add(Call(self.labels, proc))
    def ret(self):
        self.add(Ret(self.labels))
    def load_glob(self, target, name):
        self.add(LoadGlob(self.labels, target, name))
    def attr(self, base, var):
        self.address(base, base, var.offset, var.name())        
    def address(self, target, base, offset, var=None):
        self.add(Address(self.labels, Op.ADD, target, base, offset, var))
    def load(self, size, target, base, offset=None, var=None):
        self.add(Load(self.labels, Code.LOAD, size, target, base, offset, var))
    def store(self, size, target, base, offset=None, var=None):
        self.add(Load(self.labels, Code.STORE, size, target, base, offset, var))
    def imm(self, size, target, value):
        self.add(LoadImm(self.labels, size, target, value))
    def unary(self, op, size, target):
        self.add(Unary(self.labels, op, size, target))
    def binary(self, op, size, target, source):
        self.add(Binary(self.labels, op, size, target, source))
    def ternary(self, op, size, target, rs, source):
        self.add(Ternary(self.labels, op, size, target, rs, source))
    def jump(self, cond, target):
        self.add(Jump(self.labels, cond, target))
    def mov(self, cond, target, value):
        self.add(CMov(self.labels, cond, target, value))
        
    def __str__(self):
        return '\n'.join(map(str, self.data+self.instructions))

