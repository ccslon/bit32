# -*- coding: utf-8 -*-
"""
Created on Mon Jul  3 19:47:39 2023

@author: Colin
"""
from copy import copy
from c_utils import Frame
from c_types import Void, Float, Int, Short, Char, Pointer, Struct, Union, Array, Func
from c_exprs import Number, NegNumber, EnumNumber, Decimal, NegDecimal, Letter, String
from c_exprs import Post, Unary, Not, Pre, Binary, Compare, Logic
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
        copy = Scope()
        copy.size = self.size
        copy.data = self.data.copy()
        return copy

class CParser:

    TYPE = ('int','char','short','float','unsigned','signed','struct','void','typedef','const','union','enum','volatile','static')

    def resolve(self, name):
        if name in self.param_scope:
            return self.param_scope[name]
        elif name in self.stack_param_scope:
            return self.stack_param_scope[name]
        elif name in self.scope:
            return self.scope[name]
        elif name in self.globs:
            return self.globs[name]
        elif name in self.enum_consts:
            return self.enum_consts[name]
        else:
            self.error(f'Name "{name}" not found')

    def primary(self):
        '''
        PRIMARY -> id|number|character|string|'(' EXPR ')'
        '''
        if self.peek('id'):
            return self.resolve(next(self).lexeme)
        elif self.peek('decimal'):
            return Decimal(next(self))
        elif self.peek('number'):
            return Number(next(self))
        elif self.peek('character'):
            return Letter(next(self))
        elif self.peek('string'):
            return String(next(self))
        elif self.accept('('):
            primary = self.expr()
            self.expect(')')
        else:
            self.error('PRIMARY EXPRESSION')
        return primary

    def postfix(self):
        '''
        POST -> PRIMARY {'(' ARGS ')'|'[' EXPR ']'|'++'|'--'|'.' id|'->' id}
        '''
        postfix = self.primary()
        while self.peek('(','[','++','--','.','->'):
            if self.peek('('):
                assert isinstance(postfix.type, Func), self.error(f'"{postfix.token.lexeme}" is not a function')
                if postfix.type.variable:
                    call_type = VarCall
                else:
                    call_type = Call
                self.calls = True
                postfix = call_type(next(self), postfix, self.args())
                self.expect(')')
            elif self.peek('['):
                postfix = SubScr(next(self), postfix, self.expr())
                self.expect(']')
            elif self.peek('++','--'):
                postfix = Post(next(self), postfix)
            elif self.accept('.'):
                assert isinstance(postfix.type, (Struct,Union)), self.error(f'"{postfix.token.lexeme}" is type {postfix.type}')
                id = self.expect('id')
                if id.lexeme not in postfix.type:
                    self.error(f'"{id.lexeme}" is not an attribute of {postfix.type.to}')
                attr = postfix.type[id.lexeme]
                if isinstance(postfix.type, Union):
                    postfix = postfix.union(attr)
                else:
                    postfix = Dot(id, postfix, attr)
            elif self.accept('->'):
                assert hasattr(postfix.type, 'to'), self.error(f'{postfix.type} is not pointer type')
                id = self.expect('id')
                if id.lexeme not in postfix.type.to:
                    self.error(f'"{id.lexeme}" is not an attribute of {postfix.type.to}')
                attr = postfix.type.to[id.lexeme]
                if isinstance(postfix.type.to, Union):
                    postfix = Deref(id, postfix.ptr_union(attr))
                else:
                    postfix = Arrow(id, postfix, attr)
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
        self.max_args = min(max(self.max_args, len(args)), 4)
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
        elif self.peek2('-', 'number'):
            next(self)
            return NegNumber(next(self))
        elif self.peek2('-', 'decimal'):
            next(self)
            return NegDecimal(next(self))
        elif self.peek('-','~'):
            return Unary(next(self), self.cast())
        elif self.peek('++','--'):
            return Pre(next(self), self.unary())
        elif self.peek('!'):
            return Not(next(self), self.cast())
        elif self.peek('&'):
            return AddrOf(next(self), self.cast())
        elif self.peek('sizeof'):
            token = next(self)
            if self.accept('('):
                unary = SizeOf(self.type_name(), token)
                self.expect(')')
            else:
                unary = SizeOf(self.unary().type, token)
            return unary
        else:
            return self.postfix()

    def cast(self):
        '''
        CAST -> UNARY
               |'(' TYPE_NAME ')' CAST
        '''
        if self.peek2('(', *self.TYPE) or self.peek('(') and self.peek_typedefs(1):
            token = next(self)
            type = self.type_name()
            self.expect(')')
            return Cast(token, type, self.cast())
        else:
            return self.unary()

    def mul(self):
        '''
        MUL -> CAST {('*'|'/'|'%') CAST}
        '''
        mul = self.cast()
        while self.peek('*','/','%'):
            mul = Binary(next(self), mul, self.cast())
        return mul

    def add(self):
        '''
        ADD -> MUL {('+'|'-') MUL}
        '''
        add = self.mul()
        while self.peek('+','-'):
            add = Binary(next(self), add, self.mul())
        return add

    def shift(self):
        '''
        SHIFT -> ADD {('<<'|'>>') ADD}
        '''
        shift = self.add()
        while self.peek('<<','>>'):
            shift = Binary(next(self), shift, self.add())
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
            bit_and = Binary(next(self), bit_and, self.equality())
        return bit_and

    def bit_xor(self):
        '''
        BIT_XOR -> BIT_AND {'^' BIT_AND}
        '''
        bit_xor = self.bit_and()
        while self.peek('^'):
            bit_xor = Binary(next(self), bit_xor, self.bit_and())
        return bit_xor

    def bit_or(self):
        '''
        BIT_OR -> BIT_XOR {'|' BIT_XOR}
        '''
        bit_or = self.bit_xor()
        while self.peek('|'):
            bit_or = Binary(next(self), bit_or, self.bit_xor())
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
                assign = Assign(token, assign, Binary(token, assign, self.assign()))
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
        ENUM -> id ['=' number]
        '''
        id = self.expect('id')
        if self.accept('='):
            value = Number(self.expect('number')).value
        assert id.lexeme not in self.enum_consts, self.error(f'Redeclaration of enumerator "{id.lexeme}"')
        self.enum_consts[id.lexeme] = EnumNumber(id, value)
        return value

    def attr(self, spec, type):
        '''
        ATTR -> DECLR [':' number]
        '''
        type, id = self.translate_declr(type)
        if self.accept(':'):
            self.expect('number')
        if id is None and isinstance(type, Union):
            for name, attr in type.items():
                attr.location = spec.size
                spec.data[name] = attr
            spec.size += type.size
        else:
            spec[id.lexeme] = Attr(type, id)

    def spec(self):
        '''
        TYPE_SPEC -> type
                    |'void'
                    |id
                    |('struct'|'union') [id] '{' {QUAL ATTR {',' ATTR} ';'} '}'
                    |'enum' [id] '{' ENUM {',' ENUM}'}'
        '''
        if self.accept('void'):
            spec = Void()
        elif self.peek('id'):
            token = next(self)
            if token.lexeme not in self.typedefs:
                self.error(f'typedef "{token.lexeme}" not found')
            spec = copy(self.typedefs[token.lexeme])
        elif self.accept('struct'):
            id = self.accept('id')
            if self.accept('{'):
                spec = Struct(id)
                if id:
                    self.structs[id.lexeme] = spec
                while not self.accept('}'):
                    type = self.qual()
                    self.attr(spec, type)
                    while self.accept(','):
                        self.attr(spec, type)
                    self.expect(';')
            else:
                if id and id.lexeme not in self.structs:
                    self.structs[id.lexeme] = Struct(id)
                spec = self.structs[id.lexeme]
        elif self.accept('union'):
            id = self.accept('id')
            if self.accept('{'):
                spec = Union(id)
                if id:
                    self.unions[id.lexeme] = spec
                while not self.accept('}'):
                    type = self.qual()
                    self.attr(spec, type)
                    while self.accept(','):
                        self.attr(spec, type)
                    self.expect(';')
            else:
                if id and id.lexeme not in self.unions:
                    self.unions[id.lexeme] = Union(id)
                spec = self.unions[id.lexeme]
        elif self.accept('enum'):
            id = self.accept('id')
            if self.accept('{'):
                if id:
                    self.enums.append(id.lexeme)
                value = self.enum(0)
                while self.accept(','):
                    value += 1
                    value = self.enum(value)
                self.expect('}')
            else:
                assert id, self.error("Did not specify enum name")
                assert id.lexeme in self.enums, self.error(f'Enum name "{id.lexeme}" not found')
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
        id = self.declr(types)
        assert id is None, self.error(f'Did not expect name "{id.lexeme}" in TYPE NAME')
        for new_type, args in reversed(types):
            type_name = new_type(type_name, *args)
        return type_name

    def declr(self, types):
        '''
        DECLR -> {'*'} DIR_DECLR
        '''
        ns = 0
        while self.accept('*'):
            ns += 1
        id = self.dir_declr(types)
        for _ in range(ns):
            types.append((Pointer, ()))
        return id

    def dir_declr(self, types):
        '''
        DIR_DECLR -> ('(' _DECLR ')'|[id]){'(' PARAMS ')'|'[' number ']'}
        '''
        if self.accept('('):
            id = self.declr(types)
            self.expect(')')
        else:
            id = self.accept('id')
        while self.peek('(','['):
            if self.accept('('):
                params, variable = self.params()
                types.append((Func, (params, variable)))
                self.expect(')')
            elif self.accept('['):
                types.append((Array, (Number(next(self)) if self.peek('number') else None,)))
                self.expect(']')
        return id

    def init(self, type):
        '''
        INIT -> DECLR ['=' (EXPR|'{' INIT_LIST '}')]
        '''
        type, id = self.translate_declr(type)
        init = declr = Local(type, id)
        if self.peek('='):
            token = next(self)
            if self.accept('{'):
                assert isinstance(declr.type, (Array,Struct)), self.error()
                init = InitListAssign(token, declr, self.list())
                self.expect('}')
            elif isinstance(declr.type, Array) and self.peek('string'):
                init = InitArrayString(token, declr, String(next(self)))
            else:
                init = InitAssign(token, declr, self.assign())
        self.scope[declr.token.lexeme] = declr
        return init

    def translate_declr(self, type):
        types = []
        id = self.declr(types)
        for new_type, args in reversed(types):
            type = new_type(type, *args)
        return type, id

    def decln(self):
        '''
        DECLN -> QUAL [INIT {',' INIT}] ';'
        '''
        decln = []
        if self.accept('typedef'):
            type = self.qual()
            type, id = self.translate_declr(type)
            self.typedefs[id.lexeme] = type
            self.expect(';')
        else:
            type = self.qual()
            if not self.accept(';'):
                decln.append(self.init(type))
                while self.accept(','):
                    decln.append(self.init(type))
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
        type = self.qual()
        types = []
        id = self.declr(types)
        for new_type, args in reversed(types):
            if new_type is Array:
                type = Pointer(type)
            else:
                type = new_type(type, *args)
        return Local(type, id)

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
                |id ':'
                |ASSIGN ';'
        SELECT -> 'if' '(' EXPR ')' STATEMENT ['else' STATEMENT]
                 |'switch' '(' EXPR ')' '{' {'case' CONST_EXPR ':' STATEMENT} ['default' ':' STATEMENT] '}'
        LOOP -> 'while' '(' EXPR ')' STATEMENT
               |'for' '(' [EXPR {',' EXPR}] ';' EXPR ';' [EXPR {',' EXPR}] ')' STATEMENT
               |'do' STATEMENT 'while' '(' EXPR ')' ';'
        JUMP -> 'return' [EXPR] ';'
               |'break' ';'
               |'continue' ';'
               |'goto' id ';'
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
            self.returns = True
            token = next(self)
            if self.accept(';'):
                statement = Return(token, None, None)
            else:
                statement = Return(token, self.defn_ret_type, self.expr())
                self.expect(';')
        elif self.accept('break'):
            statement = Break()
            self.expect(';')
        elif self.accept('continue'):
            statement = Continue()
            self.expect(';')
        elif self.accept('goto'):
            statement = Goto(self.expect('id'))
            self.expect(';')
        elif self.peek2('id',':'):
            statement = Label(next(self))
            next(self)
        else:
            statement = self.expr()
            self.expect(';')

        return statement

    def block(self):
        '''
        BLOCK -> {'typedef' ('void'|QUAL) id ';'} {DECL} {STATE} [BLOCK]
        '''
        block = Block()
        while self.peek(*self.TYPE) or self.peek_typedefs():
            block.extend(self.decln())
        while self.peek(';','{','(','id','*','++','--','return','if','switch','while','do','for','break','continue','goto') and not self.peek_typedefs():
            block.append(self.statement())
        if block:
            block.extend(self.block())
        return block

    def program(self):
        program = Program()
        while not self.peek('end'):
            if self.accept('typedef'):
                type = self.qual()
                type, id = self.translate_declr(type)
                self.typedefs[id.lexeme] = type
                self.expect(';')
            elif self.accept('extern'):
                type = self.qual()
                type, id = self.translate_declr(type)
                if id:
                    self.globs[id.lexeme] = Glob(type, id)
                self.expect(';')
            else:
                self.accept('static')
                type = self.qual()
                type, id = self.translate_declr(type)
                if id:
                    self.globs[id.lexeme] = glob = Glob(type, id)
                if self.accept('{'):
                    assert id is not None, self.error('Function definition needs a name')
                    assert isinstance(type, Func), self.error(f'"{id.lexeme}" is not of function type')
                    assert not any(param.token is None for param in type.params), self.error(f'"{id.lexeme}" cannot have abstract parameters')
                    self.begin_func(type)
                    for param in type.params[:4]:
                        self.param_scope[param.token.lexeme] = param
                    for param in type.params[4:]:
                        self.stack_param_scope[param.token.lexeme] = param
                    if type.variable:
                        defn = VarDefn
                    else:
                        self.scope = self.param_scope
                        defn = Defn
                    block = self.block()
                    self.end_func()
                    program.append(defn(type, id, block, self.returns, self.calls, self.max_args, self.space))
                    self.expect('}')
                elif self.accept('='):
                    assert id is not None, self.error('Assigning to nothing')
                    assert not isinstance(type, Void), self.error('Cannot assign a void type a value')
                    if self.accept('{'):
                        assert isinstance(type, (Array,Struct)), self.error('Cannot list assign to scalar')
                        glob.init = self.list()
                        self.expect('}')
                    else:
                        glob.init = self.const()
                    program.append(glob)
                    self.expect(';')
                else:
                    if id and type.size:
                        program.append(glob)
                    self.expect(';')
        return program

    def peek_typedefs(self, offset=0):
        return self.peek('id', offset=offset) \
            and self.tokens[self.index+offset].lexeme in self.typedefs

    def begin_func(self, defn_type):
        self.defn_ret_type = defn_type.ret
        self.space = 0
        self.returns = False
        self.calls = False
        self.max_args = 0
        self.scope = Scope()
        self.param_scope = Scope()
        self.stack_param_scope = Scope()
        self.stack = []
        self.begin_scope()

    def end_func(self):
        self.end_scope()

    def begin_scope(self):
        self.stack.append((self.scope, self.structs, self.typedefs, self.unions, self.enums, self.enum_consts))
        self.scope = self.scope.copy()
        self.structs = self.structs.copy()
        self.typedefs = self.typedefs.copy()
        self.unions = self.unions.copy()
        self.enums = self.enums.copy()
        self.enum_consts = self.enum_consts.copy()

    def end_scope(self):
        self.space = max(self.space, self.scope.size)
        self.scope, self.structs, self.typedefs, self.unions, self.enums, self.enum_consts = self.stack.pop()

    def parse(self, tokens):
        self.stack = []
        self.structs = {}
        self.typedefs = {}
        self.unions = {}
        self.enums = []
        self.enum_consts = {}
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

    def peekn(self, *buckets):
        if self.index+len(buckets) < len(self.tokens)-1:
            for i, bucket in enumerate(buckets):
                if type(bucket) is str:
                    bucket = (bucket,)
                if not self.peek(*bucket, offset=i):
                    return False
            return True
        return False
    
    def peek2(self, first, *second):
        return self.peek(first) and self.peek(*second, offset=1)
    
    def accept(self, symbol):
        if self.peek(symbol):
            return next(self)

    def expect(self, symbol):
        if self.peek(symbol):
            return next(self)
        self.error(f'Expected "{symbol}"')

    def error(self, msg=None):
        error = self.tokens[self.index]
        raise SyntaxError(f'Line {error.line}: Unexpected {error.type} token "{error.lexeme}".'+(f' {msg}.' if msg is not None else ''))

def parse(tokens):
    parser = CParser()
    return parser.parse(tokens)