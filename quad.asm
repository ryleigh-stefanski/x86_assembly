segment .data
	mesg:		db	"Enter a value: ",0
	mesgBad:	db	"Please enter a value in the range 0-360", 10, 0
	mesgQuad4:	db	"Value is in: IV",10,0
	mesgQuad3:	db	"Value is in: III",10,0
	mesgQuad2:	db	"Value is in: II",10,0
	mesgQuad1:	db	"Value is in: I",10,0
	mesgAxis:	db	"Value is an axis",10,0
	intOutput:	db	"%d: ",0
	intInput:	db	"%d", 0
segment .bss
	input1:		resd	1

segment .text
	global asm_main
	extern printf, scanf

asm_main:
	enter	0,0
eventLoop:
	xor	rax, rax
	
	;;print prompt
	mov	rdi, mesg
	call	printf
	
	;;get user input
	mov	rdi, intInput
	mov	rsi, input1
	call	scanf
	

	;;check if greater than 360
	mov	rax, [input1]
	cmp	rax, 360
	jg	badInput
	
	;;check if less than 0
	cmp	rax, 0
	jl	badInput

	;;check if the value is on an axis
	cmp	rax, 360
	jz	axis

	cmp	rax, 270
	jz	axis

	cmp	rax, 180
	jz	axis

	cmp	rax, 90
	jz	axis
	
	;;check zero
	cmp	rax, 0
	jz	axis

	;;prepare for checking quadrant
	mov	r8, 90 
	div	r8	 ;divide by 90 as each quadrant is 90
	;;MATH LOGIC
	;;Since we checked for 360 in the axis check above, rax cannot be 360 or above
	;;As such the max value we can have is 359/90 or 3.98
	;;3 will be stored in ax, and the remainder in dx. We do not care about the
	;;remainder. The low bound we can have is 1, since above we checked for <= 0
	;;1/90 = .01111... or 0
	;;As such our ranges are the following:
	;;	3 = [271, 359]
	;;	2 = [181, 269]
	;;	1 = [91, 179]
	;;	0 = [1, 89]
	;;If we compare ax with these numbers the ge flag will be set if the rax
	;;value is in that respective quadrant(0-3). 
	;;Note: Since we checked for axis points above we need not care about them,
	;;as such the ge flag being used will cause no problems.

	;;check if quad4
	cmp	ax, 3
	je	quad4
	
	;;check quad 3
	cmp	ax, 2
	je	quad3

	;;check quad 2
	cmp	ax, 1
	je	quad2

	;;it is quad 1 if none other
	jmp	quad1

badInput:
	mov	rdi, mesgBad
	call	printf
	jmp	end

quad4:
	mov	rdi, mesgQuad4
	call	printf
	jmp	eventLoop

quad3:
	mov	rdi, mesgQuad3
	call	printf
	jmp	eventLoop

quad2:
	mov	rdi, mesgQuad2
	call	printf
	jmp	eventLoop

quad1:
	mov	rdi, mesgQuad1
	call	printf
	jmp eventLoop
axis:
	mov	rdi, mesgAxis
	call	printf
	jmp	eventLoop
end:
	leave
	ret
