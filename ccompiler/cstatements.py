# -*- coding: utf-8 -*-
"""
Created on Fri Sep  6 14:25:05 2024

@author: ccslon
"""
from collections import UserList
from bit32 import Op, Cond, Reg, Size, escape
from .cnodes import Statement, Expression, Variable, Binary
from .ctypes import Array


class If(Statement):
    """Class for if statements."""

    def __init__(self, test, true):
        self.test = test
        self.true = true
        self.false = None

    def generate(self, emitter, n):
        """Generate code for if statement."""
        emitter.if_jump_end.append(False)
        label = emitter.next_label()
        sublabel = emitter.next_label() if self.false else label
        if self.test.is_constant():
            if not self.test.evaluate():
                emitter.emit_jump(Cond.AL, sublabel)
        else:
            self.test.compare(emitter, n*self.test.soft_calls(), sublabel)
        self.true.generate(emitter, n)
        if self.false:
            if not self.true.last_is_return():
                emitter.emit_jump(Cond.AL, label)
                emitter.if_jump_end[-1] = True
            emitter.append_label(sublabel)
            self.false.branch(emitter, n, label)
            if emitter.if_jump_end[-1]:
                emitter.append_label(label)
        else:
            emitter.append_label(label)
        emitter.if_jump_end.pop()

    def branch(self, emitter, n, root):
        """Generate code for else statement."""
        sublabel = emitter.next_label() if self.false else root
        if self.test.is_constant():
            if not self.test.evaluate():
                emitter.emit_jump(Cond.AL, sublabel)
        else:
            self.test.compare(emitter, n*self.test.soft_calls(), sublabel)
        self.true.generate(emitter, n)
        if self.false:
            if not self.true.last_is_return():
                emitter.emit_jump(Cond.AL, root)
                emitter.if_jump_end[-1] = True
            emitter.append_label(sublabel)
            self.false.branch(emitter, n, root)


class Case:
    """Class for a single case in a switch statement."""

    def __init__(self, constant, statement):
        self.constant = constant
        self.statement = statement


class Switch(Statement):
    """Class for switch statements."""

    def __init__(self, test):
        self.test = test
        self.cases = []
        self.default = None

    def generate(self, emitter, n):
        """Generate code for switch statement."""
        emitter.begin_loop()
        m = n*self.test.soft_calls()
        self.test.reduce(emitter, m)
        labels = []
        min_case = min(case.constant.value for case in self.cases)
        cases = sorted(case.constant.value - min_case for case in self.cases)
        '''
        It takes 8 clock cycles for the O(1) method. It takes 9 clock cycles
        for the regular method for 4 cases. Therefore, O(1) method is only
        considered if there are more than 3 cases
        '''
        if len(cases) > 3 and cases[-1] <= 64 and len(cases) / cases[-1] > 0.5:
            table = emitter.next_label()
            jumps = {case: emitter.next_label() for case in cases}
            default = emitter.next_label()
            emitter.emit_datas(table, [(Size.WORD, jumps.get(c, default)) for c in range(cases[-1] + 1)])
            emitter.emit_binary(Op.SUB, self.test.width, Reg(m), min(self.cases, key=lambda c: c.constant.value).constant.data(emitter))
            emitter.emit_binary(Op.CMP, self.test.width, Reg(m), cases[-1])
            emitter.emit_jump(Cond.HI, default)
            emitter.emit_load_global(Reg(m+1), table)
            emitter.emit_binary(Op.SHL, Size.WORD, Reg(m), 2)
            emitter.emit_load(Size.WORD, Reg(m), Reg(m+1), Reg(m))
            emitter.emit_jump(Cond.AL, Reg(m))
            for case in self.cases:
                emitter.append_label(jumps[case.constant.value - min_case])
                case.statement.generate(emitter, n)
            emitter.append_label(default)
            if self.default:
                self.default.generate(emitter, n)
        else:
            labels = []
            for case in self.cases:
                labels.append(emitter.next_label())
                emitter.emit_binary(Op.CMP, self.test.width, Reg(m), case.constant.reduce_number(emitter, m+1))
                emitter.emit_jump(Cond.EQ, labels[-1])
            if self.default:
                default = emitter.next_label()
                emitter.emit_jump(Cond.AL, default)
            else:
                emitter.emit_jump(Cond.AL, emitter.loop_tail())
            for i, case in enumerate(self.cases):
                emitter.append_label(labels[i])
                case.statement.generate(emitter, n)
            if self.default:
                emitter.append_label(default)
                self.default.generate(emitter, n)
        emitter.append_label(emitter.loop_tail())
        emitter.end_loop()


class While(Statement):
    """Class for while loops."""

    def __init__(self, test, statement):
        self.test = test
        self.statement = statement

    def generate(self, emitter, n):
        """Generate code for while loop."""
        emitter.begin_loop()
        emitter.append_label(emitter.loop_head())
        if self.test.is_constant() :
            if not self.test.evaluate():
                emitter.emit_jump(Cond.AL, emitter.loop_tail())
        else:
            self.test.compare(emitter, n*self.test.soft_calls(), emitter.loop_tail())
        self.statement.generate(emitter, n)
        emitter.emit_jump(Cond.AL, emitter.loop_head())
        emitter.append_label(emitter.loop_tail())
        emitter.end_loop()


