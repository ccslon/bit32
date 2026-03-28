# -*- coding: utf-8 -*-
"""
Created on Fri Oct  3 09:36:40 2025

@author: ccslon
"""
from enum import Enum, IntEnum, auto
from typing import NamedTuple
from operator import add, sub, mul, floordiv, mod, lshift, rshift
import re

from bit32 import Size, Flag, Reg, Op, Cond, Byte, Char, Half, Word, Jump, Interrupt, Unary, Binary, Ternary, Load, PushPop, LoadImmediate, unescape


RE_SIZE = r'B|H|W'
RE_OP = r'|'.join(op.name for op in Op) + '|NOP|LDI?|ST|SWI|PUSH|POP|CALL|I?RET|HALT'
RE_COND = r'|'.join(cond.name for cond in Cond)
RE_REG = r'|'.join(reg.name for reg in Reg)

class Lex(Enum):
    """Enum class for token types."""

    NUMBER = auto()
    CHARACTER = auto()
    STRING = auto()
    LABEL = auto()
    CODE = auto()
    SIZE = auto()
    SPACE = auto()
    REG = auto()
    NAME = auto()
    SYMBOL = auto()
    END = auto()


class Token(NamedTuple):
    """Class for tokens in input."""

    type: Lex
    lexeme: str
    match: re.Match


TOKENS = {
    'NUMBER': r'-?(0x[0-9A-F]+|0b[01]+|\d+)',
    'CHARACTER': r"'(\\'|\\?[^'])'",
    'STRING': r'"(\\"|[^"])*"',
    'LABEL': r'\.?[A-Z_]\w*\s*:',
    'CODE': rf'^(?P<op>J(MP)?|{RE_OP})(?P<flag>S)?(?P<cond>{RE_COND})?(\.(?P<size>{RE_SIZE}))?\b',
    'SIZE': r'\.(BYTE|HALF|WORD)\b',
    'SPACE': r'\.(SPACE)\b',
    'REG': rf'\b({RE_REG})\b',
    'NAME': r'\.?[A-Z_]\w*',
    'SYMBOL': r'<<|>>|[]()+*/%^|&=!<>,[~-]',
    'END': r'$',
    'ERROR': r'\S'
}

RE = re.compile('|'.join(rf'(?P<{token}>{pattern})' for token, pattern in TOKENS.items()), re.I)


