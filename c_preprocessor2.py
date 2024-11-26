# -*- coding: utf-8 -*-
"""
Created on Tue Nov 26 11:14:05 2024

@author: ccslon
"""
import os
import re
from typing import NamedTuple

class Token(NamedTuple):
    type: str
    lexeme: str
    line: int

class MetaLexer(type):
    def __init__(self, name, bases, attrs):
        self.action = {}
        regex = []
        for attr in attrs:
            if attr.startswith('RE_'):
                name = attr[3:]
                if callable(attrs[attr]):
                    pattern = attrs[attr].__doc__
                    self.action[name] = attrs[attr]
                else:
                    pattern = attrs[attr]
                    self.action[name] = lambda self, match: match
                regex.append((name, pattern))
        self.regex = re.compile('|'.join(rf'(?P<{name}>{pattern})' for name, pattern in regex))

class LexerBase(metaclass=MetaLexer):
    def lex(self, text):
        self.line = 1
        return [Token(match.lastgroup, result, self.line) for match in self.regex.finditer(text) if (result := self.action[match.lastgroup](self, match[0])) is not None] + [Token('end','',self.line)]

class CLexer(LexerBase):
    RE_number = r'0x[0-9A-Fa-f]+|0b[01]+|\d+(\.d+)?'
    RE_character = r"(\\'|\\?[^'])'"
    def RE_string(self, match):
        r'"(\\"|[^"])*"'
        return match[1:-1]
    def RE_eof(self, match):
        r'@\n'
        self.line = 1
    RE_keyword = r'\b(typedef|const|static|volatile|void|char|short|int|float|unsigned|signed|struct|enum|union|sizeof|return|if|else|switch|case|default|while|do|for|break|continue|goto)\b'
    RE_id = r'[A-Za-z_]\w*'
    RE_symbol = r'[;:()\[\]{}]|\+\+|--|->|([+\-*/%\^\|&=!<>]|<<|>>)?=|[+\-*/%\^\|&=!<>?~]|<<|>>|(\|\|)|\.\.\.|\.|,'
    RE_define = r'\#(define)\b'
    # RE_include = r'\#(include)\b'
    RE_undef = r'\#(undef)\b'
    RE_ifdef = r'\#(ifdef)\b'
    RE_ifndef = r'\#(ifndef)\b'
    RE_else = r'\#(else)\b'
    RE_endif = r'\#(endif)\b'
    RE_hash = r'\#'
    RE_dhash = r'\#\#'
    def RE_line_splice(self, match):
        r'\\\s*\n'
        self.line += 1
    def RE_new_line(self, match):
        r'\n'
        self.line += 1
        return match
    RE_space = r'[ \t]+'
    def RE_invalid(self, match):
        r'\S'
        raise SyntaxError(f'line {self.line}: Invalid symbol "{match}"')

