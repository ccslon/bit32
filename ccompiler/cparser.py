# -*- coding: utf-8 -*-
"""
Created on Mon Jul  3 19:47:39 2023

@author: Colin
"""
from dataclasses import dataclass
from copy import copy
from .parser import Parser
from .clexer import Lex, CTYPES
from .cnodes import Frame, Translation, Definition, VariadicDefinition
from .cexprs import Number, Negative, EnumNumber, Decimal, NegativeDecimal, Character, String
from .cexprs import Post, UnaryOp, Not, Pre, BinaryOp, Compare, Logic
from .cexprs import Local, Attribute, Global, Dot, SubScript, Arrow, AddressOf, Dereference, SizeOf, Cast, Condition
from .ctypes import Type, Void, Float, Int, Short, Char, Pointer, Struct, Union, Array, Function
from .cstatements import Statement, If, Case, Switch, While, Do, For, Continue, Break, Goto, Label, Return, Compound
from .cstatements import Call, VariadicCall, InitialAssign, Assign, InitialListAssign, InitialStringArray
r'''( |\t)+$''' #to delete weird whitespace spyder adds
'''
TODO
[X] Type checking
[X] '.' vs '->' checking
[X] Cast
[X] Allocating local arrays
[X] Globals overhaul including global structs and arrays
[X] Init lists
[X] Proper ++/--
[X] Fix Unions
[X] Enums
[X] peekn
[X] Labels and goto
[X] Division/Modulo
[X] Fix void and void*
[X] Fix array strings e.g. char str[3] = "Hi";
[X] init Arrays of unknown size
[X] Fix negative numbers
[X] Fix const
[X] Add unsigned
[X] Add floats
[ ] Update Docs
[X] Typedef
[X] Const expressions
[ ] Const eval
[X] Function pointers
[ ] Function defs in function defs
[X] Error handling
[X] Generate vs Reduce
[X] Scope in Parser
[X] Line numbers in errors
[X] Returning local structs
[X] Labels in C have scope
[X] PREPROCESSING
    [X] Include header files
    [X] Macros

[ ] Bit fields
[X] Proper typedef
[X] Return width
[X] Proper preproc
[X] Assertion messages
[ ] Breakpoints in circuit
[ ] fix interrupt on interrupt bug in circuit
[X] Warn when global names collide
[X] better debugging in ASM

Test:
    [ ] Union arrow op
    [ ] Pre
    [ ] NegativeDecimal
    [ ] cast
    [ ] local typedef
    [ ] return;
    [ ] continue;
    [ ] extern
'''


@dataclass
class FunctionInfo:
    """Containment class for C function info."""

    ret: Type
    name: str
    space: int = 0
    returns: bool = False
    calls: bool = False
    max_arguments: int = 0

    def __iter__(self):
        """For unpacking."""
        return iter((self.returns, self.calls, self.max_arguments, self.space))


class Scope:
    """Class the represents scope in a C program."""

    def __init__(self):
        self.locals = Frame()
        self.structs = {}
        self.typedefs = {}
        self.unions = {}
        self.enums = []
        self.enum_numbers = {}

    def copy(self):
        """Create a copy of the scope ."""
        new = Scope()
        new.locals.update(self.locals)
        new.structs.update(self.structs)
        new.typedefs.update(self.typedefs)
        new.unions.update(self.unions)
        new.enums.extend(self.enums)
        new.enum_numbers.update(self.enum_numbers)
        return new

    def clear(self):
        """Clear the scope."""
        self.locals.clear()
        self.structs.clear()
        self.typedefs.clear()
        self.unions.clear()
        self.enums.clear()
        self.enum_numbers.clear()


