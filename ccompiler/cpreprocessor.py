# -*- coding: utf-8 -*-
"""
Created on Tue Nov 26 11:14:05 2024

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

    def delete_tokens(self, start, stop):
        """Delete tokens within given range but preserve lines breaks."""
        self.tokens[start:stop] = [token for token in self.tokens[start:stop] if token.type == Lex.NEW_LINE]

    def primary(self):
        '''
        PRIMARY -> 'defined' name
                  |'defined' '(' name ')'
                  |name|decimal|number|character|string|'(' EXPRESSION ')'
        '''
        self.accept(Lex.SPACE)
        if self.peek_defined():
            self.expand()
            return self.expression()
        if self.accept('defined'):
            self.accept(Lex.SPACE)
            if self.accept('('):
                self.accept(Lex.SPACE)
                primary = self.expect(Lex.NAME).lexeme in self.defined
                self.accept(Lex.SPACE)
                self.expect(')')
                return primary
            return self.expect(Lex.NAME).lexeme in self.defined
        if self.accept(Lex.NAME):
            return 0
        if self.peek(Lex.DECIMAL):
            return float(next(self).lexeme)
        if self.peek(Lex.NUMBER):
            lexeme = next(self).lexeme
            if lexeme.startswith('0x'):
                return int(lexeme, base=16)
            if lexeme.startswith('0b'):
                return int(lexeme, base=2)
            return int(lexeme)
        if self.peek(Lex.CHARACTER):
            return unescape(next(self).lexeme[1:-1])
        if self.peek(Lex.STRING):
            return next(self).lexeme
        if self.accept('('):
            primary = self.expression()
            self.expect(')')
            return primary
        self.error('Expected primary expression')

    def unary(self):
        '''
        UNARY -> ['-'|'~'|'!'] PRIMARY
        '''
        self.accept(Lex.SPACE)
        if self.accept('-'):
            return -self.primary()
        if self.accept('~'):
            return ~self.primary()
        if self.accept('!'):
            return not self.primary()
        return self.primary()

    def multiplicative(self):
        '''
        MULTIPLICATIVE -> UNARY {('*', '/', '%') UNARY}
        '''
        multiplicative = self.unary()
        self.accept(Lex.SPACE)
        while self.peek({'*', '/', '%'}):
            multiplicative = {
                '*': mul,
                '/': truediv,
                '%': mod
                }[next(self).lexeme](multiplicative, self.unary())
        return multiplicative

    def additive(self):
        '''
        ADDITIVE -> MULTIPLICATIVE {('+'|'-') MULTIPLICATIVE}
        '''
        additive = self.multiplicative()
        while self.peek({'+', '-'}):
            additive = {
                '+': add,
                '-': sub
                }[next(self).lexeme](additive, self.multiplicative())
        return additive

    def shift(self):
        '''
        SHIFT -> ADDITIVE {('<<'|'>>') ADDITIVE}
        '''
        shift = self.additive()
        while self.peek({'<<', '>>'}):
            shift = {
                '<<': lshift,
                '>>': rshift
                }[next(self).lexeme](shift, self.additive())
        return shift

    def relational(self):
        '''
        RELATIONAL -> SHIFT {('<'|'>'|'<='|'>=') SHIFT}
        '''
        relational = self.shift()
        while self.peek({'<', '>', '<=', '>='}):
            relational = {
                '<': lt,
                '>': gt,
                '<=': le,
                '>=': ge
                }[next(self).lexeme](relational, self.shift())
        return relational

    def equality(self):
        '''
        EQUALITY -> RELATIONAL {('=='|'!=') RELATIONAL}
        '''
        equality = self.relational()
        while self.peek({'==', '!='}):
            equality = {
                '==': eq,
                '!=': ne,
                }[next(self).lexeme](equality, self.relational())
        return equality

    def bitwise_and(self):
        '''
        BITWISE_AND -> EQUALITY {'&' EQUALITY}
        '''
        bitwise_and = self.equality()
        while self.accept('&'):
            bitwise_and &= self.equality()
        return bitwise_and

    def bitwise_xor(self):
        '''
        BITWISE_XOR -> BITWISE_AND {'^' BITWISE_AND}
        '''
        bitwise_xor = self.bitwise_and()
        while self.accept('^'):
            bitwise_xor ^= self.bitwise_and()
        return bitwise_xor

    def bitwise_or(self):
        '''
        BITWISE_OR -> BITWISE_XOR {'|' BITWISE_XOR}
        '''
        bitwise_or = self.bitwise_xor()
        while self.accept('|'):
            bitwise_or |= self.bitwise_xor()
        return bitwise_or

    def logical_and(self):
        '''
        LOGICAL_AND -> BITWISE_OR {'&&' BITWISE_OR}
        '''
        logical_and = self.bitwise_or()
        while self.accept('&&'):
            other = self.bitwise_or()
            logical_and = logical_and and other
        return logical_and

    def logical_or(self):
        '''
        LOGICAL_OR -> LOGICAL_AND {'||' LOGICAL_AND}
        '''
        logical_or = self.logical_and()
        while self.accept('||'):
            other = self.logical_and()
            logical_or = logical_or or other
        return logical_or

    def expression(self):
        '''
        EXPRESSION -> LOGICAL_OR
        '''
        return self.logical_or()

    def argument(self, expand):
        '''
        ARGUMENT -> {TOKEN|name '(' [ARGUMENT {',' ARGUMENT}] ')'|'(' ARGUMENT ')'}
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
        PARAMETER -> name
        '''
        self.accept(Lex.SPACE)
        name = self.expect(Lex.NAME)
        self.accept(Lex.SPACE)
        return name.lexeme

    def parameters(self):
        '''
        PARAMETERS -> [PARAMETER {',' PARAMETER}]
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
            self.tokens[start:self.index] = [Token(ttype, lexeme, name.line) for ttype, lexeme in body]
        else:
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
                    repl.append(Token(Lex.STRING, ''.join(arg.lexeme for arg in args[lexeme]), name.line))
                elif '##' in lexeme:
                    left, right = lexeme.split('##')
                    if left in args:
                        left = ''.join(arg.lexeme for arg in args[left])
                    if right in args:
                        right = ''.join(arg.lexeme for arg in args[right])
                    repl.append(Token(ttype, left+right, name.line))
                elif lexeme in args:
                    repl.extend(args[lexeme])
                else:
                    repl.append(Token(ttype, lexeme, name.line))
            if not self.peek(Lex.SPACE):
                repl.append(Token(Lex.SPACE, ' ', name.line))
            self.tokens[start:self.index] = repl
        self.index = start

    def include(self, start, file_name, file_path):
        """Open the file at the given file path and include it."""
        if self.original.endswith(file_name):
            self.error(f'Circular dependency originating in {self.original}')
        with open(os.path.sep.join(file_path + [file_name])) as file:
            text = file.read()
        text = self.replace_comments(text)
        self.tokens[start:self.index] = self.lexer.lex(text)

    def directive(self):
        """Expand directives and macros."""
        start = self.index
        next(self)
        self.accept(Lex.SPACE)
        if all(level['active'] for level in self.if_levels):
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
                                Token(Lex.STRINGIZE, local.lexeme, local.line)]
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
                                    Token(left.type, f'{left.lexeme}##{right.lexeme}', left.line)]
                                self.index = local_start
                else:
                    params = None
                    self.accept(Lex.SPACE)
                    body = self.index
                    while not self.peek({Lex.NEW_LINE, Lex.END}):
                        next(self)
                self.defined[name.lexeme] = (params, [(token.type, token.lexeme)
                                                      for token in self.tokens[body:self.index]])
                del self.tokens[start:self.index]
            elif self.accept('undef'):
                self.expect(Lex.SPACE)
                del self.defined[self.expect(Lex.NAME).lexeme]
                del self.tokens[start:self.index]
            elif self.accept('include'):
                self.accept(Lex.SPACE)
                if self.peek(Lex.STRING):
                    self.include(start, next(self).lexeme, [self.path])
                elif self.peek(Lex.STD):
                    file_name = next(self).lexeme
                    if file_name not in self.std_included:
                        self.include(start, file_name, [os.getcwd(), 'ccompiler', 'std'])
                        self.std_included.add(file_name)
                    else:
                        del self.tokens[start:self.index]
                else:
                    self.error()
            elif self.peek({'if', 'ifdef', 'ifndef'}):
                if self.accept('if'):
                    self.expect(Lex.SPACE)
                    test = self.expression()
                elif self.accept('ifdef'):
                    self.expect(Lex.SPACE)
                    test = self.expect(Lex.NAME).lexeme in self.defined
                elif self.accept('ifndef'):
                    self.expect(Lex.SPACE)
                    test = self.expect(Lex.NAME).lexeme not in self.defined
                self.if_levels.append({
                    'active': test,
                    'seen': test
                    })
                if not test:
                    self.if_start = start
                del self.tokens[start:self.index]
            elif self.accept('elif') or self.accept('else'):
                if not self.if_levels:
                    self.error('No corresponding if statement to go with else')
                self.if_levels[-1]['active'] = False
                self.if_start = start
                del self.tokens[start:self.index]
            elif self.accept('endif'):
                self.if_levels.pop()
                del self.tokens[start:self.index]
            else:
                del self.tokens[start:self.index]
            self.index = start
        else:
            if self.accept('if') or self.accept('ifdef') or self.accept('ifndef'):
                self.if_levels.append({
                    'active': False,
                    'seen': False
                    })
            elif self.accept('elif'):
                if all(level['active'] for level in self.if_levels[:-1]):
                    if not self.if_levels[-1]['seen'] and self.expression():
                        self.if_levels[-1]['active'] = True
                        self.if_levels[-1]['seen'] = True
                        self.delete_tokens(self.if_start, self.index)
                        self.index = self.if_start
                        self.if_start = None
            elif self.accept('else'):
                if all(level['active'] for level in self.if_levels[:-1]):
                    if not self.if_levels[-1]['seen']:
                        self.if_levels[-1]['active'] = True
                        self.if_levels[-1]['seen'] = True
                        self.delete_tokens(self.if_start, self.index)
                        self.index = self.if_start
                        self.if_start = None
            elif self.accept('endif'):
                self.if_levels.pop()
                # if we transition from inactive to active, delete what was inactive
                if all(level['active'] for level in self.if_levels): # and self.if_start is not None:
                    self.delete_tokens(self.if_start, self.index)
                    self.index = self.if_start
                    self.if_start = None

    def program(self):
        '''
        PROGRAM -> {TOKEN
                  |'#' DIRECTIVE
                  |name
                  |name '(' ARGUMENTS ')'
                  |string string
                   }
        '''
        while not self.peek(Lex.END):
            if self.peek('#'):
                self.directive()
            elif self.peek_defined() and self.if_start is None:
                self.expand()
            elif self.peek(Lex.STRING):
                start = self.index
                left = next(self)
                self.accept(Lex.SPACE)
                if self.peek(Lex.STRING):
                    right = next(self)
                    self.tokens[start:self.index] = [Token(Lex.STRING, left.lexeme+right.lexeme, left.line)]
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
        text = self.replace_comments(text)
        self.parse(self.lexer.lex(text) + [Token(Lex.END, '', self.lexer.line)])

    root = program

    def stream(self):
        """Produce a list of tokens."""
        return [token for token in self.tokens
                if token.type not in {Lex.SPACE, Lex.NEW_LINE}]

    def output(self):
        """Produce the processed input as text."""
        return ''.join(f'"{token.lexeme}"' if token.type is Lex.STRING
                       else token.lexeme for token in self.tokens)

    def comment_replacement(self, match):
        """Replace comments with space/newlines to preserve line numbers."""
        return ' ' + '\n'*match[0].count('\n')

    def peek_defined(self):
        """Peek tokens that are already defined to expand."""
        token = self.tokens[self.index]
        return token.type is Lex.NAME and token.lexeme in self.defined
