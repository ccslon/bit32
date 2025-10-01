# -*- coding: utf-8 -*-
"""
Created on Tue Nov 26 11:14:05 2024

@author: ccslon
"""
import os
import re
from .clexer import Lex, Token, CLexer
from .parser import Parser
'''
TODO:
    [X] #
    [X] ##
    [X] null directive
    [X] undef
    [X] include
    [] ifelse
'''


class CPreProcessor(Parser):
    """Class for C language pre-processor."""

    COMMENT = re.compile(r'''
                         /\*(.|\n)*?\*/     #multi line comment
                         |
                         //.*(\n|$)         #single line comment
                         ''', re.M | re.X)

    def __init__(self):
        self.original = ''
        self.lexer = CLexer()
        self.defined = {}
        self.if_start = None
        self.std_included = set()
        super().__init__()

    def repl_comments(self, text):
        """Ignore/replace comments in C input."""
        return self.COMMENT.sub(self.comment_repl, text)

    def argument(self, expand):
        '''
        ARG -> {TOKEN|name '(' [ARG {',' ARG}] ')'|'(' ARG ')'}
        '''
        self.accept(Lex.SPACE)
        while not self.peek({')', ','}):
            if self.peek_defined() and expand:
                self.expand()
            elif self.accept(Lex.NAME):
                if self.accept('('):
                    if not self.accept(')'):
                        self.argument(expand)
                        while self.accept(','):
                            self.argument(expand)
                        self.expect(')')
            elif self.accept('('):
                self.argument(expand)
                self.expect(')')
            else:
                next(self)

    def parameter(self):
        '''
        PARAM -> name
        '''
        self.accept(Lex.SPACE)
        name = self.expect(Lex.NAME)
        self.accept(Lex.SPACE)
        return name.lexeme

    def parameters(self):
        '''
        PARAMS -> [PARAM {',' PARAM}]
        '''
        parameters = {}
        self.accept(Lex.SPACE)
        if not self.peek(')'):
            parameters[self.parameter()] = True
            while self.accept(','):
                parameters[self.parameter()] = True
        return parameters

    def expand(self):
        """Expand definitions."""
        start = self.index
        name = next(self)
        params, body = self.defined[name.lexeme]
        if params is None:
            self.tokens[start:self.index] = body
        else:
            args = {}
            self.accept(Lex.SPACE)
            self.expect('(')
            self.accept(Lex.SPACE)
            if not self.accept(')'):
                for param, expand in params.items():
                    arg_start = self.index
                    self.argument(expand)
                    args[param] = self.tokens[arg_start:self.index]
                    if self.accept(')'):
                        break
                    self.expect(',')
            sub = []
            for token in body:
                if token.type is Lex.STRINGIZE:
                    sub.append(Token(Lex.STRING,
                                     ''.join(arg.lexeme
                                             for arg in args[token.lexeme]),
                                     token.line))
                elif '##' in token.lexeme:
                    left, right = token.lexeme.split('##')
                    if left in args:
                        left = ''.join(arg.lexeme for arg in args[left])
                    if right in args:
                        right = ''.join(arg.lexeme for arg in args[right])
                    sub.append(Token(token.type, left+right, token.line))
                elif token.lexeme in args:
                    sub.extend(args[token.lexeme])
                else:
                    sub.append(token)
            if not self.peek(Lex.SPACE):
                sub.append(Token(Lex.SPACE, ' ', token.line))
            self.tokens[start:self.index] = sub
        self.index = start

    def directive(self):
        """Expand directives and macros."""
        start = self.index
        next(self)
        self.accept(Lex.SPACE)
        if self.if_start is None:
            if self.accept('define'):
                self.expect(Lex.SPACE)
                name = self.expect(Lex.NAME)
                if self.accept('('):
                    params = self.parameters()
                    self.expect(')')
                    self.accept(Lex.SPACE)
                    body = self.index
                    if self.peek('##'):
                        self.error()
                    while not self.peek({Lex.NEW_LINE, Lex.END}):
                        if self.peek('#'):
                            local_start = self.index
                            next(self)
                            local = self.expect(Lex.NAME)
                            if local.lexeme in params:
                                params[local.lexeme] = False
                            self.tokens[local_start:self.index] = [
                                Token(Lex.STRINGIZE,
                                      local.lexeme,
                                      local.line)]
                            self.index = local_start
                        else:
                            self.accept(Lex.SPACE)
                            local_start = self.index
                            left = next(self)
                            self.accept(Lex.SPACE)
                            if self.accept('##'):
                                self.accept(Lex.SPACE)
                                if self.peek({Lex.NEW_LINE, Lex.END}):
                                    self.error()
                                right = next(self)
                                if left.lexeme in params:
                                    params[left.lexeme] = False
                                if right.lexeme in params:
                                    params[right.lexeme] = False
                                self.tokens[local_start:self.index] = [
                                    Token(left.type,
                                          f'{left.lexeme}##{right.lexeme}',
                                          left.line)]
                                self.index = local_start
                else:
                    params = None
                    self.accept(Lex.SPACE)
                    body = self.index
                    while not self.peek({Lex.NEW_LINE, Lex.END}):
                        next(self)
                self.defined[name.lexeme] = (params,
                                             self.tokens[body:self.index])
                del self.tokens[start:self.index]
            elif self.accept('include'):
                self.accept(Lex.SPACE)
                if self.peek(Lex.STRING):
                    file_name = next(self).lexeme
                    file_path = os.path.sep.join([self.path, file_name])
                    if self.original.endswith(file_name):
                        self.error(f'Circular dependency originating in {self.original}')
                    with open(file_path) as file:
                        text = file.read()
                    text = self.repl_comments(text)
                    self.tokens[start:self.index] = self.lexer.lex(text)
                elif self.peek(Lex.STD):
                    file_name = next(self).lexeme
                    if file_name not in self.std_included:
                        file_path = os.path.sep.join([os.getcwd(),
                                                      'ccompiler',
                                                      'std', file_name])
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
                self.expect(Lex.SPACE)
                if self.expect(Lex.NAME).lexeme in self.defined:
                    self.if_start = start
                del self.tokens[start:self.index]
            elif self.accept('endif'):
                del self.tokens[start:self.index]
            elif self.accept('undef'):
                self.expect(Lex.SPACE)
                del self.defined[self.expect(Lex.NAME).lexeme]
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
        while not self.peek(Lex.END):
            if self.peek('#'):
                self.directive()
            elif self.peek_defined():
                self.expand()
            elif self.peek(Lex.STRING):
                start = self.index
                left = next(self)
                self.accept(Lex.SPACE)
                if self.peek(Lex.STRING):
                    right = next(self)
                    self.tokens[start:self.index] = [
                        Token(Lex.STRING,
                              left.lexeme+right.lexeme,
                              left.line)]
                    self.index = start
            else:
                next(self)

    def parse(self, tokens):
        """Override of parse to initialize preproc specific members."""
        self.defined.clear()
        self.std_included.clear()
        super().parse(tokens)

    def process(self, file_name):
        """Process the list of tokens."""
        self.original = file_name
        with open(file_name) as file:
            self.path = os.path.dirname(os.path.abspath(file.name))
            text = file.read()
        text = self.repl_comments(text)
        self.parse(self.lexer.lex(text)
                   + [Token(Lex.END, '', self.lexer.line)])

    root = program

    def stream(self):
        """Produce a list of tokens."""
        return [token for token in self.tokens
                if token.type not in {Lex.SPACE, Lex.NEW_LINE}]

    def output(self):
        """Produce the processed input as text."""
        return ''.join(f'"{token.lexeme}"' if token.type is Lex.STRING
                       else token.lexeme for token in self.tokens)

    def comment_repl(self, match):
        """Replace comments with space/newlines to preserve line numbers."""
        return ' ' + '\n'*match[0].count('\n')

    def peek_defined(self):
        """Peek tokens that are already defined to expand."""
        token = self.tokens[self.index]
        return (token.type is Lex.NAME
                and token.lexeme in self.defined
                and self.if_start is None)
