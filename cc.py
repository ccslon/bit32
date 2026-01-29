 # -*- coding: utf-8 -*-
"""
Created on Mon Aug 28 09:26:08 2023

@author: ccslon
"""

from ccompiler import compile_file

if __name__ == '__main__':
    # compile_file('ccompiler/std/stdio.h', sflag=True, fflag=True)
    # compile_file('ccompiler/std/stdio.h')
    compile_file('tests/macros.c', iflag=True, fflag=False)
    # compile_file('cprograms/test_addrs.c', sflag=True, fflag=False)
    # compile_file('tests/includes.c', sflag=True, fflag=False)
    # compile_file('tests/fact.c', sflag=True, fflag=False)
    # compile_file('tests/unions.c', sflag=True, fflag=False)
    # compile_file('switch.c', sflag=True, fflag=False)
    # compile_file('tests/vardefns.c', sflag=True, fflag=False)
    # compile_file('tests/ifs.c', sflag=True, fflag=False)
    # compile_file('ccompiler/tests/fact.c')
    # compile_file('cprograms/expr.c')


def retest():
    """Rerun all tests to get their output."""
    for file in ['arrays', 'calls', 'const', 'cstrings', 'defines', 'enums', 'fact', 'fib',
                 'floats', 'func_ptrs', 'getset', 'getset2', 'globs', 'goto', 'hello', 'ifs',
                 'includes', 'init', 'logic', 'loops', 'main', 'neg_nums', 'ops', 'params',
                 'pointers', 'rconst', 'returns', 'sizeof', 'structs', 'sum', 'unions', 'unsigned',
                 'vardefns']:
        compile_file(f'tests/{file}.c', sflag=True, fflag=True)
