# -*- coding: utf-8 -*-
"""
Created on Fri May 15 20:43:58 2026

@author: Colin
"""

from enum import Enum
from bit32 import Reg, Size, Op, escape_str


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

MEMORY_CODES = {Code.ADDRESS, Code.LOAD, Code.STORE}

ARGUMENT_CODES = {Code.BINARY, Code.TERNARY, Code.ADDRESS, Code.LOAD, Code.IMMEDIATE, Code.GLOBAL}


class Argument:

    def __init__(self, value):
        self.value = value

    def live(self):
        return set()

    def __eq__(self, other):
        return str(self) == str(other)

    def __str__(self):
        return str(self.value)

    def __repr__(self):
        return str(self)

class Label(Argument):
    pass

class Register(Argument):


    def live(self):
        if self.value in {'SP', 'SR', 'ILR', 'LR', 'PC'}:
            return set()
        return {self}

    def disconnect(self, _, __):
        pass

    def color(self, graph, spill, edges):
        if self not in graph and self.value not in {'SP', 'SR', 'ILR', 'LR', 'PC'}:
            graph[self] = Registers.index(self)

    def __hash__(self):
        return hash(self.value)

Registers = [Register(r.name) for r in Reg]

class Virtual(Register):

    next_virt = 0

    def __init__(self):
        super().__init__(f'V{Virtual.next_virt:02X}')
        Virtual.next_virt += 1
        self.virtual = True

    def live(self):
        return {self}

    def disconnect(self, graph, edges):
        if self.virtual:
            for edge in edges:
                graph[edge].remove(self)

    def color(self, colors, spill, edges):
        if self.virtual:
            used_colors = {colors[edge] for edge in edges if edge in colors}
            for color in range(11):
                if color not in used_colors:
                    colors[self] = color
                    break
            else:
                spill.append(self)

    def devirtualize(self, reg):
        if self.virtual:
            self.value = reg.value
            self.virtual = False

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
        return rf'{self.labels[0]}: "{escape_str(self.value)}\0"'


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

    code = None

    def __init__(self, labels):
        super().__init__(labels)
        self.live_in = None
        self.live_out = None

    def adjust_offset(self, _):
        """Adjust the offset of a marked address instruction (default is no action)."""
        pass

    def defined(self):
        return set()

    def used(self):
        return set()

    def populate(self, _):
        pass

    def coalesce(self, _):
        return False

    def obsolete(self):
        return False

    def precolor(self, _):
        pass

    def max_used(self):
        """Find max register used by this instuction."""
        return 0


class Push(Instruction):
    """Class for push instruction objects."""

    code = Code.PUSH

    def __init__(self, labels, push):
        super().__init__(labels)
        self.push = push

    def used(self):
        return self.push[0].live()

    def display(self):
        """Display push instruction as string."""
        return f'{"PUSH": <{JUST}} {", ".join(str(reg) for reg in self.push)}'


class Pop(Instruction):
    """Class for pop instruction objects."""

    code = Code.POP

    def __init__(self, labels, pop):
        super().__init__(labels)
        self.pop = pop

    def used(self):
        return self.pop[0].live()

    def display(self):
        """Display pop instruction as string."""
        return f'{"POP": <{JUST}} {", ".join(reg.name for reg in self.pop)}'


class Jump(Instruction):
    """Class for jump instructions objects."""

    code = Code.JUMP

    def __init__(self, labels, condition, target):
        super().__init__(labels)
        self.condition = condition
        self.target = Label(target) if isinstance(target, str) else target

    def used(self):
        return self.target.live()

    def display(self):
        """Display jump instruction as string."""
        return f'{"J"+self.condition.jump(): <{JUST}} {self.target}'


