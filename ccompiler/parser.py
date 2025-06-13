# -*- coding: utf-8 -*-
"""
Created on Wed Mar 26 14:00:23 2025

@author: Colin
"""

class Parser:        

    def __init__(self):
        self.tokens = []
        self.index = 0
    
    def root(self):
        raise NotImplementedError()
    
    def parse(self, tokens):
        self.tokens.clear()
        self.tokens.extend(tokens)
        # for i, t in enumerate(self.tokens): print(i, t.type, t.lexeme)
        self.index = 0
        root = self.root()
        self.expect('end')
        return root
        
    def __next__(self):
        token = self.tokens[self.index]
        self.index += 1
        return token
    
    def peek(self, peek, offset=0):
        token = self.tokens[self.index+offset]
        if isinstance(peek, set):
            return token.type in peek or token.type in {'ctype','keyword','symbol','name'} and token.lexeme in peek
        return token.type == peek or token.type in {'ctype','keyword','symbol','name'} and token.lexeme == peek
    
    def peek2(self, first, second):
        return self.peek(first) and self.peek(second, offset=1)
    
    def accept(self, symbol):
        if self.peek(symbol):
            return next(self)
    
    def expect(self, symbol):
        if self.peek(symbol):
            return next(self)
        self.error(f'Expected "{symbol}"')
    
    def error(self, msg=''):
        error = self.tokens[self.index]
        raise SyntaxError(f'Line {error.line}: Unexpected {error.type} token "{error.lexeme}". {msg}')