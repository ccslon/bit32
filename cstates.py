# -*- coding: utf-8 -*-
"""
Created on Fri Sep  6 14:25:05 2024

@author: ccslon
"""
from bit32 import Op, Cond
from cnodes import CNode, regs
from cexprs import Block, Return

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