class Call(Instruction):
    """Class for call instruction objects."""

    code = Code.CALL

    def __init__(self, labels, target, arguments):
        super().__init__(labels)
        self.target = Label(target) if isinstance(target, str) else target
        self.arguments = arguments

    def defined(self):
        return {Registers[0]}

    def used(self):
        return {Registers[i] for i in range(self.arguments)} | self.target.live()

    def populate(self, graph):
        for virt in self.live_in:
            if virt not in graph:
                graph[virt] = set()
            for i in range(self.arguments):
                if virt != Registers[i]:
                    graph[virt].add(Registers[i])
                    graph[Registers[i]].add(virt)
        for virt in self.live_out:
            if virt not in graph:
                graph[virt] = set()
            if virt != Registers[0]:
                graph[virt].add(Registers[0])
                graph[Registers[0]].add(virt)

    def precolor(self, colors):
        for i in range(self.arguments):
            colors[Registers[i]] = i


    def max_used(self):
        """Find max register used by this instuction."""
        if isinstance(self.target, Reg):
            return self.target
        return 0

    def display(self):
        """Display call instruction as string."""
        return f'{"CALL": <{JUST}} {self.target}'

class Operation(Instruction):
    """Base class for operation instructions."""

    def __init__(self, labels, op, size, target):
        super().__init__(labels)
        self.op = op
        self.size = size
        self.target = Registers[target] if isinstance(target, Reg) else target

    def defined(self):
        return self.target.live()

    def populate(self, graph):
        if self.target not in graph:
            graph[self.target] = set()
        for reg in self.live_out:
            if reg != self.target:
                graph[self.target].add(reg)
                graph[reg].add(self.target)

class CMov(Operation):
    """Class for conditional move instruction objects."""

    code = Code.CMOV

    def __init__(self, labels, condition, target, source):
        super().__init__(labels, Op.MOV, Size.WORD, target)
        self.condition = condition
        self.source = Argument(source)

    def display(self):
        """Display cmov instruction as string."""
        return f'{"MOV"+str(self.condition): <{JUST}} {self.target}, {self.source}'


class Unary(Operation):
    """Class for unary ALU instruction objects."""

    code = Code.UNARY

    def __init__(self, labels, op, size, target, source):
        super().__init__(labels, op, size, target)
        if isinstance(source, Reg):
            self.source = Registers[source]
        elif isinstance(source, Register):
            self.source = source
        else:
            self.source = Argument(source)
        '''
        virtual
        physical
        label
        number
        character
        '''

    def defined(self):
        if self.op in {Op.CMP, Op.CMPF}:
            return set()
        return super().defined()

    def used(self):
        if self.op in {Op.CMP, Op.CMPF}:
            return self.target.live() | self.source.live()
        return self.source.live()

    def display(self):
        """Display binary instruction as string."""
        return f'{self.op.name+str(self.size): <{JUST}} {self.target}, {self.source}'


class Move(Unary):

    def __init__(self, labels, size, target, source):
        super().__init__(labels, Op.MOV, size, target, source)

    def coalesce(self, graph):
        reg = self.get_physical()
        virt = self.get_virtual()
        if virt.virtual and reg not in graph[virt]:  # if they don't interfere
            graph[reg] |= graph[virt]
            for edge in graph[virt]:
                graph[edge].remove(virt)
                graph[edge].add(reg)
            virt.devirtualize(reg)
            return True
        return False

    def obsolete(self):
        return self.target == self.source


class LeftMove(Move):


    def get_physical(self):
        return self.target

    def get_virtual(self):
        return self.source


class RightMove(Move):


    def get_physical(self):
        return self.source

    def get_virtual(self):
        return self.target


class Binary(Unary):
    """Class for ternary ALU instruction objects."""

    code = Code.BINARY

    def __init__(self, labels, op, size, target, source2, source):
        super().__init__(labels, op, size, target, source)
        self.source2 = Registers[source2] if isinstance(source2, Reg) else source2  # TODO?

    def used(self):
        return self.source.live() | self.source2.live()

    def display(self):
        """Display ternary instruction as string."""
        if self.target == self.source2:
            return super().display()
        return f'{self.op.name+str(self.size): <{JUST}} {self.target}, {self.source2}, {self.source}'


