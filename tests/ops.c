#define OP(name, op) int name(int l, int r) { if (l op r) {} return l op r; }
OP(add, +)
OP(sub, -)
OP(mul, *)
OP(div, /)
OP(mod, %)
OP(shl, <<)
OP(shr, >>)
OP(eq, ==)
OP(ne, !=)
OP(le, <=)
OP(ge, >=)
OP(lt, <)
OP(gt, >)
OP(and, &)
OP(xor, ^)
OP(or, |)
int not(int a) {
    if (!a) {

    }
    return !a;
}