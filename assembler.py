# -*- coding: utf-8 -*-
"""
Created on Fri Aug 25 10:49:03 2023

@author: ccslon
"""

import re
from bit32 import Size, Reg, FReg, Op, Cond, Byte, Char, Half, Word, Jump, Unary, Binary, Ternary, LoadStore, PushPop, Immediate,  unescape

RE_SIZE = r'|'.join(size.name for size in Size)
RE_OP = r'|'.join(op.name for op in Op)
RE_COND = r'|'.join(cond.name for cond in Cond)

TOKENS = {
    'const': r'-?(0x[0-9a-f]+|0b[01]+|\d+)',
    'string': r'"[^"]*"',
    'char': r"'\\?[^']'",
    # 'ldm': r'^(ldm)\b',
    'ld': r'^ld(?P<ld_cond>{RE_COND})?(?P<ld_flag>s)?(\.(?P<ld_size>{RE_SIZE}))?\b',
    'nop': r'^(nop)\b',
    'push': r'^push(?P<push_cond>{RE_COND})?(?P<push_flag>s)?(\.(?P<push_size>{RE_SIZE}))?\b',
    'pop': r'^pop(?P<pop_cond>{RE_COND})?(?P<pop_flag>s)?(\.(?P<pop_size>{RE_SIZE}))?\b',
    'call': r'^(call)\b',
    'ret': r'^(ret)\b',
    'halt': r'^(halt)\b',
    'space': r'\b(space)\b',
    'reg': r'\b('+r'|'.join(reg.name for reg in Reg)+'|'+'|'.join(reg.name for reg in FReg)+r')\b',
    'op': rf'^(?P<op_name>{RE_OP})(?P<op_cond>{RE_COND})?(?P<op_flag>s)?(\.(?P<op_size>{RE_SIZE}))?\b',
    'jump': rf'^j(mp)?(?P<jump_cond>{RE_COND})?\b',
    'label': r'\.?[a-z_]\w*\s*:',
    'id': r'\.?[a-z_]\w*',
    'equal': r'=',
    'lbrace': r'\[',
    'rbrace': r'\]',
    'lbrack': r'\{',
    'rbrack': r'\}',
    'comma': r',',
    'end': r'$',
    'error': r'\S+'
}

RE = re.compile('|'.join(rf'(?P<{token}>{pattern})' for token, pattern in TOKENS.items()), re.I)

def lex(text):
    return [(match.lastgroup, match.group(), match) for match in RE.finditer(text)]

