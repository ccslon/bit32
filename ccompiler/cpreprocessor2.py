# -*- coding: utf-8 -*-
"""
Created on Thu Jan 15 10:08:22 2026

@author: ccslon
"""
import os
import re
from operator import add, sub, mul, truediv, mod, lshift, rshift, eq, ne, gt, lt, ge, le
from bit32 import unescape
from .clexer import Lex, Token, CLexer
from .parser import Parser
'''
TODO:
    [X] #
    [X] ##
    [X] null directive
    [X] undef
    [X] include
    [X] ifelse
        [X] if
        [X] else
        [X] nested ifs (needs more testing)
        [X] if EXPRESSION
        [X] elif
    [X] expanded macro line numbers

    [ ] multi file 1 pass
    [ ] correct arg expansion
    [ ] accept space
    [ ] refactor
    [ ] refactor ifs
    [ ] append, no insert
    [ ] predefined macros e.g. __FILE__, __LINE__
'''

class If:
    
    def __init__(self, active, seen):
        self.active = active
        self.seen = seen

class File:

    def __init__(self, name, tokens):
        self.name = name
        self.tokens = tokens
        self.if_levels = []

class CPreProcessor(Parser):
    """Class for C language pre-processor."""

    COMMENT = re.compile(r'''
                         /\*(.|\n)*?\*/     #multi line comment
                         |
                         //.*(\n|$)         #single line comment
                         ''', re.M | re.X)

    def __init__(self):
        self.original = ''
        self.path = ''
        self.lexer = CLexer()
        self.defined = {}
        self.if_start = None
        self.if_levels = []
        self.std_included = set()
        super().__init__()

    def replace_comments(self, text):
        """Ignore/replace comments in C input."""
        return self.COMMENT.sub(self.comment_replacement, text)

    def expand(self):
        """Expand definitions."""
        name = next(self)
        params, body = self.defined[name.lexeme]
        if params is None:
            return [Token(ttype, lexeme, name.line) for ttype, lexeme in body]
        args = {}
        self.accept(Lex.SPACE)
        self.expect('(')
        self.accept(Lex.SPACE)
        if not self.accept(')'):
            for param, expand in params.items():
                self.accept(Lex.SPACE)
                arg_start = self.index
                self.argument(expand)
                args[param] = self.tokens[arg_start:self.index]
                if self.accept(')'):
                    break
                self.expect(',')
        repl = []
        for ttype, lexeme in body:
            if ttype is Lex.STRINGIZE:
                repl.append(Token(Lex.STRING, ''.join(str(arg.lexeme) for arg in args[lexeme]), name.line))
            elif '##' in str(lexeme):
                left, right = lexeme.split('##')
                if left in args:
                    left = ''.join(str(arg.lexeme) for arg in args[left])
                if right in args:
                    right = ''.join(str(arg.lexeme) for arg in args[right])
                repl.append(Token(ttype, left+right, name.line))
            elif lexeme in args:
                repl.extend(args[lexeme])
            else:
                repl.append(Token(ttype, lexeme, name.line))
        if not self.peek(Lex.SPACE):
            repl.append(Token(Lex.SPACE, ' ', name.line))
        return repl

    def object_like(self, name):
        body = []
        while not self.peek({Lex.NEW_LINE, Lex.END}):
            body.append(next(self))
        return None, [(token.type, token.lexeme) for token in body]
        
    def function_like(self):
        self.expect('(')
        params = self.parameters()
        self.expect(')')
        self.accept(Lex.SPACE)
        if self.peek('##'):
            self.error('## is a binary operator')
        body = []
        while not self.peek({Lex.NEW_LINE, Lex.END}):
            if self.accept('#'):
                local = self.expect(Lex.NAME)
                body.append(Token(Lex.STRINGIZE, local.lexeme, local.line))
            elif self.accept('##'):
                self.accept(Lex.SPACE)
                if self.peek({Lex.NEW_LINE, Lex.END}):
                    self.error('## is a binary operator')
                if body[-1].type is Lex.SPACE:
                    body.pop()
                left = body.pop()
                right = next(self)
                body.append(Token(left.type, f'{left.lexeme}##{right.lexeme}', left.line))
            else:
                body.append(next(self))
        return params, [(token.type, token.lexeme) for token in body]

    def undef(self):
        self.accept(Lex.SPACE)
        del self.defined[self.expect(Lex.NAME).lexeme]
    
    def include(self):
        """Open the file at the given file path and include it."""
        if self.original.endswith(file_name):
            self.error(f'Circular dependency originating in {self.original}')
        with open(os.path.sep.join(file_path + [file_name])) as file:
            text = file.read()
        text = self.replace_comments(text)
        self.tokens[start:self.index] = self.lexer.lex(text)
    
    def include(self):
        self.accept(Lex.SPACE)
        if self.peek(Lex.STRING):
            self.include(next(self).lexeme, [self.path])
        elif self.peek(Lex.STD):
            file_name = next(self).lexeme
            if file_name not in self.std_included:
                self.include(file_name, [os.getcwd(), 'ccompiler', 'std'])
                self.std_included.add(file_name)
        else:
            self.error()

    def directive(self):
        self.accept(Lex.SPACE)
        if self.active:
            if self.accept('define'):
                self.accept(Lex.SPACE)
                name = self.expect(Lex.NAME)
                self.defined[name.lexeme] = self.object_like() if self.accept(Lex.SPACE) else self.function_like()
            elif self.accept('undef'):
                self.undef()
            elif self.accept('include'):
                self.include()
            elif self.peek({'if', 'ifdef', 'ifndef'}):
                if self.accept('if'):
                    test = self.expression()
                elif self.accept('ifdef'):
                    test = self.expect(Lex.NAME).lexeme in self.defined
                elif self.accept('ifndef'):
                    test = self.expect(Lex.NAME).lexeme not in self.defined
                self.active = test
                self.if_levels.append(If(test, test))
            elif self.peek({'elif', 'else'}):
                next(self)
                if not self.if_levels:
                    self.error('No corresponding if statement to go with else')
                self.active = self.if_levels[-1].active = False
            elif self.accept('endif'):
                self.if_levels.pop()
        else:
            if self.peek({'if', 'ifdef', 'ifndef'}):
                next(self)
                self.if_levels.append(If(False, False))
            elif self.accept('elif'):
                top = self.if_levels.pop()
                test = self.expression()
                outer = all(level.active for level in self.if_levels)
                self.active = test and outer and not top.seen
                self.append(If(self.active, top.seen or test))
            elif self.accept('else'):
                top = self.if_levels.pop()
                outer = all(level.active for level in self.if_levels)
                self.active = outer and not top.seen
                self.append(If(self.active, True))
            elif self.accept('endif'):
                self.if_levels.pop()
            

    def program(self):
        changed = True
        while changed:
            self.index = 0
            new = []
            changed = False
            while not self.peek(Lex.END):
                if self.accept('#'):
                    new.extend(self.directive())
                    changed = True
                elif self.peek(Lex.NEW_LINE):
                    new.append(next(self))
                elif self.active:
                    if self.peek_defined():
                        new.extend(self.expand())
                        changed = True
                    elif self.peek2(Lex.STRING, Lex.STRING):
                        left = next(self)
                        self.accept(Lex.SPACE)
                        right = next(self)
                        new.append(Token(Lex.STRING, left.lexeme+right.lexeme, left.line))
                        changed = True
                    else:
                        new.append(next(self))
            new.append(next(self))  # for Lex.END
            self.tokens = new
            
    def peek(self, peek, offset=0):
        if self.tokens[self.index].type is Lex.SPACE:
            next(self)
        return super().peek(peek, offset)
                

    root = program

    def peek_defined(self):
        """Peek tokens that are already defined to expand."""
        token = self.tokens[self.index]
        return token.type is Lex.NAME and token.lexeme in self.defined