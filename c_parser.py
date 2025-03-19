# -*- coding: utf-8 -*-
"""
Created on Mon Jul  3 19:47:39 2023

@author: Colin
"""
from dataclasses import dataclass
from copy import copy
from c_nodes import Frame
from c_types import Type, Void, Float, Int, Short, Char, Pointer, Struct, Union, Array, Func
from c_exprs import Number, NegNumber, EnumNumber, Decimal, NegDecimal, Character, String
from c_exprs import Post, UnaryOp, Not, Pre, BinaryOp, Compare, Logic
from c_exprs import Local, Attr, Glob, Dot, SubScr, Arrow, Call, VarCall, AddrOf, Deref, SizeOf, Cast, Condition
from c_exprs import InitAssign, Assign, InitListAssign, InitArrayString, Return, Block, Defn, VarDefn, Program
from c_statements import Statement, If, Case, Switch, While, Do, For, Continue, Break, Goto, Label
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
[ ] Const expressions
[X] Function pointers
[ ] Function defs in function defs
[ ] Error handling
[X] Generate vs Reduce
[X] Scope in Parser
[X] Line numbers in errors
[X] Returning local structs
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

'''

class Scope(Frame):
    def copy(self):
        new = Scope()
        new.size = self.size
        new.data = self.data.copy()
        return new
    
class Context:
    def __init__(self):
        self.structs = {}
        self.typedefs = {}
        self.unions = {}
        self.enums = []
        self.enum_consts = {}
    def copy(self):
        new = Context()
        new.structs.update(self.structs.copy())
        new.typedefs.update(self.typedefs.copy())
        new.unions.update(self.unions.copy())
        new.enums.extend(self.enums.copy())
        new.enum_consts.update(self.enum_consts.copy())
        return new

@dataclass
class FuncInfo:
    ret: Type
    space: int = 0
    returns: bool = False
    calls: bool = False
    max_args: int = 0

class CParser:

    TYPE = ('int','char','short','float','unsigned','signed','struct','void','typedef','const','union','enum','volatile','static')

    def __init__(self):
        self.scope = Scope()
        self.stack_scope = Scope()
        self.stack = []
        self.func = None
        self.context = None
        self.globs = {}
        self.tokens = None
        self.index = 0

    def resolve(self, name: str):
        if name in self.scope:
            return self.scope[name]
        if name in self.stack_scope:
            return self.stack_scope[name]
        if name in self.globs:
            return self.globs[name]
        if name in self.context.enum_consts:
            return self.context.enum_consts[name]
        self.error(f'Name "{name}" not found')

    def primary(self):
        '''
        PRIMARY -> name|number|character|string|'(' EXPR ')'
        '''
        if self.peek('name'):
            return self.resolve(next(self).lexeme)
        if self.peek('decimal'):
            return Decimal(next(self))
        if self.peek('number'):
            return Number(next(self))
        if self.peek('character'):
            return Character(next(self))
        if self.peek('string'):
            return String(next(self))
        if self.accept('('):
            primary = self.expr()
            self.expect(')')
            return primary
        self.error('PRIMARY EXPRESSION')

    def postfix(self):
        '''
        POST -> PRIMARY {'(' ARGS ')'|'[' EXPR ']'|'++'|'--'|'.' name|'->' name}
        '''
        postfix = self.primary()
        while self.peek('(','[','++','--','.','->'):
            if self.peek('('):
                assert isinstance(postfix.type, Func), self.error(f'"{postfix.token.lexeme}" is not a function')
                if postfix.type.variable:
                    call_type = VarCall
                else:
                    call_type = Call
                self.func.calls = True
                postfix = call_type(next(self), postfix, self.args())
                self.expect(')')
            elif self.peek('['):
                postfix = SubScr(next(self), postfix, self.expr())
                self.expect(']')
            elif self.peek('++','--'):
                postfix = Post(next(self), postfix)
            elif self.accept('.'):
                assert isinstance(postfix.type, (Struct,Union)), self.error(f'"{postfix.token.lexeme}" is type {postfix.type}')
                name = self.expect('name')
                if name.lexeme not in postfix.type:
                    self.error(f'"{name.lexeme}" is not an attribute of {postfix.type.to}')
                attr = postfix.type[name.lexeme]
                if isinstance(postfix.type, Union):
                    postfix = postfix.union(attr)
                else:
                    postfix = Dot(name, postfix, attr)
            elif self.accept('->'):
                assert hasattr(postfix.type, 'to'), self.error(f'{postfix.type} is not pointer type')
                name = self.expect('name')
                if name.lexeme not in postfix.type.to:
                    self.error(f'"{name.lexeme}" is not an attribute of {postfix.type.to}')
                attr = postfix.type.to[name.lexeme]
                if isinstance(postfix.type.to, Union):
                    postfix = Deref(name, postfix.ptr_union(attr)) #TODO test
                else:
                    postfix = Arrow(name, postfix, attr)
        return postfix

    def args(self):
        '''
        ARGS -> [ASSIGN {',' ASSIGN}]
        '''
        args = []
        if not self.peek(')'):
            args.append(self.assign())
            while self.accept(','):
                args.append(self.assign())
        self.func.max_args = min(max(self.func.max_args, len(args)), 4)
        return args

    def unary(self):
        '''
        UNARY -> POSTFIX
                |('*'|'-'|'~'|'&'|'!') CAST
                |('++'|'--') UNARY
                |'sizeof' '(' TYPE_NAME ')'
                |'sizeof' UNARY
        '''
        if self.peek('*'):
            return Deref(next(self), self.cast())
        if self.peek2('-', 'number'):
            next(self)
            return NegNumber(next(self))
        if self.peek2('-', 'decimal'):
            next(self)
            return NegDecimal(next(self)) #TODO test
        if self.peek('-','~'):
            return UnaryOp(next(self), self.cast())
        if self.peek('++','--'):
            return Pre(next(self), self.unary())
        if self.peek('!'):
            return Not(next(self), self.cast())
        if self.peek('&'):
            return AddrOf(next(self), self.cast())
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
        if self.peek2('(', *self.TYPE) or self.peek('(') and self.peek_typedefs(1): #TODO test
            token = next(self)
            c_type = self.type_name()
            self.expect(')')
            return Cast(token, c_type, self.cast())
        return self.unary()

    def mul(self):
        '''
        MUL -> CAST {('*'|'/'|'%') CAST}
        '''
        mul = self.cast()
        while self.peek('*','/','%'):
            mul = BinaryOp(next(self), mul, self.cast())
        return mul

    def add(self):
        '''
        ADD -> MUL {('+'|'-') MUL}
        '''
        add = self.mul()
        while self.peek('+','-'):
            add = BinaryOp(next(self), add, self.mul())
        return add

    def shift(self):
        '''
        SHIFT -> ADD {('<<'|'>>') ADD}
        '''
        shift = self.add()
        while self.peek('<<','>>'):
            shift = BinaryOp(next(self), shift, self.add())
        return shift

    def relation(self):
        '''
        RELA -> SHIFT {('<'|'>'|'<='|'>=') SHIFT}
        '''
        relation = self.shift()
        while self.peek('<','>','<=','>='):
            relation = Compare(next(self), relation, self.shift())
        return relation

    def equality(self):
        '''
        EQUA -> RELA {('=='|'!=') RELA}
        '''
        equality = self.relation()
        while self.peek('==','!='):
            equality = Compare(next(self), equality, self.relation())
        return equality

    def bit_and(self):
        '''
        BIT_AND -> EQUA {'&' EQUA}
        '''
        bit_and = self.equality()
        while self.peek('&'):
            bit_and = BinaryOp(next(self), bit_and, self.equality())  #TODO test all these
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
        if self.peek('=','+=','-=','*=','/=','%=','<<=','>>=','^=','|=','&=','/=','%='):
            assert isinstance(assign, (Local,Glob,Dot,Arrow,SubScr,Deref)), self.error(f'Cannot assign to {type(assign)}')
            if self.peek('='):
                assign = Assign(next(self), assign, self.assign())
            else:
                token = next(self)
                assign = Assign(token, assign, BinaryOp(token, assign, self.assign()))
        return assign

    def expr(self):
        '''
        EXPR -> ASSIGN
        '''
        return self.assign()
        # while self.accept(','): #TODO
        #     self.assign()

    def const(self):
        '''
        CONST -> COND
        '''
        const = self.cond()
        assert const.is_const(), self.error('Must be a constant expression')
        # TODO return const.eval()
        return const

    def enum(self, value):
        '''
        ENUM -> name ['=' number]
        '''
        name = self.expect('name')
        if self.accept('='):
            value = Number(self.expect('number')).value
        assert name.lexeme not in self.context.enum_consts, self.error(f'Redeclaration of enumerator "{name.lexeme}"')
        self.context.enum_consts[name.lexeme] = EnumNumber(name, value)
        return value

    def attr(self, spec, c_type):
        '''
        ATTR -> DECLR [':' number]
        '''
        c_type, name = self.declr(c_type)
        if self.accept(':'):
            self.expect('number')
        if name is None and isinstance(c_type, Union): #TODO test
            for name, attr in c_type.items():
                attr.location = spec.size
                spec.data[name] = attr
            spec.size += c_type.size
        else:
            spec[name.lexeme] = Attr(c_type, name)

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
        elif self.peek('name'):
            token = next(self)
            if token.lexeme not in self.context.typedefs:
                self.error(f'typedef "{token.lexeme}" not found')
            spec = copy(self.context.typedefs[token.lexeme])
        elif self.accept('struct'):
            name = self.accept('name')
            if name:
                if name.lexeme not in self.context.structs:
                    self.context.structs[name.lexeme] = Struct(name)
                spec = self.context.structs[name.lexeme]
            else:
                spec = Struct(name)
            if self.accept('{'):
                while not self.accept('}'):
                    c_type = self.qual()
                    self.attr(spec, c_type)
                    while self.accept(','):
                        self.attr(spec, c_type)
                    self.expect(';')
        elif self.accept('union'):
            name = self.accept('name')
            if name:
                if name.lexeme not in self.context.unions:
                    self.context.unions[name.lexeme] = Union(name)
                spec = self.context.unions[name.lexeme]
            else:
                spec = Union(name)
            if self.accept('{'):
                while not self.accept('}'):
                    c_type = self.qual()
                    self.attr(spec, c_type)
                    while self.accept(','):
                        self.attr(spec, c_type)
                    self.expect(';')
        elif self.accept('enum'):
            name = self.accept('name')
            if self.accept('{'):
                if name:
                    self.context.enums.append(name.lexeme)
                value = self.enum(0)
                while self.accept(','):
                    value += 1
                    value = self.enum(value)
                self.expect('}')
            else:
                assert name, self.error("Did not specify enum name")
                assert name.lexeme in self.context.enums, self.error(f'Enum name "{name.lexeme}" not found')
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

    def type_name(self): #TODO test
        '''
        TYPE_NAME -> QUAL ABS_DECLR
        '''
        type_name = self.qual()
        types = []
        name = self._declr(types)
        assert name is None, self.error(f'Did not expect name "{name.lexeme}" in TYPE NAME')
        for new_type, args in reversed(types):
            type_name = new_type(type_name, *args)
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
            name = self.accept('name')
        while self.peek('(','['):
            if self.accept('('):
                params, variable = self.params()
                types.append((Func, (params, variable)))
                self.expect(')')
            elif self.accept('['):
                types.append((Array, (Number(next(self)) if self.peek('number') else None,)))
                self.expect(']')
        return name

    def init(self, declr, scope, parser):
        '''
        INITR -> '{' LIST '}'|ASSIGN|CONST
        '''
        init = declr
        if self.peek('='):
            assert declr.token is not None, self.error('Assigning to nothing')
            assert not isinstance(declr.type, Void), self.error('Cannot assign a void type a value')
            token = next(self)
            if self.accept('{'):
                assert isinstance(declr.type, (Array,Struct)), self.error('Cannot list-assign to scalar')
                init = InitListAssign(token, declr, self.list())
                self.expect('}')
            elif isinstance(declr.type, Array) and self.peek('string'):
                init = InitArrayString(token, declr, String(next(self)))
            else:
                init = InitAssign(token, declr, parser())
        scope[declr.token.lexeme] = declr
        return init

    def local_init(self, c_type):
        '''
        INIT -> DECLR ['=' INITR]
        '''
        c_type, name = self.declr(c_type)
        return self.init(Local(c_type, name), self.scope, self.assign)

    def glob_init(self, c_type, name):
        '''
        INIT -> DECLR ['=' INITR]
        '''
        return self.init(Glob(c_type, name), self.globs, self.const)

    def declr(self, c_type):
        types = []
        name = self._declr(types)
        for new_type, args in reversed(types):
            c_type = new_type(c_type, *args)
        return c_type, name

    def decln(self):
        '''
        DECLN -> QUAL [INIT {',' INIT}] ';'
        '''
        decln = []
        if self.accept('typedef'): #TODO test
            c_type = self.qual()
            c_type, name = self.declr(c_type)
            self.context.typedefs[name.lexeme] = c_type
            self.expect(';')
        else:
            c_type = self.qual()
            if not self.accept(';'):
                decln.append(self.local_init(c_type))
                while self.accept(','):
                    decln.append(self.local_init(c_type))
                self.expect(';')
        return decln

    def list(self):
        '''
        INIT_LIST -> EXPR|'{' INIT_LIST {',' INIT_LIST} '}'
        '''
        init = []
        if self.accept('{'):
            init.append(self.list())
            self.expect('}')
        else:
            init.append(self.expr())
        while self.accept(','):
            if self.accept('{'):
                init.append(self.list())
                self.expect('}')
            else:
                init.append(self.expr())
        return init

    def param(self):
        '''
        PARAM -> QUAL DECLR
        '''
        c_type = self.qual()
        types = []
        name = self._declr(types)
        for new_type, args in reversed(types): #TODO test
            if new_type is Array:
                c_type = Pointer(c_type)
            else:
                c_type = new_type(c_type, *args)
        return Local(c_type, name)

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
        STATE -> ';'
                |'{' BLOCK '}'
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
            statement = self.block()
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
                block = Block()
                while not self.peek('case','default','}'):
                    block.append(self.statement())
                statement.cases.append(Case(const, block))
            if self.accept('default'):
                self.expect(':')
                block = Block()
                while not self.peek('}'):
                    block.append(self.statement())
                statement.default = block
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
                statement = Return(token, None, None) #TODO test
            else:
                statement = Return(token, self.func.ret, self.expr())
                self.expect(';')
        elif self.accept('break'):
            statement = Break()
            self.expect(';')
        elif self.accept('continue'): #TODO test
            statement = Continue()
            self.expect(';')
        elif self.accept('goto'):
            statement = Goto(self.expect('name'))
            self.expect(';')
        elif self.peek2('name',':'):
            statement = Label(next(self))
            next(self)
        else:
            statement = self.expr()
            self.expect(';')

        return statement

    def block(self):
        '''
        BLOCK -> {'typedef' ('void'|QUAL) name ';'} {DECL} {STATE} [BLOCK]
        '''
        block = Block()
        while self.peek(*self.TYPE) or self.peek_typedefs():
            block.extend(self.decln())
        while self.peek(';','{','(','name','*','++','--','return','if','switch','while','do','for','break','continue','goto') and not self.peek_typedefs():
            block.append(self.statement())
        if block:
            block.extend(self.block())
        return block

    def program(self):
        program = Program()
        while not self.peek('end'):
            if self.accept('typedef'):
                c_type = self.qual()
                c_type, name = self.declr(c_type)
                self.context.typedefs[name.lexeme] = c_type
                self.expect(';')
            elif self.accept('extern'): #TODO test
                c_type = self.qual()
                c_type, name = self.declr(c_type)
                if name:
                    self.globs[name.lexeme] = Glob(c_type, name)
                self.expect(';')
            else:
                self.accept('static')
                qual = self.qual()
                if not self.accept(';'):
                    c_type, name = self.declr(qual)
                    if self.accept('{'):
                        assert name is not None, self.error('Function definition needs a name')
                        self.globs[name.lexeme] = Glob(c_type, name)
                        assert isinstance(c_type, Func), self.error(f'"{name.lexeme}" is not of function c_type')
                        assert not any(param.token is None for param in c_type.params), self.error(f'"{name.lexeme}" cannot have abstract parameters')
                        self.begin_func(c_type)
                        for param in c_type.params[:4]:
                            self.scope[param.token.lexeme] = param
                        for param in c_type.params[4:]:
                            self.stack_scope[param.token.lexeme] = param
                        if c_type.variable:
                            defn = VarDefn
                        else:
                            defn = Defn
                        block = self.block()
                        self.end_func()
                        program.append(defn(c_type, name, block, self.func)) # self.returns, self.calls, self.max_args, self.space))
                        self.expect('}')
                    else:
                        program.append(self.glob_init(c_type, name))
                        while self.accept(','):
                            c_type, name = self.declr(qual)
                            program.append(self.glob_init(c_type, name))
                        self.expect(';')
        return program

    def begin_func(self, func):
        self.func = FuncInfo(func.ret)
        self.begin_scope()
        self.stack_scope = Scope()

    def end_func(self):
        self.end_scope()

    def begin_scope(self):
        self.stack.append((self.scope, self.context))
        self.scope = self.scope.copy()
        self.context = self.context.copy()

    def end_scope(self):
        self.func.space = max(self.func.space, self.scope.size)
        self.scope, self.context = self.stack.pop()

    def parse(self, tokens):
        self.context = Context()
        self.globs = {}
        self.tokens = tokens
        # for i, t in enumerate(self.tokens): print(i, t.type, t.lexeme)
        self.index = 0
        program = self.program()
        self.expect('end')
        return program

    def __next__(self):
        token = self.tokens[self.index]
        self.index += 1
        return token

    def peek(self, *symbols, offset=0):
        token = self.tokens[self.index+offset]
        return token.type in symbols or token.type in ('keyword','symbol') and token.lexeme in symbols

    def peek2(self, first, *second):
        return self.peek(first) and self.peek(*second, offset=1)

    def peek_typedefs(self, offset=0):
        return self.peek('name', offset=offset) \
            and self.tokens[self.index+offset].lexeme in self.context.typedefs

    def accept(self, symbol):
        if self.peek(symbol):
            return next(self)

    def expect(self, symbol):
        if self.peek(symbol):
            return next(self)
        self.error(f'Expected "{symbol}"')

    def error(self, msg=''): #TODO test
        error = self.tokens[self.index]
        raise SyntaxError(f'Line {error.line}: Unexpected {error.type} token "{error.lexeme}". {msg}')

def parse(tokens):
    parser = CParser()
    return parser.parse(tokens)