class Assembler:
    def label(self, label):
        self.labels.append(label)
    def const(self, label, value):
        self.label(label)
        self.new_data(value)
    def char(self, label, char):
        self.label(label)
        self.new_char(char)
    def string(self, label, string):
        self.label(label)
        for char in string:
            self.new_char(char)
    def space(self, label, size):
        self.label(label)
        for _ in range(size):
            self.new_data(0)
    def jump(self, cond, label):
        self.new_inst(Jump, cond, label)
    def unary(self, op, cond, flag, size, rd):
        self.new_inst(Unary, cond, flag, size, op, rd)
    def binary(self, op, cond, flag, size, rd, src, imm):
        self.new_inst(Binary, cond, flag, size, imm, op, src, rd)
    def ternary(self, op, cond, flag, size, rd, rs, src, imm):
        self.new_inst(Ternary, cond, flag, size, imm, op, src, rs, rd)
    def load(self, rd, rb, offset, imm):
        self.new_inst(LoadStore, Cond.AL, False, Size.W, imm, False, rd, rb, offset)
    def store0(self, rd, rb):
        self.new_inst(LoadStore, Cond.AL, False, Size.W, True, True, rd, rb, 0)
    def store(self, rd, rb, offset, imm):
        self.new_inst(LoadStore, Cond.AL, False, Size.W, imm, True, rd, rb, offset)
    def immediate(self, rd, value):
        pass
    def pop(self, cond, flag, size, rd):
        self.new_inst(PushPop, cond, flag, size, False, rd)
    def push(self, cond, flag, size, rd):
        self.new_inst(PushPop, cond, flag, size, True, rd)
    
    def new_inst(self, inst, *args):
        self.inst.append((self.labels, inst, args))
        self.labels = []
    # def new_imm(self, value):
    #     self.inst.append((self.labels, Data, (value,)))
    #     self.labels = []
    # def new_data(self, value):
    #     self.data.append((self.labels, Data, (value,)))
    #     self.labels = []
    # def new_char(self, char):
    #     self.data.append((self.labels, Char, (char,)))
    #     self.labels = []
    # def name(self, name, value):
    #     self.names[name] = value

    def assemble(self, asm):
        # with open('boot.s') as bios:
        #     base = bios.read()
        base = ''
        self.inst = []
        self.data = []
        self.labels = []
        self.names = {}
        for self.line_no, line in enumerate(map(str.strip, (base+'\n'+asm).strip().split('\n'))):
            if ';' in line:
                line, comment = map(str.strip, line.split(';', 1))
            if line:
                self.tokens = lex(line)
                self.index = 0
                print(self.tokens)
                
                if self.match('id', '=', 'const'):
                    print(f'{self.line_no: >2}|{line}')
                    self.name(*self.values())
                    
                elif self.peek('label'):
                    print(f'{self.line_no: >2}|{line}')
                    
                    if self.match('label'):
                        self.label(*self.values())
                        
                #     elif self.match('label', 'const'):
                #         self.const(*self.values())
                        
                #     elif self.match('label', 'id'):
                #         self.const(*self.values())
                        
                #     elif self.match('label', 'char'):
                #         self.char(*self.values())
                        
                #     elif self.match('label', 'string'):
                #         self.string(*self.values())
                        
                #     elif self.match('label', 'space', 'const'):
                #         self.space(*self.values())
                        
                #     else:
                #         self.error()
                else:
                    print(f'{self.line_no: >2}|  {line}')
                    
                    if self.match('nop'):
                        self.jump(Cond.NV, 0)
                    
                #     elif self.match('id'):
                #         self.new_data(*self.values())
                #     elif self.match('const'):
                #         self.new_data(*self.values())
                #     elif self.match('char'):
                #         self.new_char(*self.values())
                        
                    elif self.match('jump', 'id'):
                        self.jump(*self.values())
                    
                    elif self.match('op', 'reg'):
                        self.unary(*self.values())
                    
                    elif self.match('op', 'reg', ',', 'reg'):
                        self.binary(*self.values(), False)                        
                    elif self.match('op', 'reg', ',', 'const'):
                        self.binary(*self.values(), True)                        
                    elif self.match('op', 'reg', ',', 'char'):
                        self.binary(*self.values(), True)
                    
                    elif self.match('op', 'reg', ',', 'reg', ',', 'reg'):
                        self.ternary(*self.values(), False)
                    elif self.match('op', 'reg', ',', 'reg', ',', 'const'):
                        self.ternary(*self.values(), True)
                    elif self.match('op', 'reg', ',', 'reg', ',', 'char'):
                        self.ternary(*self.values(), True)
                        
                    elif self.match('ld', 'reg', ',', '[', 'reg', ',', 'reg', ']'):
                        self.load(*self.values(), False)                            
                    elif self.match('ld', 'reg', ',', '[', 'reg', ']'):
                        self.load(*self.values(), 0, True)                
                    elif self.match('ld', 'reg', ',', '[', 'reg', ',', 'const', ']'):
                        self.load(*self.values(), True)
                    
                    elif self.match('ld', '[', 'reg', ',', 'reg', ']', ',', 'reg'):
                        self.store(*self.values(), False)
                    elif self.match('ld', '[', 'reg', ']', ',', 'reg'):
                        self.store0(*self.values())
                    elif self.match('ld', '[', 'reg', ',', 'const', ']', ',', 'reg'):
                        self.store(*self.values(), True)
                        
                    elif self.match('ld', 'reg', ',', 'const'):
                        self.immediate(*self.values())
                    elif self.match('ld', 'reg', ',', '=', 'id'):
                        self.immediate(*self.values())
                        
                    elif self.match('push', 'rd'):
                        pass
                    elif self.match('pop', 'rd'):
                        pass
                        
                    elif self.accept('push'):
                        args = [self.expect('reg')]
                        while self.accept(','):
                            args.append(self.expect('reg'))
                        self.expect('end')
                        for reg in args:
                            self.push(Cond.AL, False, Size.W, reg)
                            
                    elif self.accept('pop'):
                        args = [self.expect('reg')]
                        while self.accept(','):
                            args.append(self.expect('reg'))
                        self.expect('end')
                        for reg in reversed(args):
                            self.pop(Cond.AL, False, Size.W, reg)
                                                
                    elif self.match('call', 'reg'):
                        self.ternary(Op.ADD, Cond.AL, False, Size.W, Reg.LR, Reg.PC, 2, True)
                        self.binary(Op.MOV, Cond.AL, False, Size.W, Reg.PC, *self.values(), False)
                        
                    elif self.match('call', 'id'):
                        self.ternary(Op.ADD, Cond.AL, False, Size.W, Reg.LR, Reg.PC, 2, True)
                        self.jump(Cond.AL, *self.values())
                        
                    elif self.match('ret'):
                        self.binary(Op.MOV, Cond.AL, False, Size.W, Reg.PC, Reg.LR, False)
                        
                    elif self.match('halt'):
                        self.binary(Op.MOV, Cond.AL, False, Size.W, Reg.PC, Reg.PC, False)
                        self.op4(Op.MOV, Reg.PC, Reg.PC)
                        
                    else:
                        self.error()
                        
        return self.inst + self.data

    def trans(self, type, value):
        if type == 'const':
            if value.startswith('0x'):
                return int(value, base=16)
            elif value.startswith('0b'):
                return int(value, base=2)
            else:
                return int(value)
        elif type in ['string', 'char']:
            return unescape(value[1:-1])
        elif type == 'reg':
            return Reg[value.upper()]
        elif type == 'label':
            return value[:-1].strip()
        elif type == 'id':
            if value in self.names:
                return self.names[value]
            return value

    def values(self):
        for type, value, match in self.tokens:
            if type in ['const','string','char','reg','label','id']:
                yield self.trans(type, value)
            elif type == 'op':
                yield Op[match['op_name'].upper()]
                yield Cond.get(match['op_cond'])
                yield bool(match['op_flag'])
                yield Size.get(match['op_size'])
            elif type == 'jump':
                yield Cond.get(match['jump_cond'])
            elif type == 'ld':
                yield Cond.get(match['ld_cond'])
                yield bool(match['ld_flag'])
                yield Size.get(match['ld_size'])
            elif type == 'push':
                yield Cond.get(match['push_cond'])
                yield bool(match['push_flag'])
                yield Size.get(match['push_size'])
            elif type == 'pop':
                yield Cond.get(match['pop_cond'])
                yield bool(match['pop_flag'])
                yield Size.get(match['pop_size'])

    def match(self, *pattern):
        pattern += ('end',)
        return len(self.tokens) == len(pattern) and all(self.peek(symbol, offset=i) for i, symbol in enumerate(pattern))

    def __next__(self):
        type, value, _ = self.tokens[self.index]
        self.index += 1
        if type in ['op','jump','const','string','char','reg','cond','label','id']:
            return self.trans(type, value)
        return value

    def peek(self, symbol, offset=0):
        type, value, _ = self.tokens[self.index+offset]
        return type == symbol or (not value.isalnum() and value == symbol)

    def accept(self, symbol):
        if self.peek(symbol):
            return next(self)

    def expect(self, symbol):
        if self.peek(symbol):
            return next(self)
        self.error(expected=symbol)

    def error(self):
        etype, evalue, _ = self.tokens[self.index]
        raise SyntaxError(f'Unexpected {etype} token "{evalue}" at token #{self.index} in line {self.line_no}')