class Address(Instruction):
    """Class for address instruction objects."""

    code = Code.ADDRESS

    def __init__(self, labels, target, base, offset, marked, comment):
        super().__init__(labels)
        self.target = target
        self.base = Registers[base] if isinstance(base, Reg) else base
        self.offset = offset if isinstance(offset, Register) or offset is None else Argument(offset)
        self.marked = marked
        self.comment = comment

    def adjust_offset(self, adjustment):
        """Adjust the offset of a marked address instruction."""
        if self.marked:
            self.offset.value += adjustment

    def defined(self):
        return self.target.live()

    def used(self):
        if self.offset is None:
            return self.base.live()
        return self.base.live() | self.offset.live()

    def populate(self, graph):
        if self.target not in graph:
            graph[self.target] = set()
        for reg in self.live_out:
            if reg != self.target:
                graph[self.target].add(reg)
                graph[reg].add(self.target)

    def max_used(self):
        """Find max register used by this instuction."""
        return max(self.target, Reg.max_reg(self.base))

    def display(self):
        """Display address instruction as string."""
        return f'{"ADD": <{JUST}} {self.target}, {self.base}, {self.offset} ; {self.comment}'


class Load(Address):
    """Class for load/store instruction objects."""

    code = Code.LOAD

    def __init__(self, labels, size, target, base, offset, marked, comment):
        super().__init__(labels, target, base, offset, marked, comment)
        self.size = size

    def display(self):
        """Display load instruction as string."""
        return '{} {}, [{}{}]{}'.format(f'{"LD"+str(self.size): <{JUST}}',
                                        self.target,
                                        self.base,
                                        f', {self.offset}' if self.offset is not None else '',
                                        f' ; {self.comment}' if self.comment else '')


class Store(Load):

    code = Code.STORE

    def used(self):
        if self.offset is None:
            return self.base.live() | self.target.live()
        return self.base.live() | self.offset.live() | self.target.live()

    def display(self):
        return '{} [{}{}], {}{}'.format(f'{"ST"+str(self.size): <{JUST}}',
                                        self.base,
                                        f', {self.offset}' if self.offset is not None else '',
                                        self.target,
                                        f' ; {self.comment}' if self.comment else '')


class LoadImmediate(Instruction):
    """Class for load-immediate instruction objects."""

    code = Code.IMMEDIATE

    def __init__(self, labels, target, source, comment):
        super().__init__(labels)
        self.target = target
        self.source = Argument(source)
        self.comment = f' ; {comment}' if comment else comment

    def defined(self):
        return self.target.live()

    def populate(self, graph):
        if self.target not in graph:
            graph[self.target] = set()
        for reg in self.live_out:
            if reg != self.target:
                graph[self.target].add(reg)
                graph[reg].add(self.target)

    def max_used(self):
        """Find max register used by this instuction."""
        return self.target

    def display(self):
        """Display load-immediate instruction as string."""
        return f'{"LDI": <{JUST}} {self.target}, {self.source}{self.comment}'


class LoadGlobal(Instruction):
    """Class for load-global instruction objects."""

    code = Code.GLOBAL

    def __init__(self, labels, target, name):
        super().__init__(labels)
        self.target = target
        self.name = Label(name)

    def defined(self):
        return self.target.live()

    def populate(self, graph):
        if self.target not in graph:
            graph[self.target] = set()
        for reg in self.live_out:
            if reg != self.target:
                graph[self.target].add(reg)
                graph[reg].add(self.target)

    def display(self):
        """Display load-global instruction as string."""
        return f'{"LDI": <{JUST}} {self.target}, ={self.name}'


class Ret(Instruction):
    """Class for return instruction objects."""

    code = Code.RET

    def __init__(self, labels):
        super().__init__(labels)

    def display(self):
        """Display return instruction as string."""
        return 'RET'
