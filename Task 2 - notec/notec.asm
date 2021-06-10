extern debug

section .data

	; these two defines describe values we need to subtract in order to get proper hex value.
	HEXLETTERBIG equ 55 ;for capital letters.
	HEXLETTERSMALL equ 87 ;for normal letters.
		
section .bss

	;threadwait is used as a table that every thread sees and can modify.
	;threadwait under index i stores the number of thread that thread i is waiting for.
	;if thread is not waiting for anyone, threadwait will hold N in its memory, because
	;N is the smallest number that doesn't associate with an other thread number.
	threadwait resq N

	;threadexch is a market for all the threads. when a thread wants to exchange, it
	;puts his number + 1 in memory under his index. then, the second thread, 
	;called "the exchanger", takes the number from partner's memory space, and also puts his number 
	;in the partner's memory space. after the exchanger is done, it unlocks the partner, which can 	
	;safely take his part of the deal, which is waiting under his memory address.
	;threads put their numbers incremented, because 0 is treated as the end of exchange. It
	;couldn't be any other number, as threadexch must be declared in bss.
	threadexch resq N
	
	spinlock resd 1 ;0 stands for open lock, 1 for a closed one.

section .text
	global notec

;in notec function rdi stores thread number, rsi expression to analyze,
;r12 stores address to threadwait and r13 stores address to threadexch.
;r14 and r15 stores rdi and rsi value for time when rdi and rsi are needed as debug arguments.
;those 6 registers are therefore occupied and are solely used for what I described above.
align 8
notec:
	push	rbp ;save rbp, r12, r13, r14 and r15 value.
	push	r12
	push	r13
	push	r14
	push	r15
	mov	rbp, rsp ;save the original stack pointer.
	xor	r9, r9 ;signalizes if we are in input mode.
	xor	r10, r10 ;used in storing unpushed numeric value.
	mov	r12, threadwait
	mov	r13, threadexch

;loops through the expression in rsi	
_exprloop:	
	mov	r8b, byte [rsi]; move one sign of input to r8b.
	cmp	r8b, 0 ;if we read 0, it means that expression ended.
	je	_endfunc
	inc	rsi ;move on to next char.
	jmp	signswitch
	
;---------------------------------------------;
	
;signswitch section is responsible for determining if we are leaving or entering input mode,
;by comparing value stored in r8b with ascii values of border chars.
signswitch:

	cmp	r8b, '0' ;ascii range from 0 to '0' - 1.
	jb	_endofinput
	cmp	r8b, '9' ;ascii range from '0' to '9'.
	jbe	_inputnum
	cmp	r8b, 'A' ;ascii range from '9' + 1 to 'A' - 1.
	jb	_endofinput
	cmp	r8b, 'F' ;ascii range from 'A' to 'F'.
	jbe	_inputletb
	cmp	r8b, 'a' ;ascii range from 'A' + 1 to 'a' - 1.
	jb	_endofinput
	cmp	r8b, 'f' ;ascii range from 'a' to 'f'.
	jbe	_inputlets
	jmp	_endofinput ;rest of ascii.

;---------------------------------------------;

;these 4 sections are used if char stored in r8b represents a number in hexadecimal system.
;first 3 sections convert char's ascii value to a proper hex value.
_inputnum:
	
	sub	r8b, '0'
	jmp	_input

;input letter was capital.
_inputletb:

	sub	r8b, HEXLETTERBIG
	jmp	_input
		
;input letter was normal.
_inputlets:
	
	sub	r8b, HEXLETTERSMALL
	
	
;last section adds the converted value to current result stored in r10.
_input:

	shl	r10, 4 ;we have to multiply current result by 16, as we need to add the next digit.
	add	r10b, r8b
	mov	r9, 1 ;we also change the r9 flag to true, which indicates we are in inputmode.
	jmp	_exprloop
	
;---------------------------------------------;	

;this section checks if we were in input mode, and if we were, pushes value stored in r10 on stack.
_endofinput:	
	cmp 	r9, 0 ;if we weren't in the input mode previously, skip reseting.
	je	operationswitch
	push	r10
	xor	r9, r9 ;reset flag.
	xor	r10, r10 ;and buff for value.
	jmp	operationswitch
	
;---------------------------------------------;

;same as sign switch, but only consider non hex value chars. Find the appropiate sign using binsearch.
operationswitch:
	
	cmp	r8b, 'X'
	jbe	_lowerhalf
	cmp	r8b, 'g'
	jae	_higherquar
	cmp	r8b, 'Y' ;lower quarter of higer half.
	je	doubler
	cmp	r8b, 'Z'
	je	deleter
	jmp	bitxor ; '^' sign.
	
_lowerhalf:
	cmp	r8b, '-'
	jbe	_lowerquar
	cmp	r8b, 'W'
	jae	_lohihioct
	cmp	r8b, 'N' ;higher quarter of lower half ;lohilo oct.
	je	threadscount
	jmp 	_exprloop ; '=' sign, dont need to do anythin as we already pushed hex number on stack.
	
_lohihioct:
	cmp	r8b, 'X'
	je	swapper
	jmp	concur ; 'W' sign.
	
_lowerquar:
	cmp	r8b, '*'
	jbe	_loweroct
	cmp	r8b, '+' ;higher oct of lower quarter.
	je	addit
	jmp	arineg ; '-' sign.
	
_loweroct:
	cmp	r8b, '&'
	je	bitand
	jmp	multi ; '*' sign.
	
_higherquar:
	cmp	r8b, '|'
	jae	_higheroct
	cmp	r8b, 'n' ;lower oct of higher quarter.
	je	threadnum
	jmp	godebug ; 'g' sign.
	
