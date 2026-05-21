# -*- coding: utf-8 -*-
"""
Created on Fri Sep  6 14:25:05 2024

@author: ccslon
"""
from collections import UserList
from bit32 import Op, Cond, Reg, Size, escape_chr
from .cnodes import Statement, Expression, Variable, Binary
from .ctypes import Array


class If(Statement):
    """Class for if statements."""

    def __init__(self, test, true):
        self.test = test
        self.true = true
        self.false = None

    def generate(self, emitter):
        """Generate code for if statement."""
        emitter.if_jump_end.append(False)
        label = emitter.next_label()
        sublabel = emitter.next_label() if self.false else label
        if self.test.is_constant():
            if not self.test.evaluate():
                emitter.emit_jump(Cond.AL, sublabel)
        else:
            self.test.compare(emitter, sublabel)
        self.true.generate(emitter)
        if self.false:
            if not self.true.last_is_return():
                emitter.emit_jump(Cond.AL, label)
                emitter.if_jump_end[-1] = True
            emitter.append_label(sublabel)
            self.false.branch(emitter, label)
            if emitter.if_jump_end[-1]:
                emitter.append_label(label)
        else:
            emitter.append_label(label)
        emitter.if_jump_end.pop()

    def branch(self, emitter, root):
        """Generate code for else statement."""
        sublabel = emitter.next_label() if self.false else root
        if self.test.is_constant():
            if not self.test.evaluate():
                emitter.emit_jump(Cond.AL, sublabel)
        else:
            self.test.compare(emitter, sublabel)
        self.true.generate(emitter)
        if self.false:
            if not self.true.last_is_return():
                emitter.emit_jump(Cond.AL, root)
                emitter.if_jump_end[-1] = True
            emitter.append_label(sublabel)
            self.false.branch(emitter, root)


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

    def generate(self, emitter):
        """Generate code for switch statement."""
        emitter.begin_loop()
        test = self.test.reduce(emitter)
        labels = []
        min_case = min(case.constant.value for case in self.cases)
        cases = sorted(case.constant.value - min_case for case in self.cases)
        '''
        It takes 7 clock cycles for the O(1) method. It takes 9 clock cycles
        for the regular method for 4 cases. Therefore, O(1) method is only
        considered if there are more than 3 cases
        '''
        if len(cases) > 3 and cases[-1] <= 64 and len(cases) / cases[-1] > 0.5:
            table = emitter.next_label()
            jumps = {case: emitter.next_label() for case in cases}
            default = emitter.next_label()
            emitter.emit_datas(table, [(Size.WORD, jumps.get(c, default)) for c in range(cases[-1] + 1)])
            sub = emitter.emit_binary(Op.SUB, self.test.width, test, min(self.cases, key=lambda c: c.constant.value).constant.data(emitter))
            emitter.emit_compare(Op.CMP, self.test.width, sub, cases[-1])
            emitter.emit_jump(Cond.HI, default)
            base = emitter.emit_load_global(table)
            scaled = emitter.emit_binary(Op.SHL, Size.WORD, sub, 2)
            emitter.emit_load(Size.WORD, Reg.PC, base, scaled)
            for case in self.cases:
                emitter.append_label(jumps[case.constant.value - min_case])
                case.statement.generate(emitter)
            emitter.append_label(default)
            if self.default:
                self.default.generate(emitter)
        else:
            labels = []
            for case in self.cases:
                labels.append(emitter.next_label())
                emitter.emit_compare(Op.CMP, self.test.width, test, case.constant.reduce_number(emitter))
                emitter.emit_jump(Cond.EQ, labels[-1])
            if self.default:
                default = emitter.next_label()
                emitter.emit_jump(Cond.AL, default)
            else:
                emitter.emit_jump(Cond.AL, emitter.loop_tail())
            for label, case in zip(labels, self.cases):
                emitter.append_label(label)
                case.statement.generate(emitter)
            if self.default:
                emitter.append_label(default)
                self.default.generate(emitter)
        emitter.append_label(emitter.loop_tail())
        emitter.end_loop()


class While(Statement):
    """Class for while loops."""

    def __init__(self, test, statement):
        self.test = test
        self.statement = statement

    def generate(self, emitter):
        """Generate code for while loop."""
        emitter.begin_loop()
        emitter.append_label(emitter.loop_head())
        if self.test.is_constant():
            if not self.test.evaluate():
                emitter.emit_jump(Cond.AL, emitter.loop_tail())
        else:
            self.test.compare(emitter, emitter.loop_tail())
        self.statement.generate(emitter)
        emitter.emit_jump(Cond.AL, emitter.loop_head())
        emitter.append_label(emitter.loop_tail())
        emitter.end_loop()


