# -*- coding: utf-8 -*-
"""
Created on Fri Sep  6 14:05:50 2024

@author: ccslon
"""
from collections import UserDict
from bit32 import Op, Size, Reg, Cond, floating_point
from .cnodes import Frame
from . import cexpressions

class Type:
    """Base class for C type."""

    @classmethod
    def max_type(cls, left, right):
        """Widen 2 given C types."""
        if isinstance(left, (Float, Pointer)):
            return left
        if isinstance(right, (Float, Pointer)):
            return right
        return type(left if left.width >= right.width else right)(left.signed and right.signed)

    def cast(self, other):
        """Determine if given type is able to cast to instance type."""
        return self == other


class Void(Type):
    """Class for void type."""

    def __init__(self):
        self.size = self.width = 0

    def __eq__(self, other):
        """Determine if the given type is equal to void."""
        return isinstance(other, Void)

    def __str__(self):
        """Get string representation of void type."""
        return 'void'


class Value(Type):
    """Base class for types that hold values."""

    def __init__(self):
        self.const = False
        self.interval = 1
        self.width = 0

    def convert(self, emitter, n, other):
        """Convert to given type if applicable."""
        pass

    def fti(self, emitter, n):
        """Convert float to integer."""
        pass

    def itf(self, emitter, n):
        """Convert integer to float."""
        pass

    def address(self, emitter, n, var, base):
        """Generate address code for generic type."""
        emitter.emit_address(Reg(n), Reg(base), var.offset, var.name())
        return Reg(n)

    def reduce(self, emitter, n, var, base):
        """Generate code for generic type."""
        emitter.emit_load(self.width, Reg(n), Reg(base), var.offset, var.name())
        return Reg(n)

    def store(self, emitter, n, var, base):
        """Generate code for storing to generic type."""
        emitter.emit_store(self.width, Reg(n), Reg(base), var.offset, var.name())
        return Reg(n)

    def reduce_pre(self, emitter, n, op):
        """Generate code for pre operator."""
        emitter.emit_binary(op, self.width, Reg(n), self.interval)

    def reduce_post(self, emitter, n, op):
        """Generate code for post operator."""
        emitter.emit_ternary(op, self.width, Reg(n+1), Reg(n), self.interval)

    def reduce_binary(self, emitter, n, op, left, right):
        """Generate code for binary opertor."""
        emitter.emit_binary(op, self.width, left.reduce(emitter, n), right.reduce_number(emitter, n+1))

    def reduce_compare(self, emitter, n, left, right):
        """Generate code for compare operator."""
        emitter.emit_binary(Op.CMP, self.width, left.reduce(emitter, n), right.reduce_number(emitter, n+1))

    def list_generate(self, emitter, n, right, loc):
        """Generate code for initialization lists."""
        right.reduce(emitter, n+1)
        self.convert(emitter, n+1, right.type)
        emitter.emit_store(self.width, Reg(n+1), Reg(n), loc)

    def global_address(self, emitter, n, glob):
        """Generate address code for global variable."""
        emitter.emit_load_global(Reg(n), glob.name())
        return Reg(n)

    def global_reduce(self, emitter, n, glob):
        """Generate code for global variable."""
        self.global_address(emitter, n, glob)
        emitter.emit_load(self.width, Reg(n), Reg(n))
        return Reg(n)

    def global_store(self, emitter, n, glob):  # TODO test
        """Generate code for storing a global variable."""
        emitter.emit_load_global(Reg(n+1), glob.name())
        emitter.emit_store(self.width, Reg(n), Reg(n+1))
        return Reg(n)

    def global_data(self, emitter, expr, data):
        """Generate code for global data."""
        data.append((self.width, expr.data(emitter)))


