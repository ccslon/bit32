# -*- coding: utf-8 -*-
"""
Created on Fri Sep  6 14:05:50 2024

@author: ccslon
"""
from bit32 import Op, Size, Reg, Cond
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

    def size(self):
        """Get the total size of this type."""
        return self.width

    def cast(self, other):
        """Determine if given type is able to cast to instance type."""
        return self.__eq__(other)


class Void(Type):
    """Class for void type."""

    def __init__(self):
        self.width = 0

    def cast(self, _):
        """Any type can be case to void"""
        return True

    def get_node(self, _):
        """Get the constant node associated with this type."""
        return cexpressions.Number(0)

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

    def convert(self, emitter, source, other):
        """Convert to given type if applicable."""
        return source

    def fti(self, emitter, source):
        """Convert float to integer."""
        return source

    def itf(self, emitter, source):
        """Convert integer to float."""
        return source

    def address(self, emitter, var, base):
        """Generate address code for generic type."""
        return emitter.emit_address(base, var.offset, var.marked, var.name)

    def reduce(self, emitter, var, base):
        """Generate code for generic type."""
        return emitter.emit_load(self.width, base, var.offset, var.marked, var.name)

    def store(self, emitter, source, var, base):
        """Generate code for storing to generic type."""
        return emitter.emit_store(self.width, source, base, var.offset, var.marked, var.name)

    def reduce_pre(self, emitter, op, source):
        """Generate code for pre operator."""
        return emitter.emit_binary(op, self.width, source, self.interval)

    def reduce_post(self, emitter, op, source):
        """Generate code for post operator."""
        return emitter.emit_binary(op, self.width, source, self.interval)

    def reduce_binary(self, emitter, op, left, right):
        """Generate code for binary opertor."""
        return emitter.emit_binary(op, self.width, left.reduce(emitter), right.reduce_number(emitter))

    def reduce_compare(self, emitter, left, right):
        """Generate code for compare operator."""
        return emitter.emit_compare(Op.CMP, self.width, left.reduce(emitter), right.reduce_number(emitter))

    def list_generate(self, emitter, element, base, offset):
        """Generate code for initialization lists."""
        source = element.reduce(emitter)
        source = self.convert(emitter, source, element.type)
        emitter.emit_store(self.width, source, base, offset)

    def global_address(self, emitter, glob):
        """Generate address code for global variable."""
        return emitter.emit_load_global(glob.name)

    def global_reduce(self, emitter, glob):
        """Generate code for global variable."""
        base = self.global_address(emitter, glob)
        return emitter.emit_load(self.width, base)

    def global_store(self, emitter, source, glob):  # TODO test
        """Generate code for storing a global variable."""
        base = emitter.emit_load_global(glob.name)
        return emitter.emit_store(self.width, source, base)

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

    def convert(self, emitter, source, other):
        """Convert to given type if applicable."""
        return other.fti(emitter, source)

    def fti(self, emitter, source):
        """Convert float to integer."""
        return source

    def itf(self, emitter, source):
        """Convert integer to float."""
        return emitter.emit_unary(Op.ITF, Size.WORD, source)

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
        """Determine if the given type is equal to this type."""
        return isinstance(other, Numeric)


class Char(Numeric):
    """Class for char type."""

    def __init__(self, signed=True):
        super().__init__(signed)
        self.width = Size.BYTE

    def __str__(self):
        """Get string representation for char type."""
        return 'char'


class Short(Numeric):
    """Class for short type."""

    def __init__(self, signed=True):
        super().__init__(signed)
        self.width = Size.HALF

    def __str__(self):
        """Get string representation for short type."""
        return 'short'


class Int(Numeric):
    """Class for int type."""

    def __init__(self, signed=True):
        super().__init__(signed)
        self.width = Size.WORD

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
        self.width = Size.WORD

    def convert(self, emitter, source, other):  # TODO test
        """Convert to given type if applicable."""
        return other.itf(emitter, source)

    def fti(self, emitter, source):
        """Convert float to integer."""
        return emitter.emit_unary(Op.FTI, Size.WORD, source)

    def itf(self, emitter, source):
        """Convert integer to float."""
        return source

    def reduce_pre(self, emitter, op, source):
        """Generate code for pre operator."""
        interval = emitter.emit_unary(Op.ITF, Size.WORD, 1) # ITF A, 1
        return emitter.emit_binary(op, self.width, source, interval)

    def reduce_post(self, emitter, op, source):
        """Generate code for post operator."""
        interval = emitter.emit_unary(Op.ITF, Size.WORD, 1)
        return emitter.emit_binary(op, self.width, source, interval)

    def reduce_binary(self, emitter, op, left, right):
        """Generate code for binary operator."""
        return emitter.emit_binary(op, self.width, left.reduce_float(emitter), right.reduce_float(emitter))

    def reduce_compare(self, emitter, left, right):
        """Generate code for compare operator."""
        emitter.emit_binary(Op.CMPF, self.width, left.reduce_float(emitter), right.reduce_float(emitter))

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

    def __init__(self, ctype, const=False):
        super().__init__(False)
        self.to = self.of = ctype
        self.interval = int(ctype.size())
        self.const = const

    def reduce_binary(self, emitter, op, left, right):
        """Generate code for binary operator."""
        if self.interval > 1:
            if right.is_constant():
                return emitter.emit_binary(op, Size.WORD, left.reduce(emitter), right.fold().evaluate() * self.interval)
            left = left.reduce(emitter)
            right = right.reduce(emitter)
            scaled = emitter.emit_binary(Op.MUL, Size.WORD, right, self.interval)
            return emitter.emit_binary(op, Size.WORD, left, scaled)
        return super().reduce_binary(emitter, op, left, right)

    def reduce_array(self, emitter, array):
        """Generate code for array access."""
        return array.reduce(emitter)

    def cast(self, other):  # TODO test
        """Determine if the given type can be cast to this type."""
        return isinstance(other, (Numeric, Array))

    def get_node(self, value):
        """Get the constant node associated with pointers."""
        return cexpressions.Number(value, self)

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


