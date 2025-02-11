# -*- coding: utf-8 -*-
"""
Created on Fri Sep  6 14:25:05 2024

@author: ccslon
"""
from bit32 import Op, Cond, Reg
from c_utils import CNode
from c_exprs import Block, Return

class Statement(CNode):
    pass

class If(Statement):
    def __init__(self, cond, state):
        self.cond, self.true, self.false = cond, state, None
    def generate(self, vstr, n):
        vstr.if_jump_end.append(False)
        label = vstr.next_label()
        sublabel = vstr.next_label() if self.false else label
        self.cond.compare(vstr, n, sublabel)
        self.true.generate(vstr, n)
        if self.false:
            if not (isinstance(self.true, Return) or (isinstance(self.true, Block) and self.true and isinstance(self.true[-1], Return))):
                vstr.jump(Cond.AL, label)
                vstr.if_jump_end[-1] = True
            vstr.append_label(sublabel)
            self.false.branch(vstr, n, label)
            if vstr.if_jump_end[-1]:
                vstr.append_label(label)
        else:
            vstr.append_label(label)
        vstr.if_jump_end.pop()
    def branch(self, vstr, n, root):
        sublabel = vstr.next_label() if self.false else root
        self.cond.compare(vstr, n, sublabel)
        self.true.generate(vstr, n)
        if self.false:
            if not (isinstance(self.true, Return) or (isinstance(self.true, Block) and self.true and isinstance(self.true[-1], Return))):
                vstr.jump(Cond.AL, root)
                vstr.if_jump_end[-1] = True
            vstr.append_label(sublabel)
            self.false.branch(vstr, n, root)

class Case(Statement):
    def __init__(self, const, block):
        self.const, self.block = const, block

class Switch(Statement):
    def __init__(self, test):
        self.test, self.cases, self.default = test, [], None
    def generate(self, vstr, n):
        vstr.begin_loop()
        self.test.reduce(vstr, n)
        labels = []
        for case in self.cases:
            labels.append(vstr.next_label())
            vstr.binary(Op.CMP, self.test.width, Reg(n), case.const.num_reduce(vstr, n+1))
            vstr.jump(Cond.EQ, labels[-1])
        if self.default:
            default = vstr.next_label()
            vstr.jump(Cond.AL, default)
        else:
            vstr.jump(Cond.AL, vstr.loop_tail())
        for i, case in enumerate(self.cases):
            vstr.append_label(labels[i])
            case.block.generate(vstr, n)
        if self.default:
            vstr.append_label(default)
            self.default.generate(vstr, n)
        vstr.append_label(vstr.loop_tail())
        vstr.end_loop()

class While(Statement):
    def __init__(self, cond, state):
        self.cond, self.state = cond, state
    def generate(self, vstr, n):
        vstr.begin_loop()
        vstr.append_label(vstr.loop_head())
        self.cond.compare(vstr, n, vstr.loop_tail())
        self.state.generate(vstr, n)
        vstr.jump(Cond.AL, vstr.loop_head())
        vstr.append_label(vstr.loop_tail())
        vstr.end_loop()

class Do(Statement):
    def __init__(self, state, cond):
        self.state, self.cond = state, cond
    def generate(self, vstr, n):
        vstr.begin_loop()
        vstr.append_label(vstr.loop_head())
        self.state.generate(vstr, n)
        self.cond.compare_inv(vstr, n, vstr.loop_head())
        vstr.append_label(vstr.loop_tail())
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
        vstr.append_label(loop)
        self.cond.compare(vstr, n, vstr.loop_tail())
        self.state.generate(vstr, n)
        vstr.append_label(vstr.loop_head())
        for step in self.steps:
            step.generate(vstr, n)
        vstr.jump(Cond.AL, loop)
        vstr.append_label(vstr.loop_tail())
        vstr.end_loop()

class Continue(Statement):
    def generate(self, vstr, _):
        vstr.jump(Cond.AL, vstr.loop_head())

class Break(Statement):
    def generate(self, vstr, _):
        vstr.jump(Cond.AL, vstr.loop_tail())

class Goto(Statement):
    def __init__(self, target):
        self.target = target
    def generate(self, vstr, _):
        vstr.jump(Cond.AL, self.target.lexeme)

class Label(Statement):
    def __init__(self, label):
        self.label = label
    def generate(self, vstr, _):
        vstr.append_label(self.label.lexeme)