class Numeric(Value):
    """Base class for numeric types."""

    BINARY_OP = {
        '+': Op.ADD,
        '+=': Op.ADD,
        '++': Op.ADD,
        '-': Op.SUB,
        '-=': Op.SUB,
        '--': Op.SUB,
        '*': Op.MUL,
        '*=': Op.MUL,
        '<<': Op.SHL,
        '<<=': Op.SHL,
        '>>': Op.SHR,
        '>>=': Op.SHR,
        '^': Op.XOR,
        '^=': Op.XOR,
        '|': Op.OR,
        '|=': Op.OR,
        '||': Op.OR,
        '&':  Op.AND,
        '&=': Op.AND,
        '&&': Op.AND,
        '/':  Op.DIV,
        '/=': Op.DIV,
        '%':  Op.MOD,
        '%=': Op.MOD
    }
    UNARY_OP = {
        '++': Op.ADD,
        '--': Op.SUB,
        '-': Op.NEG,
        '~': Op.NOT
    }
    CMP = Op.CMP
    SCMP_OP = {      # Signed compare op
        '==': Cond.EQ,
        '!=': Cond.NE,
        '>':  Cond.GT,
        '<':  Cond.LT,
        '>=': Cond.GE,
        '<=': Cond.LE
    }
    INV_SCMP_OP = {  # inverse signed compare op
        '==': Cond.NE,
        '!=': Cond.EQ,
        '>':  Cond.LE,
        '<':  Cond.GE,
        '>=': Cond.LT,
        '<=': Cond.GT
    }
    UCMP_OP = {      # unsigned compare op
        '>':  Cond.HI,
        '<':  Cond.LO,
        '>=': Cond.HS,
        '<=': Cond.LS
    }
    INV_UCMP_OP = {  # inverse unsigned compare op
        '>':  Cond.LS,
        '<':  Cond.HS,
        '>=': Cond.LO,
        '<=': Cond.HI
    }

    def __init__(self, signed):
        super().__init__()
        self.signed = signed

    def convert(self, emitter, n, other):
        """Convert to given type if applicable."""
        other.fti(emitter, n)

    def fti(self, emitter, n):
        """Convert float to integer."""
        pass

    def itf(self, emitter, n):
        """Convert integer to float."""
        emitter.emit_binary(Op.ITF, Size.WORD, Reg(n), Reg(n))

    def get_unary_op(self, op):
        """Get unary operator for this type."""
        return self.UNARY_OP[op.lexeme]

    def get_binary_op(self, op):
        """Get binary operator for this type."""
        return self.BINARY_OP[op.lexeme]

    def get_cmp_op(self, op):
        """Get compare operator for this type."""
        if self.signed:
            return self.SCMP_OP[op.lexeme]
        return self.UCMP_OP.get(op.lexeme, self.SCMP_OP[op.lexeme])

    def get_inv_cmp_op(self, op):
        """Get inverse compare operator for this type."""
        if self.signed:
            return self.INV_SCMP_OP[op.lexeme]
        return self.INV_UCMP_OP.get(op.lexeme, self.INV_SCMP_OP[op.lexeme])

    def get_node(self, value):
        """Get the constant node associated with this type."""
        return cexpressions.Number(value)

    def __eq__(self, other):
        """Determine if the given is equal to this type."""
        return isinstance(other, Numeric)


class Char(Numeric):
    """Class for char type."""

    def __init__(self, signed=True):
        super().__init__(signed)
        self.size = self.width = Size.BYTE

    def __str__(self):
        """Get string representation for char type."""
        return 'char'


class Short(Numeric):
    """Class for short type."""

    def __init__(self, signed=True):
        super().__init__(signed)
        self.size = self.width = Size.HALF

    def __str__(self):
        """Get string representation for short type."""
        return 'short'


class Int(Numeric):
    """Class for int type."""

    def __init__(self, signed=True):
        super().__init__(signed)
        self.size = self.width = Size.WORD

    def __str__(self):
        """Get string representation for int type."""
        return 'int'


