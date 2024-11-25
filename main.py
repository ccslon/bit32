 # -*- coding: utf-8 -*-
"""
Created on Mon Aug 28 09:26:08 2023

@author: ccslon
"""

from c_compiler import compile as ccompile

if __name__ == '__main__':
    # ccompile('std/stdio.h', sflag=True, fflag=True)
    # ccompile('std/stdlib.h', sflag=True, fflag=False)
    ccompile('tests/fact.c', sflag=True, fflag=False)
    # ccompile('tests/ifs.c', sflag=True, fflag=True)
    # ccompile('tests/neg_nums.c')
    # ccompile('c/gcd.c', sflag=True, fflag=False)
    # ccompile('c/test_union3.c')