# -*- coding: utf-8 -*-
"""
Created on Sat Sep  7 01:02:16 2024

@author: Colin
"""

from enum import Enum
from bit32 import Reg, Size, Op

POWERS_OF_2 = {2**n: n for n in range(1, 8+1)}

JUST = 6  # justification


class Code(Enum):
    """Enum for code instruction types."""

    JUMP = 0
    UNARY = 1
    BINARY = 2
    TERNARY = 3
    LOAD = 4
    STORE = 5
    IMMEDIATE = 6
    GLOBAL = 7
    CALL = 8
    RET = 9
    PUSH = 10
    POP = 11
    ADDRESS = 12
    CMOV = 13  # "conditional move"


'''
[x] add CMovs
[x] finish data portion
[x] implement peep hole optim
[x] string output
[x] vardefns
[x] array reduce = [A, B]
[x] test
[x] refactor
[x] vstr -> emit
[x] jump to next
[] object output
[x] const eval
[x] real case?
'''


class Object:
    """Base class for bit32 objects."""

    def __init__(self, labels):
        self.labels = labels

    def __str__(self):
        """Get default string object representation."""
        return ''.join(f'{label}:\n' for label in self.labels) + f'  {self.display()}'


class Data(Object):
    """Base class for bit32 data objects."""

    def __init__(self, labels, size, value):
        super().__init__(labels)
        self.size = size
        self.value = value

    def display(self):
        """Display data as string."""
        return f'.{self.size.name.lower()} {self.value}'


class String(Data):
    """Class for String objects."""

    def __init__(self, name, string):
        super().__init__([name], Size.WORD, string)

    def __str__(self):
        """Get string representaion for string objects."""
        return rf'{self.labels[0]}: "{self.value}\0"'


class Space(Object):
    """Class for space allocation object."""

    def __init__(self, name, size):
        super().__init__([name])
        self.size = int(size)

    def __str__(self):
        """Get space string representation."""
        return f'{self.labels[0]}: .space {self.size}'


class Global(Data):
    """Class for global objects."""

    def __init__(self, name, size, value):
        super().__init__([name], size, value)

    def __str__(self):
        """Get global string representation."""
        return f'{self.labels[0]}: .{self.size.name.lower()} {self.value}'


class Instruction(Object):
    """Base class for bit32 instruction objects."""

    def __init__(self, labels, code):
        super().__init__(labels)
        self.code = code
        self.variable = None

    def max_used(self):
        """Find max register used by this instuction."""
        return 0


class CMov(Instruction):
    """Class for conditional move instruction objects."""

    def __init__(self, labels, condition, target, value):
        super().__init__(labels, Code.CMOV)
        self.condition = condition
        self.target = target
        self.value = value

    def display(self):
        """Display cmov instruction as string."""
        return f'{"MOV"+str(self.condition): <{JUST}} {self.target}, {self.value}'


class Push(Instruction):
    """Class for push instruction objects."""

    def __init__(self, labels, push):
        super().__init__(labels, Code.PUSH)
        self.push = push

    def display(self):
        """Display push instruction as string."""
        return f'{"PUSH": <{JUST}} {", ".join(reg.name for reg in self.push)}'


class Pop(Instruction):
    """Class for pop instruction objects."""

    def __init__(self, labels, pop):
        super().__init__(labels, Code.POP)
        self.pop = pop

    def display(self):
        """Display pop instruction as string."""
        return f'{"POP": <{JUST}} {", ".join(reg.name for reg in self.pop)}'


class Jump(Instruction):
    """Class for jump instructions objects."""

    def __init__(self, labels, condition, target):
        super().__init__(labels, Code.JUMP)
        self.condition = condition
        self.target = target

    def display(self):
        """Display jump instruction as string."""
        return f'{"J"+self.condition.jump(): <{JUST}} {self.target}'


class Call(Instruction):
    """Class for call instruction objects."""

    def __init__(self, labels, target):
        super().__init__(labels, Code.CALL)
        self.target = target

    def max_used(self):
        """Find max register used by this instuction."""
        if isinstance(self.target, Reg):
            return self.target
        return 0

    def display(self):
        """Display call instruction as string."""
        return f'{"CALL": <{JUST}} {self.target}'


class Unary(Instruction):
    """Class for unary ALU instruction objects."""

    def __init__(self, labels, op, size, target):
        super().__init__(labels, Code.UNARY)
        self.op = op
        self.size = size
        self.target = target

    def max_used(self):
        """Find max register used by this instuction."""
        return self.target

    def display(self):
        """Display unary instruction as string."""
        return f'{self.op.name+str(self.size): <{JUST}} {self.target}'


