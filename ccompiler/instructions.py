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
    CALL = 1
    RET = 2
    UNARY = 3
    BINARY = 4
    ADDRESS = 5
    LOAD = 6
    STORE = 7
    PUSH = 8
    POP = 9
    IMMEDIATE = 10
    GLOBAL = 11


class Argument:
    """Base class for arguments in instructions."""

    def __init__(self, value):
        self.value = value

    def live(self):
        """Is the argument a part of the live range? Defualt is no."""
        return set()

    def __eq__(self, other):
        return isinstance(other, Argument) and self.value == other.value

    def __str__(self):
        return str(self.value)

    def __repr__(self):
        return str(self)


class Label(Argument):
    """Class for labels as arguments"""
    pass


GENERAL = 11  # number of general purpose registers


class Register(Argument):
    """Base class for registers."""

    def devirtualize(self, reg):
        """Lower to physical register."""
        pass

    def disconnect(self, _, __):
        """Disconnect this register from neighbors. Defualt is do nothing."""
        pass

    def precolor(self, _):
        """Precolor this node."""
        pass

    def color(self, _, __, ___):
        """Color this register."""
        pass

    def __eq__(self, other):
        return isinstance(other, Register) and self.value == other.value

    def __hash__(self):
        return hash(self.value)


class Physical(Register):
    """Class for physical registers."""

    def __init__(self, reg):
        super().__init__(reg.name)
        self.reg = reg

    def live(self):
        """Is this register a part of the live range? Only general purpose register are."""
        if self.reg < GENERAL:
            return {self}
        return super().live()

    def devirtualize(self, other):
        """Lower to physical register."""
        other.virtual = False

    def precolor(self, colors):
        """Precolor this physical register."""
        if self.value not in colors and self.reg < GENERAL:
            colors[self.value] = int(self.reg)

    def color(self, colors, _, __):
        """Color this physical register if not already."""
        self.precolor(colors)

Registers = [Physical(reg) for reg in Reg]


class Virtual(Register):
    """Class for virtual register that will later be lowered into physical registers."""

    virtuals = []  # keep track off all created virtual registers.

    @classmethod
    def next_virtual(cls):
        """Create next virtual register."""
        virt = Virtual(f'V{len(cls.virtuals):02X}')
        cls.virtuals.append(virt)
        return virt

    @classmethod
    def clear(cls):
        """Clear all virtual registers and start at 0."""
        cls.virtuals.clear()

    def __init__(self, name):
        super().__init__(name)
        self.virtual = True

    def live(self):
        """Virtual registers are always a part of the live range."""
        return {self}

    def disconnect(self, graph, edges):
        """Disconnect this virtual from its neighbors."""
        if self.virtual:
            for edge in edges:
                graph[edge].remove(self)

    def color(self, colors, spill, edges):
        """Color this virtual register or otherwise spill."""
        if self.virtual:
            used_colors = {colors[edge.value] for edge in edges if edge.value in colors}
            for color in range(GENERAL):
                if color not in used_colors:
                    colors[self.value] = color
                    break
            else:
                spill.append(self)

    def alias(self, reg):
        """Give this node an alias."""
        if self.virtual:
            self.value = reg.value
            reg.devirtualize(self)

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
        if self.size is None:
            return f'.space {self.value}'
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

    def __init__(self, labels):
        super().__init__(labels)
        self.live_in = None
        self.live_out = None

    def adjust_offset(self, _):
        """Adjust the offset of a marked address instruction (default is no action)."""
        pass

    def defined(self):
        """Return the set of registers this instruction defines (default is none)."""
        return set()

    def used(self):
        """Return the set of registers this instruction uses (default is none)."""
        return set()

    def populate(self, _):
        """Populate the graph with registers (default is no action)."""
        pass

    def coalesce(self, _):
        """Determine if this instruction can be coalesced (default is no)."""
        return False

    def precolor(self, _):
        """Precolor the colors with registers (default is no action)."""
        pass

    @property
    def op_str(self):
        """Get the formatted op string for this instructions."""
        return str(self.op).ljust(JUST)


class Push(Instruction):
    """Class for push instruction objects."""

    code = Code.PUSH
    op = 'PUSH'

    def __init__(self, labels, push):
        super().__init__(labels)
        self.push = push

    def used(self):
        """Return the used register for this push."""
        return self.push[0].live()

    def display(self):
        """Display push instruction as string."""
        return f'{self.op_str} {", ".join(str(reg) for reg in self.push)}'


