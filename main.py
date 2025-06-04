 # -*- coding: utf-8 -*-
"""
Created on Mon Aug 28 09:26:08 2023

@author: ccslon
"""


from c_compiler import compile as ccompile

# ccompile('std/stdlib.h', sflag=True, fflag=True)
ccompile('std/stdio.h', sflag=True, fflag=False)
# ccompile('tests/defines.c', sflag=True, fflag=False, iflag=True)
# ccompile('tests/unions.c', sflag=True, fflag=False)
# ccompile('tests/unions.c', sflag=True, fflag=True)
# ccompile('tests/neg_nums.c')
# ccompile('c/fact.c', sflag=True, fflag=False, iflag=True)
# ccompile('c/test_union2.c', sflag=True, fflag=False)
# ccompile('c/test_union3.c', sflag=True, fflag=False)
# ccompile('c/uh.c', sflag=True, fflag=False)
# ccompile('c/expr.c', sflag=True, fflag=True)
# ccompile('c/expr.c')