%define	empty 0
%define EOF   -1
%define NULL  0
%define MAX_BUFFER 255

struc ll
	.pID:	resd 1
	.nameF:	resq 1
	.price:	resq 1
	.cost:	resq 1
	.quantity: resd 1
	.ptr:	resq 1
	.size:
endstruc

segment .data
	promptID:	db "Enter Product ID: ", 0
	promptNF:	db "Enter Product Name: ",0
	promptPrice:	db "Enter the Price: ",0
	promptCost:	db "Enter the Cost: ",0
	promptQuantity:	db "Enter the Quantity: ", 0
	newLine:	db "", 10, 10, 0

	outputID:	db "Product ID: %d", 10, 0
	outputNF:	db "Product Name: %s", 10, 0
	outputPrice:	db "Price: %lf", 10, 0
	outputCost:	db "Cost: %lf", 10, 0
	outputQuantity:	db "Quantity: %d", 10, 0

	outputTotalQuantity:	db "Total Quantity: %d", 10, 0
	outputTotalValue:	db "Total Value: %lf", 10, 0
	outputTotalCost:	db "Total Cost: %lf", 10, 0

	intFormat:	db "%d", 0
	fltFormat:	db "%lf", 0
	strFormat:	db "%s", 0
	test:		dq  127.012

segment .bss
	head:		resq 1	;points to head of the linked list
	lastNode:	resq 1  ;points to last node to make insertions quickier
	
	intInput:	resd 1
	fltInput:	resq 1
	strInput:	resb MAX_BUFFER
	
	totalQuantity:	resd 1
	totalValue:	resq 1
	totalCost:	resq 1
	
	tempValue:	resq 1
	tempCost:	resq 1

segment	.text
	global asm_main
	extern fscanf, printf, scanf, calloc, free, strncpy, strnlen

asm_main:
	enter	8, 0
	
	;;init totals
	mov	[totalQuantity], dword 0

	mov	[totalValue], dword 0
	mov	[totalValue +4], dword 0
	
	mov	[totalCost], dword 0
	mov	[totalCost +4], dword 0

	;;get input
	call	getInput

	;;move pointer to linked lists head to rdi 
	mov	rdi, rax

	call	printLinkedList
	mov	rax, 0
	leave
	ret

;;Gets the input and returns a pointer to the head
;;RETURN VALS
;;RAX - Pointer to head of linked list
getInput:
	enter	8, 0
	
	;;r12 will be used to reference the lastNode
	;;r13 holds the head
	;;r14 points the previous node, if this is the head it points to the head
	xor	r12, r12
	xor	r13, r13

        mov     r12b, BYTE empty  ;tells the program no nodes have been created yet
inputLoop:
        ;;create the head
        cmp     r12, BYTE empty
        jne     newNode

        ;;allocate space for head of the linked list
        mov     rdi, 1
        mov     rsi, ll.size
        call    calloc
	
        ;;move head and last node 
        mov     r13, rax             ;make head point to this new node
        mov     r12, rax         ;make lastNode point to this newly created node
	mov	r14, r12	 ;r14 points to lastNode for start of the linked list
        jmp     fillNode

newNode:
        ;;allocate space
        mov     rdi, 1
        mov     rsi, ll.size
        call    calloc

        ;;move lastNode
        mov     r14, r12	;r14 points to the previous node
        mov     [r14 + ll.ptr], rax
        mov     r12, rax
        jmp     fillNode

fillNode:
        ;;at this point lastNode contains the pointer to the most recent node in the linked list
        ;;as such any element can be accessed by this logic
        ;;      [ [lastNode] + ll.[element] ]

        ;;product ID
        mov     rdi, promptID
        call    printf

        mov     rdi, intFormat
        mov     rsi, intInput
        call    scanf

	;;check eof
	cmp	eax, EOF
	jne	notEnd
	xor	r8, r8
	mov	[r14 + ll.ptr], r8	;clears the pointer, at this point r14 holds the previous node
	jmp	endInput

