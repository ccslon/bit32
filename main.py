 # -*- coding: utf-8 -*-
"""
Created on Mon Aug 28 09:26:08 2023

@author: ccslon
"""

from c_compiler import compile as ccompile

if __name__ == '__main__':
    # ccompile('std/stdio.h', sflag=True, fflag=True)
    # ccompile('std/stdlib.h', sflag=True, fflag=False)
    # ccompile('tests/hello.c', sflag=True, fflag=False)
    # ccompile('tests/ifs.c', sflag=True, fflag=True)
    # ccompile('tests/neg_nums.c')
    # ccompile('c/test_define.c', sflag=True, fflag=False, iflag=True)
    ccompile('c/preproccat.c', sflag=True, fflag=False)
    # ccompile('c/hello.c')