class Binary(Unary):
    """Class for binary ALU instruction objects."""

    def __init__(self, labels, op, size, target, source):
        super().__init__(labels, op, size, target)
        self.code = Code.BINARY
        self.source = source

    def max_used(self):
        """Find max register used by this instuction."""
        if isinstance(self.source, Reg):
            return max(Reg.max_reg(self.target), Reg.max_reg(self.source))
        return Reg.max_reg(self.target)

    def display(self):
        """Display binary instruction as string."""
        return f'{self.op.name+str(self.size): <{JUST}} {self.target}, {self.source}'


class Ternary(Binary):
    """Class for ternary ALU instruction objects."""

    def __init__(self, labels, op, size, target, rs, source):
        super().__init__(labels, op, size, target, rs)
        self.code = Code.TERNARY
        self.source2 = source

    def max_used(self):
        """Find max register used by this instuction."""
        if isinstance(self.source2, Reg):
            return max(self.target, Reg.max_reg(self.source), self.source2)
        return max(self.target, Reg.max_reg(self.source))

    def display(self):
        """Display ternary instruction as string."""
        return f'{self.op.name+str(self.size): <{JUST}} {self.target}, {self.source}, {self.source2}'


class Address(Instruction):
    """Class for address instruction objects."""

    def __init__(self, labels, target, base, offset, variable=None):
        super().__init__(labels, Code.ADDRESS)
        self.target = target
        self.base = base
        self.offset = offset
        self.variable = variable

    def max_used(self):
        """Find max register used by this instuction."""
        return max(self.target, Reg.max_reg(self.base))

    def display(self):
        """Display address instruction as string."""
        return f'{"ADD": <{JUST}} {self.target}, {self.base}, {self.offset} ; {self.variable}'


class Load(Instruction):
    """Class for load/store instruction objects."""

    def __init__(self, labels, code, size, target, base, offset, variable=None):
        super().__init__(labels, code)
        self.size = size
        self.target = target
        self.base = base
        self.offset = offset
        self.variable = variable

    def max_used(self):
        """Find max register used by this instuction."""
        if isinstance(self.offset, Reg):
            return max(self.target, Reg.max_reg(self.base), self.offset)
        return max(self.target, Reg.max_reg(self.base))

    def display(self):
        """Display load instruction as string."""
        if self.code is Code.STORE:
            return '{} [{}{}], {}{}'.format(f'{"ST"+str(self.size): <{JUST}}',
                                            self.base.name,
                                            f', {self.offset}' if self.offset is not None else '',
                                            self.target.name,
                                            f' ; {self.variable}' if self.variable else '')
        return '{} {}, [{}{}]{}'.format(f'{"LD"+str(self.size): <{JUST}}',
                                        self.target.name,
                                        self.base.name,
                                        f', {self.offset}' if self.offset is not None else '',
                                        f' ; {self.variable}' if self.variable else '')


class LoadImmediate(Instruction):
    """Class for load-immediate instruction objects."""

    def __init__(self, labels, target, value, comment):
        super().__init__(labels, Code.IMMEDIATE)
        self.target = target
        self.value = value
        self.comment = comment

    def max_used(self):
        """Find max register used by this instuction."""
        return self.target

    def display(self):
        """Display load-immediate instruction as string."""
        return '{} {}, {}{}'.format(f'{"LDI": <{JUST}}',
                                    self.target,
                                    self.value,
                                    f' ; {self.comment}' if self.comment is not None else '')


class LoadGlobal(Instruction):
    """Class for load-global instruction objects."""

    def __init__(self, labels, target, name):
        super().__init__(labels, Code.GLOBAL)
        self.target = target
        self.name = name

    def max_used(self):
        """Find max register used by this instuction."""
        return self.target

    def display(self):
        """Display load-global instruction as string."""
        return f'{"LDI": <{JUST}} {self.target}, ={self.name}'


class Ret(Instruction):
    """Class for return instruction objects."""

    def __init__(self, labels):
        super().__init__(labels, Code.RET)

    def display(self):
        """Display return instruction as string."""
        return 'RET'