class Float(Numeric):
    """Class for float type."""

    BINARY_OP = {
        '+': Op.ADDF,
        '+=': Op.ADDF,
        '++': Op.ADDF,
        '-': Op.SUBF,
        '-=': Op.SUBF,
        '--': Op.SUBF,
        '*': Op.MULF,
        '*=': Op.MULF,
        '/':  Op.DIVF,
        '/=': Op.DIVF,
        '<<': Op.SHL,
        '<<=': Op.SHL,
        '>>': Op.SHR,
        '>>=': Op.SHR,
        '^': Op.XOR,
        '^=': Op.XOR,
        '|': Op.OR,
        '|=': Op.OR,
        '||': Op.OR,
        '&': Op.AND,
        '&=': Op.AND,
        '&&': Op.AND
    }
    UNARY_OP = {
        '++': Op.ADDF,
        '--': Op.SUBF,
        '-': Op.NEGF,
        '~': Op.NOT
    }
    CMP = Op.CMPF

    def __init__(self):
        super().__init__(True)
        self.size = self.width = Size.WORD

    def convert(self, emitter, n, other):  # TODO test
        """Convert to given type if applicable."""
        other.itf(emitter, n)

    def fti(self, emitter, n):
        """Convert float to integer."""
        emitter.emit_binary(Op.FTI, Size.WORD, Reg(n), Reg(n))

    def itf(self, emitter, n):
        """Convert integer to float."""
        pass

    def reduce_pre(self, emitter, n, op):
        """Generate code for pre operator."""
        emitter.emit_load_immediate(Reg(n+1), floating_point(1))
        emitter.emit_binary(op, self.width, Reg(n), Reg(n+1))

    def reduce_post(self, emitter, n, op):
        """Generate code for post operator."""
        emitter.emit_load_immediate(Reg(n+2), floating_point(1))
        emitter.emit_ternary(op, self.width, Reg(n+1), Reg(n), Reg(n+2))

    def reduce_binary(self, emitter, n, op, left, right):
        """Generate code for binary operator."""
        emitter.emit_binary(op, self.width, left.reduce_float(emitter, n), right.reduce_float(emitter, n+1))

    def reduce_compare(self, emitter, n, left, right):
        """Generate code for compare operator."""
        emitter.emit_binary(Op.CMPF, self.width, left.reduce_float(emitter, n), right.reduce_float(emitter, n+1))

    def get_node(self, value):
        """Get the constant node associated with floats."""
        return cexpressions.Decimal(value)

    def __eq__(self, other):
        """Determine if given type is equal to this type."""
        return isinstance(other, Numeric)

    def __str__(self):
        """Get string representation for float."""
        return 'float'


class Pointer(Int):
    """Class for pointer type."""

    def __init__(self, ctype):
        super().__init__(False)
        self.to = self.of = ctype
        self.interval = int(self.to.size)

    def reduce_binary(self, emitter, n, op, left, right):
        """Generate code for binary operator."""
        if self.interval > 1:
            left.reduce(emitter, n)
            right.reduce(emitter, n+1)
            emitter.emit_binary(Op.MUL, Size.WORD, Reg(n+1), self.interval)
            emitter.emit_binary(op, Size.WORD, Reg(n), Reg(n+1))
        else:
            super().reduce_binary(emitter, n, op, left, right)

    def reduce_array(self, emitter, n, array):
        """Generate code for array access."""
        return array.reduce(emitter, n)

    def cast(self, other):  # TODO test
        """Determine if the given type can be cast to this type."""
        return isinstance(other, (Numeric, Array))

    def __eq__(self, other):
        """Determine if given type is equal to this pointer type."""
        return (isinstance(other, Pointer)
                and (self.to == other.to
                     or isinstance(self.to, Void)
                     or isinstance(other.to, Void))
                or isinstance(other, Array)
                and (self.of == other.of
                     or isinstance(self.to, Void))
                or isinstance(other, Function) and self.to == other)

    def __str__(self):
        """Get string representation for pointer type."""
        return f'ptr({self.to})'


class List(Value):
    """Base class for types that can list initialized."""

    def list_generate(self, emitter, n, right, loc):
        """Generate code for initialization lists."""
        # can't be address or it will be optimized away incorrectly.
        emitter.emit_ternary(Op.ADD, Size.WORD, Reg(n+1), Reg(n), loc)
        for i, (loc, ctype) in enumerate(self):
            ctype.list_generate(emitter, n+1, right[i], loc)

    def global_data(self, emitter, expr, data):
        """Generate code for global data."""
        for i, (_, ctype) in enumerate(self):
            ctype.global_data(emitter, expr[i], data)
        return data


