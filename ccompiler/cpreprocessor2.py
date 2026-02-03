# -*- coding: utf-8 -*-
"""
Created on Thu Jan 15 10:08:22 2026

@author: ccslon
"""
import os
import re
from dataclasses import dataclass, field
from datetime import datetime
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


@dataclass
class If:
    """Class for keeping track of ifs."""

    active: bool
    seen: bool


@dataclass
class Macro:
    """Class for macros defined in source file."""

    parameters: list[str]
    body: list[Token]
    disabled: int = 0


@dataclass
class Frame:
    """Class for file frame."""

    path: str
    active: bool = True
    ifs: list[If] = field(default_factory=list)


class Expander(Parser):
    """Class used for expanding macros."""

    def __init__(self, defined):
        super().__init__()
        self.macro = None
        self.stack = None
        self.defined = defined
        self.lexer = CLexer()

    def argument(self):
        """
        ARGUMENT -> {TOKEN|name '(' [ARGUMENT {',' ARGUMENT}] ')'|'(' ARGUMENT ')'}
        """
        self.accept(Lex.SPACE)
        while not self.peek({')', ','}):
            if self.accept(Lex.NAME):
                if self.accept('('):
                    self.accept(Lex.SPACE)
                    if not self.accept(')'):
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
        expanded = []
        if macro.parameters is None:
            expanded.extend(Token(ttype, lexeme, name.line) for ttype, lexeme in macro.body)
        elif self.accept('('):
            args = {}
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

            def stringize(lexeme):
                return ''.join(str(arg.lexeme) for arg in args[lexeme])
            expanded_args = {}
            for ttype, lexeme in macro.body:
                if ttype is Lex.STRINGIZE:
                    expanded.append(Token(Lex.STRING, stringize(lexeme), name.line))
                elif ttype is Lex.CONCAT:
                    left, right = lexeme.split('##')
                    if left in args:
                        left = stringize(left)
                    if right in args:
                        right = stringize(right)
                    expanded.extend(self.lexer.lex(left+right, name.line)[:-1])  # cut off Lex.END
                elif lexeme in args:
                    if lexeme not in expanded_args:
                        expanded_args[lexeme] = Expander(self.defined).parse(args[lexeme])
                    expanded.extend(expanded_args[lexeme])
                else:
                    expanded.append(Token(ttype, lexeme, name.line))
            if self.index < len(self.tokens) and not self.peek(Lex.SPACE):  # To preserve token boudaries
                expanded.append(Token(Lex.SPACE, ' ', name.line))
        else:
            expanded.append(name)
        macro.disabled += 1
        self.push(expanded, macro)

    def stream(self):
        """
        STREAM -> {name ['(' ARGUMENTS ')']|TOKEN}
        """
        output = []
        while self.stack:
            self.pop()
            while self.index < len(self.tokens):
                if self.peek_defined():
                    self.expand()
                else:
                    output.append(next(self))
        return output

    root = stream

    def unwind(self):
        """Unwind the stack as needed."""
        while self.index >= len(self.tokens):
            self.pop()

    def push(self, tokens, macro):
        self.stack.append((self.index, self.tokens, self.macro))
        self.index = 0
        self.tokens = tokens
        self.macro = macro

    def pop(self):
        """Handle popping from stack."""
        if self.macro is not None:
            self.macro.disabled -= 1
        self.index, self.tokens, self.macro = self.stack.pop()

    def parse(self, tokens):
        """Override of parse to initialize preproc specific members."""
        self.stack = [(0, tokens, None)]
        return self.root()

    def __next__(self):
        """Override of __next__ to use unwind."""
        self.unwind()
        return super().__next__()

    def peek(self, peek):
        """Override of peek to use unwind."""
        self.unwind()
        return super().peek(peek)

    def peek_defined(self):
        """Peek tokens that are already defined and enabled for expansion."""
        token = self.tokens[self.index]
        return token.type is Lex.NAME and token.lexeme in self.defined and self.defined[token.lexeme].disabled == 0


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
        self.frame = None
        super().__init__({'and': [(Lex.SYMBOL, '&&')],
                          'and_eq': [(Lex.SYMBOL, '&=')],
                          'bitand': [(Lex.SYMBOL, '&')],
                          'or': [(Lex.SYMBOL, '||')],
                          'or_eq': [(Lex.SYMBOL, '|=')],
                          'bitor': [(Lex.SYMBOL, '|')],
                          'compl': [(Lex.SYMBOL, '~')],
                          'not': [(Lex.SYMBOL, '!')],
                          'not_eq': [(Lex.SYMBOL, '!=')],
                          'xor': [(Lex.SYMBOL, '^')],
                          'xor_eq': [(Lex.SYMBOL, '^=')]})

    def primary(self):
        """
        PRIMARY -> 'defined' name
                  |'defined' '(' name ')'
                  |name|decimal|number|character|string|'(' EXPRESSION ')'
        """
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
        if self.peek({Lex.DECIMAL, Lex.NUMBER}):
            return next(self).lexeme
        if self.peek(Lex.CHARACTER):
            return ord(unescape(next(self).lexeme))
        if self.peek(Lex.STRING):
            return unescape(next(self).lexeme)
        if self.accept('('):
            primary = self.expression()
            self.expect(')')
            return primary
        self.error('Expected primary expression')

    def unary(self):
        """
        UNARY -> ['-'|'~'|'!'] PRIMARY
        """
        self.accept(Lex.SPACE)
        if self.accept('-'):
            return -self.primary()
        if self.accept('~'):
            return ~self.primary()
        if self.accept('!'):
            return not self.primary()
        return self.primary()

    def multiplicative(self):
        """
        MULTIPLICATIVE -> UNARY {('*', '/', '%') UNARY}
        """
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
        """
        ADDITIVE -> MULTIPLICATIVE {('+'|'-') MULTIPLICATIVE}
        """
        additive = self.multiplicative()
        while self.peek({'+', '-'}):
            additive = {
                '+': add,
                '-': sub
                }[next(self).lexeme](additive, self.multiplicative())
        return additive

    def shift(self):
        """
        SHIFT -> ADDITIVE {('<<'|'>>') ADDITIVE}
        """
        shift = self.additive()
        while self.peek({'<<', '>>'}):
            shift = {
                '<<': lshift,
                '>>': rshift
                }[next(self).lexeme](shift, self.additive())
        return shift

    def relational(self):
        """
        RELATIONAL -> SHIFT {('<'|'>'|'<='|'>=') SHIFT}
        """
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
        """
        EQUALITY -> RELATIONAL {('=='|'!=') RELATIONAL}
        """
        equality = self.relational()
        while self.peek({'==', '!='}):
            equality = {
                '==': eq,
                '!=': ne,
                }[next(self).lexeme](equality, self.relational())
        return equality

    def bitwise_and(self):
        """
        BITWISE_AND -> EQUALITY {'&' EQUALITY}
        """
        bitwise_and = self.equality()
        while self.accept('&'):
            bitwise_and &= self.equality()
        return bitwise_and

    def bitwise_xor(self):
        """
        BITWISE_XOR -> BITWISE_AND {'^' BITWISE_AND}
        """
        bitwise_xor = self.bitwise_and()
        while self.accept('^'):
            bitwise_xor ^= self.bitwise_and()
        return bitwise_xor

    def bitwise_or(self):
        """
        BITWISE_OR -> BITWISE_XOR {'|' BITWISE_XOR}
        """
        bitwise_or = self.bitwise_xor()
        while self.accept('|'):
            bitwise_or |= self.bitwise_xor()
        return bitwise_or

    def logical_and(self):
        """
        LOGICAL_AND -> BITWISE_OR {'&&' BITWISE_OR}
        """
        logical_and = self.bitwise_or()
        while self.accept('&&'):
            other = self.bitwise_or()
            logical_and = logical_and and other
        return logical_and

    def logical_or(self):
        """
        LOGICAL_OR -> LOGICAL_AND {'||' LOGICAL_AND}
        """
        logical_or = self.logical_and()
        while self.accept('||'):
            other = self.logical_and()
            logical_or = logical_or or other
        return logical_or

    def expression(self):
        """
        EXPRESSION -> LOGICAL_OR
        """
        return self.logical_or()

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
        """
        DEFINE -> 'define' name {TOKEN}
        """
        self.accept(Lex.SPACE)
        body = []
        while not self.peek({Lex.NEW_LINE, Lex.END}):
            body.append(next(self))
        return Macro(None, [(token.type, token.lexeme) for token in body])

    def function_like(self):
        """
        DEFINE -> 'define' name '(' PARAMETERS ')' {TOKEN|'#' TOKEN|TOKEN '##' TOKEN}
        """
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
        """
        UNDEF -> 'undef' name
        """
        self.accept(Lex.SPACE)
        del self.defined[self.expect(Lex.NAME).lexeme]

    def include_file(self, file_name, file_path):
        """Open the file at the given file path and include it."""
        if self.original.endswith(file_name):
            self.error(f'Circular dependency originating in {self.original}')
        temp = self.tokens, self.index, self.macro, self.stack, self.frame, self.defined['__FILE__'], self.defined['__LINE__']
        self.process_file(file_path, file_name)
        self.tokens, self.index, self.macro, self.stack, self.frame, self.defined['__FILE__'], self.defined['__LINE__'] = temp

    def include(self):
        """
        INCLUDE -> 'include' (string|std)
        """
        self.accept(Lex.SPACE)
        if self.peek(Lex.STRING):
            self.include_file(next(self).lexeme, [self.frame.path])
        elif self.peek(Lex.STD):
            file_name = next(self).lexeme
            if file_name not in self.std_included:
                self.include_file(file_name, [os.getcwd(), 'ccompiler', 'std'])
                self.std_included.add(file_name)
        else:
            self.error('Expected file name')

    def directive(self):
        """
        DIRECTIVE -> DEFINE
                    |UNDEF
                    |INCLUDE
                    |('if'|'elif') EXPRESSION
                    |('ifdef'|'ifndef') name
                    |'else'|'endif'
        """
        self.accept(Lex.SPACE)
        if self.frame.active:
            if self.accept('define'):
                self.accept(Lex.SPACE)
                name = self.expect(Lex.NAME)
                self.defined[name.lexeme] = self.function_like() if self.peek('(') else self.object_like()
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
                self.frame.active = test
                self.frame.ifs.append(If(test, test))
            elif self.peek({'elif', 'else'}):
                next(self)
                if not self.frame.ifs:
                    self.error('No corresponding if statement to go with else')
                self.frame.active = self.frame.ifs[-1].active = False
            elif self.accept('endif'):
                self.frame.ifs.pop()
        else:
            if self.peek({'if', 'ifdef', 'ifndef'}):
                next(self)
                self.frame.ifs.append(If(False, False))
            elif self.accept('elif'):
                top = self.frame.ifs.pop()
                test = self.expression()
                outer = all(level.active for level in self.frame.ifs)
                self.frame.active = test and outer and not top.seen
                self.frame.ifs.append(If(self.frame.active, top.seen or test))
            elif self.accept('else'):
                top = self.frame.ifs.pop()
                outer = all(level.active for level in self.frame.ifs)
                self.frame.active = outer and not top.seen
                self.frame.ifs.append(If(self.frame.active, True))
            elif self.accept('endif'):
                self.frame.ifs.pop()
                self.frame.active = all(level.active for level in self.frame.ifs)

    def program(self):
        """
        PROGRAM -> {'#' DIRECTIVE|'\n'|name ['(' ARGUMENTS ')']|string string|TOKEN}
        """
        output = []
        while self.stack:
            self.pop()
            while self.index < len(self.tokens):
                if self.accept('#'):
                    self.directive()
                elif self.peek(Lex.NEW_LINE):
                    new = next(self)
                    self.defined['__LINE__'] = Macro(None, [(Lex.NUMBER, new.line)])
                    output.append(new)
                elif self.frame.active:
                    if self.peek_defined():
                        self.expand()
                    elif self.peek(Lex.STRING):
                        left = next(self)
                        space = self.accept(Lex.SPACE)
                        if self.peek(Lex.STRING):
                            right = next(self)
                            self.push([Token(Lex.STRING, left.lexeme+right.lexeme, left.line)], None)
                        else:
                            output.append(left)
                            if space is not None:
                                output.append(space)
                    else:
                        output.append(next(self))
                else:
                    next(self)
        return output

    root = program

    def process_file(self, file_path, file_name):
        """Process a single source file."""
        with open(os.path.sep.join(file_path + [file_name])) as file:
            self.frame = Frame(os.path.dirname(os.path.abspath(file.name)))
            self.defined['__FILE__'] = Macro(None, [(Lex.STRING, os.path.abspath(file.name))])
            self.defined['__LINE__'] = Macro(None, [(Lex.NUMBER, 1)])
            text = file.read()
        text = self.replace_comments(text)
        output = self.parse(self.lexer.lex(text))
        self.files.append((file_name, output))

    def process(self, file_name):
        """Process a source file."""
        self.original = file_name
        self.std_included.clear()
        self.files.clear()
        self.defined.clear()
        self.defined['__BASE_FILE__'] = Macro(None, [(Lex.STRING, file_name)])
        now = datetime.now()
        self.defined['__DATE__'] = Macro(None, [(Lex.STRING, now.strftime("%b %d %Y"))])
        self.defined['__TIME__'] = Macro(None, [(Lex.STRING, now.strftime("%H:%M:%S"))])
        self.process_file([], file_name)

    def output(self):
        """Produce a list of tokens."""
        return [token for _, tokens in self.files for token in tokens
                if token.type not in {Lex.SPACE, Lex.NEW_LINE, Lex.END}] + [Token(Lex.END, '', self.lexer.line)]

    def comment_replacement(self, match):
        """Replace comments with space/newlines to preserve line numbers."""
        return ' ' + '\n'*match[0].count('\n')

    def replace_comments(self, text):
        """Ignore/replace comments in C input."""
        return self.COMMENT.sub(self.comment_replacement, text)

    def __str__(self):
        """Produce the processed input as text."""
        return ''.join(f'"{token.lexeme}"' if token.type is Lex.STRING else str(token.lexeme)
                       for _, tokens in self.files for token in tokens)
