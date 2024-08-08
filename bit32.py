# -*- coding: utf-8 -*-
"""
Created on Wed Aug  7 11:50:55 2024

@author: ccslon
"""

from enum import IntEnum

def negative(num, base):
    return (-num ^ (2**base - 1)) + 1

class Size(IntEnum):
    B = 0
    H = 1
    W = 2

class Reg(IntEnum):
    A = 0
    B = 1
    C = 2
    D = 3
    E = 4
    F = 5
    G = 6
    H = 7
    LR = 12
    FP = 13
    SP = 14
    PC = 15
    
class FReg(IntEnum):
    F0 = FA = 8
    F1 = FB = 9
    F2 = FC = 10
    F3 = FD = 11

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
    MULF = 19
    DIVF = 20
    NEGF = 21
    #CMPF = 22
    FTI = 23
    MUL = 24
    DIV = 25
    MOD = 26
    SHL = 27
    SHR = 28
    ASL = 29
    ROL = 30
    ROR = 31
    
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
    LT = 11
    GE = 12
    LE = 13
    GT = 14
    AL = 15
    
ESCAPE = {
    '\0': r'\0',
    '\t': r'\t',
    '\n': r'\n',
    '\b': r'\b',
    '\\': r'\\'
}
UNESCAPE = {
    r'\n': '\n',
    r'\0': '\0',
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
    def __int__(self):
        return int(''.join(self.bin).replace('X','0'), base=2)
    def little_end(self):
        bin = int(self)
        return f'{bin&0xff:02x} {(bin&0xff00) >> 8:02x} {(bin&0xff0000) >> 16:02x} {(bin&0xff000000) >> 24:02x}'
    def hex(self):
        return f'{int(self):04x}'
    def format_bin(self):
        return ' '.join(self.bin)
    def format_dec(self):
        return ' '.join(map(str,self.dec)) #map(int,self.dec)))

class Byte(Data):
    pass

class Half(Data):
    pass

class Word(Data):
    pass

class Char(Byte):
    pass

class Inst(Word):
    pass

class Jump(Inst):
    def __init__(self, cond, offset24):
        #assert -256 <= offset24 < 256
        if offset24 < 0:
            self.str = f'J{cond.name} -0x{-offset24:06X}'
        else:
            self.str = f'J{cond.name} 0x{offset24:06X}'
        self.dec = cond,0,0,offset24
        if offset24 < 0:
            offset24 = negative(offset24, 24)
        self.bin = f'{cond:04b}','0','000',f'{offset24:024b}'
class Binary(Inst):
    def __init__(self, cond, flags, size, imm, op, rd, src):
        if imm:
            self.str = f'{op.name}{cond.name}{"S" if flags else ""}.{size.name} {rd.name}, {src}'
        else:
            self.str = f'{op.name}{cond.name}{"S" if flags else ""}.{size.name} {rd.name}, {src.name}'
        self.dec = cond,int(flags),1,size,int(imm),op,src,0,rd
        if imm:
            if src < 0:
                src = negative(src, 8)
            self.bin = f'{cond:04b}',f'{flags:b}','001',f'{size:02b}','1',f'{op:05b}',f'{src:08b}',f'{rd:04b}',f'{rd:04b}'
        else:
            self.bin = f'{cond:04b}',f'{flags:b}','001',f'{size:02b}','0',f'{op:05b}','XXXX',f'{src:04b}',f'{rd:04b}',f'{rd:04b}'
        

class Unary(Inst):
    pass
class Tertiary(Inst):
    def __init__(self, cond, flags, size, imm, op, rd, rs, src):
        if imm:
            self.str = f'{op.name}{cond.name}{"S" if flags else ""}.{size.name} {rd.name}, {src}'
        else:
            self.str = f'{op.name}{cond.name}{"S" if flags else ""}.{size.name} {rd.name}, {src.name}'
        self.dec = cond,int(flags),1,size,int(imm),op,src,0,rd
        if imm:
            if src < 0:
                src = negative(src, 8)
            self.bin = f'{cond:04b}',f'{flags:b}','001',f'{size:02b}','1',f'{op:05b}',f'{src:08b}','XXXX',f'{rd:04b}'
        else:
            self.bin = f'{cond:04b}',f'{flags:b}','001',f'{size:02b}','0',f'{op:05b}','XXXX',f'{src:04b}','XXXX',f'{rd:04b}'

class Load(Inst):
    pass

class StackOp(Inst):
    pass

class Interrupt(Inst):
    pass

class Immediate(Inst):
    pass
    
'''
add
cmn
sub
cmp
and
tst
xor
teq
or
bic
mul
div
mod
cmp
cmn
teq
tst
and
or
xor
not
neg
shr
shl
rol
ror
addf
subf
mulf
divf
itf
fti

'''