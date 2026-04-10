# -*- coding: utf-8 -*-
"""
Created on Wed Aug  7 11:50:55 2024

@author: ccslon
"""

from enum import IntEnum
from struct import pack


def twos_compliment(number, bits):
    """Make a 2's compliment binary number."""
    if number < 0:
        return (-number ^ (2**bits - 1)) + 1
    return number & (2**bits - 1)


def floating_point(i):
    """Convert to floating point number (big endian)."""
    return int.from_bytes(pack('>f', float(i)), 'big')


class Size(IntEnum):
    """Enum class for the different data sizes the bit32 CPU supports."""

    BYTE = B = 1
    HALF = H = 2  # 2 bytes
    WORD = W = 4  # 4 bytes

    @classmethod
    def get(cls, name):
        """Get an size enum based on the given name. Default to Word."""
        return cls[name.upper()] if name else cls.WORD

    def __str__(self):
        """Get size string representation."""
        return f'.{self.name[0]}' if self != Size.WORD else ''


class Flag(IntEnum):
    """Enum class for CPU status register flags."""

    Z =         0b00000001  # zero flag
    N =         0b00000010  # negative flag
    V =         0b00000100  # overflow flag
    C =         0b00001000  # carry bit
    HALT =      0b00010000  # halt
    INT_EN =    0b00100000  # interrupt enable


class Reg(IntEnum):
    """Enum for the registers found in the bit32 CPU."""

    A = 0
    B = 1
    C = 2
    D = 3
    E = 4
    F = 5
    G = 6
    H = 7
    I = 8
    J = 9
    K = 10
    SP = 11     # stack pointer
    SR = 12     # status register
    ILR = 13    # interrupt link register
    LR = 14     # link register
    PC = 15     # program counter

    @classmethod
    def max_reg(cls, reg):
        """Ignore register if not scratch register."""
        return reg if reg < Reg.SP else cls.A

    def __str__(self):
        """Get register string representation."""
        return self.name


class Op(IntEnum):
    """Enum class for all of the bit32 ALU operations."""

    MOV = 0
    ADD = 1
    ADC = 2
    CMN = 3
    MVN = 4
    SUB = 5
    SBC = 6
    CMP = 7
    NOT = 8
    NEG = 9
    AND = 10
    TST = 11
    OR = 12
    # = 13
    XOR = 14
    TEQ = 15
    ITF = 16
    ADDF = 17
    SUBF = 18
    CMPF = 19
    FTI = 20
    NEGF = 21
    MULF = 22
    DIVF = 23
    MUL = 24
    DIV = 25
    MOD = 26
    SHR = 27
    SHL = 28
    ASL = 29
    ROR = 30
    ROL = 31


class Cond(IntEnum):
    """Enum class for the different instruction conditions."""

    NV = 0
    EQ = 1
    NE = 2
    MI = 3
    PL = 4
    VS = 5
    VC = 6
    CS = HS = 7
    CC = LO = 8
    HI = 9
    LS = 10
    LE = 11
    LT = 12
    GT = 13
    GE = 14
    AL = 15

    @classmethod
    def get(cls, name):
        """Get an condition enum based on the given name. Default to Always."""
        return cls[name.upper()] if name else cls.AL

    def jump(self):
        """Get special formatting for Jump instructions."""
        return self.name if self != self.AL else 'MP'

    def __str__(self):
        """Get condition string representation."""
        return self.name if self != self.AL else ''


ESCAPE = {
    '\0': r'\0',
    '\n': r'\n',
    '\t': r'\t',
    '\b': r'\b',
    '\\': r'\\'
}
ESCAPE_CHR = {'\'': r'\''} | ESCAPE
ESCAPE_STR = {'\"': r'\"'} | ESCAPE

def escape_chr(char):
    return ESCAPE_CHR.get(char, char)

def escape_str(text):
    """Escape given string."""
    return ''.join(ESCAPE_STR.get(char, char) for char in text)


UNESCAPE = {
    r'\0': '\0',
    r'\"': '\"',
    r'\'': '\'',
    r'\n': '\n',
    r'\t': '\t',
    r'\b': '\b',
    r'\\': '\\'
}

def unescape(text):
    """Interpret escaped characters and replace with ascii value."""
    for k, v in UNESCAPE.items():
        text = text.replace(k, v)
    return text


class Data:
    """Base class for any piece of data in bit32 memory."""

    size = Size.WORD

    def __init__(self):
        self.bin = 0

    def little_end(self):
        """Produce little endian representaion for this instance of data."""
        return f'{self.bin & 0xff:02x} {self.bin>>8 & 0xff:02x} {self.bin>>16 & 0xff:02x} {self.bin>>24 & 0xff:02x}'

    def hex(self):
        """Produce 32 bit hex representation for this instance of data."""
        return f'{self.bin:08x}'

    def __setitem__(self, item, value):
        """
        Override of __setitem__.

        Allows for syntactical sugar in derived classes.
        """
        if isinstance(item, slice):
            self.bin |= ((value or 0) & (1 << (item.start-item.stop+1)) - 1) << item.stop
        else:
            self.bin |= ((value or 0) & 1) << item