class Linker:
    def link(objects):
        targets = {}
        indices = set()
        print(objects)
        for i, (labels, type, args) in enumerate(objects):
            for label in labels:
                targets[label] = i
                indices.add(i)
            objects[i] = (type, args)
        print('-'*67)
        print(targets)
        contents = []
        for i, (type, args) in enumerate(objects):
            if args and type is not Char:
                *args, last = args
                if isinstance(last, str):
                    last = targets[last]
                    if type is Jump:
                        last = type.SIZE * (last-i)
                args = *args, last
            data = type(*args)
            contents.append(data.little_end())
            print('>>' if i in indices else '  ', f'{i*4:06x}', f'{data.str: <20}', f'| {data.format_dec(): <20}', f'{data.format_bin(): <45}', data.hex())
        print('\n', ' '.join(contents))
        print(len(contents))
        return contents

# assembler = Assembler()

# def assemble(program, fflag=True, name='out'):
#     if program.endswith('.s'):
#         name = program[:-2]
#         with open(program) as file:
#             program = file.read()
#     objects = assembler.assemble(program)
#     bit16 = Linker.link(objects)
#     if fflag:
#         with open(f'{name}.bit16', 'w+') as file:
#             file.write('v2.0 raw\n' + ' '.join(bit16))

test = '''
mov A, 0
mov B, 10
addge C, 1
loop:
    cmp A, B
    jge done
    add A, 1
    jmp loop
done:
    nop
    neg.h A
    nots A
    mov C, '\\n'
    adds.w LR, PC, 2
    add.b D, C, 't'
    
'''

if __name__ == '__main__':
    ass = Assembler()
    objs = ass.assemble(test)
    Linker.link(objs)