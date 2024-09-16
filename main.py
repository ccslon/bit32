# -*- coding: utf-8 -*-
"""
Created on Mon Aug 28 09:26:08 2023

@author: ccslon
"""

from c_compiler import compile as ccompile

if __name__ == '__main__':
    
    # ccompile('std/stdlib.h', sflag=False, fflag=True)
    # ccompile('std/stdlib.h', sflag=True, fflag=False)
    ccompile('tests/fact.c', sflag=True, fflag=False)
    # ccompile('tests/const.c', sflag=True, fflag=True)
    # ccompile('c/test.c', sflag=True, fflag=False)
    # ccompile('c/test_union.c')