class Do(Statement):
    """Class for do loops."""

    def __init__(self, statement, test):
        self.statement = statement
        self.test = test

    def generate(self, emitter):
        """Generate code for do loop."""
        emitter.begin_loop()
        emitter.append_label(emitter.loop_head())
        self.statement.generate(emitter)
        if self.test.is_constant():
            if self.test.evaluate():
                emitter.emit_jump(Cond.AL, emitter.loop_head())
        else:
            self.test.inverse_compare(emitter, emitter.loop_head())
        emitter.append_label(emitter.loop_tail())
        emitter.end_loop()


class For(While):
    """Class for for loops."""

    def __init__(self, initials, test, steps, statement):
        super().__init__(test, statement)
        self.initials = initials
        self.steps = steps

    def generate(self, emitter):
        """Generate code for for loop."""
        if self.initials is not None:
            self.initials.generate(emitter)
        loop = emitter.next_label()
        emitter.begin_loop()
        emitter.append_label(loop)
        if self.test is not None:
            if self.test.is_constant():
                if not self.test.evaluate():
                    emitter.emit_jump(Cond.AL, emitter.loop_tail())
            else:
                self.test.compare(emitter, emitter.loop_tail())
        self.statement.generate(emitter)
        emitter.append_label(emitter.loop_head())
        if self.steps is not None:
            self.steps.generate(emitter)
        emitter.emit_jump(Cond.AL, loop)
        emitter.append_label(emitter.loop_tail())
        emitter.end_loop()


class Continue(Statement):
    """Class for continue statements."""

    def generate(self, emitter):
        """Generate code for continue statement."""
        emitter.emit_jump(Cond.AL, emitter.loop_head())


class Break(Statement):
    """Class for break statements."""

    def generate(self, emitter):
        """Generate code for break statement."""
        emitter.emit_jump(Cond.AL, emitter.loop_tail())


class Goto(Statement):
    """Class for goto statements."""

    def __init__(self, target):
        self.target = target

    def generate(self, emitter):
        """Generate code for goto statement."""
        emitter.emit_jump(Cond.AL, self.target)


class Label(Statement):
    """Class for label statements."""

    def __init__(self, name):
        self.name = name

    def generate(self, emitter):
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

    def generate(self, emitter):
        """Generate code return statement."""
        if self.value:
            if self.value.is_constant():
                target = self.value.fold().reduce(emitter)
            else:
                target = self.value.reduce(emitter)
                target = self.type.convert(emitter, target, self.value.type)
            emitter.emit_left_move(self.type.width, Reg.A, target)            
        emitter.emit_jump(Cond.AL, emitter.return_label)


class Compound(UserList, Statement):
    """Classs for compound statements."""

    def last_is_return(self):
        """Determine if the last statement in a function body is a return."""
        return self and self[-1].last_is_return()

    def generate(self, emitter):
        """Generate code for compound statements."""
        for statement in self:
            statement.generate(emitter)
            if isinstance(statement, (Return, Break, Continue)):  # Dead code elimination
                break


class InitAssignment(Binary, Statement):
    """Class for initial assignments."""

    def __init__(self, token, left, right):
        if left.type != right.type:
            token.error(f'{left.type} != {right.type}')
        super().__init__(left.type, left, right)

    def soft_calls(self):
        """Determine if initial assignment soft calls."""
        return self.left.hard_calls() or self.right.soft_calls()

    def reduce(self, emitter):
        """Generate code for initial assignment."""
        right = self.right.reduce(emitter)
        conv = self.type.convert(emitter, right, self.right.type)
        return self.left.store(emitter, conv)

    def generate(self, emitter):
        """Generate code for initial assignment."""
        self.reduce(emitter)

    def global_generate(self, emitter):
        """Generate initial assignment as global."""
        emitter.emit_global(self.left.name, self.width, self.right.data(emitter))


class Assignment(InitAssignment):
    """Class for assignments."""

    def __init__(self, token, left, right):
        if left.type.const:
            token.error('Cannot assign to a const')
        super().__init__(token, left, right)