class ByteBase(Data):
    """Base class for single bytes."""

    size = Size.BYTE

    def little_end(self):
        """Produce little endian representaion for this byte."""
        return f'{self.bin & 0xff:02x}'

    def hex(self):
        """Produde 8 bit hex representation for this byte."""
        return f'{self.bin:02x}'


class Byte(ByteBase):
    """Class for single bytes."""

    def __init__(self, byte):
        super().__init__()
        self[7:0] = twos_compliment(byte, 8)


class Char(ByteBase):
    """Byte derived class specifically for ascii characters."""

    def __init__(self, char):
        super().__init__()
        assert 0 <= ord(char) < 128
        self[7:0] = ord(char)


class Half(Data):
    """Class for half-word sized data (2 bytes)."""

    size = Size.HALF

    def __init__(self, half):
        super().__init__()
        self[15:0] = twos_compliment(half, 16)

    def little_end(self):
        """Produce little endian representaion for this half-word."""
        return f'{self.bin & 0xff:02x} {self.bin>>8 & 0xff:02x}'

    def hex(self):
        """Produde 16 bit hex representation for this half-word."""
        return f'{self.bin:04x}'


class Word(Data):
    """Class for word sized data (4 bytes)."""

    def __init__(self, word):
        super().__init__()
        self[31:0] = twos_compliment(word, 32)


class Code(IntEnum):
    """Enum for the different instruction types."""

    JUMP = 0
    INTERRUPT = 1
    ALU = 2
    LOAD = 4
    STACK = 6
    WORD = 7


class Instruction(Data):
    """Base class for bit32 instructions."""


class Jump(Instruction):
    """Class for Jump instructions."""

    def __init__(self, cond, link, offset24):
        super().__init__()
        self[31:28] = cond
        self[27] = link
        self[26:24] = Code.JUMP
        self[23:0] = twos_compliment(offset24, 24)


class Interrupt(Instruction):
    """Class for interrupt instructions."""

    def __init__(self, cond, software, code24):
        super().__init__()
        self[31:28] = cond
        self[27] = software
        self[26:24] = Code.INTERRUPT
        self[23:0] = code24


class Unary(Instruction):
    """Class for unary ALU instructions."""

    def __init__(self, cond, flag, size, op, rd):
        super().__init__()
        self[31:28] = cond
        self[27] = flag
        self[26:24] = Code.ALU
        self[23:22] = size >> 1
        self[21:17] = op
        self[16:12] = None
        self[11:8] = rd
        self[7:4] = rd
        self[3:0] = rd


class Binary(Instruction):
    """Class for binary ALU instructions."""

    def __init__(self, cond, flag, size, imm, op, src, rd):
        super().__init__()
        self[31:28] = cond
        self[27] = op is Op.CMPF or flag
        self[26:24] = Code.ALU | imm
        self[23:22] = size >> 1
        self[21:17] = op
        if imm:
            if isinstance(src, str):
                self[16] = True
                self[15:8] = ord(src)
            else:
                assert -128 <= src < 256
                self[16] = src >= 0
                self[15:8] = twos_compliment(src, 8)
        else:
            self[16:12] = None
            self[11:8] = src
        self[7:4] = rd
        self[3:0] = rd


class Ternary(Instruction):
    """Class for ternary ALU instructions."""

    def __init__(self, cond, flag, size, imm, op, src, rs, rd):
        super().__init__()
        self[31:28] = cond
        self[27] = flag
        self[26:24] = Code.ALU | imm
        self[23:22] = size >> 1
        self[21:17] = op
        if imm:
            self[16] = None
            if isinstance(src, str):
                self[15:8] = ord(src)
            else:
                assert 0 <= src < 256
                self[15:8] = src
        else:
            self[16:12] = None
            self[11:8] = src
        self[7:4] = rs
        self[3:0] = rd


class Load(Instruction):
    """Class for load and store instructions."""

    def __init__(self, cond, size, imm, storing, rd, rb, offset):
        super().__init__()
        self[31:28] = cond
        self[27] = storing
        self[26:24] = Code.LOAD | imm
        self[23:22] = size >> 1
        if imm:
            assert -128 <= offset < 256
            self[21:17] = None
            self[16] = offset >= 0
            self[15:8] = twos_compliment(offset, 8)
        else:
            self[21:12] = None
            self[11:8] = offset
        self[7:4] = rb
        self[3:0] = rd


class PushPop(Instruction):
    """Class for push and pop instructions."""

    def __init__(self, cond, size, pushing, rd):
        super().__init__()
        self[31:28] = cond
        self[27] = pushing
        self[26:24] = Code.STACK
        self[23:22] = size >> 1
        self[21:17] = None
        self[16] = not pushing
        self[15:8] = twos_compliment((-1)**pushing * size, 8)
        self[7:4] = None
        self[3:0] = rd


class LoadImmediate(Instruction):
    """Class for load-immediate instruction."""

    def __init__(self, cond, size, rd, link=None):
        super().__init__()
        self[31:28] = cond
        self[27] = link
        self[26:24] = Code.WORD
        self[23:22] = size >> 1
        self[21:4] = None
        self[3:0] = rd
