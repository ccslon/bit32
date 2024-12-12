# -*- coding: utf-8 -*-
"""
Created on Thu Aug 31 21:52:15 2023

@author: ccslon
"""

import assembler
import c_preproc
import c_parser

def compile(file_name, iflag=False, sflag=False, fflag=True):
    if file_name.endswith('.c') or file_name.endswith('.h'):
        preproc = c_preproc.CPreProcessor()
        preproc.process(file_name)
        if iflag:
            text = preproc.output()
            print(text)
            if fflag:
                with open(f'{file_name[:-2]}.i', 'w+') as file:
                    file.write(text)
        else:
            ast = c_parser.parse(preproc.stream())
            asm = ast.generate()
            if sflag:
                assembler.display(asm)
                # print(asm)
                if fflag:
                    with open(f'{file_name[:-2]}.s', 'w+') as file:
                        file.write(asm)
            else:
                assembler.assemble(asm, fflag, file_name[:-2])
    else:
        print("Wrong file type")