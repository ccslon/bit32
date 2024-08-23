# -*- coding: utf-8 -*-
"""
Created on Wed Aug  7 11:50:55 2024

@author: ccslon
"""
'''

'''

from enum import IntEnum

def negative(num, base):
    return (-num ^ (2**base - 1)) + 1

class Size(IntEnum):
    BYTE = 1
    HALF = 2 #TODO
    WORD = 4
    @classmethod
    def get(cls, name):
        return {'B': cls.BYTE, 'H': cls.HALF, 'W': cls.WORD}.get(name.upper() if name else name, cls.WORD)
    def display(self):
        return f'.{self.name[0]}' if self != Size.WORD else ''

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
    F0 = 8
    F1 = 9
    F2 = 10
    F3 = 11

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
    @classmethod
    def get(cls, name):
        return cls[name.upper()] if name else cls.AL
    def display(self):
        return self.name if self != self.AL else ''
    def display_jump(self):
        return self.name if self != self.AL else 'MP'    
    
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
    size = Size.WORD
    def __init__(self, value):
        self.str = f'0x{value:08x}'
        self.dec = value,
        if value < 0:
            value = negative(value, 32)
        self.bin = f'{value:032b}',
    def __int__(self):
        return int(''.join(self.bin).replace('X','0'), base=2)
    def little_end(self):
        bin = int(self)
        return f'{bin & 0xff:02x} {bin>>8 & 0xff:02x} {bin>>16 & 0xff:02x} {bin>>24 & 0xff:02x}'
    def hex(self):
        return f'{int(self):08x}'
    def format_bin(self):
        return ' '.join(self.bin)
    def format_dec(self):
        return ' '.join(map(str, map(int,self.dec)))

class Byte(Data):
    size = Size.BYTE
    def __init__(self, byte):
        self.str = f'0x{byte:02x}'
        self.dec = byte,
        if byte < 0:
            byte = negative(byte, 8)
        self.bin = f'{byte:08b}',
    def little_end(self):
        return self.hex()
    def hex(self):
        return f'{int(self):02x}'

class Char(Byte):
    size = Size.BYTE
    def __init__(self, char):
        self.str = f"'{escape(char)}'"
        assert 0 <= ord(char) < 128
        self.dec = ord(char),
        self.bin = f'{ord(char):08b}',

class Half(Data):
    size = Size.HALF
    def __init__(self, half):
        self.str = f'0x{half:04x}'
        self.dec = half,
        if half < 0:
            half = negative(half, 16)
        self.bin = f'{half:016b}',
    def little_end(self):
        bin = int(self)
        return f'{bin & 0xff:02x} {bin>>8 & 0xff:02x}'
    def hex(self):
        return f'{int(self):04x}'

class Word(Data):
    def __init__(self, word):
        self.str = f'0x{word:08x}'
        self.dec = word,
        if word < 0:
            word = negative(word, 32)
        self.bin = f'{word:032b}',

class Inst(Word):
    pass

class Jump(Inst):
    def __init__(self, cond, offset24):
        if offset24 < 0:
            self.str = f'J{cond.display_jump()} -0x{-offset24:06X}'
        else:
            self.str = f'J{cond.display_jump()} 0x{offset24:06X}'
        self.dec = cond,0,0,offset24
        if offset24 < 0:
            offset24 = negative(offset24, 24)
        self.bin = f'{cond:04b}','0','000',f'{offset24:024b}'
 
class Unary(Inst):
    def __init__(self, cond, flag, size, op, rd):
        self.str = f'{op.name}{cond.display()}{"S"*flag}.{size.name[0]} {rd.name}'
        self.dec = cond,int(flag),1,size,0,op,rd,rd,rd
        self.bin = f'{cond:04b}',f'{flag:b}','001',f'{size>>1:02b}','0',f'{op:05b}','XXXX',f'{rd:04b}',f'{rd:04b}',f'{rd:04b}'       
 
