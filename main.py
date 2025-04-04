 # -*- coding: utf-8 -*-
"""
Created on Mon Aug 28 09:26:08 2023

@author: ccslon
"""


from c_compiler import compile as ccompile

if __name__ == '__main__':
    # ccompile('std/stdlib.h', sflag=True, fflag=True)
    # ccompile('std/stdlib.h', sflag=True, fflag=False)
    # ccompile('tests/defines.c', sflag=True, fflag=False, iflag=True)
    ccompile('tests/logic.c', sflag=True, fflag=False)
    ccompile('tests/logic.c', sflag=True, fflag=True)
    # ccompile('tests/neg_nums.c')
    # ccompile('c/fact.c', sflag=True, fflag=False, iflag=True)
    # ccompile('c/test_funcs.c', sflag=True, fflag=False)
    # ccompile('c/uh.c', sflag=True, fflag=False)
    # ccompile('c/expr.c', sflag=True, fflag=True)
    # ccompile('c/expr.c')