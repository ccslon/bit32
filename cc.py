 # -*- coding: utf-8 -*-
"""
Created on Mon Aug 28 09:26:08 2023

@author: ccslon
"""

from ccompiler import ccompile_cwd

'''
[X] Modify compile function
[X] Comma operator
[ ] static
'''

if __name__ == '__main__':
    # ccompile_cwd('tests', ['getset.c'], Sflag=True, fflag=False)
    # ccompile_cwd('ccompiler/std', ['string.c'], sflag=True, fflag=False)
    # ccompile_cwd('cprograms', ['switch.c'], Sflag=True, fflag=False)
    # ccompile_cwd('cprograms', ['hello.c'], oflag='hello', Sflag=True, fflag=False)
    # ccompile_cwd('cprograms/assign', ['assign.c', 'lexer.c', 'nodes.c', 'parser.c', 'intmap.c'], 'assign', eflag=True, fflag=True)
    ccompile_cwd('cprograms/assign', ['assign.c', 'lexer.c', 'nodes.c', 'parser.c', 'intmap.c'])
    # ccompile_cwd('cprograms', ['test_pointers.c'], Sflag=True)
    # ccompile_cwd('cprograms', ['hello.c'], oflag='hello')