def lex(text):
    """Produce list of tokens from input."""
    return [Token(Lex[match.lastgroup], match.group(), match) for match in RE.finditer(text)]


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
        if immediate and isinstance(source, int) and not (-128 <= source < 256):
            assert op is Op.MOV
            self.emit_load_immediate(condition, size, destination, source)
        else:
            self.new_instruction(Binary, condition, flag, size, immediate, op, source, destination)

    def emit_ternary(self, op, condition, flag, size, destination, source, source2, immediate):
        """Emit ternary instruction."""
        assert op not in {Op.MOV, Op.MVN, Op.CMN, Op.CMP, Op.NOT, Op.NEG, Op.TST, Op.TEQ, Op.CMPF}
        if immediate:
            assert -128 <= source2 < 256
        self.new_instruction(Ternary, condition, flag, size, immediate, op, source2, source, destination)

    def emit_load(self, condition, size, destination, base, offset, immediate):
        """Emit load instruction."""
        self.new_instruction(Load, condition, size, immediate, False, destination, base, offset)

    def emit_store(self, condition, size, base, offset, destination, immediate):
        """Emit store instruction."""
        self.new_instruction(Load, condition, size, immediate, True, destination, base, offset)

    def emit_push(self, condition, size, destination):
        """Emit push instruction."""
        self.new_instruction(PushPop, condition, size, True, destination)

    def emit_pop(self, condition, size, destination):
        """Emit pop instruction."""
        self.new_instruction(PushPop, condition, size, False, destination)

    def emit_load_immediate(self, condition, size, destination, value):
        """Emit load-immediate instruction."""
        self.new_instruction(LoadImmediate, condition, size, destination)
        self.new_instruction(Word, value)

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
        PRIMARY -> name|number|character|'(' EXPRESSION ')'
        """
        if self.peek(Lex.NAME):
            name = next(self).lexeme
            if name in self.names:
                return self.names[name]
            return name
        if self.peek(Lex.NUMBER):
            value = next(self).lexeme
            if value.startswith('0x'):
                return int(value, base=16)
            if value.startswith('0b'):
                return int(value, base=2)
            return int(value)
        if self.peek(Lex.CHARACTER):
            return ord(unescape(next(self).lexeme[1:-1]))
        if self.accept('('):
            primary = self.expression()
            self.expect(')')
            return primary
        self.error("Expected name, number, character, or '('")

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
        BITWISE_AND -> SHIFT {'&' SHIFT}
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
        EXPRESSION -> BITWISE_OR
        """
        try:
            return self.bitwise_or()
        except TypeError:
            self.error('Did you forget to declare a variable?')

    def definition(self):
        """
        DEFINITION -> name '=' EXPRESSION
        """
        name = next(self).lexeme
        self.expect('=')
        self.names[name] = self.expression()

    def size(self):
        """
        SIZE -> size
        """
        return {'BYTE': Byte,
                'HALF': Half,
                'WORD': Word}[next(self).lexeme.upper()[1:]]

    def string(self):
        """
        STRING -> string
        """
        return unescape(next(self).lexeme[1:-1])

    def labeled(self, emitter):
        """
        LABELED -> LABEL ':' [(SIZE|space) EXPRESSION|STRING]
        """
        label = next(self).lexeme[:-1].strip()
        if self.peek(Lex.SIZE):
            emitter.emit_literal(label, self.size(), self.expression())
        elif self.accept(Lex.SPACE):
            emitter.emit_space(label, self.expression())
        elif self.peek(Lex.STRING):
            emitter.emit_string(label, self.string())
        else:
            emitter.labels.append(label)

    def reg(self):
        """
        REG -> reg
        """
        return Reg[self.expect(Lex.REG).lexeme]

    def label(self):
        """
        LABEL -> name
        """
        return self.expect(Lex.NAME).lexeme

    def code(self, emitter):
        """
        CODE -> 'nop'|JUMP|CALL|LOAD|STORE|PUSH|POP|LOAD_IMM|RET...

        """
        op, flag, cond, size = next(self).match.group('op', 'flag', 'cond', 'size')
        op = op.upper()
        cond = Cond.get(cond)
        size = Size.get(size)
        if op == 'NOP':
            emitter.emit_jump(Cond.NV, 0)
        elif op in {'J', 'JMP'}:
            assert flag is None
            assert size is Size.WORD
            if self.peek(Lex.NAME):
                emitter.emit_jump(cond, self.label())
            elif self.peek(Lex.REG):
                emitter.emit_binary(Op.MOV, cond, False, Size.WORD, Reg.PC, self.reg(), False)
            else:
                self.error('JMP instruction expects label or register')
        elif op == 'LD':
            target = self.reg()
            self.expect(',')
            self.expect('[')
            base = self.reg()
            imm = True
            if self.accept(','):
                if self.peek(Lex.REG):
                    imm = False
                    offset = self.reg()
                else:
                    offset = self.expression()
            else:
                offset = 0
            self.expect(']')
            emitter.emit_load(cond, size, target, base, offset, imm)
        elif op == 'ST':
            self.expect('[')
            base = self.reg()
            imm = True
            if self.accept(','):
                if self.peek(Lex.REG):
                    imm = False
                    offset = self.reg()
                else:
                    offset = self.expression()
            else:
                offset = 0
            self.expect(']')
            self.expect(',')
            target = self.reg()
            emitter.emit_store(cond, size, base, offset, target, imm)
        elif op == 'PUSH':
            args = [self.reg()]
            while self.accept(','):
                args.append(self.reg())
            for reg in reversed(args):
                emitter.emit_push(Cond.AL, Size.WORD, reg)
        elif op == 'POP':
            args = [self.reg()]
            while self.accept(','):
                args.append(self.reg())
            for reg in args:
                emitter.emit_pop(Cond.AL, Size.WORD, reg)
        elif op == 'LDI':
            target = self.reg()
            self.expect(',')
            emitter.emit_load_immediate(cond, size, target, self.label() if self.accept('=') else self.expression())
        elif op == 'CALL':
            if self.peek(Lex.REG):
                emitter.emit_ternary(Op.ADD, cond, False, Size.WORD, Reg.LR, Reg.PC, 2*Size.WORD, True)
                emitter.emit_binary(Op.MOV, cond, False, Size.WORD, Reg.PC, self.reg(), False)
            else:
                emitter.emit_call(cond, self.label())
        elif op == 'RET':
            emitter.emit_binary(Op.MOV, cond, False, Size.WORD, Reg.PC, Reg.LR, False)
        elif op == 'IRET':
            emitter.emit_binary(Op.MOV, Cond.AL, False, Size.WORD, Reg.PC, Reg.ILR, False)
        elif op == 'HALT':
            emitter.emit_binary(Op.OR, cond, False, Size.WORD, Reg.SR, Flag.HALT, True)
        elif op == 'SWI':
            emitter.emit_interrupt(cond, self.label())
        else:
            op = Op[op]
            flag = bool(flag)
            target = self.reg()
            if self.accept(','):
                if self.peek(Lex.REG):
                    source = self.reg()
                    if self.accept(','):
                        if self.peek(Lex.REG):
                            imm = False
                            source2 = self.reg()
                        else:
                            imm = True
                            source2 = self.expression()
                        emitter.emit_ternary(op, cond, flag, size, target, source, source2, imm)
                    else:
                        emitter.emit_binary(op, cond, flag, size, target, source, False)
                else:
                    emitter.emit_binary(op, cond, flag, size, target, self.expression(), True)
            else:
                emitter.emit_unary(op, cond, flag, size, target)

    def data(self, emitter):
        """
        DATA -> SIZE EXPRESSION
        """
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
                if self.peek(Lex.NAME):
                    self.definition()
                elif self.peek(Lex.LABEL):
                    self.labeled(emitter)
                elif self.peek(Lex.CODE):
                    self.code(emitter)
                else:
                    self.data(emitter)
                self.expect(Lex.END)
        return emitter.instructions + emitter.data

    def __next__(self):
        """Move parse index forward and return consumed token value."""
        token = self.tokens[self.index]
        self.index += 1
        return token

    def peek(self, peek, offset=0):
        """Peek at the next token to confirm correct desired symbol."""
        token = self.tokens[self.index+offset]
        if isinstance(peek, set):
            return (token.type in peek
                    or token.type is Lex.SYMBOL and token.lexeme in peek)
        return (token.type is peek
                or token.type is Lex.SYMBOL and token.lexeme == peek)

    def accept(self, symbol):
        """Accept and return next token if it is the correct desired symbol."""
        if self.peek(symbol):
            return next(self)

    def expect(self, symbol):
        """Expect given symbol as the next token. Raise error if not."""
        if self.peek(symbol):
            return next(self)
        self.error(f'Expected {symbol}')

    def error(self, message=''):
        """Raise syntax error if one is found while parsing tokens."""
        error = self.tokens[self.index]
        raise SyntaxError(f'Line {self.line_no+1}: Unexpected {error.type} token "{error.lexeme}". {message}')


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
        i += type.size
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
    r'\.?[a-z_]\w*': Color.CYAN,  # name
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
    try:
        objects = assembler.assemble(program)
    except SyntaxError as error:
        return print(error)
    # objects = assembler.assemble(program)
    bit32 = link(objects)
    if fflag:
        with open(f'{name}.bit32', 'w+') as file:
            file.write('v2.0 raw\n' + ' '.join(bit32))


if __name__ == '__main__':
    assembly = '''
    MYSIZE = 32
    main:
        OR A, MYSIZE - 1
    loop:
        JMP loop
        RET
    '''
    assemble(assembly)
