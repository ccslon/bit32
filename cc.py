 # -*- coding: utf-8 -*-
"""
Created on Mon Aug 28 09:26:08 2023

@author: ccslon
"""

from ccompiler import compile_file

if __name__ == '__main__':
    # ccompile('std/stdlib.h', sflag=True, fflag=True)
    # compile_file('std/stdio.h', sflag=True, fflag=False)
    # ccompile('tests/defines.c', sflag=True, fflag=False, iflag=True)
    compile_file('ccompiler/tests/fact.c', sflag=True, fflag=False)
    # compile_file('ccompiler/tests/fact.c')
    # compile_file('c/fact.c')