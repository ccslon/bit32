# -*- coding: utf-8 -*-
"""
Created on Mon Aug 28 09:26:08 2023

@author: ccslon
"""

from c_compiler import compile as ccompile

if __name__ == '__main__':
    
    # ccompile('std/stdlib.h', sflag=False, fflag=True)
    # ccompile('std/stdlib.h', sflag=True, fflag=False)
    ccompile('tests/cstrings.c', sflag=True, fflag=True)
    # ccompile('tests/const.c', sflag=True, fflag=True)
    # ccompile('c/sec5.12.c', sflag=True, fflag=False)
    # ccompile('c/sort.c')