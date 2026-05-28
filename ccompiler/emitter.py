# -*- coding: utf-8 -*-
"""
Created on Sat Sep  7 01:02:16 2024

@author: Colin
"""
from .instructions import (Code, Register, Registers, GENERAL, Virtual, String, Space, Global, Data,
                           Push, Pop, Call, Ret, LoadGlobal, Address, Load, Store, LoadImmediate, Unary, Binary,
                           LeftMove, RightMove, Jump, CMov)
from bit32 import Reg, Size, Cond, Op, escape_chr

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

[x] Register Allocation
    [x] connect everything (ongoing)
    [x] add Number (Argument)
    [] add blocks
    [x] peephole optimization
    [x] calc liveliness
    [x] build graph
    [x] coalesce
        [x] add left and right move
    [x] color
    [x] max reg

    [x] sort graph
    [x] numbers -> Argument
    [x] __hash__ and __eq__
    [x] .is_...


[x] Common subexpression elimination
    [x] add table and signatures

[x] Refactor
    [x] fix unary vs binary vs ternary in assembler
    [x] refactor Nodes
    [x] refactor Arguments
    [x] refactor Instructions
    [x] fix conditionals
    [x] fix abandonded labels. add blocks?
    [x] coverage
    [x] remove unused
    [x] document

[] make optimization levels
    [] peephole = 1
    [] CSE = 2
    [] both = 3

[x] fix struct/array __iter__
[x] fix union init list
[] var arg macros
[] refactor instruction display?
[] add more to stds