class Pop(Instruction):
    """Class for pop instruction objects."""

    code = Code.POP
    op = 'POP'

    def __init__(self, labels, pop):
        super().__init__(labels)
        self.pop = pop

    def used(self):
        """Return the used register for this pop."""
        return self.pop[0].live()

    def display(self):
        """Display pop instruction as string."""
        return f'{self.op_str} {", ".join(reg.name for reg in self.pop)}'


class Jump(Instruction):
    """Class for jump instructions objects."""

    code = Code.JUMP

    def __init__(self, labels, condition, target):
        super().__init__(labels)
        self.condition = condition
        self.target = Label(target) if isinstance(target, str) else target

    def used(self):
        """Return the used register for this jump."""
        return self.target.live()

    @property
    def op_str(self):
        """Get the formatted op string for jumps."""
        return f'J{self.condition.jump()}'.ljust(JUST)

    def display(self):
        """Display jump instruction as string."""
        return f'{self.op_str} {self.target}'


class Call(Instruction):
    """Class for call instruction objects."""

    code = Code.CALL
    op = 'CALL'

    def __init__(self, labels, target, arguments):
        super().__init__(labels)
        self.target = Label(target) if isinstance(target, str) else target
        self.arguments = arguments

    def defined(self):
        """Return the defined register. A function's return value should always be in A."""
        return {Registers[0]}

    def used(self):
        """Return the used registers for the function's arguments."""
        return {Registers[i] for i in range(self.arguments)} | self.target.live()

    def populate(self, graph):
        """Populate the graph with registers."""
        for reg in self.live_in:
            if reg not in graph:
                graph[reg] = set()
            for i in range(self.arguments):
                if reg != Registers[i]:
                    graph[reg].add(Registers[i])
                    graph[Registers[i]].add(reg)
        for reg in self.live_out:
            if reg not in graph:
                graph[reg] = set()
            if reg != Registers[0]:
                graph[reg].add(Registers[0])
                graph[Registers[0]].add(reg)

    def display(self):
        """Display call instruction as string."""
        return f'{self.op_str} {self.target}'


class Definition(Instruction):
    """Base class for instruction objects that define a target."""

    def __init__(self, labels, target):
        super().__init__(labels)
        self.target = Registers[target] if isinstance(target, Reg) else target

    def defined(self):
        """Return the register this instruction defines."""
        return self.target.live()

    def populate(self, graph):
        """Populate the graph with the target register."""
        if self.target not in graph:
            graph[self.target] = set()
        for reg in self.live_out:
            if reg != self.target:
                graph[self.target].add(reg)
                graph[reg].add(self.target)


class Operation(Definition):
    """Base class for operation instruction objects."""

    def __init__(self, labels, op, size, target):
        super().__init__(labels, target)
        self.op = op
        self.size = size


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

    def defined(self):
        """Comparison unary instructions do not define any registers."""
        if self.op in {Op.CMP, Op.CMPF}:
            return set()
        return super().defined()

    def used(self):
        """Comparison unary instructions use the target register."""
        if self.op in {Op.CMP, Op.CMPF}:
            return self.target.live() | self.source.live()
        return self.source.live()

    @property
    def op_str(self):
        """Get the formatted op string for ALU operations."""
        return f'{self.op.name}{self.size}'.ljust(JUST)

    def display(self):
        """Display binary instruction as string."""
        return f'{self.op_str} {self.target}, {self.source}'


class CMov(Unary):
    """Class for conditional move instruction objects."""

    def __init__(self, labels, condition, target, source):
        super().__init__(labels, Op.MOV, Size.WORD, target, source)  # TODO I think these should have a size
        self.condition = condition

    @property
    def op_str(self):
        """Get the formatted op string for cmovs."""
        return f'{self.op.name}{self.condition}'.ljust(JUST)

class Move(Unary):
    """Base class for coalescable Move instructions."""

    def __init__(self, labels, size, target, source):
        super().__init__(labels, Op.MOV, size, target, source)

    def coalesce(self, graph):
        """Attempt to coalesce this move isntruction."""
        parent = self.get_parent()
        child = self.get_child()
        if parent != child and parent not in graph[child]:  # if they don't interfere
            graph[parent] |= graph[child]
            for edge in graph[child]:
                graph[edge].remove(child)
                graph[edge].add(parent)
            child.alias(parent)
            return True
        return False

    def precolor(self, colors):
        """Precolor with parent registers used in moves."""
        self.get_parent().precolor(colors)


