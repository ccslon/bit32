# -*- coding: utf-8 -*-
"""
Created on Wed Aug  7 11:50:55 2024

@author: ccslon
"""

from enum import IntEnum

def negative(num, base):
    return (-num ^ (2**base - 1)) + 1

class Size(IntEnum):
    BYTE = B = 1
    HALF = H = 2
    WORD = W = 4
    @classmethod
    def get(cls, name):
        return cls[name.upper()] if name else cls.WORD
    def display(self):
        return f'.{self.name[0]}' if self != Size.WORD else ''

class Flag(IntEnum):
    Z = 0b00000001
    N = 0b00000010
    V = 0b00000100
    C = 0b00001000
    HALT = 0b00010000
    INT_EN = 0b00100000

class Reg(IntEnum):
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
    SP = 11
    SR = 12
    ILR = 13
    LR = 14
    PC = 15

class Op(IntEnum):
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
        return cls[name.upper()] if name else cls.AL
    def display(self):
        return self.name if self != self.AL else ''
    def display_jump(self):
        return self.name if self != self.AL else 'MP'

class InstOp(IntEnum):
    JUMP = 0
    INT = 1
    ALU = 2
    LOAD = 4
    STACK = 6
    WORD = 7

ESCAPE = {
    '\0': r'\0',
    '\"': r'\"',
    '\'': r'\'',
    '\n': r'\n',
    '\t': r'\t',
    '\b': r'\b',
    '\\': r'\\'
}
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
    for k, v in UNESCAPE.items():
        text = text.replace(k, v)
    return text

def escape(char):
    return ESCAPE.get(char, char)

class Data:
    size = Size.WORD
    def __init__(self):
        self.bin = 0
        self.dec = []
    def __setitem__(self, item, value):
        if isinstance(item, slice):
            self.bin |= (value or 0) << item.stop
            self.dec.append((value, item.start-item.stop+1))
        else:
            self.bin |= (value or 0) << item
            self.dec.append((value, 1))
    def little_end(self):
        return f'{self.bin & 0xff:02x} {self.bin>>8 & 0xff:02x} {self.bin>>16 & 0xff:02x} {self.bin>>24 & 0xff:02x}'
    def hex(self):
        return f'{self.bin:08x}'
    def format_bin(self):
        return ' '.join('X'*size if value is None else f'{value:0{size}b}' for value, size in self.dec)
    def format_dec(self):
        return ' '.join('0' if value is None else f'{value:d}' for value, _ in self.dec)

class Byte(Data):
    size = Size.BYTE
    def __init__(self, byte):
        super().__init__()
        if byte < 0:
            byte = negative(byte, 8)
        self[7:0] = byte
        self.str = f'0x{byte:02x}'
    def little_end(self):
        return f'{self.bin & 0xff:02x}'
    def hex(self):
        return f'{self.bin:02x}'

class Char(Byte):
    def __init__(self, char):
        super().__init__(ord(char))
        assert 0 <= ord(char) < 128
        self[7:0] = ord(char)
        self.str = f"'{escape(char)}'"

class Half(Data):
    size = Size.HALF
    def __init__(self, half):
        super().__init__()
        if half < 0:
            half = negative(half, 16)
        self[15:0] = half
        self.str = f'0x{half:04x}'
    def little_end(self):
        return f'{self.bin & 0xff:02x} {self.bin>>8 & 0xff:02x}'
    def hex(self):
        return f'{self.bin:04x}'

class Word(Data):
    def __init__(self, word):
        super().__init__()
        if word < 0:
            word = negative(word, 32)
        self[31:0] = word
        self.str = f'0x{word:08x}'

class Inst(Data):
    pass

class Jump(Inst):
    def __init__(self, cond, link, offset24):
        super().__init__()
        self[31:28] = cond
        self[27] = link
        self[26:24] = InstOp.JUMP
        op = f'CALL{cond.display()}' if link else f'J{cond.display_jump()}'
        if offset24 < 0:
            self.str = f'{op} -0x{-offset24:06X}'
            offset24 = negative(offset24, 24)
        else:
            self.str = f'{op} 0x{offset24:06X}'
        self[23:0] = offset24