class Emitter:
    """Class for emitting bit32 objects."""

    def __init__(self):
        self.clear()

    def clear(self):
        """Reset the emitter."""
        self.n_labels = 0
        self.if_jump_end = []
        self.loop = []
        self.labels = []
        self.instructions = []
        self.data = []
        self.strings = []

    def begin_loop(self):
        """
        Begin loop or swtich block.

        Head and tail labels are created for the current loop/switch block
        that are used for continue and break instructions.
        """
        self.loop.append((self.next_label(), self.next_label()))

    def loop_head(self):
        """Get the current loop head label."""
        return self.loop[-1][0]

    def loop_tail(self):
        """Get the current loop tail label."""
        return self.loop[-1][1]

    def end_loop(self):
        """End current loop or switch block."""
        self.loop.pop()

    def next_label(self):
        """Create a new unique label."""
        label = self.n_labels
        self.n_labels += 1
        return f'.L{label}'

    def append_label(self, label):
        """Append the given label to the current label list."""
        self.labels.append(label)

    def add(self, instruction):
        """Append the given instruction to the current list of instructions."""
        self.instructions.append(instruction)
        self.labels = []  # reset label list

    def optimize_body(self):
        """Peephole optimize the current function body."""
        i = 0
        while i < len(self.instructions)-1:
            # peephole size = 1
            # strength reduction
            inst1 = self.instructions[i]
            if inst1.code is Code.BINARY and not isinstance(inst1.source, Reg) and inst1.source in POWERS_OF_2:
                if inst1.op is Op.MUL:
                    inst1.op = Op.SHL
                    inst1.source = POWERS_OF_2[inst1.source]
                elif inst1.op is Op.DIV:
                    inst1.op = Op.SHR
                    inst1.source = POWERS_OF_2[inst1.source]
                elif inst1.op is Op.MOD:
                    inst1.op = Op.AND
                    inst1.source -= 1
            i += 1

        i = 0
        while i < len(self.instructions)-1:
            # peephole size = 2
            # get labels and code
            inst1 = self.instructions[i]
            inst2 = self.instructions[i+1]

            if inst1.code is Code.BINARY and inst1.op is Op.MOV and inst2.code is Code.BINARY and inst1.target is inst2.source:
                # redundant MOV after function call
                '''
                MOV A, B
                ADD C, A
                = ADD C, B
                '''
                self.instructions[i:i+2] = [Binary(inst1.labels+inst2.labels,
                                                   inst2.op, inst2.size,
                                                   inst2.target, inst1.source)]
                continue
            if inst1.code is Code.ADDRESS:
                # address collapse
                if inst2.code is Code.ADDRESS and inst1.target is inst2.base:
                    '''
                    ADD A, B, n
                    ADD C, A, m
                    = ADD C, B, n+m
                    '''
                    self.instructions[i:i+2] = [Address(inst1.labels+inst2.labels,
                                                        inst2.target, inst1.base,
                                                        inst1.offset+inst2.offset,
                                                        inst1.variable)]
                    continue
                if inst2.code is Code.BINARY and inst2.op is Op.ADD and inst1.target is inst2.target and not isinstance(inst2.source, Reg):
                    '''
                    ADD A, B, n
                    ADD A, m
                    = ADD A, B, n+m
                    '''
                    self.instructions[i:i+2] = [Address(inst1.labels+inst2.labels,
                                                        inst1.target, inst1.base,
                                                        inst1.offset+inst2.source,
                                                        inst1.variable)]
                    continue
                if inst2.code in {Code.LOAD, Code.STORE} and inst1.target is inst2.base:
                    '''
                    ADD A, B, n
                    LD C, [A, m]
                    = LD C, [B, n+m]
                    '''
                    self.instructions[i:i+2] = [Load(inst1.labels+inst2.labels,
                                                     inst2.code, inst2.size,
                                                     inst2.target, inst1.base,
                                                     inst1.offset+inst2.offset,
                                                     inst1.variable)]
                    continue
            i += 1

        # "you don't need to be a pilot to know planes don't belong in trees"

        # general redundant MOV before function call
        for args in range(1, 4+1):
            i = 0
            while i < len(self.instructions) - 2*args - 1:
                for j in range(args):
                    inst1 = self.instructions[i+j]
                    inst2 = self.instructions[i+args+j]
                    if (inst1.code not in {Code.BINARY, Code.TERNARY,
                                           Code.ADDRESS, Code.LOAD,
                                           Code.IMMEDIATE, Code.GLOBAL}
                        or inst2.code is not Code.BINARY
                        or inst2.op is not Op.MOV
                        or inst1.target is not inst2.source):
                        break
                else:
                    for j in range(args):
                        inst1 = self.instructions[i+j]
                        inst2 = self.instructions[i+args+j]
                        if inst1.code is Code.BINARY and inst1.op is not Op.MOV:
                            self.instructions[i+j] = Ternary(inst1.labels+inst2.labels,
                                                             inst1.op, inst1.size,
                                                             inst2.target,
                                                             inst1.target,
                                                             inst1.source)
                        else:
                            inst1.target = inst2.target
                    del self.instructions[i+args:i + 2*args]
                    i += args
                    continue
                i += 1

    def optimize(self):
        """
        Peephole optimize entire program.

        This happens after all functions are generated.
        """
        i = 0
        while i < len(self.instructions)-1:
            # peephole size = 2
            # eliminate redundant jumps
            inst1 = self.instructions[i]
            inst2 = self.instructions[i+1]
            '''
            JMP label
            label: ...
            '''
            if inst1.code is Code.JUMP and inst1.target in inst2.labels:
                inst2.labels += inst1.labels
                del self.instructions[i]
                continue
            i += 1

    def begin_body(self, definition):
        """Begin the body of a function."""
        if definition.returns or definition.type.return_type.width:
            self.return_label = self.next_label()
        self.temp = self.instructions
        self.instructions = []

    def end_body(self):
        """End the body of a function."""
        self.body = self.labels, self.instructions
        self.labels = []
        self.instructions = self.temp

    def add_body(self):
        """Add stored body to rest of code."""
        labels, body = self.body
        if body:
            body[0].labels += self.labels
            self.labels = labels
        else:
            self.labels += labels
        self.instructions += body

    def emit_string_array(self, name, string):
        """Emit string array object."""
        self.data.append(String(name, string))

    def emit_string_ptr(self, string):
        """Emit string pointer object."""
        if string not in self.strings:
            self.strings.append(string)
            self.emit_string_array(f'.S{self.strings.index(string)}', string)
        return f'.S{self.strings.index(string)}'

    def emit_space(self, name, size):
        """Emit space allocation object."""
        self.data.append(Space(name, size))

    def emit_global(self, name, size, value):
        """Emit global object."""
        self.data.append(Global(name, size, value))

    def emit_datas(self, label, datas):
        """
        Emit multiple data objects.

        For global structs or arrays.
        """
        size, data = datas[0]
        self.data.append(Data([label], size, data))
        for size, data in datas[1:]:
            self.data.append(Data([], size, data))

    def emit_push(self, regs):
        """Emit push instruction object."""
        if regs:
            self.add(Push(self.labels, regs))

    def emit_pop(self, regs):
        """Emit pop instruction object."""
        if regs:
            self.add(Pop(self.labels, regs))

    def emit_call(self, proc):
        """Emit call instruction object."""
        self.add(Call(self.labels, proc))

    def emit_ret(self):
        """Emit return instruction object."""
        self.add(Ret(self.labels))

    def emit_load_global(self, target, name):
        """Emit load-global instruction object."""
        self.add(LoadGlobal(self.labels, target, name))

    def emit_attribute(self, base, variable):
        """Emit address instruction object. Specifically for attributes."""
        self.emit_address(base, base, variable.offset, variable.name())

    def emit_address(self, target, base, offset, variable=None):
        """Emit address instruction object."""
        self.add(Address(self.labels, target, base, offset, variable))

    def emit_load(self, size, target, base, offset=None, variable=None):
        """Emit load instruction object."""
        self.add(Load(self.labels, Code.LOAD, size, target, base, offset, variable))

    def emit_store(self, size, target, base, offset=None, variable=None):
        """Emit store instruction object."""
        self.add(Load(self.labels, Code.STORE, size, target, base, offset, variable))

    def emit_load_immediate(self, target, value, comment=None):
        """Emit load-immediate instruction object."""
        self.add(LoadImmediate(self.labels, target, value, comment))

    def emit_unary(self, op, size, target):
        """Emit unary ALU instruction object."""
        self.add(Unary(self.labels, op, size, target))

    def emit_binary(self, op, size, target, source):
        """Emit binary ALU instruction object."""
        self.add(Binary(self.labels, op, size, target, source))

    def emit_ternary(self, op, size, target, rs, source):
        """Emit ternary ALU instruction object."""
        self.add(Ternary(self.labels, op, size, target, rs, source))

    def emit_jump(self, cond, target):
        """Emit jump instruction object."""
        self.add(Jump(self.labels, cond, target))

    def emit_cmov(self, cond, target, value):
        """Emit cmov instruction object."""
        self.add(CMov(self.labels, cond, target, value))

    def __str__(self):
        """Get string representaion of all emmitted objects."""
        return '\n'.join(map(str, self.data+self.instructions))
