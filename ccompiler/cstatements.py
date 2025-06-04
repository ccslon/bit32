# -*- coding: utf-8 -*-
"""
Created on Fri Sep  6 14:25:05 2024

@author: ccslon
"""
from collections import UserList
from bit32 import Op, Cond, Reg, Size, escape
from .cnodes import Statement, Expr, Binary
from .ctypes import Array

class If(Statement):
    def __init__(self, cond, state):
        self.cond, self.true, self.false = cond, state, None
    def generate(self, vstr, n):
        vstr.if_jump_end.append(False)
        label = vstr.next_label()
        sublabel = vstr.next_label() if self.false else label
        self.cond.compare(vstr, n*self.cond.soft_calls(), sublabel)
        self.true.generate(vstr, n)
        if self.false:
            if not self.true.last_is_return():
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
        self.cond.compare(vstr, n*self.cond.soft_calls(), sublabel)
        self.true.generate(vstr, n)
        if self.false:
            if not self.true.last_is_return():
                vstr.jump(Cond.AL, root)
                vstr.if_jump_end[-1] = True
            vstr.append_label(sublabel)
            self.false.branch(vstr, n, root)

class Case:
    def __init__(self, const, block):
        self.const, self.block = const, block

class Switch(Statement):
    def __init__(self, test):
        self.test, self.cases, self.default = test, [], None
    def generate(self, vstr, n):
        vstr.begin_loop()
        m = n*self.test.soft_calls()
        self.test.reduce(vstr, m)
        labels = []
        for case in self.cases:
            labels.append(vstr.next_label())
            vstr.binary(Op.CMP, self.test.width, Reg(m), case.const.reduce_num(vstr, m+1))
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
        self.cond.compare(vstr, n*self.cond.soft_calls(), vstr.loop_tail())
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
        self.cond.compare_inv(vstr, n*self.cond.soft_calls(), vstr.loop_head())
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
        self.cond.compare(vstr, n*self.cond.soft_calls(), vstr.loop_tail())
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
        vstr.jump(Cond.AL, self.target)

class Label(Statement):
    def __init__(self, name):
        self.name = name
    def generate(self, vstr, _):
        vstr.append_label(self.name)

class Return(Statement):
    def __init__(self, token, ret, expr):
        if expr is not None:
            if ret != expr.type:
                token.error(f'Return expression type {expr.type} != function return type {ret}')
            expr.width = ret.width
        self.ret, self.expr = ret, expr
    def last_is_return(self):
        return True
    def generate(self, vstr, n):
        if self.expr:
            self.expr.reduce(vstr, n)
            self.ret.convert(vstr, n, self.expr.type)
        vstr.jump(Cond.AL, vstr.return_label)

class Compound(UserList, Statement):
    def last_is_return(self):
        return self and self[-1].last_is_return()
    def generate(self, vstr, n):
        for statement in self:
            statement.generate(vstr, n)

class InitAssign(Binary, Statement):
    def __init__(self, token, left, right):
        super().__init__(left.type, token, left, right)
        if left.type != right.type:
            token.error(f'{left.type} != {right.type}')
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
        if left.type.const:
            token.error('Cannot assign to a const')

class InitListAssign(Statement):
    def __init__(self, token, left, right):
        if isinstance(left.type, Array):
            if left.type.length is None:  #TODO test
                left.type.length = len(right)
                left.type.size =  len(right) * left.type.of.size
            elif left.type.length < len(right):
                token.error('Not large enough')
        self.left, self.right = left, right
    def generate(self, vstr, n):
        self.left.address(vstr, n)
        for i, (loc, ctype) in enumerate(self.left.type):
            ctype.list_generate(vstr, n, self.right[i], loc)
    def glob_generate(self, vstr):
        vstr.datas(self.left.token.lexeme, self.left.type.glob_data(vstr, self.right, []))

class InitArrayString(Statement):
    def __init__(self, token, array, string):
        if array.type.length is None:
            array.type.size = array.type.length = len(string.value) + 1
        elif array.type.size < len(string.value) + 1:
            token.error('Not large enough')
        self.array = array
        self.string = string
    def generate(self, vstr, n):
        self.array.address(vstr, n)
        for i, c in enumerate(self.string.value+'\0'):
            vstr.binary(Op.MOV, Size.BYTE, Reg(n+1), f"'{escape(c)}'")
            vstr.store(Size.BYTE, Reg(n+1), Reg(n), i)
    def glob_generate(self, vstr):
        vstr.string_array(self.array.token.lexeme, self.string.token.lexeme)

class Call(Expr, Statement):
    def __init__(self, token, func, args):
        super().__init__(func.type.ret, token)
        if len(args) < len(func.type.params):
            token.error(f'Not enough arguments provided in function call "{func.token.lexeme}"')
        for i, param in enumerate(func.type.params):
            if param.type != args[i].type:
                token.error(f'Argument #{i+1} of "{func.token.lexeme}" {param.type} != {args[i].type}')
        self.func, self.args, self.params = func, args, func.type.params
    def hard_calls(self):
        return True
    def soft_calls(self):
        return self.func.hard_calls() or any(arg.hard_calls() for arg in self.args)
    def reduce_args(self, vstr, n):
        for i, arg in enumerate(self.args):
            arg.reduce(vstr, n+i)
            self.params[i].type.convert(vstr, n+i, arg.type)
        if n > 0:
            for i, arg in enumerate(self.args[:4]):
                vstr.binary(Op.MOV, arg.width, Reg(i), Reg(n+i))
        for i, arg in reversed(list(enumerate(self.args[4:]))): #TODO test thsi branch
            vstr.push(arg.width, Reg(n+4+i))
    def reduce(self, vstr, n):
        self.reduce_args(vstr, n)
        self.func.call(vstr, n if n else min(4, len(self.args)))
        if n > 0 and self.width:
            vstr.binary(Op.MOV, Size.WORD, Reg(n), Reg.A)
        return Reg(n)
    def generate(self, vstr, n):
        self.reduce_args(vstr, n*self.soft_calls())
        self.func.call(vstr, n)

class VarCall(Call):
    def reduce_args(self, vstr, n):
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
        self.reduce_args(vstr, n)
        self.func.call(vstr, n if n else min(4, len(self.args)))
        self.adjust_stack(vstr)
        if n > 0 and self.width:
            vstr.binary(Op.MOV, Size.WORD, Reg(n), Reg.A)
        return Reg(n)
    def generate(self, vstr, n):
        self.reduce_args(vstr, n*self.soft_calls())
        self.func.call(vstr, n)
        self.adjust_stack(vstr)

