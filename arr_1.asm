%define ARRAY_SIZE	5
%define ELEMENT_SIZE    4
%define EOF	       -1
%define RESIZE_MULTIPLE 2

segment .data
	inputPrompt:	db "Please Enter int value (ctrl-d to stop): ", 0
	intFormat:	db "%d", 0
	intOutput:	db "Current Arr: %d, Min Val: %d, Arithm Val: %d", 10, 0
	numElements:	db "number of elements: %d", 10, 0
	sum:		db "Sum: %d", 10, 0
	min:		db "Min: %d", 10, 0
	max:		db "Max: %d", 10, 0
	
segment .bss
	myArray:	resq 1		;this is a pointer
	intInput:	resd 1
	arraySize:	resq 1		;this holds the arrays current size, used for resizing

segment .text
	global		asm_main
	extern		printf, scanf, calloc, free

asm_main:
	enter		0, 0

	;;allocate array
	mov		rdi, ARRAY_SIZE
	mov		rsi, ELEMENT_SIZE
	call		calloc
	mov		[myArray], rax
	mov		[arraySize], DWORD ARRAY_SIZE

	;;clear registers
	xor		r12, r12
	xor		r13, r13
	xor		r9, r9

	;;prepare to input elements
	mov		rdi, [myArray]
	mov		rcx, ARRAY_SIZE
	cld

inputLoop:
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
	mov		r9, [arraySize]
	cmp		r12, [arraySize]
	jle		skipResize
	
	;;prepare for call to resizeArray
	mov		rdi, [arraySize]
	mov		rsi, RESIZE_MULTIPLE
	mov		rdx, myArray
	call		resizeArray

	;;store return values from resizeArray
	mov		[myArray], rax
	mov		[arraySize], QWORD rdx

skipResize:	
	;;sums values
	add		r13, [intInput]

	;;add elements to array and loop
	xor		rax, rax
	mov		eax, [intInput]
	pop		rdi

	;;relocate rdi to new location
	mov		rcx, r12 	;loop number of elements - 1 timesi
	sub		rcx, 1
	cmp		rcx, 0		;skip if it is the only element
	je		skipRelocate
	mov		rdi, [myArray] 
relocateLoop:
	add		rdi, 4		;move up to current element
	loop		relocateLoop
skipRelocate:
	stosd
	pop		rcx
	jmp inputLoop

inputDone:
	;;set up array access
	mov		rbx, [myArray]
	mov		rcx, r12

	;;set up max and min
	xor		r14, r14
	xor		r15, r15
	movsx		r14, DWORD [rbx]
	movsx		r15, DWORD [rbx]

minMaxLoop:
	push 		rcx
	push 		rsi

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

	;;free the arrays memory
	mov		rdi, [myArray]
	call		free
	
	;;exit
	mov		rax, 0
	leave
	ret

;;Function Parameters
;;RDI - array size
;;RSI - resize multiple
;;RDX - the arrays pointer
;;
;;Return Values
;;RAX returns the array pointer
;;RDX returns array size
resizeArray:
        enter 0,0
	push		r12
	push 		r13

	xor		rbx, rbx
	xor		rax, rax

	;;store for safe keeping
	mov		r13, rdx		;store the arrays pointer
	mov		r8, rdi		;store old array size
        mov             rax, rdi	;array size

	;;calculate new size
        mov             rbx, rsi		;resize multiple
        mul             bl
        mov             r12, QWORD rax		;r12 temp holds the new size

        ;;allocate new memory
        mov             rdi, rax
        mov             rsi, ELEMENT_SIZE
        call            calloc

        ;;move elements into new array
        mov             rdi, rax        ;dest
        mov             rsi, [r13]  ;source
        mov             rcx, r12        ;old array size
        cld
        rep             movsd
	
	;;give return values and pop values back off stack
	mov		rdx, r12	;put size into rdx for returni
	pop		r13
	pop		r12

        leave
        ret

