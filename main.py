# -*- coding: utf-8 -*-
"""
Created on Mon Aug 28 09:26:08 2023

@author: ccslon
"""

from ccompiler import compile as ccompile

if __name__ == '__main__':
    
    ccompile('tests/vfuncs.c', sflag=True, fflag=False)
    # ccompile('tests/const.c', sflag=True, fflag=True)