class CParser(Parser):
    """Parser class for parsing the C programming language."""

    STATEMENTS = {'{', Lex.NAME, 'if', '*', 'return', 'for', 'while', '(',
                  'switch', 'do', '++', '--', 'break', 'continue', ';', 'goto'}

    def __init__(self):
        self.globs = {}
        self.scope = Scope()
        self.stack = []
        super().__init__()

    def parse(self, tokens):
        """Override of parse."""
        self.globs.clear()
        self.scope.clear()
        self.stack.clear()
        return super().parse(tokens)

    def resolve(self, name):
        """Resolve name of variables."""
        if name in self.scope.locals:
            return self.scope.locals[name]
        if name in self.stack_params:
            return self.stack_params[name]
        if name in self.globs:
            return self.globs[name]
        if name in self.scope.enum_numbers:
            return self.scope.enum_numbers[name]
        self.error(f'Name "{name}" not found')

    def primary(self):
        '''
        PRIMARY -> name|number|character|string|'(' EXPR ')'
        '''
        if self.peek(Lex.NAME):
            return self.resolve(next(self).lexeme)
        if self.peek(Lex.DECIMAL):
            return Decimal(next(self))
        if self.peek(Lex.NUMBER):
            return Number(next(self))
        if self.peek(Lex.CHARACTER):
            return Character(next(self))
        if self.peek(Lex.STRING):
            return String(next(self))
        if self.accept('('):
            primary = self.expr()
            self.expect(')')
            return primary
        self.error('PRIMARY EXPRESSION')

    def postfix(self):
        '''
        POST -> PRIMARY {'(' arguments ')'|'[' EXPR ']'|'++'|'--'|'.' name|'->' name}
        '''
        postfix = self.primary()
        while self.peek({'(', '[', '++', '--', '.', '->'}):
            if self.peek('('):
                if not isinstance(postfix.type, Function):
                    self.error(f'"{postfix.token.lexeme}" is not a function')
                call_type = VariadicCall if postfix.type.variable else Call
                self.func.calls = True
                postfix = call_type(next(self), postfix, self.arguments())
                self.expect(')')
            elif self.peek('['):
                postfix = SubScript(next(self), postfix, self.expr())
                self.expect(']')
            elif self.peek({'++', '--'}):
                postfix = Post(next(self), postfix)
            elif self.accept('.'):
                if not isinstance(postfix.type, (Struct, Union)):
                    self.error(f'"{postfix.token.lexeme}" is type {postfix.type}')
                name = self.expect(Lex.NAME)
                if name.lexeme not in postfix.type:
                    self.error(f'"{name.lexeme}" is not an attribute of {postfix.type}')
                attr = postfix.type[name.lexeme]
                postfix = Dot(name, postfix, attr)
            elif self.accept('->'):
                if not isinstance(postfix.type, Pointer):
                    self.error(f'{postfix.type} is not pointer type')
                name = self.expect(Lex.NAME)
                if name.lexeme not in postfix.type.to:
                    self.error(f'"{name.lexeme}" is not an attribute of {postfix.type.to}')
                attr = postfix.type.to[name.lexeme]
                postfix = Arrow(name, postfix, attr)
        return postfix

    def arguments(self):
        '''
        arguments -> [ASSIGN {',' ASSIGN}]
        '''
        arguments = []
        if not self.peek(')'):
            arguments.append(self.assign())
            while self.accept(','):
                arguments.append(self.assign())
        self.func.max_arguments = min(max(self.func.max_arguments, len(arguments)), 4)
        return arguments

    def unary(self):
        '''
        UNARY -> POSTFIX
                |('*'|'-'|'~'|'&'|'!') CAST
                |('++'|'--') UNARY
                |'sizeof' '(' TYPE_NAME ')'
                |'sizeof' UNARY
        '''
        if self.peek('*'):
            return Dereference(next(self), self.cast())
        if self.peek2('-', Lex.DECIMAL):
            next(self)
            return NegativeDecimal(next(self))
        if self.peek2('-', Lex.NUMBER):
            next(self)
            return Negative(next(self))
        if self.peek({'-', '~'}):
            return UnaryOp(next(self), self.cast())
        if self.peek({'++', '--'}):
            return Pre(next(self), self.unary())
        if self.peek('!'):
            return Not(next(self), self.cast())
        if self.peek('&'):
            return AddressOf(next(self), self.cast())
        if self.peek('sizeof'):
            token = next(self)
            if self.accept('('):
                unary = SizeOf(self.type_name(), token)
                self.expect(')')
            else:
                unary = SizeOf(self.unary().type, token)
            return unary
        return self.postfix()

    def cast(self):
        '''
        CAST -> UNARY
               |'(' TYPE_NAME ')' CAST
        '''
        if self.peek2('(', CTYPES | self.scope.typedefs.keys()):
            token = next(self)
            ctype = self.type_name()
            self.expect(')')
            return Cast(token, ctype, self.cast())
        return self.unary()

    def mul(self):
        '''
        MUL -> CAST {('*'|'/'|'%') CAST}
        '''
        mul = self.cast()
        while self.peek({'*', '/', '%'}):
            mul = BinaryOp(next(self), mul, self.cast())
        return mul

    def add(self):
        '''
        ADD -> MUL {('+'|'-') MUL}
        '''
        add = self.mul()
        while self.peek({'+', '-'}):
            add = BinaryOp(next(self), add, self.mul())
        return add

    def shift(self):
        '''
        SHIFT -> ADD {('<<'|'>>') ADD}
        '''
        shift = self.add()
        while self.peek({'<<', '>>'}):
            shift = BinaryOp(next(self), shift, self.add())
        return shift

    def relation(self):
        '''
        RELA -> SHIFT {('<'|'>'|'<='|'>=') SHIFT}
        '''
        relation = self.shift()
        while self.peek({'<', '>', '<=', '>='}):
            relation = Compare(next(self), relation, self.shift())
        return relation

    def equality(self):
        '''
        EQUA -> RELA {('=='|'!=') RELA}
        '''
        equality = self.relation()
        while self.peek({'==', '!='}):
            equality = Compare(next(self), equality, self.relation())
        return equality

    def bit_and(self):
        '''
        BIT_AND -> EQUA {'&' EQUA}
        '''
        bit_and = self.equality()
        while self.peek('&'):
            bit_and = BinaryOp(next(self), bit_and, self.equality())
        return bit_and

    def bit_xor(self):
        '''
        BIT_XOR -> BIT_AND {'^' BIT_AND}
        '''
        bit_xor = self.bit_and()
        while self.peek('^'):
            bit_xor = BinaryOp(next(self), bit_xor, self.bit_and())
        return bit_xor

    def bit_or(self):
        '''
        BIT_OR -> BIT_XOR {'|' BIT_XOR}
        '''
        bit_or = self.bit_xor()
        while self.peek('|'):
            bit_or = BinaryOp(next(self), bit_or, self.bit_xor())
        return bit_or

    def logic_and(self):
        '''
        LOGIC_AND -> BIT_OR {'&&' BIT_OR}
        '''
        logic_and = self.bit_or()
        while self.peek('&&'):
            logic_and = Logic(next(self), logic_and, self.bit_or())
        return logic_and

    def logic_or(self):
        '''
        LOGIC_OR -> LOGIC_AND {'||' LOGIC_AND}
        '''
        logic_or = self.logic_and()
        while self.peek('||'):
            logic_or = Logic(next(self), logic_or, self.logic_and())
        return logic_or

    def cond(self):
        '''
        COND -> LOGIC_OR ['?' EXPR ':' COND]
        '''
        cond = self.logic_or()
        if self.accept('?'):
            expr = self.expr()
            cond = Condition(self.expect(':'), cond, expr, self.cond())
        return cond

    def assign(self):
        '''
        ASSIGN -> UNARY ['+'|'-'|'*'|'/'|'%'|'<<'|'>>'|'^'|'|'|'&']'=' ASSIGN
                 |COND
        '''
        assign = self.cond()
        if self.peek({'=', '+=', '-=', '*=', '/=', '%=',
                      '<<=', '>>=', '^=', '|=', '&=', '/=', '%='}):
            if not isinstance(assign, (Local, Global, Dot,
                                       Arrow, SubScript, Dereference)):
                self.error(f'Cannot assign to {type(assign)}')
            if self.peek('='):
                assign = Assign(next(self), assign, self.assign())
            else:
                token = next(self)
                assign = Assign(token, assign,
                                BinaryOp(token, assign, self.assign()))
        return assign

    def expr(self):
        '''
        EXPR -> ASSIGN
        '''
        return self.assign()

    def const(self):
        '''
        CONST -> COND
        '''
        const = self.cond()
        if not const.is_const():
            self.error('Must be a constant expression')
        # TODO return const.eval()
        return const

    def enum(self, value):
        '''
        ENUM -> name ['=' CONST]
        '''
        name = self.expect(Lex.NAME)
        if self.accept('='):
            value = Number(self.expect(Lex.NUMBER)).value  # todo
        if not name.lexeme not in self.scope.enum_numbers:
            self.error(f'Redeclaration of enumerator "{name.lexeme}"')
        self.scope.enum_numbers[name.lexeme] = EnumNumber(name, value)
        return value

    def attr(self, spec, ctype):
        '''
        ATTR -> DECLR [':' number]
        '''
        ctype, name = self.declr(ctype)
        if self.accept(':'):
            self.expect(Lex.NUMBER)
        if name is None and isinstance(ctype, Union):
            for name, attr in ctype.items():
                attr.offset = spec.size
                spec.data[name] = attr
            spec.size += ctype.size
        else:
            spec[name.lexeme] = Attribute(ctype, name)

    def spec(self):
        '''
        TYPE_SPEC -> type
                    |'void'
                    |name
                    |('struct'|'union') [name] '{' {QUAL ATTR {',' ATTR} ';'} '}'
                    |'enum' [name] '{' ENUM {',' ENUM}'}'
        '''
        if self.accept('void'):
            spec = Void()
        elif self.peek(Lex.NAME):
            token = next(self)
            if token.lexeme not in self.scope.typedefs:
                self.error(f'typedef "{token.lexeme}" not found')
            spec = copy(self.scope.typedefs[token.lexeme])
        elif self.accept('struct'):
            name = self.accept(Lex.NAME)
            if name:
                if name.lexeme not in self.scope.structs:
                    self.scope.structs[name.lexeme] = Struct(name)
                spec = self.scope.structs[name.lexeme]
            else:
                spec = Struct(name)
            if self.accept('{'):
                while not self.accept('}'):
                    qual = self.qual()
                    self.attr(spec, qual)
                    while self.accept(','):
                        self.attr(spec, qual)
                    self.expect(';')
        elif self.accept('union'):
            name = self.accept(Lex.NAME)
            if name:
                if name.lexeme not in self.scope.unions:
                    self.scope.unions[name.lexeme] = Union(name)
                spec = self.scope.unions[name.lexeme]
            else:
                spec = Union(name)
            if self.accept('{'):
                while not self.accept('}'):
                    qual = self.qual()
                    self.attr(spec, qual)
                    while self.accept(','):
                        self.attr(spec, qual)
                    self.expect(';')
        elif self.accept('enum'):
            name = self.accept(Lex.NAME)
            if self.accept('{'):
                if name:
                    self.scope.enums.append(name.lexeme)
                value = self.enum(0)
                while self.accept(','):
                    value += 1
                    value = self.enum(value)
                self.expect('}')
            else:
                if not name:
                    self.error("Did not specify enum name")
                if name.lexeme not in self.scope.enums:
                    self.error(f'Enum name "{name.lexeme}" not found')
            spec = Char()
        elif self.accept('float'):
            spec = Float()
        else:
            if self.accept('unsigned'):
                signed = False
            else:
                self.accept('signed')
                signed = True
            if self.accept('char'):
                spec = Char(signed)
            elif self.accept('short'):
                self.accept('int')
                spec = Short(signed)
            elif self.accept('int'):
                spec = Int(signed)
            elif self.accept('long'):
                self.accept('int')
                spec = Int(signed)
            else:
                spec = Int(signed)
        return spec

    def qual(self):
        '''
        TYPE_QUAL -> ['const'|'volatile'] SPEC
        '''
        if self.accept('const'):
            qual = self.spec()
            qual.const = True
            return qual
        self.accept('volatile')
        return self.spec()

    def type_name(self):
        '''
        TYPE_NAME -> QUAL ABS_DECLR
        '''
        type_name = self.qual()
        types = []
        name = self._declr(types)
        if name is not None:
            self.error(f'Did not expect name "{name.lexeme}" in TYPE NAME')
        for new_type, arguments in reversed(types):
            type_name = new_type(type_name, *arguments)
        return type_name

    def _declr(self, types):
        '''
        DECLR -> {'*'} DIR_DECLR
        '''
        ns = 0
        while self.accept('*'):
            ns += 1
        name = self.dir_declr(types)
        for _ in range(ns):
            types.append((Pointer, ()))
        return name

    def dir_declr(self, types):
        '''
        DIR_DECLR -> ('(' _DECLR ')'|[name]){'(' PARAMS ')'|'[' number ']'}
        '''
        if self.accept('('):
            name = self._declr(types)
            self.expect(')')
        else:
            name = self.accept(Lex.NAME)
        while self.peek({'(', '['}):
            if self.accept('('):
                params, variable = self.params()
                types.append((Function, (params, variable)))
                self.expect(')')
            elif self.accept('['):
                types.append((Array,
                              (Number(next(self))
                               if self.peek(Lex.NUMBER) else None,)))
                self.expect(']')
        return name

    def init_declr(self, declr, scope, parser):
        '''
        INIT_DECLR -> DECLR ['=' INIT]
        INIT -> '{' LIST '}'|ASSIGN|CONST
        '''
        if declr.token is None:
            self.error('Expected ;')
        init_declr = declr
        if self.peek('='):  # INIT
            if declr.token is None:
                self.error('Assigning to nothing')
            if isinstance(declr.type, Void):
                self.error('Cannot assign a void type a value')
            token = next(self)
            if self.accept('{'):
                if not isinstance(declr.type, (Array, Struct)):
                    self.error('Cannot list-assign to scalar')
                init_declr = InitialListAssign(token, declr,
                                               self.init_list(parser))
                self.expect('}')
            elif isinstance(declr.type, Array) and self.peek(Lex.STRING):
                init_declr = InitialStringArray(token, declr, String(next(self)))
            else:
                init_declr = InitialAssign(token, declr, parser())
        scope[declr.token.lexeme] = declr
        return init_declr

    def local_init_declr(self, qual):
        '''
        INIT_DECLR -> DECLR ['=' INIT]
        '''
        ctype, name = self.declr(qual)
        return self.init_declr(Local(ctype, name),
                               self.scope.locals, self.assign)

    def glob_init_declr(self, ctype, name):
        '''
        INIT_DECLR -> DECLR ['=' INIT]
        '''
        return self.init_declr(Global(ctype, name), self.globs, self.const)

    def declr(self, ctype):
        types = []
        name = self._declr(types)
        for new_type, arguments in reversed(types):
            ctype = new_type(ctype, *arguments)
        return ctype, name

    def decln(self):
        '''
        DECLN -> DECLN_SPEC [INIT_DECLR {',' INIT_DECLR}] ';'
        '''
        decln = []
        if self.accept('typedef'):
            qual = self.qual()
            ctype, name = self.declr(qual)
            self.scope.typedefs[name.lexeme] = ctype
            self.expect(';')
        else:
            qual = self.qual()
            if not self.accept(';'):
                decln.append(self.local_init_declr(qual))
                while self.accept(','):
                    decln.append(self.local_init_declr(qual))
                self.expect(';')
        return decln

    def init_list(self, parser):
        '''
        INIT_LIST -> EXPR|'{' INIT_LIST {',' INIT_LIST} '}'
        '''
        init_list = []
        if self.accept('{'):
            init_list.append(self.init_list(parser))
            self.expect('}')
        else:
            init_list.append(parser())
        while self.accept(','):
            if self.accept('{'):
                init_list.append(self.init_list(parser))
                self.expect('}')
            else:
                init_list.append(parser())
        return init_list

    def param(self):
        '''
        PARAM -> QUAL DECLR
        '''
        ctype = self.qual()
        types = []
        name = self._declr(types)
        for new_type, arguments in reversed(types):
            if new_type is Array:
                ctype = Pointer(ctype)
            else:
                ctype = new_type(ctype, *arguments)
        return Local(ctype, name)

    def params(self):
        '''
        PARAMS -> [PARAM {',' PARAM} [',' '...']]
        '''
        params = []
        variable = False
        if not self.peek(')'):
            params.append(self.param())
            while self.accept(','):
                if self.accept('...'):
                    variable = True
                    break
                params.append(self.param())
        return params, variable

    def statement(self):
        '''
        STATEMENT -> ';'
                    |'{' COMPOUND '}'
                    |SELECT
                    |LOOP
                    |JUMP
                    |name ':'
                    |ASSIGN ';'
        SELECT -> 'if' '(' EXPR ')' STATEMENT ['else' STATEMENT]
                 |'switch' '(' EXPR ')' '{' {'case' CONST_EXPR ':' STATEMENT} ['default' ':' STATEMENT] '}'
        LOOP -> 'while' '(' EXPR ')' STATEMENT
               |'for' '(' [EXPR {',' EXPR}] ';' EXPR ';' [EXPR {',' EXPR}] ')' STATEMENT
               |'do' STATEMENT 'while' '(' EXPR ')' ';'
        JUMP -> 'return' [EXPR] ';'
               |'break' ';'
               |'continue' ';'
               |'goto' name ';'
        '''
        if self.accept(';'):
            statement = Statement()
        elif self.accept('{'):
            self.begin_scope()
            statement = self.compound()
            self.end_scope()
            self.expect('}')
        elif self.accept('if'):
            self.expect('(')
            expr = self.expr()
            self.expect(')')
            statement = If(expr, self.statement())
            if self.accept('else'):
                statement.false = self.statement()
        elif self.accept('switch'):
            self.expect('(')
            test = self.expr()
            self.expect(')')
            self.expect('{')
            statement = Switch(test)
            while self.accept('case'):
                const = self.const()
                self.expect(':')
                compound = Compound()
                while not self.peek({'case', 'default', '}'}):
                    compound.append(self.statement())
                statement.cases.append(Case(const, compound))
            if self.accept('default'):
                self.expect(':')
                compound = Compound()
                while not self.peek('}'):
                    compound.append(self.statement())
                statement.default = compound
            self.expect('}')
        elif self.accept('while'):
            self.expect('(')
            expr = self.expr()
            self.expect(')')
            statement = While(expr, self.statement())
        elif self.accept('for'):
            self.expect('(')
            inits = []
            if not self.accept(';'):
                inits.append(self.expr())
                while self.accept(','):
                    inits.append(self.expr())
                self.expect(';')
            cond = self.expr()
            self.expect(';')
            steps = []
            if not self.accept(')'):
                steps.append(self.expr())
                while self.accept(','):
                    steps.append(self.expr())
                self.expect(')')
            statement = For(inits, cond, steps, self.statement())
        elif self.accept('do'):
            statement = self.statement()
            self.expect('while')
            self.expect('(')
            statement = Do(statement, self.expr())
            self.expect(')')
            self.expect(';')
        elif self.peek('return'):
            self.func.returns = True
            token = next(self)
            if self.accept(';'):
                statement = Return(token, self.func.ret, None)
            else:
                statement = Return(token, self.func.ret, self.expr())
                self.expect(';')
        elif self.accept('break'):
            statement = Break()
            self.expect(';')
        elif self.accept('continue'):
            statement = Continue()
            self.expect(';')
        elif self.accept('goto'):
            target = self.expect(Lex.NAME).lexeme
            statement = Goto(f'{self.func.name}_{target}')
            self.expect(';')
        elif self.peek2(Lex.NAME, ':'):
            label = next(self).lexeme
            statement = Label(f'{self.func.name}_{label}')
            next(self)
        else:
            statement = self.expr()
            self.expect(';')

        return statement

    def compound(self):
        '''
        COMPOUND -> {DECLN} {STATEMENT} [COMPOUND]
        '''
        compound = Compound()
        while self.peek({'typedef'} | CTYPES | self.scope.typedefs.keys()):
            compound.extend(self.decln())
        while (self.peek(self.STATEMENTS)
               and not self.peek(set(self.scope.typedefs.keys()))):
            compound.append(self.statement())
        if compound:
            compound.extend(self.compound())
        return compound

    def ext_decln(self):
        '''
        EXT_DECLN -> FUNC_DEFN|DECLN
        FUNC_DEFN -> QUAL DECLR '{' COMPOUND '}'
        DECLN -> DECLN_SPEC [INIT_DECLR {',' INIT_DECLR}] ';'
        '''
        ext_decln = []
        if self.accept('typedef'):
            qual = self.qual()
            ctype, name = self.declr(qual)
            self.scope.typedefs[name.lexeme] = ctype
            self.expect(';')
        elif self.accept('extern'):
            qual = self.qual()
            ctype, name = self.declr(qual)
            if name:
                self.globs[name.lexeme] = Global(ctype, name)
            self.expect(';')
        elif self.accept('register'):
            raise NotImplementedError()
        else:
            self.accept('static')
            qual = self.qual()
            if not self.accept(';'):
                ctype, name = self.declr(qual)
                if self.accept('{'):  # FUNC_DEFN
                    if name is None:
                        self.error('Function definition needs a name')
                    self.globs[name.lexeme] = Global(ctype, name)
                    if not isinstance(ctype, Function):
                        self.error(f'"{name.lexeme}" is not of function type')
                    if any(param.token is None for param in ctype.params):
                        self.error(f'"{name.lexeme}" cannot have abstract parameters')
                    self.func = FunctionInfo(ctype.ret, name.lexeme)
                    self.stack_params = Frame()
                    self.begin_scope()
                    for param in ctype.params[:4]:
                        self.scope.locals[param.token.lexeme] = param
                    for param in ctype.params[4:]:
                        self.stack_params[param.token.lexeme] = param
                    defn = VariadicDefinition if ctype.variable else Definition
                    compound = self.compound()
                    self.end_scope()
                    ext_decln.append(defn(ctype, name, compound, self.func))
                    self.expect('}')
                else:  # DECLN
                    ext_decln.append(self.glob_init_declr(ctype, name))
                    while self.accept(','):
                        ctype, name = self.declr(qual)
                        ext_decln.append(self.glob_init_declr(ctype, name))
                    self.expect(';')
        return ext_decln

    def translation(self):
        '''
        TRANS_UNIT -> {EXT_DECLN}
        '''
        translation = Translation()
        while not self.peek(Lex.END):
            translation.extend(self.ext_decln())
        return translation

    root = translation

    def begin_scope(self):
        """Begin a new scope."""
        self.stack.append(self.scope)
        self.scope = self.scope.copy()

    def end_scope(self):
        """End a scope."""
        self.func.space = max(self.func.space, self.scope.locals.size)
        self.scope = self.stack.pop()


def parse(tokens):
    """Util function for parsing."""
    parser = CParser()
    return parser.parse(tokens)