class Binary(Inst):
    def __init__(self, cond, flag, size, imm, op, src, rd):
        if imm:
            if isinstance(src, str):
                self.str = f"{op.name}{cond.display()}{'S'*flag}.{size.name[0]} {rd.name}, '{escape(src)}'"
                self.dec = cond,int(flag),1,size,1,op,ord(src),rd,rd
                self.bin = f'{cond:04b}',f'{flag:b}','001',f'{size>>1:02b}','1',f'{op:05b}',f'{ord(src):08b}',f'{rd:04b}',f'{rd:04b}'
            else:
                assert 0 <= src < 256
                self.str = f"{op.name}{cond.display()}{'S'*flag}.{size.name[0]} {rd.name}, {src}"
                self.dec = cond,int(flag),1,size,1,op,src,rd,rd
                self.bin = f'{cond:04b}',f'{flag:b}','001',f'{size>>1:02b}','1',f'{op:05b}',f'{src:08b}',f'{rd:04b}',f'{rd:04b}'
        else:
            self.str = f'{op.name}{cond.display()}{"S"*flag}.{size.name[0]} {rd.name}, {src.name}'
            self.dec = cond,int(flag),1,size,0,op,0,src,rd,rd
            self.bin = f'{cond:04b}',f'{flag:b}','001',f'{size>>1:02b}','0',f'{op:05b}','XXXX',f'{src:04b}',f'{rd:04b}',f'{rd:04b}'

class Ternary(Inst):
    def __init__(self, cond, flag, size, imm, op, src, rs, rd):
        if imm:
            if isinstance(src, str):
                self.str = f"{op.name}{cond.display()}{'S'*flag}.{size.name[0]} {rd.name}, {rs.name}, '{escape(src)}'"
                self.dec = cond,int(flag),1,size,1,op,ord(src),rs,rd
                self.bin = f'{cond:04b}',f'{flag:b}','001',f'{size>>1:02b}','1',f'{op:05b}',f'{ord(src):08b}',f'{rs:04b}',f'{rd:04b}'
            else:
                assert 0 <= src < 256
                self.str = f'{op.name}{cond.display()}{"S"*flag}.{size.name[0]} {rd.name}, {rs.name}, {src}'
                self.dec = cond,int(flag),1,size,1,op,src,rs,rd
                self.bin = f'{cond:04b}',f'{flag:b}','001',f'{size>>1:02b}','1',f'{op:05b}',f'{src:08b}',f'{rs:04b}',f'{rd:04b}'
        else:
            self.str = f'{op.name}{cond.display()}{"S"*flag}.{size.name[0]} {rd.name}, {rs.name}, {src.name}'
            self.dec = cond,int(flag),1,size,0,op,src,rs,rd
            self.bin = f'{cond:04b}',f'{flag:b}','001',f'{size>>1:02b}','0',f'{op:05b}','XXXX',f'{src:04b}',f'{rs:04b}',f'{rd:04b}'

class LoadStore(Inst):
    def __init__(self, cond, flag, size, imm, storing, rd, rb, offset):
        if storing:
            self.str = f'LD{cond.display()}{"S"*flag}.{size.name[0]} [{rb.name}, {offset if imm else offset.name}], {rd.name}'
        else:
            self.str = f'LD{cond.display()}{"S"*flag}.{size.name[0]} {rd.name}, [{rb.name}, {offset if imm else offset.name}]'
        self.dec = cond,int(flag),4,size,str(int(imm)),int(storing),0,offset,rb,rd
        if imm:
            self.bin = f'{cond:04b}',f'{flag:b}','100',f'{size>>1:02b}','1',str(int(storing)),'XXXXXXXX',f'{offset:04b}',f'{rb:04b}',f'{rd:04b}'
        else:
            self.bin = f'{cond:04b}',f'{flag:b}','100',f'{size>>1:02b}','1',str(int(storing)),'XXXX',f'{offset:08b}',f'{rb:04b}',f'{rd:04b}'

class PushPop(Inst):
    def __init__(self, cond, flag, size, pushing, rd):
        if pushing:
            self.str = f'PUSH{cond.display()}{"S"*flag}.{size.name[0]} {rd.name}'
        else:
            self.str = f'POP{cond.display()}{"S"*flag}.{size.name[0]} {rd.name}'
        self.dec = cond,int(flag),5,Size.WORD,0,int(pushing),0,(-1)**pushing * size,0,rd
        self.bin = f'{cond:04b}',f'{flag:b}','101',f'{size>>1:02b}','0',str(int(pushing)),'XXXX',f'{negative(-size,8) if pushing else size:08b}','XXXX',f'{rd:04b}'

class Interrupt(Inst):
    pass

class Immediate(Inst):
    def __init__(self, cond, flag, size, rd):
        self.str = f'LD{cond.display()}.{size.name[0]} {rd.name}, ...'
        self.dec = cond,0,7,size,0,rd
        self.bin = f'{cond:04b}',f'{flag:b}','111',f'{size>>1:02b}','XXXXXXXXXXXXXXXXXX',f'{rd:04b}'