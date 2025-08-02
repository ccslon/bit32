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
    def generate(self, emitter, n):
        emitter.if_jump_end.append(False)
        label = emitter.next_label()
        sublabel = emitter.next_label() if self.false else label
        self.cond.compare(emitter, n*self.cond.soft_calls(), sublabel)
        self.true.generate(emitter, n)
        if self.false:
            if not self.true.last_is_return():
                emitter.jump(Cond.AL, label)
                emitter.if_jump_end[-1] = True
            emitter.append_label(sublabel)
            self.false.branch(emitter, n, label)
            if emitter.if_jump_end[-1]:
                emitter.append_label(label)
        else:
            emitter.append_label(label)
        emitter.if_jump_end.pop()
    def branch(self, emitter, n, root):
        sublabel = emitter.next_label() if self.false else root
        self.cond.compare(emitter, n*self.cond.soft_calls(), sublabel)
        self.true.generate(emitter, n)
        if self.false:
            if not self.true.last_is_return():
                emitter.jump(Cond.AL, root)
                emitter.if_jump_end[-1] = True
            emitter.append_label(sublabel)
            self.false.branch(emitter, n, root)

class Case:
    def __init__(self, const, block):
        self.const, self.block = const, block

class Switch(Statement):
    def __init__(self, test):
        self.test, self.cases, self.default = test, [], None
    def generate(self, emitter, n):
        emitter.begin_loop()
        m = n*self.test.soft_calls()
        self.test.reduce(emitter, m)
        labels = []
        min_case = min(case.const.value for case in self.cases)
        cases = sorted(case.const.value - min_case for case in self.cases)
        '''
        It takes 8 clock cycles for the O(1) method. It takes 8 clock cycles
        for the regular method for 4 cases. Therefore, O(1) method is only
        considered if there are more than 4 cases
        '''
        if len(cases) > 4 and len(cases) / cases[-1] > 0.5:
            table = emitter.next_label()
            jumps = {case:emitter.next_label() for case in cases}            
            default = emitter.next_label()
            emitter.datas(table, [(Size.WORD, jumps.get(c, default)) for c in range(cases[-1] + 1)])            
            emitter.binary(Op.SUB, self.test.width, Reg(m), min(self.cases, key=lambda c: c.const.value).const.data(emitter))
            emitter.binary(Op.CMP, self.test.width, Reg(m), max(self.cases, key=lambda c: c.const.value).const.data(emitter))
            emitter.jump(Cond.HI, default)
            emitter.load_glob(Reg(m+1), table)
            emitter.binary(Op.SHL, Size.WORD, Reg(m), 2)
            emitter.load(Size.WORD, Reg(m), Reg(m+1), Reg(m))
            emitter.jump(Cond.AL, Reg(m))
            for case in self.cases:
                emitter.append_label(jumps[case.const.value - min_case])
                case.block.generate(emitter, n)
            emitter.append_label(default)
            if self.default:
                self.default.generate(emitter, n)
        else:    
            labels = []
            for case in self.cases:
                labels.append(emitter.next_label())
                emitter.binary(Op.CMP, self.test.width, Reg(m), case.const.reduce_num(emitter, m+1))
                emitter.jump(Cond.EQ, labels[-1])
            if self.default:
                default = emitter.next_label()
                emitter.jump(Cond.AL, default)
            else:
                emitter.jump(Cond.AL, emitter.loop_tail())
            for i, case in enumerate(self.cases):
                emitter.append_label(labels[i])
                case.block.generate(emitter, n)
            if self.default:
                emitter.append_label(default)
                self.default.generate(emitter, n)
        emitter.append_label(emitter.loop_tail())
        emitter.end_loop()

class While(Statement):
    def __init__(self, cond, state):
        self.cond, self.state = cond, state
    def generate(self, emitter, n):
        emitter.begin_loop()
        emitter.append_label(emitter.loop_head())
        self.cond.compare(emitter, n*self.cond.soft_calls(), emitter.loop_tail())
        self.state.generate(emitter, n)
        emitter.jump(Cond.AL, emitter.loop_head())
        emitter.append_label(emitter.loop_tail())
        emitter.end_loop()

class Do(Statement):
    def __init__(self, state, cond):
        self.state, self.cond = state, cond
    def generate(self, emitter, n):
        emitter.begin_loop()
        emitter.append_label(emitter.loop_head())
        self.state.generate(emitter, n)
        self.cond.compare_inv(emitter, n*self.cond.soft_calls(), emitter.loop_head())
        emitter.append_label(emitter.loop_tail())
        emitter.end_loop()

class For(While):
    def __init__(self, inits, cond, steps, state):
        super().__init__(cond, state)
        self.inits, self.steps = inits, steps
    def generate(self, emitter, n):
        for init in self.inits:
            init.generate(emitter, n)
        loop = emitter.next_label()
        emitter.begin_loop()
        emitter.append_label(loop)
        self.cond.compare(emitter, n*self.cond.soft_calls(), emitter.loop_tail())
        self.state.generate(emitter, n)
        emitter.append_label(emitter.loop_head())
        for step in self.steps:
            step.generate(emitter, n)
        emitter.jump(Cond.AL, loop)
        emitter.append_label(emitter.loop_tail())
        emitter.end_loop()

