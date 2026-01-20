# -*- coding: utf-8 -*-
"""
Created on Sun Aug 17 14:24:04 2025

@author: Colin
"""
import re
from enum import Enum, auto
from typing import NamedTuple


class Lex(Enum):
    """Enum for token types."""

    DECIMAL = auto()
    NUMBER = auto()
    CHARACTER = auto()
    STD = auto()
    STRING = auto()
    CTYPE = auto()
    KEYWORD = auto()
    SYMBOL = auto()
    NAME = auto()
    SPACE = auto()
    NEW_LINE = auto()
    INVALID = auto()
    END = auto()
    STRINGIZE = auto()
    CONCAT = auto()


# all of the type keywords in C that this compiler supports
CTYPES = {
    'const', 'volatile', 'void',
    'char', 'short', 'int',
    'long', 'float', 'unsigned',
    'signed', 'struct', 'enum', 'union'
}


class Token(NamedTuple):
    """Class for tokens in input."""

    type: Lex
    lexeme: str
    line: int        

    def error(self, msg):
        """Raise error messages for the parser."""
        raise SyntaxError(f'Line {self.line}: {msg}')


class MetaLexer(type):
    """
    Meta class for Lexers.

    Meta-coding that allows lexer patterns to be methods.
    """

    def __init__(self, name, _, attrs):
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
        self.regex = re.compile('|'.join(rf'(?P<{name}>{pattern})'
                                         for name, pattern in regex))


class Lexer(metaclass=MetaLexer):
    """
    Base class for lexers.

    Lexers take in a string as input and output a list of tokens
    that represent the input based on the regex patterns defined in the class.
    """

    def __init__(self):
        self.line = 1

    def lex(self, text, line=0):
        """Produce list of tokens based on defined regex patterns."""
        self.line = line
        return [Token(Lex[match.lastgroup.upper()], result, self.line)
                for match in self.regex.finditer(text)
                if (result := self.action[match.lastgroup](self, match[0]))
                is not None]  # allows actions that do not create a token


class CLexer(Lexer):
    """Lexer specifically for the C programming language."""

    def RE_decimal(self, match):
        r'\d+\.\d+'
        return float(match)

    def RE_number(self, match):
        r'0x[0-9A-Fa-f]+|0b[01]+|\d+'
        if match.startswith('0x'):
            return int(match, base=16)
        if match.startswith('0b'):
            return int(match, base=2)
        return int(match)

    def RE_character(self, match):
        r"'(\\'|\\?[^'])'"
        return match[1:-1]

    def RE_string(self, match):
        r'"(\\"|[^"])*"'
        return match[1:-1]

    def RE_std(self, match):
        r'<\s*\w+\.h\s*>'
        return match[1:-1].strip()

    RE_ctype = rf"\b({'|'.join(CTYPES)})\b"

    RE_keyword = r'\b(include|defined?|undef|typedef|static|extern|register|sizeof|return|if|ifdef|ifndef|elif|else|endif|switch|case|default|while|do|for|break|continue|goto)\b'

    RE_symbol = r'[#]{2}|[]#;:()[{}]|[+]{2}|--|->|(<<|>>|[+*/%^|&=!<>-])?=|<<|>>|[|]{2}|[&]{2}|[+*/%^|&=!<>?~-]|[.]{3}|[.]|,'

    RE_name = r'[A-Za-z_]\w*'

    RE_space = r'[ \t]+'

    def RE_line_splice(self, _):
        r'\\\s*\n'
        self.line += 1

    def RE_new_line(self, match):
        r'\n'
        self.line += 1
        return match

    def RE_invalid(self, match):
        r'\S'
        raise SyntaxError(f'line {self.line}: Invalid symbol "{match}"')

    RE_end = r'$'