notEnd:
        ;;move the value into the structs location
        mov     rax, [intInput]
        mov     [r12 + ll.pID], eax

	;;prouct name
	mov	rdi, promptNF
	call	printf
	
	;;get name
	mov	rdi, strFormat
	mov	rsi, strInput
	call	scanf

	;;get strln and add one for eol
	mov	rdi, strInput
	mov	rsi, MAX_BUFFER
	call	strnlen
	inc	rax
	mov	r15, rax

	;;allocate memory for string
	mov	rdi, rax
	mov	rsi, 1;
	call 	calloc

	;;copy string to nodes location
	mov	[r12 + ll.nameF], rax
	mov	rdi, rax
	mov	rsi, strInput
	mov	rdx, r15
	call	strncpy

	;;product price
	mov	rdi, promptPrice
	call	printf
	
	;;after scanf return value should be in xmm0
	mov	rax, 1		;idk if I need to specify 1 return value?
	mov	rdi, fltFormat
	mov	rsi, fltInput
	call	scanf

	;;store double
	movq	[r12 + ll.price], xmm0

	;;store double in tempValue
	movq	[tempValue], xmm0

	;;product cost
	mov	rdi, promptCost
	call	printf

	mov	rdi, fltFormat
	mov	rsi, fltInput
	call	scanf

	;;store double
	movq	[r12 + ll.cost], xmm0

	;;store double in tempCost
	movq	[tempCost], xmm0

	;;product quantity
	mov	rdi, promptQuantity
	call	printf

	xor	rax, rax
	mov	rdi, intFormat
	mov	rsi, intInput
	call	scanf

	;;move the value into structs location
	mov	rax, [intInput]
	mov	[r12 + ll.quantity], eax
	
	;;add value tot totalQuantity
	mov	r15, rax	;holds the quantity
	add 	eax, [totalQuantity]
	mov	[totalQuantity], eax

	;;calculate new totalCost
	cvtsi2sd	xmm1, r15d	;restores quantity to xmm1, cvtsi2sd uses dword so this uses r15d
	movsd	xmm0, qword [tempCost]
	mulsd	xmm0, xmm1
	movsd	xmm2, qword [totalCost]
	addsd	xmm0, xmm2
	movsd	[totalCost], xmm0

	;;calculate new totalValue
	cvtsi2sd xmm1, r15d	;restore quantity to xmm1
	movsd	xmm0, qword [tempValue] 
	mulsd	xmm0, xmm1
	movsd	xmm2, qword [totalValue]
	addsd	xmm0, xmm2
	movsd	[totalValue], xmm0

	;;put newline
	mov	rdi, newLine
       	call	printf

	jmp     inputLoop

endInput:
	;;give return vals
	mov	rax, r13
	leave
	ret



;;Prints the contents of the linked list
;;RDI - the pointer to the head of the linked list
;;Returns void
printLinkedList:
	enter	8,0
        
	mov     r12, rdi     ;;r12 will point to the node
outputLoop:
	push	rcx
	push 	rsi

	;;skip if head is null
	cmp	r12, NULL
	je	endOutputLoop

        ;;output nodes information
        mov     rdi, outputID
        mov     eax, [r12 + ll.pID]
        mov     rsi, rax
        call    printf

	mov	rdi, outputNF
	mov	rax, [r12 + ll.nameF]
	mov	rsi, rax
	call	printf

	mov	rdi, outputPrice
	movsd	xmm0, [r12 + ll.price]
	mov	rax, 1
	call	printf
	
	mov	rdi, outputCost
	movsd	xmm0, [r12 + ll.cost]
	mov	rax, 1
	call	printf

	mov	rdi, outputQuantity
	mov	eax, [r12 + ll.quantity]
	mov	rsi, rax
	call	printf

	mov	rdi, newLine
	call	printf

        ;;move to next node
        mov     r12, [r12 + ll.ptr]

	pop	rsi
	pop	rcx

	cmp	r12, NULL
        jne     outputLoop

endOutputLoop:
	xor	rsi, rsi
	xor	r10, r10

	;;output total information
	mov     rdi, outputTotalQuantity
        mov     esi, dword [totalQuantity]
        call    printf

        mov     rdi, outputTotalValue
	mov	rax, 1
        movsd   xmm0, qword [totalValue]
        call    printf

        mov     rdi, outputTotalCost
        mov	rax, 1
	movsd     xmm0, qword [totalCost]
        call    printf

	leave
	ret
