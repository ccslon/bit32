# -*- coding: utf-8 -*-
"""
Created on Wed Jun  4 10:31:38 2025

@author: Colin
"""
import assembler
from . import cpreproc
from . import cparser


def compile_file(file_name, iflag=False, sflag=False, fflag=True):
    """
    Compile file based on the flags given the file name.

    iflag: Output only preprocessed C code.
    sflag: Output only bit32 assembly code.
    fflag: Output to file.
    """
    if file_name.endswith('.c') or file_name.endswith('.h'):
        preproc = cpreproc.CPreProcessor()
        preproc.process(file_name)
        if iflag:
            text = preproc.output()
            print(text)
            if fflag:
                with open(f'{file_name[:-2]}.i', 'w+') as file:
                    file.write(text)
        else:
            ast = cparser.parse(preproc.stream())
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