class Do(Statement):
    """Class for do loops."""

    def __init__(self, statement, test):
        self.statement = statement
        self.test = test

    def generate(self, emitter, n):
        """Generate code for do loop."""
        emitter.begin_loop()
        emitter.append_label(emitter.loop_head())
        self.statement.generate(emitter, n)
        if self.test.is_constant():
            if self.test.evaluate():
                emitter.emit_jump(Cond.AL, emitter.loop_head())
        else:
            self.test.inverse_compare(emitter, n*self.test.soft_calls(), emitter.loop_head())
        emitter.append_label(emitter.loop_tail())
        emitter.end_loop()


class For(While):
    """Class for for loops."""

    def __init__(self, initials, test, steps, statement):
        super().__init__(test, statement)
        self.initials = initials
        self.steps = steps

    def generate(self, emitter, n):
        """Generate code for for loop."""
        for init in self.initials:
            init.generate(emitter, n)
        loop = emitter.next_label()
        emitter.begin_loop()
        emitter.append_label(loop)
        if self.test is not None:
            if self.test.is_constant():
                if not self.test.evaluate():
                    emitter.emit_jump(Cond.AL, emitter.loop_tail())
            else:
                self.test.compare(emitter, n*self.test.soft_calls(), emitter.loop_tail())
        self.statement.generate(emitter, n)
        emitter.append_label(emitter.loop_head())
        for step in self.steps:
            step.generate(emitter, n)
        emitter.emit_jump(Cond.AL, loop)
        emitter.append_label(emitter.loop_tail())
        emitter.end_loop()


class Continue(Statement):
    """Class for continue statements."""

    def generate(self, emitter, _):
        """Generate code for continue statement."""
        emitter.emit_jump(Cond.AL, emitter.loop_head())


class Break(Statement):
    """Class for break statements."""

    def generate(self, emitter, _):
        """Generate code for break statement."""
        emitter.emit_jump(Cond.AL, emitter.loop_tail())


class Goto(Statement):
    """Class for goto statements."""

    def __init__(self, target):
        self.target = target

    def generate(self, emitter, _):
        """Generate code for goto statement."""
        emitter.emit_jump(Cond.AL, self.target)


class Label(Statement):
    """Class for label statements."""

    def __init__(self, name):
        self.name = name

    def generate(self, emitter, _):
        """Generate code for label statement."""
        emitter.append_label(self.name)


class Return(Statement):
    """Class for return statements."""

    def __init__(self, token, ctype, value):
        if value is not None:
            if ctype != value.type:
                token.error(f'Return expression type {value.type} != function return type {ctype}')
            value.width = ctype.width
        self.type = ctype
        self.value = value

    def last_is_return(self):
        """Determine if the last statement in a function body is a return."""
        return True

    def generate(self, emitter, n):
        """Generate code return statement."""
        if self.value:
            if self.value.is_constant():
                self.value.fold().reduce(emitter, n)
            else:
                self.value.reduce(emitter, n)
                self.type.convert(emitter, n, self.value.type)
        emitter.emit_jump(Cond.AL, emitter.return_label)


class Compound(UserList, Statement):
    """Classs for compound statements."""

    def last_is_return(self):
        """Determine if the last statement in a function body is a return."""
        return self and self[-1].last_is_return()

    def generate(self, emitter, n):
        """Generate code for compound statements."""
        for statement in self:
            statement.generate(emitter, n)
            if isinstance(statement, (Return, Break, Continue)):  # Dead code elimination
                break


class InitialAssign(Binary, Statement):
    """Class for initial assignments."""

    def __init__(self, token, left, right):
        if left.type != right.type:
            token.error(f'{left.type} != {right.type}')
        super().__init__(left.type, left, right)

    def soft_calls(self):
        """Determine if initial assignment soft calls."""
        return self.left.hard_calls() or self.right.soft_calls()

    def reduce(self, emitter, n):
        """Generate code for initial assignment."""
        self.right.reduce(emitter, n)
        self.type.convert(emitter, n, self.right.type)
        self.left.store(emitter, n)
        return Reg(n)

    def generate(self, emitter, n):
        """Generate code for initial assignment."""
        self.reduce(emitter, n*self.soft_calls())

    def global_generate(self, emitter):
        """Generate initial assignment as global."""
        emitter.emit_global(self.left.token.lexeme, self.width, self.right.data(emitter))


class Assign(InitialAssign):
    """Class for assignments."""

    def __init__(self, token, left, right):
        if left.type.const:
            token.error('Cannot assign to a const')
        super().__init__(token, left, right)


