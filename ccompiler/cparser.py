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
from .cexpressions import (Local, Attribute, Global, Number, Decimal, Character, String,
                           AddressOf, Dereference, SizeOf, Cast, Post, UnaryOp, Not, Pre,
                           BinaryOp, Compare, Logic, Dot, SubScript, Arrow,  Conditional)
from .ctypes import Type, Void, Float, Int, Short, Char, Pointer, Struct, Union, Array, Function
from .cstatements import (Statement, If, Case, Switch, While, Do, For, Continue, Break, Goto, Label, Return, Compound,
                          Call, VariadicCall, InitAssignment, Assignment, InitListAssignment, InitStringArray)
r'''( |\t)+$'''  # To delete weird whitespace spyder adds
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
[X] Update Docs
[X] Typedef
[X] Const expressions
[X] Const eval
[ ] Register variables (use max_args)
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

[-] Bit fields
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

    return_type: Type
    name: str
    space: int = 0
    register_space: int = 0
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
        self.enums = {}
        self.types = {}
        self.typedefs = {}

    def copy(self):
        """Create a copy of the scope."""
        new = Scope()
        new.locals.update(self.locals)
        new.enums.update(self.enums)
        new.types.update(self.types)
        new.typedefs.update(self.typedefs)
        return new

    def clear(self):
        """Clear the scope."""
        self.locals.clear()
        self.enums.clear()
        self.types.clear()
        self.typedefs.clear()


