# -*- coding: utf-8 -*-
"""
Created on Sat Sep  7 01:02:16 2024

@author: Colin
"""

from bit32 import Reg

class Visitor:
    def __init__(self):
        self.clear()
    def clear(self):
        self.max_reg = 0
        self.if_jump_end = []
    def begin_func(self, defn):
        self.return_label = None
    def begin_loop(self):
        pass
    def loop_head(self):
        pass
    def loop_tail(self):
        pass
    def end_loop(self):
        pass
    def next_label(self):
        pass
    def maximize(self, *regs):
        self.max_reg = max((self.max_reg, *(reg for reg in regs if isinstance(reg, Reg) and reg <= Reg.K)))
    def append_label(self, label):
        pass
    def string_ptr(self, string):
        pass
    def push(self, size, rs):
        pass
    def call(self, proc):
        self.maximize(proc)
    def load_glob(self, rd, name):
        self.maximize(rd)
    def load(self, size, rd, rb, offset=None, name=None):
        self.maximize(rd, rb, offset)
    def store(self, size, rd, rb, offset=None, name=None):
        self.maximize(rd, rb, offset)
    def imm(self, size, rd, value):
        self.maximize(rd)
    def unary(self, op, size, rd):
        self.maximize(rd)
    def binary(self, op, size, rd, src):
        self.maximize(rd, src)
    def ternary(self, op, size, rd, rs, src):
        self.maximize(rd, rs, src)
    def jump(self, cond, target):
        pass
    def mov(self, cond, rd, value):
        self.maximize(rd)

class Emitter(Visitor):
    def clear(self):
        self.n_labels = 0
        self.if_jump_end = []
        self.loop = []
        self.labels = []
        self.asm = []
        self.data = []
        self.strings = []
    def begin_func(self, defn):
        if defn.returns or defn.type.ret.width:
            self.return_label = self.next_label()
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
    def string_array(self, name, string):
        self.data.append(rf'{name}: "{string}\0"')
    def string_ptr(self, string):
        if string not in self.strings:
            self.strings.append(string)
            self.string_array(rf'.S{self.strings.index(string)}', string)
        return f'.S{self.strings.index(string)}'
    def add(self, asm):
        for label in self.labels:
            self.asm.append(f'{label}:')
        self.asm.append(f'  {asm}')
        self.labels.clear()
    def space(self, name, size):
        self.data.append(f'{name}: .space {size}')
    def glob(self, name, size, value):
        self.data.append(f'{name}: .{size.name.lower()} {value}')
    def datas(self, label, datas):
        self.data.append(f'{label}:')
        for size, data in datas:
            self.data.append(f'  .{size.name.lower()} {data}')
    def push(self, size, rs):
        self.add(f'PUSH{size.display()} {rs.name}') #TODO test
    def pushm(self, *regs):
        if regs:
            self.add('PUSH '+', '.join(reg.name for reg in regs))
    def popm(self, *regs):
        if regs:
            self.add('POP '+', '.join(reg.name for reg in regs))
    def call(self, proc):
        self.add(f'CALL {proc.name if isinstance(proc, Reg) else proc}')
    def ret(self):
        self.add('RET')
    def load_glob(self, rd, name):
        self.add(f'LDI {rd.name}, ={name}')
    def load(self, size, rd, rb, offset=None, name=None):
        self.add(f'LD{size.display()} {rd.name}, [{rb.name}'+(f', {offset}' if offset is not None else '')+']'+(f' ; {name}' if name else ''))
    def store(self, size, rd, rb, offset=None, name=None):
        self.add(f'ST{size.display()} [{rb.name}'+(f', {offset}' if offset is not None else '')+f'], {rd.name}'+(f' ; {name}' if name else ''))
    def imm(self, size, rd, value):
        self.add(f'LDI{size.display()} {rd.name}, {value}')
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