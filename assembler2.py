# -*- coding: utf-8 -*-
"""
Created on Fri Oct  3 09:36:40 2025

@author: ccslon
"""
from enum import IntEnum, IntFlag
from typing import NamedTuple
from operator import add, sub, mul, floordiv, mod, lshift, rshift, eq, ne, gt, lt, ge, le
import re

from bit32 import Size, Flag, Reg, Op, Cond, Byte, Char, Half, Word, Jump, Interrupt, Unary, Binary, Ternary, Load, PushPop, LoadImmediate, unescape


class Debug(IntFlag):
    """Flag enum class for debugging options."""

    NONE = 0
    OBJECT_FILE = 1
    FULL = 2
    SHORT = 4
    PRINT_BYTES = 8


DEBUG = Debug.NONE

RE_SIZE = r'B|H|W'
RE_OP = r'|'.join(op.name for op in Op) + '|LDI|LD|ST|SWI|PUSH|POP|CALL|IRET|RET'
RE_COND = r'|'.join(cond.name for cond in Cond)
RE_REG = r'|'.join(reg.name for reg in Reg)

class Token(NamedTuple):
    """Class for tokens in input."""

    type: str #Lex
    lexeme: str
    line: int

    def error(self, msg):
        """Raise error messages for the parser."""
        raise SyntaxError(f'Line {self.line}: {msg}')

TOKENS = {
    'number': r'-?(0x[0-9a-f]+|0b[01]+|\d+)',
    'string': r'"(\\"|[^"])*"',
    'character': r"'(\\'|\\?[^'])'",
    'label': r'\.?[a-z_]\w*\s*:',
    'code': rf'^(?P<op>j(mp)?|{RE_OP})(?P<flag>s)?(?P<cond>{RE_COND})?(\.(?P<width>{RE_SIZE}))?\s',
    'halt': r'^(halt)\b',
    'size': r'\.(byte|half|word)\b',
    'space': r'\.(space)\b',
    'reg': rf'\b({RE_REG})\b',
    'name': r'\.?[a-z_]\w*',
    'symbol': r'<<|>>|[()+*/%^|&=!<>,~-]',
    'end': r'$',
    'error': r'\S+'
}

RE = re.compile('|'.join(rf'(?P<{token}>{pattern})' for token, pattern in TOKENS.items()), re.I)


def lex(text):
    """Produce list of tokens from input."""
    return [Token(match.lastgroup, match.group(), match) for match in RE.finditer(text)]


