# -*- coding: utf-8 -*-
"""
Created on Wed Mar 26 14:00:23 2025

@author: Colin
"""
from .clexer import Lex


class Parser:
    """
    Base class for top-down parsers.

    This class is a top-down parser, AKA a recursive decent parser.
    Many of the methods should closely resemble the actual rules found in the
    C grammar.
    """

    def __init__(self):
        self.tokens = []
        self.index = 0

    def root(self):
        """Abstract method that denotes the starting symbol for the grammar."""
        raise NotImplementedError()

    def parse(self, tokens):
        """
        Parse the list of input tokens based on the root.

        Takes in a list of tokens and outputs the root node for the
        abstract syntax tree.
        """
        self.tokens.clear()
        self.tokens.extend(tokens)
        # for i, t in enumerate(self.tokens): print(i, t.type, t.lexeme)
        self.index = 0
        root = self.root()
        self.expect(Lex.END)
        return root

    def __next__(self):
        """Move parse index forward and return consumed token."""
        token = self.tokens[self.index]
        self.index += 1
        return token

    def peek(self, peek, offset=0):
        """Peek at the next token to confirm correct desired symbol."""
        token = self.tokens[self.index+offset]
        if isinstance(peek, set):
            return (token.type in peek
                    or token.type in {Lex.CTYPE, Lex.KEYWORD, Lex.SYMBOL, Lex.NAME}
                    and token.lexeme in peek)
        return (token.type is peek
                or token.type in {Lex.CTYPE, Lex.KEYWORD, Lex.SYMBOL}
                and token.lexeme == peek)

    def peek2(self, first, second):
        """
        Peek at the next 2 tokens to confirm correct desired symbols.

        This allows for LL(2) grammars, which the C programming language is.
        """
        return self.peek(first) and self.peek(second, offset=1)

    def accept(self, symbol):
        """Accept and return next token if it is the correct desired symbol."""
        if self.peek(symbol):
            return next(self)

    def expect(self, symbol):
        """Expect given symbol as the next token. Raise error if not."""
        if self.peek(symbol):
            return next(self)
        self.error(f'Expected "{symbol}"')

    def error(self, msg=''):
        """Raise syntax error if one is found while parsing tokens."""
        error = self.tokens[self.index]
        raise SyntaxError(f'Line {error.line}: Unexpected {error.type} token "{error.lexeme}". {msg}')
