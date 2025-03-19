# -*- coding: utf-8 -*-
"""
Created on Tue Nov 26 11:14:05 2024

@author: ccslon
"""
import os
import re
from typing import NamedTuple
'''
TODO:
    [X] #
    [X] ##
    [X] null directive
    [X] undef
    [X] include
    [] ifelse    
'''  
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
        return [Token(match.lastgroup, result, self.line) for match in self.regex.finditer(text) if (result := self.action[match.lastgroup](self, match[0])) is not None]

class CLexer(LexerBase):
    RE_decimal = r'\d+\.\d+'
    RE_number = r'0x[0-9A-Fa-f]+|0b[01]+|\d+'
    RE_character = r"'(\\'|\\?[^'])'"
    def RE_std(self, match):
        r'<\s*\w+\.h\s*>'
        return match[1:-1].strip()
    def RE_string(self, match):
        r'"(\\"|[^"])*"'
        return match[1:-1]    
    RE_keyword = r'\b(include|define|undef|typedef|const|static|volatile|extern|void|char|short|int|long|float|unsigned|signed|struct|enum|union|sizeof|return|if|ifdef|ifndef|else|endif|switch|case|default|while|do|for|break|continue|goto)\b'
    RE_symbol = r'[#]{2}|[]#;:()[{}]|[+]{2}|--|->|(<<|>>|[+*/%^|&=!<>-])?=|<<|>>|[|]{2}|[&]{2}|[+*/%^|&=!<>?~-]|\.\.\.|\.|,'
    RE_name = r'[A-Za-z_]\w*'
    RE_space = r'[ \t]+'
    def RE_line_splice(self, match):
        r'\\\s*\n'
        self.line += 1
    def RE_new_line(self, match):
        r'\n'
        self.line += 1
        return match
    def RE_invalid(self, match):
        r'\S'
        raise SyntaxError(f'line {self.line}: Invalid symbol "{match}"')