_higheroct:
	cmp	r8b, '~'
	je	logneg
	jmp	bitor ; '|' sign.
	
;---------------------------------------------;

;all of the operator functions are in this section. after completion all of them come back to _exprloop.

;bit and of two values on top of stack '&'.
bitand:
	pop	rdx
	and	[rsp], rdx
	jmp	_exprloop
	 
;multiplication of two values on top of stack '*'.
multi:
	pop	rcx
	pop	rax
	mul	rcx
	push	rax
	jmp	_exprloop

;addition of two values on top of stack '+'.
addit:
	pop 	rdx
	add 	[rsp], rdx
	jmp	_exprloop
	 
;arithmetic negation of value on top of stack '-'.
arineg:
	not	QWORD [rsp]
	inc	QWORD [rsp]
	jmp	_exprloop

;push number of notec instances to stack 'N'.
threadscount:
	push 	N
	jmp	_exprloop

;concurrency between two notec, with swapping of their top stack 'W'.
concur:
	mov	rdx, spinlock
	mov	ecx, 1 ;closed lock.
	
_busylockwait:
	xor	eax, eax ;opened lock.
	lock \
	cmpxchg [rdx], ecx ;close the lock if it was open.
	jne	_busylockwait ;jump to busy wait if it was closed.
	pop	rcx ;store the value of notec we want to exchange with.
	cmp	rcx, N
	jae	_exprloop ;we dont really care what happens when value in 
			   ;rcx doesnt represent notec instance.
	inc	rdi ;as said in threadexch description, thread put their incremented by one number.
	cmp	rdi, [r12 + 8 * rcx] ;check if notec numbered rcx waits for us.
	je	_exchange ;if yes, we can exchange.
	
	;else we have to wait for exchange partner.
	dec	rdi ;recover your number.
	inc	rcx ;same as with rdi.
	mov	[r12 + 8 * rdi], rcx ;we have to manifest that we are waiting for notec rcx.
	dec	rcx
	pop	r8 ;pop the stack, get the number to be exchanged.
	mov	[r13 + 8 * rdi], r8 ;put your top stack on exchange market.
	mov	DWORD [rdx], 0; we can unlock the lock, as now we will only wait for answer from now on.

;active waiting for answer from specific thread.
_waitexch:
	mov	r8, [r12 + 8 * rdi]
	cmp	r8, 0 ;we can only leave if someone changed our threadwait qword to 0
			;which indicates end of exchange.
	je	_endofexch
	jmp	_waitexch

;our new value awaits in threadexch under our address.
_endofexch:
	mov	r8, [r13 + 8 * rdi]
	push	r8 ;push the exchanged value on your stack.
	jmp	_exprloop ;end of exchange.

;we are the exchanger, as our transaction partner already waits for us.
_exchange:
	mov	DWORD [rdx], 0 ;unlock all other threads waiting on lock.
	dec	rdi ;recover your previous rdi value
	pop	r8 ;get the number to be exchanged.
	mov	rax, [r13 + 8 * rcx] ;get the exchange number of awaiting thread rcx.
	mov	[r13 + 8 * rcx], r8 ;put your exchange number to partner's buffer space.
	mov	QWORD [r12 + 8 * rcx], 0 ;unlock partner thread, as the transaction is complete.
	
	push 	rax
	jmp	_exprloop

;swapping of two values on top of stack 'X'.
swapper:
	pop	rdx
	pop	rcx
	push	rdx
	push	rcx
	jmp	_exprloop
	
;pushing the top of the stack 'Y'.
doubler:
	pop	rdx
	push	rdx
	push 	rdx
	jmp	_exprloop

;popping stack 'Z'.
deleter:
	pop	rdx
	jmp	_exprloop

;bit xor of two values on top of stack '^'.	
bitxor:
	pop	rdx
	xor	[rsp], rdx
	jmp	_exprloop

;call of external debug function, which may result in stack change 'g'.
godebug:
	mov	rax, rsp
	xor	rdx, rdx
	mov	r8, 16
	div	r8
	mov	r14, rsi ;use r14 as buffer for our rsi, so that rsi can become argument.
	mov	r15, rdi ;use r15 as buffer for our rdi, so that rdi can become argument.
	mov	rsi, rsp ;rsi is used as argument of debug function.
	cmp	rdx, 0
	jne	_unalign
	call	debug
	jmp	_debugreset
_unalign:
	sub	rsp, 8
	call	debug
	add	rsp, 8
_debugreset:
	mov	rsi, r14
	xor	r9, r9 ;reset r9 and r10 registers in case debug changed them.
	xor	r10, r10
	mov	rdi, r15
	mov	r8, 8 ;move stack by appropiate amount specified in rax.
	mul	r8
	add	rsp, rax
	jmp	_exprloop
	
;push your identity number on top of stack 'n'.
threadnum:
	push	rdi
	jmp	_exprloop

;bit or of two values on top of stack '|'.
bitor:
	pop 	rdx
	or	[rsp], rdx
	jmp	_exprloop

;logical negation of value on top of the stack '~'.
logneg:
	not	QWORD [rsp]
	jmp	_exprloop


;---------------------------------------------;

_endfunc:
	cmp	r9, 0 ;if last instruction we processed was a hex number, save it on stack.
	je 	_return ;else just move on without adding anything.
	push 	r10
	
_return:
	pop	rax ;save the result of function in rax.
	mov	rsp, rbp ;restore the stack balance.
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	rbp ;restore r12, r13, r14, r15, rbp values.
	ret
