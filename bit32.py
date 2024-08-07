# -*- coding: utf-8 -*-
"""
Created on Wed Aug  7 11:50:55 2024

@author: ccslon
"""

from enum import IntEnum

def negative(num, base):
    return (-num ^ (2**base - 1)) + 1

class Reg(IntEnum):
    r = 0
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
    fA = 8
    fB = 9
    fC = 10
    fD = 11

class Op(IntEnum):
    MOV = 0
    MVN = 
    ADD = 1
    SUB = 2
    CMP = 3
    MUL = 4
    NOT = 5
    DIV = 6
    MOD = 7
    AND = 8
    OR =  9
    XOR = 10
    # = 11
    # = 12
    NEG = 13
    SHR = 14
    SHL = 15

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