class List:
    """Base class for types that can list initialized."""

    def list_generate(self, emitter, right, base, offset):
        """Generate code for initialization lists."""
        # can't be address or it will be optimized away incorrectly.
        base = emitter.emit_binary(Op.ADD, Size.WORD, base, offset)
        for (offset, ctype), element in zip(self, right):
            ctype.list_generate(emitter, element, base, offset)

    def global_data(self, emitter, expr, data):
        """Generate code for global data."""
        for (_, ctype), etype in zip(self, expr):
            ctype.global_data(emitter, etype, data)
        return data


class Array(List, Value):
    """Class for array type."""

    def __init__(self, of, length):
        super().__init__()
        self.of = of
        self.length = length
        self.width = Size.WORD

    def size(self):
        return self.length * self.of.size()

    def reduce(self, emitter, var, base):
        """Generate code for loading array."""
        return self.address(emitter, var, base)

    def reduce_array(self, emitter, array):
        """Generate code for special array access."""
        return array.address(emitter)

    def global_reduce(self, emitter, glob):
        """Generate code for global array."""
        return self.global_address(emitter, glob)

    def __iter__(self):
        """Iterate through array."""
        for i in range(self.length):
            yield i*self.of.size(), self.of

    def __eq__(self, other):  # TODO test
        """Determine if given type is equal to this array type."""
        return isinstance(other, (Array, Pointer)) and self.of == other.of

    def __str__(self):
        """Get string representation for array."""
        return f'array({self.of})'


class Record(Value):


    def __init__(self, name, frame):
        super().__init__()
        self.name = name.lexeme if name is not None else name
        self.frame = frame
        self.width = Size.WORD

    def size(self):
        return self.frame.size

class Struct(List, Record):
    """Class for struct type."""

    FrameType = Frame

    def reduce(self, emitter, var, base):
        """Generate code for loading a struct."""
        return self.address(emitter, var, base)

    def store(self, emitter, source, var, base):
        """Generate code for storing a struct."""
        base = self.address(emitter, var, base)
        frame = {}
        for offset, ctype in self:
            # I forget what this loop does. I think it has to do with absorbed unions
            if offset in frame:
                if ctype.size() > frame[offset].size():
                    frame[offset] = ctype
            else:
                frame[offset] = ctype
        for offset, ctype in frame.items():
            if ctype.size() in {Size.WORD, Size.BYTE, Size.HALF}:
                target = emitter.emit_load(ctype.width, source, offset)
                emitter.emit_store(ctype.width, target, base, offset)
            else:
                for i in range(ctype.size() // Size.WORD):
                    target = emitter.emit_load(Size.WORD, source, offset + Size.WORD*i)
                    emitter.emit_store(Size.WORD, target, base, offset + Size.WORD*i)
                for j in range(ctype.size() % Size.WORD):
                    target = emitter.emit_load(Size.BYTE, source, offset + Size.WORD*(i+1)+j)
                    emitter.emit_store(Size.BYTE, target, base, offset + Size.WORD*(i+1)+j)

    def __iter__(self):
        """Iterate through struct."""
        for attr in self.frame.values():
            yield attr.offset, attr.type

    def __eq__(self, other):
        """Determine if the given type is equal to this struct type."""
        return isinstance(other, Struct) and self.name == other.name

    def __str__(self):
        """Get string representation for struct."""
        return f'struct {self.name}'


class UnionFrame(Frame):
    """Class for union frames."""

    def __setitem__(self, name, attr):
        """Override of __setitem__ to match C union behavior."""
        attr.offset = 0
        self.size = max(self.size, attr.type.size())
        self.data[name] = attr


class Union(Record):
    """Class for union type."""

    FrameType = UnionFrame


class Function(Value):
    """Class for function type."""

    def __init__(self, return_type, parameters, variadic):
        super().__init__()
        self.return_type = return_type
        self.parameters = parameters
        self.variadic = variadic
        self.width = Size.WORD

    def size(self):
        return 0

    def global_reduce(self, emitter, glob):
        """Generate code for loading global function."""
        return self.global_address(emitter, glob)

    def cast(self, other):
        """Determine if type can be cast to given type (functions cannot)."""
        return False

    def __eq__(self, other):
        """Determine if given type is equal to this function type."""
        return (isinstance(other, Function)
                and self.return_type == other.return_type
                and len(self.parameters) == len(other.parameters)
                and self.variadic == other.variadic
                and all(p.type == o.type for p, o in zip(self.parameters, other.parameters)))

    def __str__(self):
        """Get string representation for this function type."""
        return f'{self.return_type} func({",".join(map(str, (param.type for param in self.parameters)))})'
