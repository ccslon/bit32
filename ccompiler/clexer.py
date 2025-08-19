# -*- coding: utf-8 -*-
"""
Created on Sun Aug 17 14:24:04 2025

@author: Colin
"""
import re
from enum import Enum, auto
from typing import NamedTuple

class Lex(Enum):
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

CTYPES = {
    'const','volatile','void',
    'char','short','int',
    'long','float','unsigned',
    'signed','struct','enum','union'
}

class Token(NamedTuple):
    type: str
    lexeme: str
    line: int
    def error(self, msg):
        raise SyntaxError(f'Line {self.line}: {msg}')

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
        return [Token(Lex[match.lastgroup.upper()], result, self.line) for match in self.regex.finditer(text) if (result := self.action[match.lastgroup](self, match[0])) is not None]

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
    RE_ctype = rf"\b({'|'.join(CTYPES)})\b"
    RE_keyword = r'\b(include|define|undef|typedef|static|extern|sizeof|return|if|ifdef|ifndef|else|endif|switch|case|default|while|do|for|break|continue|goto)\b'
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
