//#define FOO 5

#if defined FOO
#define BAR -2
#if FOO >= 5 && BAR > - 3 
int maybe = 456
#endif
int yes = 40000
#else
#define BAR 34
int no = 1234
#endif

//#define BAR 3
#if BAR == 0
#define BAZ 9
#elif BAR == 1
#define BAZ 8
#elif BAR == 2
#define BAZ 7
#else
#define BAZ 6
#endif
int bar = BAZ

int main() {
    int i;
    for (i=0; i < BAR; i++) {

    }
}


/*
Dead block
Nested
Already True'd
Level

def process_tokens(tokens, eval_condition):
    result = []
    stack = []

    for tok in tokens:
        kind = tok.kind  # e.g. "IF", "ELIF", "ELSE", "ENDIF", "TEXT"
        outer_active = all(frame["active"] for frame in stack) if stack else True

        if kind == "IF":
            cond_val = eval_condition(tok.value) if outer_active else False
            stack.append({
                "active": cond_val and outer_active,
                "seen_true": cond_val,
                "should_evaluate": outer_active
            })

        elif kind == "ELIF":
            frame = stack.pop()
            outer_active = all(f["active"] for f in stack) if stack else True
            seen_true = frame["seen_true"]
            cond_val = eval_condition(tok.value) if (outer_active and not seen_true) else False
            stack.append({
                "active": (not seen_true and cond_val and outer_active),
                "seen_true": seen_true or cond_val,
                "should_evaluate": outer_active
            })

        elif kind == "ELSE":
            frame = stack.pop()
            outer_active = all(f["active"] for f in stack) if stack else True
            stack.append({
                "active": (not frame["seen_true"] and outer_active),
                "seen_true": True,
                "should_evaluate": outer_active
            })

        elif kind == "ENDIF":
            stack.pop()

        else:
            # normal token
            if all(frame["active"] for frame in stack):
                result.append(tok)

    return result


*/