%define ARRAY_SIZE	5
%define ELEMENT_SIZE    4
%define EOF	       -1

segment .data
	inputPrompt:	db "Please Enter int value (ctrl-d to stop): ", 0
	intFormat:	db "%d", 0
	intOutput:	db "Current Arr: %d, Min Val: %d, Arithm Val: %d", 10, 0
	numElements:	db "number of elements: %d", 10, 0
	sum:		db "Sum: %d", 10, 0
	min:		db "Min: %d", 10, 0
	max:		db "Max: %d", 10, 0
	arraySize:	db  5d
	
segment .bss
	myArray:	resq 1
	intInput:	resd 1

segment .text
	global		asm_main
	extern		printf, scanf, calloc

asm_main:
	enter		0, 0

	xor		r12, r12
	xor		r13, r13
	xor		r9, r9

	mov		rdi, myArray
	mov		rcx, ARRAY_SIZE

inputLoop:
	inc		rcx
	push		rcx
	push		rdi

	;;prompt and get inputs
	mov		rdi, inputPrompt
	call		printf

	mov		rdi, intFormat
	mov		rsi, intInput
	call		scanf
	
	;;check if end of reading
	cmp		eax, EOF
	je		inputDone
	inc		r12

	;;check if array bounds exceeded
	cmp		r12, ARRAY_SIZE
	jle		skipResize
;	call		resizeArray
	;;resize
	mov		rdi, 10	;new array size
	mov		rsi, ELEMENT_SIZE
	call		calloc

	;;move elements into new array
	mov		rdi, rax	;dest
	mov		rsi, myArray	;source
	mov		rcx, ARRAY_SIZE	;old array size
	mov		[myArray], rax	;replace old ptr with new
	cld
	rep		movsd

skipResize:
	;;sums values
	add		r13, [intInput]

	;;add elements to array and loop
	xor		rax, rax
	mov		eax, [intInput]
	pop		rdi

	;;relocate rdi to new location
;;	push 		rcx
;	mov		rcx, r12 	;loop number of elements times
;	mov		rdi, myArray 
;relocateLoop:
;	add		rdi, 4		;move up to current element
;	loop		relocateLoop
;	pop		rcx
	stosd
	mov		r9, [rdi - 4]
	pop		rcx
	jmp inputLoop

inputDone:
	;;set up array access
	mov		rbx, myArray
	mov		rcx, r12

	;;set up max and min
	xor		r14, r14
	xor		r15, r15
	movsx		r14, DWORD [rbx]
	movsx		r15, DWORD [rbx]

minMaxLoop:
	push 		rcx
	push 		rsi

	;;printing to test output
	xor r9,r9
	movsx	   	 r9, DWORD [rbx]
	mov		rdi, intFormat
	mov		rsi, r9
	call		printf

	;;comparisons - min
	movsx		 r9, DWORD [rbx]
	sub 		r9, r14		;sets flags
	jns		returnMin
	movsx		r14, DWORD [rbx]

returnMin:	;;-max
	movsx		r9, DWORD [rbx]
	sub		r9, r15		;sets flags
	js		returnMax
	movsx		r15, DWORD [rbx]
returnMax:
	pop rsi
	pop rcx
	add		rbx, 4
	loop		minMaxLoop
	jmp     	printStuff


;;not coding in this function yet
resizeArray:
	enter 0,0
	mov	rax, ARRAY_SIZE
	ret

printStuff:
	;;print number of elements
	mov		rdi, numElements
	mov		rsi, r12
	call		printf
	
	;;print sum
	mov		rdi, sum
	mov 		rsi, r13
	call		printf
	
	;;print min
	mov		rdi, min
	mov		rsi, r14
	call		printf

	;;print max
	mov		rdi, max
	mov		rsi, r15
	call 		printf

	;;exit
	mov		rax, 0
	leave
	ret