class CParser(Parser):
    """Parser class for parsing the C programming language."""

    STATEMENTS = {'{', Lex.NAME, 'if', '*', 'return', 'for', 'while', '(',
                  'switch', 'do', '++', '--', 'break', 'continue', ';', 'goto'}
    STORAGE = {'typedef', 'extern', 'auto'}

    def __init__(self):
        self.globals = {}
        self.scope = Scope()
        self.stack = []
        super().__init__()

    def parse(self, tokens):
        """Override of parse."""
        self.globals.clear()
        self.scope.clear()
        self.stack.clear()
        return super().parse(tokens)

    def resolve(self, name):
        """Resolve name of variables."""
        if name in self.scope.locals:
            return self.scope.locals[name]
        if name in self.stack_parameters:
            return self.stack_parameters[name]
        if name in self.globals:
            return self.globals[name]
        if name in self.scope.enums:
            return self.scope.enums[name]
        self.error(f'Name "{name}" not found')

    def primary(self):
        """
        PRIMARY -> name|decimal|number|character|string|'(' EXPRESSION ')'
        """
        if self.peek(Lex.NAME):
            return self.resolve(next(self).lexeme)
        if self.peek(Lex.DECIMAL):
            return Decimal(next(self).lexeme)
        if self.peek(Lex.NUMBER):
            return Number(next(self).lexeme)
        if self.peek(Lex.CHARACTER):
            return Character(next(self))
        if self.peek(Lex.STRING):
            return String(next(self))
        if self.accept('('):
            primary = self.expression()
            self.expect(')')
            return primary
        self.error('PRIMARY EXPRESSION')

    def postfix(self):
        """
        POST -> PRIMARY {'(' ARGUMENTS ')'|'[' EXPRESSION ']'|'++'|'--'|'.' name|'->' name}
        """
        postfix = self.primary()
        while self.peek({'(', '[', '++', '--', '.', '->'}):
            if self.peek('('):
                if not isinstance(postfix.type, Function):
                    self.error(f'{postfix.type} is not a function type')
                call_type = VariadicCall if postfix.type.variadic else Call
                self.function.calls = True
                postfix = call_type(next(self), postfix, self.arguments())
                self.expect(')')
            elif self.accept('['):
                postfix = SubScript(postfix, self.expression())
                self.expect(']')
            elif self.peek({'++', '--'}):
                postfix = Post(next(self), postfix)
            elif self.accept('.'):
                if not isinstance(postfix.type, (Struct, Union)):
                    self.error(f'Member reference when {postfix.type} is not a struct or union')
                name = self.expect(Lex.NAME)
                if name.lexeme not in postfix.type:
                    self.error(f'"{name.lexeme}" is not an attribute of {postfix.type}')
                attr = postfix.type[name.lexeme]
                postfix = Dot(postfix, attr)
            elif self.accept('->'):
                if not isinstance(postfix.type, Pointer):
                    self.error(f'{postfix.type} is not pointer type')
                name = self.expect(Lex.NAME)
                if name.lexeme not in postfix.type.to:
                    self.error(f'"{name.lexeme}" is not an attribute of {postfix.type.to}')
                attr = postfix.type.to[name.lexeme]
                postfix = Arrow(postfix, attr)
        return postfix

    def arguments(self):
        """
        ARGUMENTS -> [ASSIGNMENT {',' ASSIGNMENT}]
        """
        arguments = []
        if not self.peek(')'):
            arguments.append(self.assignment())
            while self.accept(','):
                arguments.append(self.assignment())
        self.function.max_arguments = min(max(self.function.max_arguments, len(arguments)), 4)
        return arguments

    def unary(self):
        """
        UNARY -> POSTFIX
                |('*'|'-'|'~'|'&'|'!') CAST
                |('++'|'--') UNARY
                |'sizeof' '(' TYPE_NAME ')'
                |'sizeof' UNARY
        """
        if self.peek('*'):
            return Dereference(next(self), self.cast())
        if self.peek({'-', '~'}):
            return UnaryOp(next(self), self.cast())
        if self.peek({'++', '--'}):
            return Pre(next(self), self.unary())
        if self.accept('!'):
            return Not(self.cast())
        if self.peek('&'):
            return AddressOf(next(self), self.cast())
        if self.accept('sizeof'):
            if self.accept('('):
                unary = SizeOf(self.type_name())
                self.expect(')')
            else:
                unary = SizeOf(self.unary().type)
            return unary
        return self.postfix()

    def cast(self):
        """
        CAST -> UNARY
               |'(' TYPE_NAME ')' CAST
        """
        if self.peek2('(', CTYPES | self.scope.typedefs.keys()):
            token = next(self)
            ctype = self.type_name()
            self.expect(')')
            return Cast(token, ctype, self.cast())
        return self.unary()

    def multiplicative(self):
        """
        MULTIPLICATIVE -> CAST {('*'|'/'|'%') CAST}
        """
        multiplicative = self.cast()
        while self.peek({'*', '/', '%'}):
            multiplicative = BinaryOp(next(self), multiplicative, self.cast())
        return multiplicative

    def additive(self):
        """
        ADDITIVE -> MULTIPLICATIVE {('+'|'-') MULTIPLICATIVE}
        """
        additive = self.multiplicative()
        while self.peek({'+', '-'}):
            additive = BinaryOp(next(self), additive, self.multiplicative())
        return additive

    def shift(self):
        """
        SHIFT -> ADDITIVE {('<<'|'>>') ADDITIVE}
        """
        shift = self.additive()
        while self.peek({'<<', '>>'}):
            shift = BinaryOp(next(self), shift, self.additive())
        return shift

    def relational(self):
        """
        RELATIONAL -> SHIFT {('<'|'>'|'<='|'>=') SHIFT}
        """
        relational = self.shift()
        while self.peek({'<', '>', '<=', '>='}):
            relational = Compare(next(self), relational, self.shift())
        return relational

    def equality(self):
        """
        EQUALITY -> RELATIONAL {('=='|'!=') RELATIONAL}
        """
        equality = self.relational()
        while self.peek({'==', '!='}):
            equality = Compare(next(self), equality, self.relational())
        return equality

    def bitwise_and(self):
        """
        BITWISE_AND -> EQUALITY {'&' EQUALITY}
        """
        bitwise_and = self.equality()
        while self.peek('&'):
            bitwise_and = BinaryOp(next(self), bitwise_and, self.equality())
        return bitwise_and

    def bitwise_xor(self):
        """
        BITWISE_XOR -> BITWISE_AND {'^' BITWISE_AND}
        """
        bitwise_xor = self.bitwise_and()
        while self.peek('^'):
            bitwise_xor = BinaryOp(next(self), bitwise_xor, self.bitwise_and())
        return bitwise_xor

    def bitwise_or(self):
        """
        BITWISE_OR -> BITWISE_XOR {'|' BITWISE_XOR}
        """
        bitwise_or = self.bitwise_xor()
        while self.peek('|'):
            bitwise_or = BinaryOp(next(self), bitwise_or, self.bitwise_xor())
        return bitwise_or

    def logical_and(self):
        """
        LOGICAL_AND -> BITWISE_OR {'&&' BITWISE_OR}
        """
        logical_and = self.bitwise_or()
        while self.peek('&&'):
            logical_and = Logic(next(self), logical_and, self.bitwise_or())
        return logical_and

    def logical_or(self):
        """
        LOGICAL_OR -> LOGICAL_AND {'||' LOGICAL_AND}
        """
        logical_or = self.logical_and()
        while self.peek('||'):
            logical_or = Logic(next(self), logical_or, self.logical_and())
        return logical_or

    def conditional(self):
        """
        CONDITIONAL -> LOGICAL_OR ['?' EXPRESSION ':' CONDITIONAL]
        """
        conditional = self.logical_or()
        if self.accept('?'):
            expression = self.expression()
            self.expect(':')
            conditional = Conditional(conditional, expression, self.conditional())
        return conditional

    def assignment(self):
        """
        ASSIGNMENT -> UNARY ['+'|'-'|'*'|'/'|'%'|'<<'|'>>'|'^'|'|'|'&']'=' ASSIGNMENT
                 |CONDITIONAL
        """
        assignment = self.conditional()
        if self.peek({'=', '+=', '-=', '*=', '/=', '%=',
                      '<<=', '>>=', '^=', '|=', '&=', '/=', '%='}):
            if not isinstance(assignment, (Local, Global, Dot, Arrow, SubScript, Dereference)):
                self.error(f'Cannot assign to {type(assignment)}')
            if self.peek('='):
                assignment = Assignment(next(self), assignment, self.assignment())
            else:
                token = next(self)
                assignment = Assignment(token, assignment, BinaryOp(token, assignment, self.assignment()))
        return assignment

    def expression(self):
        """
        EXPRESSION -> ASSIGNMENT
        """
        return self.assignment()

    def constant(self):
        """
        CONSTANT -> CONDITIONAL
        """
        constant = self.conditional()
        if not constant.is_constant():
            self.error('Must be a constant expression')
        return constant.fold()

    def enum(self, value):
        """
        ENUM -> name ['=' CONSTANT]
        """
        name = self.expect(Lex.NAME)
        if name.lexeme in self.scope.enums:
            self.error(f'Redeclaration of enumerator "{name.lexeme}"')
        if self.accept('='):
            value = self.constant().value
        self.scope.enums[name.lexeme] = Number(value)
        return value

    def attribute(self, specifier, ctype):
        """
        ATTRIBUTE -> DECLARATOR [':' number]
        """
        ctype, name = self.declarator(ctype)
        if self.accept(':'):
            self.expect(Lex.NUMBER)
        if name is None and isinstance(ctype, Union):
            for name, attr in ctype.items():
                attr.offset = specifier.size
                specifier.data[name] = attr
            specifier.size += ctype.size
        else:
            specifier[name.lexeme] = Attribute(ctype, name)

    def struct_or_union(self, new_type):
        """
        STRUCT_OR_UNION -> ('struct'|'union') [name] '{' {QUALIFIER ATTRIBUTE {',' ATTR} ';'} '}'
        """
        name = self.accept(Lex.NAME)
        if name:
            if name.lexeme not in self.scope.types:
                self.scope.types[name.lexeme] = new_type(name)
            struct_or_union = copy(self.scope.types[name.lexeme])
        else:
            struct_or_union = new_type(name)
        if self.accept('{'):
            while not self.accept('}'):
                qualifier = self.qualifier()
                self.attribute(struct_or_union, qualifier)
                while self.accept(','):
                    self.attribute(struct_or_union, qualifier)
                self.expect(';')
            if name:
                self.scope.types[name.lexeme] = struct_or_union
        return struct_or_union

    def specifier(self):
        """
        TYPE_SPEC -> 'void'
                    |name
                    |STRUCT_OR_UNIO
                    |'enum' [name] '{' ENUM {',' ENUM}'}
                    |type
        """
        if self.accept('void'):
            specifier = Void()
        elif self.peek(Lex.NAME):
            token = next(self)
            if token.lexeme not in self.scope.typedefs:
                self.error(f'typedef "{token.lexeme}" not found')
            specifier = copy(self.scope.typedefs[token.lexeme])
        elif self.accept('struct'):
            specifier = self.struct_or_union(Struct)
        elif self.accept('union'):
            specifier = self.struct_or_union(Union)
        elif self.accept('enum'):
            name = self.accept(Lex.NAME)
            if self.accept('{'):
                if name:
                    self.scope.types[name.lexeme] = None
                value = self.enum(0)
                while self.accept(','):
                    value += 1
                    value = self.enum(value)
                self.expect('}')
            else:
                if not name:
                    self.error("Did not specify enum name")
                if name.lexeme not in self.scope.types:
                    self.error(f'Enum name "{name.lexeme}" not found')
            specifier = Char()
        elif self.accept('float'):
            specifier = Float()
        else:
            if self.accept('unsigned'):
                signed = False
            else:
                self.accept('signed')
                signed = True
            if self.accept('char'):
                specifier = Char(signed)
            elif self.accept('short'):
                self.accept('int')
                specifier = Short(signed)
            elif self.accept('int'):
                specifier = Int(signed)
            elif self.accept('long'):
                self.accept('int')
                specifier = Int(signed)
            else:
                specifier = Int(signed)
        return specifier

    def qualifier(self):
        """
        QUALIFIER -> ['const'] ['volatile'] SPECIFIER
        """
        const = bool(self.accept('const'))
        self.accept('volatile')
        qualifier = self.specifier()
        qualifier.const = const
        return qualifier

    def type_name(self):
        """
        TYPE_NAME -> QUALIFIER ABSTRACT_DECLARATOR
        """
        type_name = self.qualifier()
        type_name, name = self.declarator(type_name)
        if name is not None:
            self.error(f'Did not expect name "{name.lexeme}" in TYPE NAME')
        return type_name

    def declarator(self, ctype, types=None, is_top=True):
        """
        DECLARATOR -> {'*'} DIRECT_DECLARATOR
        """
        if types is None:
            types = []
        qualifiers = []
        while self.accept('*'):
            qualifiers.append(bool(self.accept('const')))
            self.accept('volatile')
        ctype, name = self.direct_declarator(ctype, types)
        types.extend(((Pointer, (qual,)) for qual in qualifiers))
        if is_top:
            for new_type, args in reversed(types):
                ctype = new_type(ctype, *args)
        return ctype, name

    def direct_declarator(self, ctype, types):
        """
        DIRECT_DECLARATOR -> ('(' _DECLARATOR ')'|[name]){'(' PARAMETERS ')'|'[' [number] ']'}
        """
        if self.accept('('):
            ctype, name = self.declarator(ctype, types, is_top=False)
            self.expect(')')
        else:
            name = self.accept(Lex.NAME)
        while self.peek({'(', '['}):
            if self.accept('('):
                params, variadic = self.parameters()
                types.append((Function, (params, variadic)))
                self.expect(')')
            elif self.accept('['):
                types.append((Array, (Number(next(self).lexeme) if self.peek(Lex.NUMBER) else None,)))
                self.expect(']')
        return ctype, name

    def initializer_list(self, parser):
        """
        INITIALIZER_LIST -> [INITIALIZER {',' INITIALIZER}]
        """
        initializer_list = []
        if not self.peek('}'):
            while True:
                initializer_list.append(self.initializer(parser))
                if self.peek('}'):
                    break
                self.expect(',')
        return initializer_list

    def initializer(self, parser):
        """
        INITIALIZER -> '{' INITIALIZER_LIST '}'|ASSIGNMENT|CONSTANT
        """
        if self.accept('{'):
            initializer = self.initializer_list(parser)
            self.expect('}')
        else:
            initializer = parser()
        return initializer

    def init_declarator(self, storage, qualifier):
        """
        INIT_DECLARATOR -> DECLARATOR ['=' INITIALIZER]
        """
        ctype, name = self.declarator(qualifier)
        return self._init_declarator_tail(storage, ctype, name, Local, self.scope.locals, self.assignment)

    def declaration(self):
        """
        DECLARATION -> SPECIFIER [INIT_DECLARATOR {',' INIT_DECLARATOR}] ';'
        """
        declaration = []
        storage, qualifier = self.specifiers()
        if not self.accept(';'):
            while True:
                init_decl = self.init_declarator(storage, qualifier)
                if init_decl:
                    declaration.append(init_decl)
                if self.accept(';'):
                    break
                self.expect(',')
        return declaration

    def parameter(self):
        """
        PARAMETER -> QUALIFIER DECLARATOR
        """
        qualifier = self.qualifier()
        ctype, name = self.declarator(qualifier)
        if isinstance(ctype, Array):
            ctype = Pointer(ctype.of, ctype.const)
        return Local(ctype, name)

    def parameters(self):
        """
        PARAMETERS -> [PARAMETER {',' PARAMETER} [',' '...']]
        """
        params = []
        variadic = False
        if not self.peek(')'):
            params.append(self.parameter())
            while self.accept(','):
                if self.accept('...'):
                    variadic = True
                    break
                params.append(self.parameter())
        return params, variadic

    def statement(self):
        """
        STATEMENT -> ';'
                    |'{' COMPOUND '}'
                    |SELECT
                    |LOOP
                    |JUMP
                    |name ':'
                    |ASSIGNMENT ';'
        SELECT -> 'if' '(' EXPRESSION ')' STATEMENT ['else' STATEMENT]
                 |'switch' '(' EXPRESSION ')' '{' {'case' CONSTANT ':' STATEMENT} ['default' ':' STATEMENT] '}'
        LOOP -> 'while' '(' EXPRESSION ')' STATEMENT
               |'for' '(' [EXPRESSION {',' EXPRESSION}] ';' EXPRESSION ';' [EXPRESSION {',' EXPRESSION}] ')' STATEMENT
               |'do' STATEMENT 'while' '(' EXPRESSION ')' ';'
        JUMP -> 'return' [EXPRESSION] ';'
               |'break' ';'
               |'continue' ';'
               |'goto' name ';'
        """
        if self.accept(';'):
            statement = Statement()
        elif self.accept('{'):
            self.begin_scope()
            statement = self.compound()
            self.end_scope()
            self.expect('}')
        elif self.accept('if'):
            self.expect('(')
            expression = self.expression()
            self.expect(')')
            statement = If(expression, self.statement())
            if self.accept('else'):
                statement.false = self.statement()
        elif self.accept('switch'):
            self.expect('(')
            test = self.expression()
            self.expect(')')
            self.expect('{')
            statement = Switch(test)
            while self.accept('case'):
                const = self.constant()
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
            expression = self.expression()
            self.expect(')')
            statement = While(expression, self.statement())
        elif self.accept('for'):
            self.expect('(')
            inits = []
            if not self.accept(';'):
                inits.append(self.expression())
                while self.accept(','):
                    inits.append(self.expression())
                self.expect(';')
            test = None if self.peek(';') else self.expression()
            self.expect(';')
            steps = []
            if not self.accept(')'):
                steps.append(self.expression())
                while self.accept(','):
                    steps.append(self.expression())
                self.expect(')')
            statement = For(inits, test, steps, self.statement())
        elif self.accept('do'):
            statement = self.statement()
            self.expect('while')
            self.expect('(')
            statement = Do(statement, self.expression())
            self.expect(')')
            self.expect(';')
        elif self.peek('return'):
            self.function.returns = True
            token = next(self)
            statement = Return(token, self.function.return_type, None if self.peek(';') else self.expression())
            self.expect(';')
        elif self.accept('break'):
            statement = Break()
            self.expect(';')
        elif self.accept('continue'):
            statement = Continue()
            self.expect(';')
        elif self.accept('goto'):
            target = self.expect(Lex.NAME).lexeme
            statement = Goto(f'{self.function.name}_{target}')
            self.expect(';')
        elif self.peek2(Lex.NAME, ':'):
            label = next(self).lexeme
            statement = Label(f'{self.function.name}_{label}')
            next(self)
        else:
            statement = self.expression()
            self.expect(';')

        return statement

    def compound(self):
        """
        COMPOUND -> {DECLARATION} {STATEMENT} [COMPOUND]
        """
        compound = Compound()
        while self.peek(self.STORAGE | CTYPES | self.scope.typedefs.keys()):
            compound.extend(self.declaration())
        while (self.peek(self.STATEMENTS) and not self.peek(set(self.scope.typedefs.keys()))):
            compound.append(self.statement())
        if compound:
            compound.extend(self.compound())
        return compound

    def specifiers(self):
        """
        SPECIFIERS -> ['typedef'|'extern'|'static'|'auto'|'register'] QUALIFIER
        """
        return next(self).lexeme if self.peek(self.STORAGE) else None, self.qualifier()

    def external(self):
        """
        EXTERNAL -> DEFINITION|DECLARATION
        DEFINITION -> QUALIFIER DECLARATOR '{' COMPOUND '}'
        DECLARATION -> SPECIFIER [INIT_DECLARATOR {',' INIT_DECLARATOR}] ';'
        """
        external = []
        storage, qualifier = self.specifiers()
        if not self.accept(';'):
            declaring = False
            while True:
                ctype, name = self.declarator(qualifier)
                if self.accept('{'):  # DEFINITION
                    if declaring:
                        self.error('You cannot define a function while already declaring')
                    if name is None:
                        self.error('Function definition needs a name')
                    if storage in {'typedef', 'extern'}:
                        self.error(f'Function definition cannot be {storage}')
                    if not isinstance(ctype, Function):
                        self.error(f'"{name.lexeme}" is not of function type')
                    if any(param.token is None for param in ctype.parameters):
                        self.error(f'"{name.lexeme}" cannot have abstract parameters')
                    self.globals[name.lexeme] = Global(ctype, name)
                    self.function = FunctionInfo(ctype.return_type, name.lexeme)
                    self.stack_parameters = Frame()
                    self.begin_scope()
                    for param in ctype.parameters[:4]:
                        self.scope.locals[param.token.lexeme] = param
                    for param in ctype.parameters[4:]:
                        self.stack_parameters[param.token.lexeme] = param
                    defn = VariadicDefinition if ctype.variadic else Definition
                    compound = self.compound()
                    self.end_scope()
                    self.expect('}')
                    external.append(defn(ctype, name, compound, self.function))
                    break
                else:  # DECLARATION
                    declaring = True
                    tail = self._init_declarator_tail(storage, ctype, name, Global, self.globals, self.constant)
                    if tail:
                        external.append(tail)
                    if self.accept(';'):
                        break
                    self.expect(',')
        return external

    def _init_declarator_tail(self, storage, ctype, name, VarType, scope, parser):
        if name is None:
            self.error('Expected ;')
        if storage == 'typedef':
            self.scope.typedefs[name.lexeme] = ctype
            return
        if storage == 'extern':
            self.globals[name.lexeme] = Global(ctype, name)
            return
        variable = Global(ctype, name) if storage == 'static' else VarType(ctype, name)
        init_decl = variable
        if self.peek('='):
            if isinstance(ctype, Void):
                self.error('Cannot assign a value to a void type')
            if isinstance(ctype, Function):
                self.error('Cannot assign a value to a function type')
            token = next(self)
            initializer = self.initializer(parser)
            if isinstance(initializer, String) and isinstance(ctype, Array):
                init_decl = InitStringArray(token, init_decl, initializer)
            elif isinstance(initializer, list) and isinstance(ctype, Array | Struct):
                init_decl = InitListAssignment(token, init_decl, initializer)
            else:
                init_decl = InitAssignment(token, init_decl, initializer)
        if storage == 'static':
            self.globals[name.lexeme] = variable
        else:
            scope[name.lexeme] = variable
        return init_decl

    def translation(self):
        """
        TRANSLATION -> {EXTERNAL}
        """
        translation = Translation()
        while not self.peek(Lex.END):
            translation.extend(self.external())
        return translation

    root = translation

    def begin_scope(self):
        """Begin a new scope."""
        self.stack.append(self.scope)
        self.scope = self.scope.copy()

    def end_scope(self):
        """End a scope."""
        self.function.space = max(self.function.space, self.scope.locals.size)
        # self.function.register_space = max(self.function.register_space, len(self.scope.registers))
        self.scope = self.stack.pop()


def parse(tokens):
    """Util function for parsing."""
    parser = CParser()
    return parser.parse(tokens)