class Emitter:
    """Class for emitting bit32 objects."""

    def __init__(self):
        self.data = []
        self.instructions = []
        self.labels = []

    def emit_literal(self, label, size, value):
        """Emit labeled literal data."""
        self.labels.append(label)
        if size == Size.BYTE:
            self.new_data(Byte, value)
        elif size == Size.HALF:
            self.new_data(Half, value)
        else:
            self.new_data(Word, value)

    def emit_char(self, label, _, char):
        """Emit literal character data."""
        self.labels.append(label)
        self.new_data(Char, char)

    def emit_string(self, label, string):
        """Emit literal string data."""
        self.labels.append(label)
        for char in string:
            self.new_data(Char, char)

    def emit_space(self, label, size):
        """Emit space data."""
        self.labels.append(label)
        for _ in range(size // Size.WORD):
            self.new_data(Word, 0)
        for _ in range(size % Size.WORD):
            self.new_data(Byte, 0)

    def emit_jump(self, condition, label):
        """Emit jump instruction."""
        self.new_instruction(Jump, condition, False, label)

    def emit_call(self, condition, label):
        """Emit call instruction."""
        self.new_instruction(Jump, condition, True, label)

    def emit_interrupt(self, condition, label):
        """Emit interrupt instruction."""
        self.new_instruction(Interrupt, condition, True, label)

    def emit_unary(self, op, condition, flag, size, destination):
        """Emit unary instruction."""
        assert op in {Op.NOT, Op.NEG, Op.NEGF}
        self.new_instruction(Unary, condition, flag, size, op, destination)

    def emit_binary(self, op, condition, flag, size, destination, source, immediate):
        """Emit binary instruction."""
        assert op not in {Op.NOT, Op.NEG, Op.NEGF}
        self.new_instruction(Binary, condition, flag, size, immediate, op, source, destination)

    def emit_ternary(self, op, condition, flag, size, destination, source, source2, immediate):
        """Emit ternary instruction."""
        assert op not in {Op.MOV, Op.MVN, Op.CMN, Op.CMP, Op.NOT, Op.NEG, Op.TST, Op.TEQ, Op.CMPF}
        self.new_instruction(Ternary, condition, flag, size, immediate, op, source2, source, destination)

    def emit_load(self, condition, size, destination, base, offset, immediate):
        """Emit load instruction."""
        self.new_instruction(Load, condition, size, immediate, False, destination, base, offset)

    def emit_store(self, condition, size, base, offset, destination, immediate):
        """Emit store instruction."""
        self.new_instruction(Load, condition, size, immediate, True, destination, base, offset)

    def emit_store0(self, condition, size, base, destination):
        """Emit store instruction with 0 offset."""
        self.new_instruction(Load, condition, size, True, True, destination, base, 0)

    def emit_load_immediate(self, condition, size, destination, value):
        """Emit load-immediate instruction."""
        self.new_instruction(LoadImmediate, condition, size, destination)
        self.new_instruction(Word, value)

    def emit_push(self, condition, size, destination):
        """Emit push instruction."""
        self.new_instruction(PushPop, condition, size, True, destination)

    def emit_pop(self, condition, size, destination):
        """Emit pop instruction."""
        self.new_instruction(PushPop, condition, size, False, destination)

    def emit_binary_with_name(self, op, condition, flag, size, destination, value):
        """Emit binary instruction with named variable."""
        if -128 <= value < 256:
            self.emit_binary(op, condition, flag, size, destination, value, immediate=True)
        else:
            assert op == Op.MOV, f'{op.name}'
            self.emit_load_immediate(condition, size, destination, value)

    def emit_ternary_with_name(self, op, condition, flag, size, destination, source, value):
        """Emit ternary instruction with named variable."""
        assert -128 <= value < 256
        self.emit_ternary(op, condition, flag, size, destination, source, value, immediate=True)

    def new_instruction(self, instruction, *arguments):
        """Emit a new instruction."""
        self.instructions.append((self.labels, instruction, arguments))
        self.labels = []

    def new_data(self, type, value):
        """Emit a new piece of data."""
        self.data.append((self.labels, type, (value,)))
        self.labels = []


class Assembler:
    """Class for the assembler that parses assembly instructions."""

    def __init__(self):
        self.tokens = []
        self.index = 0
        self.names = {}

    def primary(self):
        """
        PRIMARY -> 'defined' name
                  |'defined' '(' name ')'
                  |name|decimal|number|character|string|'(' EXPRESSION ')'
        """
        if self.accept(Lex.NAME):
            name = next(self)
            if name.lexeme in self.names:
                return self.names[name.lexeme]
            return name.lexeme
        if self.peek(Lex.NUMBER):
            return int(next(self).lexeme)
        if self.peek(Lex.CHARACTER):
            return ord(unescape(next(self).lexeme))
        if self.accept('('):
            primary = self.expression()
            self.expect(')')
            return primary
        self.error('Expected primary expression')

    def unary(self):
        """
        UNARY -> ['-'|'~'|'!'] PRIMARY
        """
        if self.accept('-'):
            return -self.primary()
        if self.accept('~'):
            return ~self.primary()
        return self.primary()

    def multiplicative(self):
        """
        MULTIPLICATIVE -> UNARY {('*', '/', '%') UNARY}
        """
        multiplicative = self.unary()
        while self.peek({'*', '/', '%'}):
            multiplicative = {
                '*': mul,
                '/': floordiv,
                '%': mod
                }[next(self).lexeme](multiplicative, self.unary())
        return multiplicative

    def additive(self):
        """
        ADDITIVE -> MULTIPLICATIVE {('+'|'-') MULTIPLICATIVE}
        """
        additive = self.multiplicative()
        while self.peek({'+', '-'}):
            additive = {
                '+': add,
                '-': sub
                }[next(self).lexeme](additive, self.multiplicative())
        return additive

    def shift(self):
        """
        SHIFT -> ADDITIVE {('<<'|'>>') ADDITIVE}
        """
        shift = self.additive()
        while self.peek({'<<', '>>'}):
            shift = {
                '<<': lshift,
                '>>': rshift
                }[next(self).lexeme](shift, self.additive())
        return shift

    def bitwise_and(self):
        """
        BITWISE_AND -> EQUALITY {'&' EQUALITY}
        """
        bitwise_and = self.shift()
        while self.accept('&'):
            bitwise_and &= self.shift()
        return bitwise_and

    def bitwise_xor(self):
        """
        BITWISE_XOR -> BITWISE_AND {'^' BITWISE_AND}
        """
        bitwise_xor = self.bitwise_and()
        while self.accept('^'):
            bitwise_xor ^= self.bitwise_and()
        return bitwise_xor

    def bitwise_or(self):
        """
        BITWISE_OR -> BITWISE_XOR {'|' BITWISE_XOR}
        """
        bitwise_or = self.bitwise_xor()
        while self.accept('|'):
            bitwise_or |= self.bitwise_xor()
        return bitwise_or

    def expression(self):
        """
        EXPRESSION -> LOGICAL_OR
        """
        return self.bitwise_or()

    def definition(self):
        name = next(self)
        self.expect('=')
        self.names[name.lexeme] = self.expression()

    def size(self):
        return Size[next(self).lexeme.lower()[1:]]

    def string(self):
        return unescape(next(self).lexeme[1:-1])

    def labeled(self, emitter):
        label = next(self)
        # size
        if self.peek('size'):
            emitter.emit_literal(label.lexeme, self.size(), self.expression())
        # string
        elif self.accept('string'):
            emitter.emit_string(label.lexeme, self.string())
        # space
        elif self.peek('space'):
            emitter.emit_string(label.lexeme, self.expression())
        # error
        else:
            self.error()

    def code(self, emitter):
        op, flag, cond, width = ...
        

    def data(self, emitter):
        emitter.new_data(self.size(), self.expression())

    def assemble(self, assembly):
        """Parse and assemble the given assembly code and output bit32 objects."""
        with open('boot.s') as boot:
            assembly = f'{boot.read()}\n{assembly}'
        emitter = Emitter()
        self.names.clear()
        for self.line_no, line in enumerate(map(str.strip, assembly.splitlines())):
            if ';' in line:
                line, comment = map(str.strip, line.split(';', 1))
            if line:
                self.tokens = lex(line)
                self.index = 0
                if self.peek('id'):
                    self.definition()
                elif self.peek('label'):
                    self.labeled(emitter)
                elif self.peek('code'):
                    self.code(emitter)
                else:
                    self.data(emitter)



                if self.match('id', '=', 'const'):
                    name, value = self.matched()
                    self.names[name] = value

                elif self.peek('label'):
                    if self.match('label'):
                        emitter.labels.append(*self.matched())
                    elif self.match('label', 'size', 'const'):
                        emitter.emit_literal(*self.matched())
                    elif self.match('label', 'size', 'id'):
                        emitter.emit_literal(*self.matched())
                    elif self.match('label', 'size', 'char'):
                        emitter.emit_char(*self.matched())
                    elif self.match('label', 'string'):
                        emitter.emit_string(*self.matched())
                    elif self.match('label', 'space', 'const'):
                        emitter.emit_space(*self.matched())
                    elif self.match('label', 'space', 'id'):
                        emitter.emit_space(*self.matched())
                    else:
                        self.error()
                elif self.peek('op'):
                    if self.match('op', 'reg'):
                        emitter.emit_unary(*self.matched())

                    elif self.match('op', 'reg', ',', 'reg'):
                        emitter.emit_binary(*self.matched(), False)
                    elif self.match('op', 'reg', ',', 'const'):
                        emitter.emit_binary(*self.matched(), True)
                    elif self.match('op', 'reg', ',', 'char'):
                        emitter.emit_binary(*self.matched(), True)
                    elif self.match('op', 'reg', ',', 'id'):
                        emitter.emit_binary_with_name(*self.matched())

                    elif self.match('op', 'reg', ',', 'reg', ',', 'reg'):
                        emitter.emit_ternary(*self.matched(), False)
                    elif self.match('op', 'reg', ',', 'reg', ',', 'const'):
                        emitter.emit_ternary(*self.matched(), True)
                    elif self.match('op', 'reg', ',', 'reg', ',', 'char'):
                        emitter.emit_ternary(*self.matched(), True)
                    elif self.match('op', 'reg', ',', 'reg', ',', 'id'):
                        emitter.emit_ternary_with_name(*self.matched())
                    else:
                        self.error()
                else:
                    if self.match('nop'):
                        emitter.emit_jump(Cond.NV, 0)

                    elif self.match('size', 'const') or self.match('size', 'id'):
                        size, value = self.matched()
                        if size == Size.BYTE:
                            emitter.new_data(Byte, value)
                        elif size == Size.HALF:
                            emitter.new_data(Half, value)
                        else:
                            emitter.new_data(Word, value)
                    elif self.match('size', 'char'):
                        size, char = self.matched()
                        emitter.new_data(Char, char)

                    elif self.match('jump', 'id'):
                        emitter.emit_jump(*self.matched())

                    elif self.match('jump', 'reg'):
                        cond, reg = self.matched()
                        emitter.emit_binary(Op.MOV, cond, False, Size.WORD, Reg.PC, reg, False)

                    elif self.match('swi', 'id'):
                        emitter.emit_interrupt(*self.matched())

                    elif self.match('ld', 'reg', ',', '[', 'reg', ',', 'reg', ']'):
                        emitter.emit_load(*self.matched(), False)
                    elif self.match('ld', 'reg', ',', '[', 'reg', ']'):
                        emitter.emit_load(*self.matched(), 0, True)
                    elif self.match('ld', 'reg', ',', '[', 'reg', ',', 'const', ']'):
                        emitter.emit_load(*self.matched(), True)
                    elif self.match('ld', 'reg', ',', '[', 'reg', ',', 'id', ']'):
                        emitter.emit_load(*self.matched(), True)

                    elif self.match('st', '[', 'reg', ',', 'reg', ']', ',', 'reg'):
                        emitter.emit_store(*self.matched(), False)
                    elif self.match('st', '[', 'reg', ']', ',', 'reg'):
                        emitter.emit_store0(*self.matched())
                    elif self.match('st', '[', 'reg', ',', 'const', ']', ',', 'reg'):
                        emitter.emit_store(*self.matched(), True)
                    elif self.match('st', '[', 'reg', ',', 'id', ']', ',', 'reg'):
                        emitter.emit_store(*self.matched(), True)

                    elif self.match('ldi', 'reg', ',', 'const'):
                        emitter.emit_load_immediate(*self.matched())
                    elif self.match('ldi', 'reg', ',', '=', 'id'):
                        emitter.emit_load_immediate(*self.matched())

                    elif self.match('push', 'rd'):
                        emitter.emit_push(*self.matched())
                    elif self.match('pop', 'rd'):
                        emitter.emit_pop(*self.matched())

                    elif self.accept('push'):
                        args = [self.expect('reg')]
                        while self.accept(','):
                            args.append(self.expect('reg'))
                        self.expect('end')
                        for reg in reversed(args):
                            emitter.emit_push(Cond.AL, Size.WORD, reg)

                    elif self.accept('pop'):
                        args = [self.expect('reg')]
                        while self.accept(','):
                            args.append(self.expect('reg'))
                        self.expect('end')
                        for reg in args:
                            emitter.emit_pop(Cond.AL, Size.WORD, reg)

                    elif self.match('call', 'reg'):
                        cond, reg = self.matched()
                        emitter.emit_ternary(Op.ADD, cond, False, Size.WORD, Reg.LR, Reg.PC, 2*Size.WORD, True)
                        emitter.emit_binary(Op.MOV, cond, False, Size.WORD, Reg.PC, reg, False)

                    elif self.match('call', 'id'):
                        emitter.emit_call(*self.matched())

                    elif self.match('ret'):
                        emitter.emit_binary(Op.MOV, *self.matched(), False, Size.WORD, Reg.PC, Reg.LR, False)

                    elif self.match('iret'):
                        emitter.emit_binary(Op.MOV, Cond.AL, False, Size.WORD, Reg.PC, Reg.ILR, False)

                    elif self.match('halt'):
                        emitter.emit_binary(Op.OR, Cond.AL, False, Size.WORD, Reg.SR, Flag.HALT, True)

                    else:
                        print(line)
                        self.error()

        return emitter.instructions + emitter.data

    def translate(self, type, value):
        """Translate matched values from their string values."""
        if type == 'const':
            if value.startswith('0x'):
                return int(value, base=16)
            if value.startswith('0b'):
                return int(value, base=2)
            return int(value)
        if type in {'string', 'char'}:
            return unescape(value[1:-1])
        if type == 'reg':
            return Reg[value.upper()]
        if type == 'label':
            return value[:-1].strip()
        if type == 'id' and value in self.names:
            return self.names[value]
        return value

    def matched(self):
        """Get -important- value matched in match method."""
        for type, value, match in self.tokens:
            if type in {'const', 'string', 'char', 'reg', 'label', 'id'}:
                yield self.translate(type, value)
            elif type == 'op':
                yield Op[match['op_name'].upper()]
                yield Cond.get(match['op_cond'])
                yield bool(match['flag'])
                yield Size.get(match['op_size'])
            elif type == 'jump':
                yield Cond.get(match['jump_cond'])
            elif type == 'int':
                yield Cond.get(match['int_cond'])
            elif type == 'ldi':
                yield Cond.get(match['ldi_cond'])
                yield Size.get(match['ldi_size'])
            elif type == 'ld':
                yield Cond.get(match['ld_cond'])
                yield Size.get(match['ld_size'])
            elif type == 'st':
                yield Cond.get(match['st_cond'])
                yield Size.get(match['st_size'])
            elif type == 'push':
                yield Cond.get(match['push_cond'])
                yield Size.get(match['push_size'])
            elif type == 'pop':
                yield Cond.get(match['pop_cond'])
                yield Size.get(match['pop_size'])
            elif type == 'call':
                yield Cond.get(match['call_cond'])
            elif type == 'ret':
                yield Cond.get(match['ret_cond'])
            elif type == 'size':
                if value.lower() == '.word':
                    yield Size.WORD
                elif value.lower() == '.byte':
                    yield Size.BYTE
                elif value.lower() == '.half':
                    yield Size.HALF

    def match(self, *pattern):
        """Match given pattern."""
        pattern += ('end',)
        return len(self.tokens) == len(pattern) and all(self.peek(symbol, offset=i) for i, symbol in enumerate(pattern))

    def __next__(self):
        """Move parse index forward and return consumed token value."""
        type, value, _ = self.tokens[self.index]
        self.index += 1
        return self.translate(type, value)

    def peek(self, symbol, offset=0):
        """Peek at the next token to confirm correct desired symbol."""
        type, value, _ = self.tokens[self.index+offset]
        return type == symbol or (not value.isalnum() and value == symbol)

    def accept(self, symbol):
        """Accept and return next token if it is the correct desired symbol."""
        if self.peek(symbol):
            return next(self)

    def expect(self, symbol):
        """Expect given symbol as the next token. Raise error if not."""
        if self.peek(symbol):
            return next(self)
        self.error()

    def error(self):
        """Raise syntax error if one is found while parsing tokens."""
        etype, evalue, _ = self.tokens[self.index]
        raise SyntaxError(f'Unexpected {etype} token "{evalue}" at token #{self.index} in line {self.line_no+1}')


def link(objects):
    """Link assembled objects and assign labels addresses."""
    targets = {}
    indices = set()
    addr = 0
    for i, (labels, type, args) in enumerate(objects):
        for label in labels:
            if label in targets:
                print(f'{repl("Warning", Color.RED)}: label collision "{label}"')
            targets[label] = addr
            indices.add(addr)
        objects[i] = (type, args)
        addr += type.size
    print(f'Heap starts at address 0x{addr:08x}')
    targets['stdheap'] = addr
    contents = []
    i = 0
    if DEBUG & Debug.OBJECT_FILE:
        file = open('assemblylog.txt', 'w+')
    for type, args in objects:
        if args and type is not Char:
            *args, last = args
            if isinstance(last, str):
                last = targets[last]
                if type is Jump:
                    last -= i
            args = *args, last
        data = type(*args)
        contents.append(data.little_end())
        if DEBUG & Debug.OBJECT_FILE:
            print(f'{i:06x}:', data.str, file=file)
        if DEBUG & Debug.FULL:
            print('>>' if i in indices else '  ', f'{i:06x}:', f'{data.str: <20}', f'| {data.format_dec(): <23}', f'{data.format_bin(): <40}', data.hex())
        elif DEBUG & Debug.SHORT:
            print('>>' if i in indices else '  ', f'{i:08x}:', f'{data.little_end(): <11}', f'| {data.str: <20}')
        i += type.size
    if DEBUG & Debug.OBJECT_FILE:
        file.close()
    if DEBUG & Debug.PRINT_BYTES:
        print('\n'+' '.join(contents))
    print('Interrupt Vector:', '0x'+Interrupt(Cond.AL, False, targets['interrupt_handler']).hex())
    print(repl('\nSuccess!', Color.GREEN), len(contents), 'items.', i, 'bytes')
    return contents


class Color(IntEnum):
    """Enum class for colors used in sntax highlighting."""

    GREY = 8
    RED = 9
    GREEN = 10
    ORANGE = 11
    BLUE = 12
    PURPLE = 13
    CYAN = 14
    WHITE = 15


# ANSI 8-bit color mode (look it up)
PATTERNS = {
    r'"(\\"|[^"])*"': Color.GREEN,  # string
    r"'(\\'|\\?[^'])'": Color.GREEN,  # char
    r'\b-?(0x[0-9a-f]+|0b[01]+|\d+)\b': Color.ORANGE,  # const
    rf'\b({RE_REG})\b': Color.WHITE,  # register
    r'\b(nop)\b': Color.BLUE,
    rf'\b({RE_OP})({RE_COND})?s?(\.({RE_SIZE}))?\b': Color.BLUE,  # ops
    rf'\b(call|ret|halt|j(mp)?)({RE_COND})?\b': Color.BLUE,  # ops
    rf'\b(ldi|ld|st|push|pop)({RE_COND})?(\.({RE_SIZE}))?\b': Color.BLUE,  # ops
    r'\.(byte|half|word|space)\b': Color.BLUE,  # size|space
    r'\.?[a-z_]\w*': Color.CYAN,  # id
    r';.*$': Color.GREY  # comment
}


def repl(text, color):
    """Replace given text with highlighted text."""
    if color:
        return f'\33[38;5;{color}m{text}\33[0m'
    return text


def display(assembly):
    """Display highlighted assemgly code."""
    for line in assembly.split('\n'):
        new = ''
        while line:
            for pattern, color in PATTERNS.items():
                match = re.match(pattern, line, re.I)
                if match:
                    new += repl(match[0], color)
                    line = line[len(match[0]):]
                    break
            if match is None:
                new += line[0]
                line = line[1:]
        print(new)


def assemble(program, fflag=True, name='out'):
    """Wrapper function for assembling."""
    if program.endswith('.s'):
        name = program[:-2]
        with open(program) as file:
            program = file.read()
    assembler = Assembler()
    objects = assembler.assemble(program)
    bit32 = link(objects)
    if fflag:
        with open(f'{name}.bit32', 'w+') as file:
            file.write('v2.0 raw\n' + ' '.join(bit32))


if __name__ == '__main__':
    assembly = '''
    main:
    loop:
        JMP loop
        RET
    '''
    assemble(assembly)
