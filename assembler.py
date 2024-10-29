# -*- coding: utf-8 -*-
"""
Created on Fri Aug 25 10:49:03 2023

@author: ccslon
"""
from enum import IntEnum
import re

from bit32 import Size, Reg, Op, Cond, Byte, Char, Half, Word, Jump, Interrupt, Unary, Binary, Ternary, Load, PushPop, LoadImm, unescape

RE_SIZE = r'B|H|W'
RE_OP = r'|'.join(op.name for op in Op)
RE_COND = r'|'.join(cond.name for cond in Cond)
RE_REG = r'|'.join(reg.name for reg in Reg)

TOKENS = {
    'const': r'-?(0x[0-9a-f]+|0b[01]+|\d+)',
    'string': r'"(\\"|[^"])*"',
    'char': r"'\\?[^']'",
    'ldi': rf'^ldi(?P<ldi_cond>{RE_COND})?(\.(?P<ldi_size>{RE_SIZE}))?\b',
    'ld': rf'^ld(?P<ld_cond>{RE_COND})?(\.(?P<ld_size>{RE_SIZE}))?\b',
    'st': rf'^st(?P<st_cond>{RE_COND})?(\.(?P<st_size>{RE_SIZE}))?\b',
    'int': rf'^int(?P<int_cond>{RE_COND})?\b',
    'nop': r'^(nop)\b',
    'push': rf'^push(?P<push_cond>{RE_COND})?(\.(?P<push_size>{RE_SIZE}))?\b',
    'pop': rf'^pop(?P<pop_cond>{RE_COND})?(\.(?P<pop_size>{RE_SIZE}))?\b',
    'call': r'^(call)\b',
    'ret': r'^(ret)\b',
    'halt': r'^(halt)\b',
    'size': r'\b(byte|half|word)\b',
    'space': r'\b(space)\b',
    'reg': rf'\b({RE_REG})\b',
    'op': rf'^(?P<op_name>{RE_OP})(?P<op_cond>{RE_COND})?(?P<flag>s)?(\.(?P<op_size>{RE_SIZE}))?\s',
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

    def const(self, label, size, value):
        self.labels.append(label)
        if size == Size.BYTE:
            self.new_data(Byte, value)
        elif size == Size.HALF:
            self.new_data(Half, value)
        else:
            self.new_data(Word, value)
    def label(self, label, _, value):
        self.labels.append(label)
        self.new_data(Word, value)
    def char(self, label, _, char):
        self.labels.append(label)
        self.new_data(Char, char)
    def string(self, label, string):
        self.labels.append(label)
        for char in string:
            self.new_data(Char, char)
    def space(self, label, size):
        self.labels.append(label)
        for _ in range(size // 4):
            self.new_data(Word, 0)
        for _ in range(size % 4):
            self.new_data(Byte, 0)
    def jump(self, cond, label):
        self.new_inst(Jump, cond, False, label)
    def call(self, cond, label):
        self.new_inst(Jump, cond, True, label)
    def interrupt(self, cond, label):
        self.new_inst(Interrupt, cond, label)
    def unary(self, op, cond, flag, size, rd):
        assert op in [Op.NOT, Op.NEG, Op.NEGF]
        self.new_inst(Unary, cond, flag, size, op, rd)
    def binary(self, op, cond, flag, size, rd, src, imm):
        assert op not in [Op.NOT, Op.NEG]
        self.new_inst(Binary, cond, flag, size, imm, op, src, rd)
    def ternary(self, op, cond, flag, size, rd, rs, src, imm):
        assert op not in [Op.MOV, Op.MVN, Op.CMN, Op.CMP, Op.NOT, Op.NEG, Op.TST, Op.TEQ]
        self.new_inst(Ternary, cond, flag, size, imm, op, src, rs, rd)
    def load(self, cond, size, rd, rb, offset, imm):
        self.new_inst(Load, cond, size, imm, False, rd, rb, offset)
    def store0(self, cond, size, rb, rd):
        self.new_inst(Load, cond, size, True, True, rd, rb, 0)
    def store(self, cond, size, rb, offset, rd, imm):
        self.new_inst(Load, cond, size, imm, True, rd, rb, offset)
    def load_imm(self, cond, size, rd, value):
        self.new_inst(LoadImm, cond, size, rd)
        self.new_inst(Word, value)
    def pop(self, cond, size, rd):
        self.new_inst(PushPop, cond, size, False, rd)
    def push(self, cond, size, rd):
        self.new_inst(PushPop, cond, size, True, rd)
    def binary_w_name(self, op, cond, flag, size, rd, value):
        if 0 <= value < 256:
            assert op not in [Op.NOT, Op.NEG]
            self.new_inst(Binary, cond, flag, size, True, op, value, rd)
        else:
            assert op == Op.MOV, f'{op.name}'
            self.load_imm(cond, size, rd, value)
    def ternary_w_name(self, op, cond, flag, size, rd, rs, value):
        assert op in [Op.NOT, Op.NEG]
        assert 0 <= value < 256
        self.new_inst(Ternary, cond, flag, size, True, op, value, rs, rd)
    def new_inst(self, inst, *args):
        self.inst.append((self.labels, inst, args))
        self.labels = []
    def new_data(self, type, value):
        self.data.append((self.labels, type, (value,)))
        self.labels = []
    def name(self, name, value):
        self.names[name] = value

    def assemble(self, asm):
        with open('boot.s') as boot:
            base = boot.read()
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

                if self.match('id', '=', 'const'):
                    print(f'{self.line_no: >2}|{line}')
                    self.name(*self.values())

                elif self.peek('label'):
                    print(f'{self.line_no: >2}|{line}')

                    if self.match('label'):
                        self.labels.append(*self.values())
                    elif self.match('label', 'size', 'const'):
                        self.const(*self.values())
                    elif self.match('label', 'size', 'id'):
                        self.label(*self.values())
                    elif self.match('label', 'size', 'char'):
                        self.char(*self.values())
                    elif self.match('label', 'string'):
                        self.string(*self.values())
                    elif self.match('label', 'space', 'const'):
                        self.space(*self.values())
                    else:
                        self.error()
                else:
                    print(f'{self.line_no: >2}|  {line}')

                    if self.match('nop'):
                        self.jump(Cond.NV, 0)

                    elif self.match('id'):
                        self.new_data(Word, *self.values())
                    elif self.match('size', 'const') or self.match('size', 'id'):
                        size, value = self.values()
                        if size == Size.BYTE:
                            self.new_data(Byte, value)
                        elif size == Size.HALF:
                            self.new_data(Half, value)
                        else:
                            self.new_data(Word, value)
                    elif self.match('size', 'char'):
                        size, char = self.values()
                        self.new_data(Char, char)

                    elif self.match('jump', 'id'):
                        self.jump(*self.values())
                        
                    elif self.match('int', 'id'):
                        self.interrupt(*self.values())

                    elif self.match('op', 'reg'):
                        self.unary(*self.values())

                    elif self.match('op', 'reg', ',', 'reg'):
                        self.binary(*self.values(), False)
                    elif self.match('op', 'reg', ',', 'const'):
                        self.binary(*self.values(), True)
                    elif self.match('op', 'reg', ',', 'char'):
                        self.binary(*self.values(), True)
                    elif self.match('op', 'reg', ',', 'id'):
                        self.binary_w_name(*self.values())

                    elif self.match('op', 'reg', ',', 'reg', ',', 'reg'):
                        self.ternary(*self.values(), False)
                    elif self.match('op', 'reg', ',', 'reg', ',', 'const'):
                        self.ternary(*self.values(), True)
                    elif self.match('op', 'reg', ',', 'reg', ',', 'char'):
                        self.ternary(*self.values(), True)
                    elif self.match('op', 'reg', ',', 'reg', ',', 'id'):
                        self.ternary_w_name(*self.values())

                    elif self.match('ld', 'reg', ',', '[', 'reg', ',', 'reg', ']'):
                        self.load(*self.values(), False)
                    elif self.match('ld', 'reg', ',', '[', 'reg', ']'):
                        self.load(*self.values(), 0, True)
                    elif self.match('ld', 'reg', ',', '[', 'reg', ',', 'const', ']'):
                        self.load(*self.values(), True)

                    elif self.match('st', '[', 'reg', ',', 'reg', ']', ',', 'reg'):
                        self.store(*self.values(), False)
                    elif self.match('st', '[', 'reg', ']', ',', 'reg'):
                        self.store0(*self.values())
                    elif self.match('st', '[', 'reg', ',', 'const', ']', ',', 'reg'):
                        self.store(*self.values(), True)

                    elif self.match('ldi', 'reg', ',', 'const'):
                        self.load_imm(*self.values())
                    elif self.match('ldi', 'reg', ',', '=', 'id'):
                        self.load_imm(*self.values())

                    elif self.match('push', 'rd'):
                        self.push(*self.values())
                    elif self.match('pop', 'rd'):
                        self.pop(*self.values())

                    elif self.accept('push'):
                        args = [self.expect('reg')]
                        while self.accept(','):
                            args.append(self.expect('reg'))
                        self.expect('end')
                        for reg in args:
                            self.push(Cond.AL, Size.WORD, reg)

                    elif self.accept('pop'):
                        args = [self.expect('reg')]
                        while self.accept(','):
                            args.append(self.expect('reg'))
                        self.expect('end')
                        for reg in reversed(args):
                            self.pop(Cond.AL, Size.WORD, reg)

                    elif self.match('call', 'reg'):
                        self.ternary(Op.ADD, Cond.AL, False, Size.WORD, Reg.LR, Reg.PC, 4*2, True)
                        self.binary(Op.MOV, Cond.AL, False, Size.WORD, Reg.PC, *self.values(), False)

                    elif self.match('call', 'id'):
                        self.call(Cond.AL, *self.values())

                    elif self.match('ret'):
                        self.binary(Op.MOV, Cond.AL, False, Size.WORD, Reg.PC, Reg.LR, False)

                    elif self.match('halt'):
                        self.binary(Op.MOV, Cond.AL, False, Size.WORD, Reg.PC, Reg.PC, False)

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
                yield bool(match['flag'])
                yield Size.get(match['op_size'])
            elif type == 'jump':
                yield Cond.get(match['jump_cond'])
            elif type == 'int':
                yield Cond.get(match['int_cond'])
            elif type == 'ldi':
                yield Cond.get(match['ldi_cond'])
                yield Size.get(match['ldi_size'])
            elif type == 'ld':
                yield Cond.get(match['ld_cond'])
                yield Size.get(match['ld_size'])
            elif type == 'st':
                yield Cond.get(match['st_cond'])
                yield Size.get(match['st_size'])
            elif type == 'push':
                yield Cond.get(match['push_cond'])
                yield Size.get(match['push_size'])
            elif type == 'pop':
                yield Cond.get(match['pop_cond'])
                yield Size.get(match['pop_size'])
            elif type == 'size':
                if value.lower() == 'word':
                    yield Size.WORD
                elif value.lower() == 'byte':
                    yield Size.BYTE
                elif value.lower() == 'half':
                    yield Size.HALF

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
        self.error()

    def error(self):
        etype, evalue, _ = self.tokens[self.index]
        raise SyntaxError(f'Unexpected {etype} token "{evalue}" at token #{self.index} in line {self.line_no}')

class Linker:
    def link(objects):
        targets = {}
        indices = set()
        addr = 0
        for i, (labels, type, args) in enumerate(objects):
            for label in labels:
                targets[label] = addr
                indices.add(addr)
            objects[i] = (type, args)
            addr += type.size
        print('-'*67)
        contents = []
        i = 0
        for type, args in objects:
            if args and type is not Char:
                *args, last = args
                if isinstance(last, str):
                    last = targets[last]
                    if type is Jump:
                        last -= i
                args = *args, last
            data = type(*args)
            contents.append(data.little_end())
            print('>>' if i in indices else '  ', f'{i:06x}', f'{data.str: <20}', f'| {data.format_dec(): <23}', f'{data.format_bin(): <42}', data.hex())
            i += type.size
        print('\n'+' '.join(contents))
        print(len(contents), 'items.', i, 'bytes')
        return contents

assembler = Assembler()

class Color(IntEnum):
    ITAL = 3
    GREY = 30
    RED = 31
    GREEN = 32
    ORANGE = 33
    BLUE = 34
    PURPLE = 35
    CYAN = 36
    WHITE = 37

PATTERNS = {
    r'"(\\"|[^"])*"': Color.GREEN, #string
    r"'\\?[^']'": Color.GREEN, #char
    r'\b-?(0x[0-9a-f]+|0b[01]+|\d+)\b': Color.ORANGE, #const
    rf'\b({RE_REG})\b': Color.ITAL, #register
    r'\b(nop)\b': Color.BLUE,
    rf'\b({RE_OP})({RE_COND})?s?(\.({RE_SIZE}))?\b': Color.BLUE, #ops
    rf'\b(call|ret|halt|j(mp)?)({RE_COND})?\b': Color.BLUE, #ops
    rf'\b(ldi|ld|st|push|pop)({RE_COND})?(\.({RE_SIZE}))?\b': Color.BLUE, #ops
    r'\b(byte|half|word|space)\b': Color.BLUE, #size|space
    r'\.?[a-z_]\w*': Color.CYAN, #id
    r';.*$': Color.GREY #comment
}

def repl(match, color):
    if color:
        return f'\33[1;{color}m{match[0]}\33[0m'
    return match[0]

def display(asm):
    for line in asm.split('\n'):
        new = ""
        while line:
            for pattern, color in PATTERNS.items():
                match = re.match(pattern, line, re.I)
                if match:
                    new += repl(match, color)
                    line = line[len(match[0]):]
                    break
            if match is None:
                new += line[0]
                line = line[1:]
        print(new)

def assemble(program, fflag=True, name='out'):
    if program.endswith('.s'):
        name = program[:-2]
        with open(program) as file:
            program = file.read()
    objects = assembler.assemble(program)
    bit32 = Linker.link(objects)
    if fflag:
        with open(f'{name}.bit32', 'w+') as file:
            file.write('v2.0 raw\n' + ' '.join(bit32))

if __name__ == '__main__':
    ASM = '''
    foo:
        ret
    main:
        push lr
        call foo
        mov A, 5
        add A, -3
        int foo
        mov B, 6
        push B
        sub sp, 4
        add B, -2
        st [sp, 0], B
        sub B, 1
        ld B, [sp, 0]
        add sp, 4
        pop C
        pop pc
        jcs main
        call main
        int main
        mov A, -3
        add A, B
        adc A, B, C
        cmn A, B
        sub A, 1
        sbc A, B, 0xff
        cmp A, 'c'
        ld A, [FP, 3]
        st [FP, 3], A
        push A
        ldi A, 100000
        ret
    '''
    assemble(ASM)