class CPreProc:
    
    COMMENT = re.compile(r'''
                         /\*(.|\n)*?\*/     #multi line comment
                         |
                         //.*(\n|$)         #single line comment
                         ''', re.M | re.X)
    STD = re.compile(r'''
                     ^
                     \s*
                     \#
                     \s*
                     include
                     \s+
                     (?P<file><\w+\.h>)
                     \s*
                     $
                     ''', re.M | re.X)
    INCLUDE = re.compile(r'''
                         ^
                         \s*
                         \#
                         \s*
                         include
                         \s+
                         (?P<file>"\w+\.[ch]")
                         \s*
                         $
                         ''', re.M | re.X)
    def comments(self, text):
        return self.COMMENT.sub(self.repl, text)
    
    def include(self, regex, text, ext=''):
        for m in regex.finditer(text):
            file_name = m['file'][1:-1]
            text = regex.sub(self.repl, text)
            with open(f'{ext}{os.path.sep}{file_name}') as file:
                text = file.read() + '\n@\n' + text
            self.defined[file_name.replace('.','_')] = None
        return text

    def includes(self, text):
        while self.STD.search(text) or self.INCLUDE.search(text):
            text = self.include(self.STD, text, f'{os.getcwd()}{os.path.sep}std')
            text = self.include(self.INCLUDE, text, self.path)
        return text
    
    def arg(self):
        while not self.peek(')', ','):
            if self.accept('number'):
                pass
            elif self.accept('character'):
                pass
            elif self.accept('string'):
                pass
            elif self.accept('keyword'):
                pass
            elif self.accept('id'):
                if self.accept('('):
                    if not self.accept(')'):
                        self.arg()
                        while self.accept(','):
                            self.arg()
                        self.expect(')')
            elif self.accept('('):
                self.arg()
                self.expect(')')
            elif self.accept('symbol'):
                pass
    
    def preproc(self, file_name):
        with open(file_name) as file:
            self.path = os.path.dirname(os.path.abspath(file.name))
            text = file.read()
        self.defined = {}
        text = self.includes(text)
        text = self.comments(text)
        # text = re.sub(r'\\\s*\n', '', text, re.M)
        self.lexer = CLexer()
        self.tokens = self.lexer.lex(text)
        for i, token in enumerate(self.tokens):
            print(i, token.type, token.lexeme)
        self.index = 0
        # print(self.tokens)
        while not self.accept('end'):
            print(self.tokens[self.index])
            if self.peek('define'):
                start = self.index
                next(self)
                id = self.expect('id')
                params = None
                if self.accept('('):
                    params = []
                    if not self.accept(')'):
                        params.append(self.expect('id').lexeme)
                        while self.accept(','):
                            params.append(self.expect('id').lexeme)
                        self.expect(')')
                body = self.index
                while not self.peek('new_line'): #TODO or eof
                    next(self)
                end = self.index
                self.defined[id.lexeme] = params, self.tokens[body:end]
                self.tokens[start:end] = []
                self.index = start
            elif self.peek_defined():
                print(self.defined)
                start = self.index
                id = next(self)
                params, body = self.defined[id.lexeme]
                if params is None:
                    self.tokens[start:self.index] = body
                else:
                    args = {}
                    self.expect('(')
                    if not self.accept(')'):
                        p = 0
                        arg_start = self.index
                        self.arg()
                        arg_end = self.index
                        args[params[p]] = self.tokens[arg_start:arg_end]
                        p += 1
                        while self.accept(','):
                            arg_start = self.index
                            self.arg()
                            arg_end = self.index
                            args[params[p]] = self.tokens[arg_start:arg_end]
                            p += 1
                        self.expect(')')
                    end = self.index
                    print(args)
                    i = 0
                    sub = []
                    for token in body:
                        if token.lexeme in args:
                            sub.extend(args[token.lexeme])
                        else:
                            sub.append(token)
                    self.tokens[start:end] = sub
                    self.index = start
            else:
                next(self)
        # print(self.defined)
        # text = self.defines(text)
        # text = self.concat(text)
        # return text
        print(''.join(token.lexeme for token in self.tokens))
    
    def repl(self, match):
        return '\n' * match[0].count('\n')
    
    def space(self):
        if self.tokens[self.index].type == 'space':
            next(self)
    
    def __next__(self):
        token = self.tokens[self.index]
        self.index += 1
        return token
    
    def peek_defined(self):
        self.space()
        token = self.tokens[self.index]
        return token.type == 'id' and token.lexeme in self.defined
    
    def peek(self, *symbols, offset=0):
        self.space()
        token = self.tokens[self.index+offset]
        return token.type in symbols or not token.lexeme.isalnum() and token.lexeme in symbols

    def accept(self, symbol):
        if self.peek(symbol):
            return next(self)

    def expect(self, symbol):
        if self.peek(symbol):
            return next(self)
        self.error(f'Expected "{symbol}"')

    def error(self, msg=None):
        error = self.tokens[self.index]
        raise SyntaxError(f'Line {error.line}: Unexpected {error.type} token "{error.lexeme}".'+(f' {msg}.' if msg is not None else ''))


if __name__ == '__main__':
    p = CPreProc()
    p.preproc('c/preproc.c')