class Interrupt(Inst):
    def __init__(self, cond, software, code24):
        super().__init__()
        self[31:28] = cond
        self[27] = software
        self[26:24] = InstOp.INT
        self[23:0] = code24
        self.str = f'INT{cond.display()} 0x{code24:06X}'

class Unary(Inst):
    def __init__(self, cond, flag, size, op, rd):
        super().__init__()
        self[31:28] = cond
        self[27] = flag
        self[26:24] = InstOp.ALU
        self[23:22] = size >> 1
        self[21:17] = op
        self[16:12] = None
        self[11:8] = rd
        self[7:4] = rd
        self[3:0] = rd
        self.str = f'{op.name}{cond.display()}{"S"*flag}.{size.name[0]} {rd.name}'

class Binary(Inst):
    def __init__(self, cond, flag, size, imm, op, src, rd):
        super().__init__()
        self[31:28] = cond
        self[27] = flag if op != Op.CMPF else True
        self[26:24] = InstOp.ALU | imm
        self[23:22] = size >> 1
        self[21:17] = op
        if imm:
            if isinstance(src, str):
                self[16] = True
                self[15:8] = ord(src)
                src = f"'{escape(src)}'"
            else:
                assert -128 <= src < 256
                if src < 0:
                    self[16] = False
                    self[15:8] = negative(src, 8)
                else:
                    self[16] = True
                    self[15:8] = src
        else:
            self[16:12] = None
            self[11:8] = src
            src = src.name
        self[7:4] = rd
        self[3:0] = rd
        self.str = f"{op.name}{cond.display()}{'S'*flag}.{size.name[0]} {rd.name}, {src}"

class Ternary(Inst):
    def __init__(self, cond, flag, size, imm, op, src, rs, rd):
        super().__init__()
        self[31:28] = cond
        self[27] = flag
        self[26:24] = InstOp.ALU | imm
        self[23:22] = size >> 1
        self[21:17] = op
        if imm:
            self[16] = None
            if isinstance(src, str):
                self[15:8] = ord(src)
                src = f"'{escape(src)}'"
            else:
                assert 0 <= src < 256
                self[15:8] = src
        else:
            self[16:12] = None
            self[11:8] = src
            src = src.name
        self[7:4] = rs
        self[3:0] = rd
        self.str = f'{op.name}{cond.display()}{"S"*flag}.{size.name[0]} {rd.name}, {rs.name}, {src}'

class Load(Inst):
    def __init__(self, cond, size, imm, storing, rd, rb, offset):
        super().__init__()
        self[31:28] = cond
        self[27] = storing
        self[26:24] = InstOp.LOAD | imm
        self[23:22] = size >> 1
        if imm:
            assert -128 <= offset < 256
            self[21:17] = None
            if offset < 0:
                self[16] = False
                offset = negative(offset, 8)
            else:
                self[16] = True
            self[15:8] = offset
        else:
            self[21:12] = None
            self[11:8] = offset
            offset = offset.name
        self[7:4] = rb
        self[3:0] = rd
        if storing:
            self.str = f'ST{cond.display()}.{size.name[0]} [{rb.name}, {offset}], {rd.name}'
        else:
            self.str = f'LD{cond.display()}.{size.name[0]} {rd.name}, [{rb.name}, {offset}]'

class PushPop(Inst):
    def __init__(self, cond, size, pushing, rd):
        super().__init__()
        self[31:28] = cond
        op = 'PUSH' if pushing else 'POP'
        self[27] = pushing
        self[26:24] = InstOp.STACK
        self[23:22] = size >> 1
        self[21:17] = None
        if pushing:
            self[16] = False
            self[15:8] = negative(-size, 8)
        else:
            self[16] = True
            self[15:8] = size
        self[7:4] = None
        self[3:0] = rd
        self.str = f'{op}{cond.display()}.{size.name[0]} {rd.name}'

class LoadImm(Inst):
    def __init__(self, cond, size, rd, link=None):
        super().__init__()
        self[31:28] = cond
        self[27] = link
        self[26:24] = InstOp.WORD
        self[23:22] = size >> 1
        self[21:4] = None
        self[3:0] = rd
        self.str = f'LDI{cond.display()}.{size.name[0]} {rd.name}, ...'