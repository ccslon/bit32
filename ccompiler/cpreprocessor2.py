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

lexer = CLexer()

class If:

    def __init__(self, active, seen):
        self.active = active
        self.seen = seen

class Macro:
    
    def __init__(self, params, body):
        self.parameters = params
        self.body = body
        self.enabled = True

class File:

    def __init__(self, name, tokens):
        self.name = name
        self.tokens = tokens

class Expander(Parser):
    
    def __init__(self, defined):
        self.defined = defined
        super().__init__()

    def argument(self):
        """
        ARGUMENT -> {TOKEN|name '(' [ARGUMENT {',' ARGUMENT}] ')'|'(' ARGUMENT ')'}
        """
        self.accept(Lex.SPACE)
        while not self.peek({')', ','}):
            if self.accept(Lex.NAME):
                if self.accept('('):
                    self.accept(Lex.SPACE)
                    if not self.peek(')'):
                        while True:
                            self.argument()
                            if self.accept(')'):
                                break
                            self.expect(',')
            elif self.accept('('):
                self.argument()
                self.expect(')')
            else:
                next(self)

    def expand(self):
        """Expand definitions."""
        name = next(self)
        macro = self.defined[name.lexeme]
        macro.enabled = False
        if macro.parameters is None:
            return [Token(ttype, lexeme, name.line) for ttype, lexeme in macro.body]
        args = {}
        if self.accept('('):
            self.accept(Lex.SPACE)
            if not self.accept(')'):
                for param in macro.parameters:
                    self.accept(Lex.SPACE)
                    start = self.index
                    self.argument()
                    args[param] = self.tokens[start:self.index]
                    if self.accept(')'):
                        break
                    self.expect(',')
            repl = []
            expanded_args = {}
            for ttype, lexeme in macro.body:
                if ttype is Lex.STRINGIZE:
                    repl.append(Token(Lex.STRING, ''.join(str(arg.lexeme) for arg in args[lexeme]), name.line))
                elif ttype is Lex.CONCAT:
                    left, right = lexeme.split('##')
                    if left in args:
                        left = ''.join(str(arg.lexeme) for arg in args[left])
                    if right in args:
                        right = ''.join(str(arg.lexeme) for arg in args[right])
                    repl.extend(lexer.lex(left+right, name.line)[:-1])  # cut off Lex.END
                elif lexeme in args:
                    if lexeme not in expanded_args:
                        expanded_args[lexeme] = Expander(self.defined).parse(args[lexeme])
                    repl.extend(expanded_args[lexeme])
                else:
                    repl.append(Token(ttype, lexeme, name.line))
            if not self.peek(Lex.SPACE):
                repl.append(Token(Lex.SPACE, ' ', name.line))
            return repl
        return [name]    
    
    def parse(self, tokens):
        output = []
        stack = [(0, tokens)]
        while stack:
            self.index, self.tokens = stack.pop()
            while self.index < len(self.tokens):
                if self.peek_defined():
                    expanded = self.expand()
                    stack.append((self.index, self.tokens))
                    self.index = 0
                    self.tokens = expanded
                else:
                    output.append(next(self))
        return output

    def peek_defined(self):
        """Peek tokens that are already defined to expand."""
        token = self.tokens[self.index]
        return token.type is Lex.NAME and token.lexeme in self.defined and self.defined[token.lexeme].enabled