class InitListAssignment(Statement):
    """Class for initial list assignments."""

    def __init__(self, token, left, right):
        if isinstance(left.type, Array):
            if left.type.length is None:  # TODO test
                left.type.length = len(right)
            elif left.type.length < len(right):
                token.error('Not large enough')
        self.left = left
        self.right = right

    def generate(self, emitter):
        """Generate code for initial list assignment."""
        base = self.left.address(emitter)
        # base = emitter.emit_binary(Op.ADD, Size.WORD, Reg.SP, self.left.offset)
        for (offset, ctype), element in zip(self.left.type, self.right):
            ctype.list_generate(emitter, element, base, offset)

    def global_generate(self, emitter):
        """Generate code for initial list assignment as a global."""
        emitter.emit_datas(self.left.name, self.left.type.global_data(emitter, self.right, []))


class InitStringArray(Statement):
    """Class for local string array assignments."""

    def __init__(self, token, array, string):
        if array.type.length is None:
            array.type.length = len(string.value) + 1
        elif array.type.length < len(string.value) + 1:
            token.error('Not large enough')
        self.array = array
        self.string = string

    def generate(self, emitter):
        """Generate code for local string array assignments."""
        base = self.array.address(emitter)
        emitter.emit_stack_string_array(f'{self.string.value}\0', base)

    def global_generate(self, emitter):
        """Generate code for local string array assignments as a global."""
        emitter.emit_string_array(self.array.name, self.string.value)


class Comma(Expression, Statement):
    """Class for comma operator."""

    def __init__(self, left, right):
        super().__init__(right.type)
        self.left = left
        self.right = right

    def is_constant(self):
        """Determine if the last node is constant."""
        return self.right.is_constant()

    def reduce(self, emitter):
        """Generate code for commas."""
        self.left.reduce(emitter)
        return self.right.reduce(emitter)

    def generate(self, emitter):
        """Generate code for commas."""
        self.left.generate(emitter)
        self.right.generate(emitter)


class Call(Expression, Statement):
    """Class for function calls."""

    def __init__(self, token, function, arguments):
        if len(arguments) < len(function.type.parameters):
            token.error('Not enough arguments provided for function call'
                        + f' "{function.name}"' if isinstance(function, Variable) else '')
        for i, (param, arg) in enumerate(zip(function.type.parameters, arguments)):
            if param.type != arg.type:
                token.error(f'Argument #{i+1} of "{function.token.lexeme}" {param.type} != {arg.type}')
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

    def reduce_arguments(self, emitter):
        """Generate code for arguments."""
        args = []
        for param, arg in zip(self.parameters, self.arguments):
            target = arg.reduce(emitter)
            conv = param.type.convert(emitter, target, arg.type)
            args.append(conv)
        self.move_arguments(emitter, args)

    def move_arguments(self, emitter, targets):
        """Move arguments into proper positions before calling."""
        for i, (target, arg) in enumerate(zip(targets[:4], self.arguments[:4])):
            emitter.emit_left_move(arg.width, Reg(i), target)
        for target in reversed(targets[4:]):
            emitter.emit_push([target])  # TODO test

    def reduce(self, emitter):
        """Generate code for function call (as an expression)."""
        self.reduce_arguments(emitter)
        self.function.call(emitter, len(self.arguments))
        return emitter.emit_right_move(Size.WORD, Reg.A)

    def generate(self, emitter):
        """Generate code for function call (as a statement)."""
        self.reduce_arguments(emitter)
        self.function.call(emitter, len(self.arguments))


class VariadicCall(Call):
    """Class for variadic function calls."""

    def reduce_arguments(self, emitter):
        """Generate code for arguments."""
        args = []
        for i, (param, arg) in enumerate(zip(self.parameters, self.arguments)):
            target = arg.reduce(emitter)
            conv = param.type.convert(emitter, target, arg.type)
            args.append(conv)
        for i, arg in enumerate(self.arguments[len(self.parameters):]):
            args.append(arg.reduce(emitter))
        self.move_arguments(emitter, args)

    def adjust_stack(self, emitter):
        """Remove remaining arguments from stack."""
        if len(self.arguments) > 4:
            emitter.emit_stack_deallocation(len(self.arguments[4:]) * Size.WORD)  # TODO test

    def reduce(self, emitter):
        """Generate code for variadic function call (as an expression)."""
        self.reduce_arguments(emitter)
        self.function.call(emitter, len(self.arguments))
        self.adjust_stack(emitter)
        return emitter.emit_right_move(Size.WORD, Reg.A)

    def generate(self, emitter):
        """Generate code for variadic function call (as a statement)."""
        self.reduce_arguments(emitter)
        self.function.call(emitter, len(self.arguments))
        self.adjust_stack(emitter)