class InitialListAssign(Statement):
    """Class for initial list assignments."""

    def __init__(self, token, left, right):
        if isinstance(left.type, Array):
            if left.type.length is None:  # TODO test
                left.type.length = len(right)
                left.type.size = len(right) * left.type.of.size
            elif left.type.length < len(right):
                token.error('Not large enough')
        self.left = left
        self.right = right

    def generate(self, emitter, n):
        """Generate code for initial list assignment."""
        self.left.address(emitter, n)
        for i, (loc, ctype) in enumerate(self.left.type):
            ctype.list_generate(emitter, n, self.right[i], loc)

    def global_generate(self, emitter):
        """Generate code for initial list assignment as a global."""
        emitter.emit_datas(self.left.token.lexeme, self.left.type.global_data(emitter, self.right, []))


class InitialStringArray(Statement):
    """Class for local string array assignments."""

    def __init__(self, token, array, string):
        if array.type.length is None:
            array.type.size = array.type.length = len(string.value) + 1
        elif array.type.size < len(string.value) + 1:
            token.error('Not large enough')
        self.array = array
        self.string = string

    def generate(self, emitter, n):
        """Generate code for local string array assignments."""
        self.array.address(emitter, n)
        for i, c in enumerate(self.string.value+'\0'):
            emitter.emit_binary(Op.MOV, Size.BYTE, Reg(n+1), f"'{escape(c)}'")
            emitter.emit_store(Size.BYTE, Reg(n+1), Reg(n), i)

    def global_generate(self, emitter):
        """Generate code for local string array assignments as a global."""
        emitter.emit_string_array(self.array.token.lexeme, self.string.token.lexeme)


class Call(Expression, Statement):
    """Class for function calls."""

    def __init__(self, token, function, arguments):
        if len(arguments) < len(function.type.parameters):
            token.error('Not enough arguments provided for function call'
                        + f' "{function.name()}"' if isinstance(function, Variable) else '')
        for i, param in enumerate(function.type.parameters):
            if param.type != arguments[i].type:
                token.error(f'Argument #{i+1} of "{function.token.lexeme}" {param.type} != {arguments[i].type}')
        super().__init__(function.type.return_type)
        self.function = function
        self.arguments = arguments
        self.parameters = function.type.parameters

    def hard_calls(self):
        """Determine if function calls "hard call" (they do)."""
        return True

    def soft_calls(self):
        """Determine if a funciton call "soft calls"."""
        return self.function.hard_calls() or any(arg.hard_calls() for arg in self.arguments)

    def reduce_arguments(self, emitter, n):
        """Generate code for arguments."""
        for i, arg in enumerate(self.arguments):
            arg.reduce(emitter, n+i)
            self.parameters[i].type.convert(emitter, n+i, arg.type)
        if n > 0:
            for i, arg in enumerate(self.arguments[:4]):
                emitter.emit_binary(Op.MOV, arg.width, Reg(i), Reg(n+i))
        for i, arg in reversed(list(enumerate(self.arguments[4:]))):  # TODO test thsi branch
            # emitter.push(arg.width, Reg(n+4+i))
            emitter.emit_push([Reg(n+4+i)])

    def reduce(self, emitter, n):
        """Generate code for function call (as an expression)."""
        self.reduce_arguments(emitter, n)
        self.function.call(emitter, n if n else min(4, len(self.arguments)))
        if n > 0 and self.width:
            emitter.emit_binary(Op.MOV, Size.WORD, Reg(n), Reg.A)
        return Reg(n)

    def generate(self, emitter, n):
        """Generate code for function call (as a statement)."""
        self.reduce_arguments(emitter, n*self.soft_calls())
        self.function.call(emitter, n)


class VariadicCall(Call):
    """Class for variadic function calls."""

    def reduce_arguments(self, emitter, n):
        """Generate code for arguments."""
        for i, param in enumerate(self.parameters):
            self.arguments[i].reduce(emitter, n+i)
            param.type.convert(emitter, n+i, self.arguments[i].type)
        for i, arg in enumerate(self.arguments[len(self.parameters):]):
            arg.reduce(emitter, len(self.parameters)+n+i)
        if n > 0:
            for i, arg in enumerate(self.arguments[:4]):
                emitter.emit_binary(Op.MOV, arg.width, Reg(i), Reg(n+i))
        for i, arg in reversed(list(enumerate(self.arguments[4:]))):
            emitter.emit_push([Reg(n+4+i)])  # TODO test

    def adjust_stack(self, emitter):
        """Remove remaining arguments from stack."""
        if len(self.arguments) > 4:
            emitter.emit_binary(Op.ADD, Size.WORD, Reg.SP, len(self.arguments[4:]) * Size.WORD)  # TODO test

    def reduce(self, emitter, n):
        """Generate code for variadic function call (as an expression)."""
        self.reduce_arguments(emitter, n)
        self.function.call(emitter, n if n else min(4, len(self.arguments)))
        self.adjust_stack(emitter)
        if n > 0 and self.width:
            emitter.emit_binary(Op.MOV, Size.WORD, Reg(n), Reg.A)
        return Reg(n)

    def generate(self, emitter, n):
        """Generate code for variadic function call (as a statement)."""
        self.reduce_arguments(emitter, n*self.soft_calls())
        self.function.call(emitter, n)
        self.adjust_stack(emitter)
