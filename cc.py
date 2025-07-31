 # -*- coding: utf-8 -*-
"""
Created on Mon Aug 28 09:26:08 2023

@author: ccslon
"""

from ccompiler import compile_file

if __name__ == '__main__':
    # compile_file('ccompiler/std/stdio.h', sflag=True, fflag=True)
    # compile_file('ccompiler/std/stdio.h')
    # ccompile('tests/defines.c', sflag=True, fflag=False, iflag=True)
    # compile_file('tests/hello.c', sflag=True, fflag=False)
    # compile_file('cprograms/test_union.c', sflag=True, fflag=False)
    # compile_file('tests/calls.c', sflag=True, fflag=False)
    # compile_file('tests/params.c', sflag=True, fflag=False)
    # compile_file('tests/unions.c', sflag=True, fflag=False)
    # compile_file('tests/vardefns.c', sflag=True, fflag=False)
    # compile_file('tests/ifs.c', sflag=True, fflag=False)
    # compile_file('ccompiler/tests/fact.c')
    compile_file('cprograms/expr.c')
    # compile_file('cprograms/fact.c', sflag=True, fflag=True)
    # compile_file('cprograms/expr.c', iflag=True, fflag=True)