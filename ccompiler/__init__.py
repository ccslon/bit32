# -*- coding: utf-8 -*-
"""
Created on Wed Jun  4 10:31:38 2025

@author: Colin
"""
import assembler2 as assembler
from .cpreprocessor import CPreProcessor
from .emitter import Emitter
from . import cparser


def compile_file(file_name, iflag=False, sflag=False, fflag=True):
    """
    Compile file based on the flags given the file name.

    iflag: Output only preprocessed C code.
    sflag: Output only bit32 assembly code.
    fflag: Output to file.
    """
    if file_name.endswith('.c') or file_name.endswith('.h'):
        cpreproc = CPreProcessor()
        cpreproc.process(file_name)
        if iflag:
            text = str(cpreproc)
            print(text)
            if fflag:
                with open(f'{file_name[:-2]}.i', 'w+') as file:
                    file.write(text)
        else:
            ast = cparser.parse(cpreproc.output())
            emitter = Emitter()
            ast.generate(emitter)
            asm = str(emitter)
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

def comp_cwd(cwd, files, oflag='out', Eflag=False, Sflag=False, fflag=True):
    comp([f'{cwd}/{file}' for file in files], f'{cwd}/{oflag}', Eflag, Sflag, fflag)

def comp(files, oflag='out', Eflag=False, Sflag=False, fflag=True):
    processed = []
    for file_name in files:
        if file_name.endswith(('.c', '.h')):
            preproc = CPreProcessor()
            try:
                preproc.process(file_name)
            except SyntaxError as error:
                print(f'In file "{file_name}" {error}')
                return
            processed.append(preproc)
        # elif file_name.endswith(('.i', '.s')):
        #     processed.append()
        else:
            print(f'"{file_name}" Wrong file type')
            return
    if Eflag:
        file_type = 'i'
        output = ''.join(map(str, processed))
        print(output)
    else:
        emitter = Emitter()
        for file_name, preproc in zip(files, processed):
            try:
                root = cparser.parse(preproc.output())
                root.generate(emitter)
            except SyntaxError as error:
                print(f'In file "{file_name}" {error}')
                return
        if Sflag:
            file_type = 's'
            output = str(emitter)
            assembler.display(output)
        else:
            stds = set()
            for preproc in processed:
                stds |= preproc.std_included
            preproc = CPreProcessor()
            for std in stds & {'ctype', 'errno', 'math', 'stdio', 'stdlib', 'string'}:
                try:
                    preproc.process(f'ccompiler/std/{std}.c')
                    root = cparser.parse(preproc.output())
                except SyntaxError as error:
                    print(f'In file "{std}.c" {error}')
                    return
                root.generate(emitter)
            try:
                assembler.assemble(str(emitter), fflag, oflag)
            except SyntaxError as error:
                print(error)
            return
    if fflag:
        with open(f'{oflag}.{file_type}', 'w+') as file:
            file.write(output)