class LeftMove(Move):
    """Class for "left" move instructions objects."""

    def get_parent(self):
        """Get the parent register."""
        return self.target

    def get_child(self):
        """Get the child register."""
        return self.source


class RightMove(Move):
    """Class for "right" move instruction objects."""

    def get_parent(self):
        """Get the parent register."""
        return self.source

    def get_child(self):
        """Get the child register."""
        return self.target


class Binary(Unary):
    """Class for ternary ALU instruction objects."""

    code = Code.BINARY

    def __init__(self, labels, op, size, target, source2, source):
        super().__init__(labels, op, size, target, source)
        self.source2 = Registers[source2] if isinstance(source2, Reg) else source2

    def used(self):
        """Return the used registers."""
        return self.source.live() | self.source2.live()

    def display(self):
        """Display ternary instruction as string."""
        if self.target == self.source2:
            return super().display()
        return f'{self.op_str} {self.target}, {self.source2}, {self.source}'


class Address(Definition):
    """Class for address instruction objects."""

    code = Code.ADDRESS
    op = 'ADD'

    def __init__(self, labels, target, base, offset, marked, comment):
        super().__init__(labels, target)
        self.base = Registers[base] if isinstance(base, Reg) else base
        self.offset = offset if isinstance(offset, Register) or offset is None else Argument(offset)
        self.marked = marked
        self.comment = comment

    def adjust_offset(self, adjustment):
        """Adjust the offset of a marked address instruction."""
        if self.marked:
            self.offset.value += adjustment

    def used(self):
        """Get the used registers."""
        if self.offset is None:
            return self.base.live()
        return self.base.live() | self.offset.live()

    @property
    def comment_str(self):
        """Get the comment as a string."""
        return f' ; {self.comment}' if self.comment else ''

    def display(self):
        """Display address instruction as string."""
        if self.target == self.base:
            return f'{self.op_str} {self.target}, {self.offset}{self.comment_str}'
        return f'{self.op_str} {self.target}, {self.base}, {self.offset}{self.comment_str}'


class Load(Address):
    """Class for load instruction objects."""

    code = Code.LOAD

    def __init__(self, labels, size, target, base, offset, marked, comment):
        super().__init__(labels, target, base, offset, marked, comment)
        self.size = size

    @property
    def op_str(self):
        """Get the formatted op string for loads."""
        return f'LD{self.size}'.ljust(JUST)

    def display(self):
        """Display load instruction as string."""
        return '{} {}, [{}{}]{}'.format(self.op_str, self.target, self.base,
                                        f', {self.offset}' if self.offset is not None else '',
                                        self.comment_str)


class Store(Load):
    """Class for store instruction objects."""

    code = Code.STORE

    def used(self):
        """Get the used registers."""
        if self.offset is None:
            return self.base.live() | self.target.live()
        return self.base.live() | self.offset.live() | self.target.live()

    @property
    def op_str(self):
        """Get the formatted op string for stores."""
        return f'ST{self.size}'.ljust(JUST)

    def display(self):
        """Display store instruction as string."""
        return '{} [{}{}], {}{}'.format(self.op_str, self.base,
                                        f', {self.offset}' if self.offset is not None else '',
                                        self.target, self.comment_str)


class LoadImmediate(Definition):
    """Class for load-immediate instruction objects."""

    code = Code.IMMEDIATE
    op = 'LDI'

    def __init__(self, labels, target, source, comment):
        super().__init__(labels, target)
        self.source = Argument(source)
        self.comment = f' ; {comment}' if comment else comment

    def display(self):
        """Display load-immediate instruction as string."""
        return f'{self.op_str} {self.target}, {self.source}{self.comment}'


class LoadGlobal(Definition):
    """Class for load-global instruction objects."""

    code = Code.GLOBAL
    op = 'LDI'

    def __init__(self, labels, target, name):
        super().__init__(labels, target)
        self.name = name

    def display(self):
        """Display load-global instruction as string."""
        return f'{self.op_str} {self.target}, ={self.name}'


class Ret(Instruction):
    """Class for return instruction objects."""

    code = Code.RET

    def display(self):
        """Display return instruction as string."""
        return 'RET'
