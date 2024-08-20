msg: "Hello world!\n\0"
OUT = 0x80000000
main:
	ld A, =msg
	ld B, =OUT
loop:
	ld C, [A]
	cmp C, '\0'
	jeq end
	ld [B], C
	add A, 1
	jmp loop
end:
	halt