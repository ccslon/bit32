# -*- coding: utf-8 -*-
"""
Created on Wed Jun  4 10:31:38 2025

@author: Colin
"""
from assembler import assemble, display
from .cpreprocessor import CPreProcessor
from .cparser import parse
from .emitter import Emitter


def ccompile_dir(dir_, files, oflag='out', Eflag=False, Sflag=False, fflag=True):
    """Compile the given files in the given directory based on the given flags."""
    ccompile([f'{dir_}/{file}' for file in files], f'{dir_}/{oflag}', Eflag, Sflag, fflag)


def ccompile(files, oflag='out', Eflag=False, Sflag=False, fflag=True):
    """Compile the given files based on the given flags."""
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
                root = parse(preproc.output())
                root.generate(emitter)
            except SyntaxError as error:
                print(f'In file "{file_name}" {error}')
                return
        if Sflag:
            file_type = 's'
            output = str(emitter)
            display(output)
        else:
            preproc = CPreProcessor()
            for std in ['bit32', 'ctype', 'math', 'stdio', 'stdlib', 'string']:
                try:
                    preproc.process(f'ccompiler/std/{std}.c')
                    root = parse(preproc.output())
                except SyntaxError as error:
                    print(f'In file "{std}.c" {error}')
                    return
                root.generate(emitter)
            try:
                assemble(str(emitter), oflag)
            except SyntaxError as error:
                print(error)
            return
    if fflag:
        with open(f'{oflag}.{file_type}', 'w+') as file:
            file.write(output)

def debug_std(std):
    preproc = CPreProcessor()
    try:
        preproc.process(f'ccompiler/std/{std}.c')
        root = parse(preproc.output())
        emitter = Emitter()
        root.generate(emitter)
    except SyntaxError as error:
        print(f'In file "{std}.c" {error}')
        return
    print(emitter)