class CPreProcessor(Expander):
    """Class for C language pre-processor."""

    COMMENT = re.compile(r'''
                         /\*(.|\n)*?\*/     #multi line comment
                         |
                         //.*(\n|$)         #single line comment
                         ''', re.M | re.X)

    def __init__(self):
        self.original = ''
        self.std_included = set()
        self.files = []
        self.path = ''
        self.active = True
        self.if_levels = []
        super().__init__({'and': (Lex.SYMBOL, '&&'),
                          'and_eq': (Lex.SYMBOL, '&='),
                          'bitand': (Lex.SYMBOL, '&'),
                          'or': (Lex.SYMBOL, '||'),
                          'or_eq': (Lex.SYMBOL, '|='),
                          'bitor': (Lex.SYMBOL, '|'),
                          'compl': (Lex.SYMBOL, '~'),
                          'not': (Lex.SYMBOL, '!'),
                          'not_eq': (Lex.SYMBOL, '!='),
                          'xor': (Lex.SYMBOL, '^'),
                          'xor_eq': (Lex.SYMBOL, '^=')})

    def parameter(self):
        """
        PARAMETER -> name
        """
        self.accept(Lex.SPACE)
        name = self.expect(Lex.NAME)
        self.accept(Lex.SPACE)
        return name.lexeme

    def parameters(self):
        """
        PARAMETERS -> [PARAMETER {',' PARAMETER}]
        """
        parameters = []
        self.accept(Lex.SPACE)
        if not self.peek(')'):
            while True:
                parameters.append(self.parameter())
                if self.peek(')'):
                    break
                self.expect(',')
        return parameters

    def object_like(self):
        body = []
        while not self.peek({Lex.NEW_LINE, Lex.END}):
            body.append(next(self))
        return Macro(None, [(token.type, token.lexeme) for token in body])

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
                body.append(Token(Lex.CONCAT, f'{left.lexeme}##{right.lexeme}', left.line))
            else:
                body.append(next(self))
        return Macro(params, [(token.type, token.lexeme) for token in body])

    def undef(self):
        self.accept(Lex.SPACE)
        del self.defined[self.expect(Lex.NAME).lexeme]

    def include_file(self, file_name, file_path):
        """Open the file at the given file path and include it."""
        if self.original.endswith(file_name):
            self.error(f'Circular dependency originating in {self.original}')
        temp = self.tokens, self.index, self.active, self.if_levels, self.path, self.defined['__FILE__']
        self.process_file(file_path, file_name)
        self.tokens, self.index, self.active, self.if_levels, self.path, self.defined['__FILE__'] = temp

    def include(self):
        self.accept(Lex.SPACE)
        if self.peek(Lex.STRING):
            self.include_file(next(self).lexeme, [self.path])
        elif self.peek(Lex.STD):
            file_name = next(self).lexeme
            if file_name not in self.std_included:
                self.include_file(file_name, [os.getcwd(), 'ccompiler', 'std'])
                self.std_included.add(file_name)
        else:
            self.error('Expected file name')

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
        output = []
        stack = [(self.index, self.tokens)]
        while stack:
            self.index, self.tokens = stack.pop()
            while self.index < len(self.tokens):
                if self.peek(Lex.END):
                    break
                if self.accept('#'):
                    self.directive()
                elif self.peek(Lex.NEW_LINE):
                    output.append(next(self))
                elif self.active:
                    if self.peek_defined():
                        expanded = self.expand() + [Token(Lex.END, '', -1)]
                        stack.append((self.index, self.tokens))
                        self.index = 0
                        self.tokens = expanded
                    elif self.peek(Lex.STRING):
                        left = next(self)
                        space = self.accept(Lex.SPACE)
                        if self.peek(Lex.STRING):
                            right = next(self)
                            output.append(Token(Lex.STRING, left.lexeme+right.lexeme, left.line))
                        else:
                            output.append(left)
                            if space is not None:
                                output.append(space)
                    else:
                        output.append(next(self))
            # reenable macros
            for macro in self.defined.values():
                macro.enabled = True
        output.append(next(self))  # for Lex.END
        return output

    def parse(self, tokens):
        """Override of parse to initialize preproc specific members."""
        self.tokens = tokens
        self.index = 0
        return self.program()
    
    def process_file(self, file_path, file_name):
        self.active = True
        self.if_levels = []
        with open(os.path.sep.join(file_path + [file_name])) as file:
            self.path = os.path.dirname(os.path.abspath(file.name))            
            self.defined['__FILE__'] = Macro(None, [(Lex.STRING, os.path.abspath(file.name))])
            text = file.read()
        text = self.replace_comments(text)
        output = self.parse(lexer.lex(text))
        self.files.append((file_name, output))
    
    def process(self, file_name):
        """Process the list of tokens."""
        self.original = file_name
        self.defined.clear()
        self.std_included.clear()
        self.files.clear()
        self.process_file([], file_name)

    def stream(self):
        """Produce a list of tokens."""
        return [File(file_name.rsplit(os.path.sep, 1)[-1][:-2],
                     [token for token in tokens if token.type not in {Lex.SPACE, Lex.NEW_LINE}])
                for file_name, tokens in self.files]

    def output(self):
        """Produce the processed input as text."""
        return ''.join(f'"{token.lexeme}"' if token.type is Lex.STRING
                       else str(token.lexeme) for _, tokens in self.files for token in tokens)

    def comment_replacement(self, match):
        """Replace comments with space/newlines to preserve line numbers."""
        return ' ' + '\n'*match[0].count('\n')

    def replace_comments(self, text):
        """Ignore/replace comments in C input."""
        return self.COMMENT.sub(self.comment_replacement, text)