select instructions -> coalesce -> peephole -> color -> peephole again
'''

POWERS_OF_2 = {2**n: n for n in range(8)}

class Emitter:
    """Class for emitting bit32 objects."""

    def __init__(self):
        self.clear()

    def clear(self):
        """Reset the emitter."""
        self.next_label_id = 0
        self.loop = []
        self.labels = []
        self.instructions = []
        self.data = []
        self.strings = []
        self.table = {}

    def begin_loop(self):
        """
        Begin loop or switch block.

        Head and tail labels are created for the current loop/switch block
        that are used as targets for continue and break instructions.
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
        label = self.next_label_id
        self.next_label_id += 1
        return f'.L{label}'

    def append_label(self, label):
        """Append the given label to the current label list."""
        self.labels.append(label)

    def add(self, instruction):
        """Append the given instruction to the current list of instructions."""
        self.instructions.append(instruction)
        if self.labels:
            self.table.clear()
        self.labels = []  # reset label list

    def optimize_body(self):
        """Peephole optimize the current function body."""
        i = 0
        while i < len(self.instructions)-1:
            # peephole size = 1
            # strength reduction
            inst1 = self.instructions[i]
            if (inst1.code is Code.BINARY
                and not isinstance(inst1.source, Register)
                and inst1.source.value in POWERS_OF_2):
                if inst1.op is Op.MUL:  # x * 2**n = x << n
                    inst1.op = Op.SHL
                    inst1.source.value = POWERS_OF_2[inst1.source.value]
                elif inst1.op is Op.DIV:   # x / 2**n = x >> n
                    inst1.op = Op.SHR
                    inst1.source.value = POWERS_OF_2[inst1.source.value]
                elif inst1.op is Op.MOD:  # x % 2**n = x & 2**n - 1
                    inst1.op = Op.AND
                    inst1.source.value -= 1
            i += 1

        new = []
        i = 0
        while i < len(self.instructions)-1:
            # peephole size = 2
            # get labels and code
            inst1 = self.instructions[i]
            inst2 = self.instructions[i+1]
            if (inst1.code is Code.UNARY
                and inst1.op is Op.MOV
                and inst2.code is Code.UNARY
                and inst2.op is Op.ITF
                and inst1.target == inst2.source
                and not isinstance(inst1.source, Register)):
                '''
                MOV A, n
                ITF C, A
                = ITF C, n
                '''
                inst2.labels += inst1.labels
                inst2.source = inst1.source
                inst2.live_in = inst1.live_in
            elif (inst1.code is Code.ADDRESS
                  and inst2.code in {Code.ADDRESS, Code.LOAD, Code.STORE}
                  and inst1.target not in inst2.live_out
                  and inst1.target == inst2.base
                  and not isinstance(inst1.offset, Register)
                  and not isinstance(inst2.offset, Register)):
                '''
                Address collapse
                ADD A, B, n
                LD C, [A, m]
                = LD C, [B, n+m]
                '''
                inst2.labels += inst1.labels
                inst2.base = inst1.base
                inst2.offset.value += inst1.offset.value
                inst2.marked = inst1.marked
                inst2.comment = inst1.comment + inst2.comment
                inst2.live_in = inst1.live_in
            else:
                new.append(inst1)
            i += 1
        if self.instructions:
            new.append(self.instructions[-1])
        self.instructions = new

        # "you don't need to be a pilot to know planes don't belong in trees"

    def optimize(self):
        """
        Peephole optimize entire program.

        This happens after all functions are generated.
        """
        new = []
        i = 0
        while i < len(self.instructions)-1:
            # peephole size = 2
            # eliminate redundant jumps
            inst1 = self.instructions[i]
            inst2 = self.instructions[i+1]
            if inst1.code is Code.JUMP and inst1.target.value in inst2.labels:
                '''
                JMP label
                label: ...
                '''
                inst2.labels += inst1.labels
            elif (inst1.code is Code.UNARY
                  and inst1.op is Op.MOV
                  and inst1.target == inst1.source):
                '''
                MOV A, A
                '''
                inst2.labels += inst1.labels
            elif (inst1.code is Code.STORE
                  and inst2.code is Code.LOAD
                  and not inst2.labels
                  and inst1.target == inst2.target
                  and inst1.base == inst2.base
                  and inst1.offset == inst2.offset):
                '''
                ST [A, B], C
                LD C, [A, B]
                '''
                new.append(inst1)
                i += 1
            else:
                new.append(inst1)
            i += 1
        if self.instructions:
            new.append(self.instructions[-1])
        self.instructions = new

    def calculate_liveliness(self):
        """Calculate liveliness for each instruction."""
        live = set()
        for inst in reversed(self.instructions):
            inst.live_out = live
            inst.live_in = inst.used() | (inst.live_out - inst.defined())
            live = inst.live_in

    def build_graph(self):
        """Populate inference graph."""
        graph = {}
        for inst in self.instructions:
            inst.populate(graph)
        return graph

    def coalesce(self, graph):
        """Coalesce move instructions."""
        changed = False
        for inst in self.instructions:
            if inst.coalesce(graph):
                changed = True
        return changed

    def color(self, graph, registers):
        """Color each register."""
        # sort graph
        graph = {
            node: edge
            for node, edge in sorted(
                    sorted(
                        graph.items(),
                        key=lambda i: i[0].value,
                        reverse=True),
                    key=lambda i: len(i[1]))
        }
        stack = []
        spill = []
        for node, edges in graph.items():
            if len(edges) < registers:  # Leave 1 for spill?
                stack.append((node, edges))
            else:
                spill.append(node)
            node.disconnect(graph, edges)
        # Assign registers
        colors = {}
        for inst in self.instructions:
            inst.precolor(colors)
        while stack:
            node, edges = stack.pop()
            node.color(colors, spill, edges)
        return colors, spill

    def allocate_registers(self):
        """Allocate registers and return max register used."""
        # coalescing loop
        changed = True
        while changed:
            self.calculate_liveliness()
            graph = self.build_graph()
            changed = self.coalesce(graph)
        # peephole optimize body
        self.optimize_body()
        # build graph again
        graph = self.build_graph()
        # color graph
        colors, spill = self.color(graph, GENERAL)
        assert not spill, str(spill)
        max_reg = max(colors.values()) if colors else -1
        # devirtualize registers
        for virt in Virtual.virtuals:
            if virt in colors:
                virt.devirtualize(Registers[colors[virt]])
        return max_reg

    def begin_body(self, definition):
        """Begin the body of a function."""
        Virtual.clear()
        if definition.returns or definition.type.return_type.width:
            self.return_label = self.next_label()
        self.temp = self.instructions
        self.instructions = []
        self.table.clear()

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

    def emit_jump(self, cond, target):
        """Emit jump instruction object."""
        self.add(Jump(self.labels, cond, target))
        self.table.clear()

    def emit_call(self, proc, args):
        """Emit call instruction object."""
        self.add(Call(self.labels, proc, min(args, 4)))
        self.table.clear()

    def emit_ret(self):
        """Emit return instruction object."""
        self.add(Ret(self.labels))

    def emit_unary(self, op, size, source):
        """Emit unary ALU instruction object."""
        t = (Code.UNARY, op, size, source)
        if not self.labels and t in self.table:
            return self.table[t]
        target = Virtual.next_virtual()
        self.add(Unary(self.labels, op, size, target, source))
        self.table[t] = target
        return target

    def emit_compare(self, op, size, left, right):
        """Emit compare instruction object."""
        self.add(Unary(self.labels, op, size, left, right))

    def emit_binary(self, op, size, left, right):
        """Emit binary ALU instruction object."""
        t = (Code.BINARY, op, size, left, right)
        if not self.labels and t in self.table:
            return self.table[t]
        target = Virtual.next_virtual()
        self.add(Binary(self.labels, op, size, target, left, right))
        self.table[t] = target
        return target

    def emit_left_move(self, size, target, source):
        """Emit left move instruction object."""
        self.add(LeftMove(self.labels, size, target, source))

    def emit_right_move(self, size, source):
        """Emit right move instruction object."""
        target = Virtual.next_virtual()
        self.add(RightMove(self.labels, size, target, source))
        return target

    def emit_cmov(self, cond, inv):
        """Emit cmov instruction object."""
        target = Virtual.next_virtual()
        self.add(CMov(self.labels, cond, target, 1))
        self.add(CMov(self.labels, inv, target, 0))
        return target

    def emit_stack_allocation(self, space):
        """Emit stack allocation instruction object."""
        self.add(Binary(self.labels, Op.SUB, Size.WORD, Reg.SP, Reg.SP, space))

    def emit_stack_deallocation(self, space):
        """Emit stack deallocation instruction object."""
        self.add(Binary(self.labels, Op.ADD, Size.WORD, Reg.SP, Reg.SP, space))

    def emit_attribute(self, base, offset, comment):
        """Emit address instruction object. Specifically for attributes."""
        return self.emit_address(base, offset, False, comment)

    def emit_address(self, base, offset, marked=False, comment=''):
        """Emit address instruction object."""
        target = Virtual.next_virtual()
        self.add(Address(self.labels, target, base, offset, marked, comment))
        return target

    def emit_load(self, size, base, offset=None, marked=False, comment=''):
        """Emit load instruction object."""
        t = (Code.LOAD, base, offset, marked)
        if not self.labels and t in self.table:
            return self.table[t]
        target = Virtual.next_virtual()
        self.add(Load(self.labels, size, target, base, offset, marked, comment))
        self.table[t] = target
        return target

    def emit_store(self, size, target, base, offset=None, marked=False, comment=''):
        """Emit store instruction object."""
        self.add(Store(self.labels, size, target, base, offset, marked, comment))
        self.table.clear()
        return target

    def emit_table_jump(self, base, offset):
        """Emit instruction object from jump table. Specifically for switch statements."""
        self.add(Load(self.labels, Size.WORD, Reg.PC, base, offset, False, ''))

    def emit_load_global(self, name):
        """Emit load-global instruction object."""
        t = (Code.GLOBAL, name)
        if not self.labels and t in self.table:
            return self.table[t]
        target = Virtual.next_virtual()
        self.add(LoadGlobal(self.labels, target, name))
        self.table[t] = target
        return target

    def emit_load_immediate(self, value, comment=''):
        """Emit load-immediate instruction object."""
        t = (Code.IMMEDIATE, value)
        if not self.labels and t in self.table:
            return self.table[t]
        target = Virtual.next_virtual()
        self.add(LoadImmediate(self.labels, target, value, comment))
        self.table[t] = target
        return target

    def emit_logic(self, label, sublabel):
        """Emit instruction objects for logical operators."""
        target = Virtual.next_virtual()
        self.add(Unary(self.labels, Op.MOV, Size.WORD, target, 1))
        self.emit_jump(Cond.AL, sublabel)
        self.append_label(label)
        self.add(Unary(self.labels, Op.MOV, Size.WORD, target, 0))
        return target

    def emit_stack_string_array(self, string, base):
        """Emit instruction objects specifically for stack string arrays."""
        for i, c in enumerate(string):
            self.add(Unary(self.labels, Op.MOV, Size.BYTE, Reg.A, f"'{escape_chr(c)}'"))
            self.add(Store(self.labels, Size.BYTE, Reg.A, base, i, False, ''))

    def emit_phi(self, size, true, false):
        """Emit "phi" instruction object specifically for conditional expressions."""
        self.add(Unary(self.labels, Op.MOV, size, true, false))

    def __str__(self):
        """Get string representaion of all emmitted objects."""
        return '\n'.join(map(str, self.data+self.instructions))