class CPreProcessor:
    
    COMMENT = re.compile(r'''
                         /\*(.|\n)*?\*/     #multi line comment
                         |
                         //.*(\n|$)         #single line comment
                         ''', re.M | re.X)
                         
    def repl_comments(self, text):
        return self.COMMENT.sub(self.comment_repl, text)
        
    def arg(self, expand):
        '''
        ARG -> {TOKEN
              |name '(' [ARG {',' ARG}] ')'
              |'(' ARG ')'
               }
        '''
        self.accept('space')
        while not self.peek(')', ','):
            if self.peek_defined() and expand:
                self.expand()
            elif self.accept('name'):
                if self.accept('('):
                    if not self.accept(')'):
                        self.arg(expand)
                        while self.accept(','):
                            self.arg(expand)
                        self.expect(')')
            elif self.accept('('):
                self.arg(expand)
                self.expect(')')
            else:
                next(self)
    
    def param(self):
        '''
        PARAM -> name
        '''
        self.accept('space')
        name = self.expect('name')
        self.accept('space')
        return name.lexeme
    
    def params(self):
        '''
        PARAMS -> [PARAM {',' PARAM}]        
        '''
        params = {}
        self.accept('space')
        if not self.peek(')'):
            params[self.param()] = True
            while self.accept(','):
                params[self.param()] = True
        return params
    
    def expand(self):
        start = self.index
        name = next(self)
        params, body = self.defined[name.lexeme]
        if params is None:
            self.tokens[start:self.index] = body
        else:
            args = {}
            self.accept('space')
            self.expect('(')
            self.accept('space')
            if not self.accept(')'):
                for param, expand in params.items():
                    arg_start = self.index
                    self.arg(expand)
                    args[param] = self.tokens[arg_start:self.index]
                    if self.accept(')'):
                        break
                    self.expect(',')
            sub = []
            for token in body:
                if token.type == 'stringize':
                    sub.append(Token('string',''.join(arg.lexeme for arg in args[token.lexeme]),token.line))
                elif '##' in token.lexeme:
                    left, right = token.lexeme.split('##')
                    if left in args:
                        left = ''.join(arg.lexeme for arg in args[left])
                    if right in args:
                        right = ''.join(arg.lexeme for arg in args[right])
                    sub.append(Token(token.type,left+right,token.line))
                elif token.lexeme in args:
                    sub.extend(args[token.lexeme])
                else:
                    sub.append(token)
            if not self.peek('space'):
                sub.append(Token('space',' ',token.line))
            self.tokens[start:self.index] = sub
        self.index = start
    
    def directive(self):
        start = self.index
        next(self)
        self.accept('space')
        if self.if_start is None:
            if self.accept('define'):
                self.expect('space')
                name = self.expect('name')
                if self.accept('('):
                    params = self.params()
                    self.expect(')')
                    self.accept('space')
                    body = self.index
                    if self.peek('##'):
                        self.error()
                    while not self.peek('new_line','end'):
                        if self.peek('#'):
                            local_start = self.index
                            next(self)
                            local = self.expect('name')
                            if local.lexeme in params:
                                params[local.lexeme] = False
                            self.tokens[local_start:self.index] = \
                                [Token('stringize',local.lexeme,local.line)]
                            self.index = local_start
                        else:
                            self.accept('space')
                            local_start = self.index
                            left = next(self)
                            self.accept('space')
                            if self.accept('##'):
                                self.accept('space')
                                if self.peek('new_line','end'):
                                    self.error()
                                right = next(self)
                                if left.lexeme in params:
                                    params[left.lexeme] = False
                                if right.lexeme in params:
                                    params[right.lexeme] = False
                                self.tokens[local_start:self.index] = \
                                    [Token(left.type,f'{left.lexeme}##{right.lexeme}',left.line)]
                                self.index = local_start
                else:
                    params = None
                    self.accept('space')
                    body = self.index
                    while not self.peek('new_line','end'):
                        next(self)                    
                self.defined[name.lexeme] = params, self.tokens[body:self.index]
                del self.tokens[start:self.index]
            elif self.accept('include'):
                self.accept('space')
                if self.peek('string'):
                    file_name = next(self).lexeme
                    file_path = os.path.sep.join([self.path, file_name])
                    if self.original.endswith(file_name):
                        self.error(f'Circular dependency originating in {self.original}')
                    with open(file_path) as file:
                        text = file.read()
                    text = self.repl_comments(text)
                    self.tokens[start:self.index] = self.lexer.lex(text)
                elif self.peek('std'):
                    file_name = next(self).lexeme
                    if file_name not in self.std_included:
                        file_path = os.path.sep.join([os.getcwd(), 'std', file_name])
                        if self.original.endswith(file_name):
                            self.error(f'Circular dependency originating in {self.original}')
                        with open(file_path) as file:
                            text = file.read()
                        text = self.repl_comments(text)
                        self.tokens[start:self.index] = self.lexer.lex(text)
                        self.std_included.add(file_name)
                    else:
                        del self.tokens[start:self.index]
                else:
                    self.error()                
            elif self.accept('ifndef'):
                self.expect('space')
                if self.expect('name').lexeme in self.defined:
                    self.if_start = start
                del self.tokens[start:self.index]
            elif self.accept('endif'):            
                del self.tokens[start:self.index]
            elif self.accept('undef'):
                self.expect('space')
                del self.defined[self.expect('name').lexeme]
                del self.tokens[start:self.index]
            else:
                del self.tokens[start:self.index]
            self.index = start
        else:
            if self.accept('endif'):
                del self.tokens[self.if_start:self.index]
                self.index = self.if_start
                self.if_start = None

    def program(self):
        '''
        PROGRAM -> {TOKEN
                  |'#' DIRECTIVE
                  |name
                  |name '(' ARGS ')'
                  |string string
                   }
        '''
        while not self.accept('end'):
            if self.peek('#'):
                self.directive()
            elif self.peek_defined():
                self.expand()
            elif self.peek('string'):
                start = self.index    
                left = next(self)
                self.accept('space')
                if self.peek('string'):
                    right = next(self)
                    self.tokens[start:self.index] = \
                        [Token('string',left.lexeme+right.lexeme,left.line)]
                    self.index = start
            else:
                next(self)
    
    def process(self, file_name):
        self.original = file_name
        with open(file_name) as file:
            self.path = os.path.dirname(os.path.abspath(file.name))
            text = file.read()
        text = self.repl_comments(text)
        self.lexer = CLexer()
        self.tokens = self.lexer.lex(text) + [Token('end','',self.lexer.line)]
        # for i, token in enumerate(self.tokens): print(i, token.type, token.lexeme)
        self.index = 0
        self.defined = {}
        self.if_start = None
        self.std_included = set()
        self.program()        

    def stream(self):
        return [token for token in self.tokens if token.type in \
                ('decimal','number','character','string','keyword','symbol','name','end')]
            
    def output(self):
        return ''.join(f'"{token.lexeme}"' if token.type == 'string' else token.lexeme for token in self.tokens)
    
    def comment_repl(self, match):
        return ' ' + '\n'*match[0].count('\n')
    
    def __next__(self):
        token = self.tokens[self.index]
        self.index += 1
        return token
    
    def peek_defined(self):
        token = self.tokens[self.index]
        return token.type == 'name' and token.lexeme in self.defined and self.if_start is None
    
    def peek(self, *symbols, offset=0):
        token = self.tokens[self.index+offset]
        return token.type in symbols or token.type in ('keyword','symbol') and token.lexeme in symbols

    def accept(self, symbol):
        if self.peek(symbol):
            return next(self)

    def expect(self, symbol):
        if self.peek(symbol):
            return next(self)
        self.error(f'Expected "{symbol}"')

    def error(self, msg=None):
        error = self.tokens[self.index]
        raise SyntaxError(f'Line {error.line}: Unexpected {error.type} token "{error.lexeme}".' \
                          + (f' {msg}.' if msg is not None else ''))

if __name__ == '__main__':
    p = CPreProcessor()
    p.process('c/preprocA.c')
    print('||||||||||||||||\n', p.output(), '\b\n||||||||||||||||')