class Struct(Frame, List):
    """Class for struct type."""

    def __init__(self, name):
        super().__init__()
        self.const = False
        self.name = name.lexeme if name is not None else name
        self.width = Size.WORD

    def reduce(self, emitter, n, var, base):
        """Generate code for loading a struct."""
        return self.address(emitter, n, var, base)

    def store(self, emitter, n, var, base):
        """Generate code for storing a struct."""
        self.address(emitter, n+1, var, base)
        frame = {}
        for loc, ctype in self:
            if loc in frame:
                if ctype.size > frame[loc].size:
                    frame[loc] = ctype
            else:
                frame[loc] = ctype
        for loc, ctype in frame.items():
            if ctype.size in [Size.WORD, Size.BYTE, Size.HALF]:
                emitter.emit_load(ctype.width, Reg(n+2), Reg(n), loc)
                emitter.emit_store(ctype.width, Reg(n+2), Reg(n+1), loc)
            else:
                for i in range(ctype.size // Size.WORD):
                    emitter.emit_load(Size.WORD, Reg(n+2), Reg(n), loc + Size.WORD*i)
                    emitter.emit_store(Size.WORD, Reg(n+2), Reg(n+1), loc + Size.WORD*i)
                for j in range(ctype.size % Size.WORD):
                    emitter.emit_load(Size.BYTE, Reg(n+2), Reg(n), loc + Size.WORD*(i+1)+j)
                    emitter.emit_store(Size.BYTE, Reg(n+2), Reg(n+1), loc + Size.WORD*(i+1)+j)

    def __iter__(self):
        """Iterate through struct."""
        for attr in self.data.values():
            yield attr.offset, attr.type

    def __eq__(self, other):
        """Determine if the given type is equal to this struct type."""
        return isinstance(other, Struct) and self.name == other.name

    def __str__(self):
        """Get string representation for struct."""
        return f'struct {self.name}'


class Array(List):
    """Class for array type."""

    def __init__(self, of, length):
        super().__init__()
        if length is None:
            self.length = length
        else:
            self.size = of.size * length.value
            self.length = length.value
        self.of = of
        self.width = Size.WORD

    def reduce(self, emitter, n, var, base):
        """Generate code for loading array."""
        return self.address(emitter, n, var, base)

    def reduce_array(self, emitter, n, array):
        """Generate code for special array access."""
        return array.address(emitter, n)

    def global_reduce(self, emitter, n, glob):
        """Generate code for global array."""
        self.global_address(emitter, n, glob)

    def __iter__(self):
        """Iterate through array."""
        for i in range(self.length):
            yield i*self.of.size, self.of

    def __eq__(self, other):  # TODO test
        """Determine if given type is equal to this array type."""
        return isinstance(other, (Array, Pointer)) and self.of == other.of

    def __str__(self):
        """Get string representation for array."""
        return f'array({self.of})'


class Union(UserDict, Value):
    """Class for union type."""

    def __init__(self, name):
        super().__init__()
        self.const = False
        self.size = 0
        self.width = Size.WORD
        self.name = name

    def __setitem__(self, name, attr):
        """Override of __setitem__ to match C union behavior."""
        attr.offset = 0
        self.size = max(self.size, attr.type.size)
        super().__setitem__(name, attr)


class Function(Value):
    """Class for function type."""

    def __init__(self, return_type, parameters, variadic):
        super().__init__()
        self.return_type = return_type
        self.parameters = parameters
        self.variadic = variadic
        self.size = 0
        self.width = Size.WORD

    def global_reduce(self, emitter, n, glob):
        """Generate code for loading global function."""
        return self.global_address(emitter, n, glob)

    def cast(self, other):
        """Determine if type can be cast to given type (functions cannot)."""
        return False

    def __eq__(self, other):
        """Determine if given type is equal to this function type."""
        return (isinstance(other, Function)
                and self.return_type == other.return_type
                and len(self.parameters) == len(other.parameters)
                and self.variadic == other.variadic
                and all(param.type == other.parameters[i].type
                        for i, param in enumerate(self.parameters)))

    def __str__(self):
        """Get string representation for this function type."""
        return f'{self.return_type} func({",".join(map(str, (param.type for param in self.parameters)))})'