class Continue(Statement):
    def generate(self, emitter, _):
        emitter.jump(Cond.AL, emitter.loop_head())

class Break(Statement):
    def generate(self, emitter, _):
        emitter.jump(Cond.AL, emitter.loop_tail())

class Goto(Statement):
    def __init__(self, target):
        self.target = target
    def generate(self, emitter, _):
        emitter.jump(Cond.AL, self.target)

class Label(Statement):
    def __init__(self, name):
        self.name = name
    def generate(self, emitter, _):
        emitter.append_label(self.name)

class Return(Statement):
    def __init__(self, token, ret, expr):
        if expr is not None:
            if ret != expr.type:
                token.error(f'Return expression type {expr.type} != function return type {ret}')
            expr.width = ret.width
        self.ret, self.expr = ret, expr
    def last_is_return(self):
        return True
    def generate(self, emitter, n):
        if self.expr:
            self.expr.reduce(emitter, n)
            self.ret.convert(emitter, n, self.expr.type)
        emitter.jump(Cond.AL, emitter.return_label)

class Compound(UserList, Statement):
    def last_is_return(self):
        return self and self[-1].last_is_return()
    def generate(self, emitter, n):
        for statement in self:
            statement.generate(emitter, n)

class InitAssign(Binary, Statement):
    def __init__(self, token, left, right):
        super().__init__(left.type, token, left, right)
        if left.type != right.type:
            token.error(f'{left.type} != {right.type}')
    def soft_calls(self):
        return self.left.hard_calls() or self.right.soft_calls()
    def reduce(self, emitter, n):
        self.right.reduce(emitter, n)
        self.type.convert(emitter, n, self.right.type)
        self.left.store(emitter, n)
        return Reg(n)
    def generate(self, emitter, n):
        self.reduce(emitter, n*self.soft_calls())
    def glob_generate(self, emitter):
        emitter.glob(self.left.token.lexeme, self.width, self.right.data(emitter))

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
    def generate(self, emitter, n):
        self.left.address(emitter, n)
        for i, (loc, ctype) in enumerate(self.left.type):
            ctype.list_generate(emitter, n, self.right[i], loc)
    def glob_generate(self, emitter):
        emitter.datas(self.left.token.lexeme, self.left.type.glob_data(emitter, self.right, []))

class InitArrayString(Statement):
    def __init__(self, token, array, string):
        if array.type.length is None:
            array.type.size = array.type.length = len(string.value) + 1
        elif array.type.size < len(string.value) + 1:
            token.error('Not large enough')
        self.array = array
        self.string = string
    def generate(self, emitter, n):
        self.array.address(emitter, n)
        for i, c in enumerate(self.string.value+'\0'):
            emitter.binary(Op.MOV, Size.BYTE, Reg(n+1), f"'{escape(c)}'")
            emitter.store(Size.BYTE, Reg(n+1), Reg(n), i)
    def glob_generate(self, emitter):
        emitter.string_array(self.array.token.lexeme, self.string.token.lexeme)

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
    def reduce_args(self, emitter, n):
        for i, arg in enumerate(self.args):
            arg.reduce(emitter, n+i)
            self.params[i].type.convert(emitter, n+i, arg.type)
        if n > 0:
            for i, arg in enumerate(self.args[:4]):
                emitter.binary(Op.MOV, arg.width, Reg(i), Reg(n+i))
        for i, arg in reversed(list(enumerate(self.args[4:]))): #TODO test thsi branch
            # emitter.push(arg.width, Reg(n+4+i))
            emitter.push([Reg(n+4+i)])
    def reduce(self, emitter, n):
        self.reduce_args(emitter, n)
        self.func.call(emitter, n if n else min(4, len(self.args)))
        if n > 0 and self.width:
            emitter.binary(Op.MOV, Size.WORD, Reg(n), Reg.A)
        return Reg(n)
    def generate(self, emitter, n):
        self.reduce_args(emitter, n*self.soft_calls())
        self.func.call(emitter, n)

class VarCall(Call):
    def reduce_args(self, emitter, n):
        for i, param in enumerate(self.params):
            self.args[i].reduce(emitter, n+i)
            param.type.convert(emitter, n+i, self.args[i].type)
        for i, arg in enumerate(self.args[len(self.params):]):
            arg.reduce(emitter, len(self.params)+n+i)
        if n > 0:
            for i, arg in enumerate(self.args[:4]):
                emitter.binary(Op.MOV, arg.width, Reg(i), Reg(n+i))
        for i, arg in reversed(list(enumerate(self.args[4:]))):
            emitter.push([Reg(n+4+i)]) #TODO test
    def adjust_stack(self, emitter):
        if len(self.args) > 4:
            emitter.binary(Op.ADD, Size.WORD, Reg.SP, len(self.args[4:]) * Size.WORD) #TODO test
    def reduce(self, emitter, n):
        self.reduce_args(emitter, n)
        self.func.call(emitter, n if n else min(4, len(self.args)))
        self.adjust_stack(emitter)
        if n > 0 and self.width:
            emitter.binary(Op.MOV, Size.WORD, Reg(n), Reg.A)
        return Reg(n)
    def generate(self, emitter, n):
        self.reduce_args(emitter, n*self.soft_calls())
        self.func.call(emitter, n)
        self.adjust_stack(emitter)

