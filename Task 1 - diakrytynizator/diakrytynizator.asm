section .data
	; These defines are used in validation of char.
	VALIDCHARLIMIT equ 0x10FFFF
	NOCHANGELIMIT equ 0x7F
	VALIDERROR equ 2
	VALIDCHANGE equ 1
	VALIDIGNORE equ 0
	
	; These defines describe maximal unicode value char can have in order to fit
	; inside that many bytes in utf-8.
	UNIONEBYTE equ 0x7F
	UNITWOBYTE equ 0x7FF
	UNITHREEBYTE equ 0xFFFF
	
	; These defines are for clearer system calls.
	SYSREAD equ 0
	SYSWRITE equ 1
	EXIT equ 60
	STDIN equ 0
	STDOUT equ 1
	
	; These four defines describe maximal values that first byte of charachter
	; can have in order to have specified byte length.
	ONEBYTELEN equ 127
	TWOBYTELEN equ 223
	THREEBYTELEN equ 239
	FOURBYTELEN equ 247
	
	; Other.
	SHIFT equ 6
	DIAKRYSHIFT equ 128
	MODULO equ 0x10FF80

section .bss
	onebuff:	resb 1
	readbuff:	resb 4096
	wrtbuff:	resb 4096

section .text
	global _start

;rbp and rsp are considered stack pointers in this program, thus they are not manually modified.
_start:
	mov 	rbp, rsp ;save the pointer to original stack.
	call 	checkParam
	xor	r13, r13 ;r13 will be used to monitor number of bytes written in wrtbuff
_wordloop:
	call 	readChar
	mov 	rdi, rax ;write results of readChar to arguments.
	mov 	rsi, rdx ;these will be used by next functions.
	
	call 	validateChar
	cmp 	rax, VALIDIGNORE ;if VALIDIGNORE was returned, write char stored in buff.
	je 	_writing
	
	;else given char has to be changed
	sub	rdi, DIAKRYSHIFT ;w(x - 0x80) + 0x80 task specification.
	call 	diakry
	add 	rax, DIAKRYSHIFT
	mov 	rdi, rax
	call 	determineLen ;determine length of calculated unicode value in utf-8 bytes.
	mov 	rsi, rax ;mov the result length to rsi.
	call 	changeToUTF
	mov	rdi, rax

_writing:
	call 	writeChar
	jmp 	_wordloop
	
;-----------------------------------------;

;checks if there is at least one cmd line argument and checks if all of them are ints
;checkParam does not have any local arguments. It also doesn't return anything. If
;error is found, it jumps straight to error exit. checkParam modifies r8 and r9 and stack args.
checkParam:

	mov 	r8, [rbp]
	cmp 	r8, 1 ;if no arguments were passed (argc = 1) exit witch code 1.
	je 	_errorexit
	mov 	r9, 1 ;loop counter.
	dec 	r8 ;decrement arguments count to ignore program call argument.
	
_paramloop:
		
	mov 	rdi, [rbp + 8 + 8 * r9] ;rbp + 8 is pointing to program call, r9 stands for
				     ;argument that is currently processed.
	call 	toInteger
	mov 	[rbp + 8 + 8 * r9], rax ;switch string argument to integer argument on stack.
	cmp 	r8, r9 ;if r8 is equal to r9 than we have considered every given argument.
	je 	_paramend
	inc 	r9
	jmp 	_paramloop
	
_paramend:

	ret

;-----------------------------------------;

;converts string to integer. If any char is non numeric, exits program with code 1.
;toInteger needs one argument (string to convert) in rdi. It returns the result int in rax.
;toInteger modifies rax, rdi and r10.
toInteger:

	xor 	rax, rax

_intloop:

	movzx	r10, byte [rdi] ; get one char from rdi string.
	cmp 	r10, 0 ;0 means end of string argument, conversion is complete.
	je 	_tointend
	inc 	rdi
	cmp 	r10, '0' ;if char is below '0' in ascii, it's not valid (expecting digit).
			  
	jb 	_errorexit
	cmp 	r10, '9' ;if char is above '9' in ascii, it's not valid (expecting digit).
	ja 	_errorexit
	sub 	r10, '0' ;change char to digit.
	imul 	rax, 10 ;multiply previous stored value by 10, as we need to add 
		         ;newly conversed digit.
	add 	rax, r10
	jmp 	_intloop
	
_tointend:

	mov	r11, MODULO
	xor	rdx, rdx
	div	r11 ;modulo the arguments, so they dont get to big (it won't affect diakry anyway)
	mov	rax, rdx
	ret
		
;-----------------------------------------;

;read one charachter, determine its length by the first byte value and unicode value.
;readChar doesn't need any arguments. It returns read char in rax and its utf-8 byte length in rdx.
;readChar modifies: rax, rdi, rsi, rdx, rcx (cl), r8, r10, r9.
readChar:
	
	cmp	r14, r15
	jne	_readcont ;skip filling buffer if we have'nt read all the chars
	call	fillBuff
		
_readcont:
	;determining number of bytes that build one char.
	xor	r8, r8
	xor	r11, r11
	xor 	rax, rax
	mov 	r11b, [readbuff + r14] ;save read input to cl in order to check char length.
	inc	r14
	mov 	r8b, r11b ;also save it to r8b in case the char is only one byte long.
	cmp 	r11b, ONEBYTELEN
	jbe 	_readend
	
	mov	al, r11b ;used for extracting bits used in unicode value of char.
	mov 	cl, 3
	mov 	r10, 1	;number of loops to be made.
	xor	r9, r9 ;loop counter.
	xor 	r8, r8 ;for holding the unicode value of char.
	cmp 	r11b, TWOBYTELEN
	jbe	_shiftfirstbyte
	
	inc	cl
	inc	r10
	cmp 	r11b, THREEBYTELEN
	jbe	_shiftfirstbyte
	
	inc 	cl
	inc 	r10
	cmp	r11b, FOURBYTELEN
	jbe	_shiftfirstbyte
	jmp 	_errorexit ;jmp to error exit if larger number of bytes was detected.
	
_shiftfirstbyte:
	shl	al, cl
	shr	al, cl
	
_readloop:
	
	add	r8, rax ;hold the current result in r8 so al can shift its digits.
	shl	r8, SHIFT ;make space for next set of digits.
	xor	rax, rax ;we need free space in rax.
	cmp	r14, r15 ;if the buffer is already fully read, go to single byte reading mode 
	je	_readNormal
	mov	al, [readbuff + r14] ;mov the r14'th readbuff byte to al
	inc	r14 ;increment tha amount of bytes we've read
	
_readloopcont:

	shl	al, 2 ;two leftmost bytes must be ignoread.
	shr	al, 2 ;return bits to original places.	
	inc 	r9
	cmp	r10, r9 ;leave the loop if we've read all bytes.
	je	_readend
	jmp	_readloop
	
_readend:

	mov	rdx, 1	;length of the char in bytes used later in validation.
	add	rdx, r10
	add	rax, r8 ;add the previously calculated unicode values.
	ret

;-----------------------------------------;
;This section is for sysreading input only

;readChar jumps here if his wrtbuff is already read and char it currently reads didn't end yet.
;here we are just reading one byte so we can complete the char and move on.
_readNormal:

	;sysread config
	mov	rax, SYSREAD
	mov	rdi, STDIN
	mov	rsi, onebuff
	mov	rdx, 1
	syscall
	
	cmp	rax, 0 ;we definetly should not except end of input here, as we are 
			;in the middle of reading a char.
	je	_errorexit
	mov	al, [onebuff] ;move the result to al.
	jmp	_readloopcont ;jmp back to readChar.

;fillBuff is responsible for filling the readbuff with chars. It will maximally fill
;4096 bytes. fillBuff saves the length of read bytes in r15, so we can easily monitor how
;many bytes we have left to read from. this function modifies rax, rdi, rsi, rdx, r15, r14.
fillBuff:
	
	;sysread config
	mov	rax, SYSREAD
	mov	rdi, STDIN
	mov	rsi, readbuff
	mov	rdx, 4096
	syscall
	
	cmp	rax, 0 ;if no bytes were read, we now it's the end of the input.
	je	_normexit ;so we can exit program normally without error.
	mov	r15, rax ;mov the amount of read chars to r15
	xor	r14, r14 ;put 0 to r14, which will represent the number of bytes already read from readbuff

	ret

;-----------------------------------------;

;Checks what should be done with char stored in rdi.
;validateChar needs two arguments: rdi (char unicode value) and rsi (bytes it took to read it)
;validateChar returns numeric value of what to do next, in rax.
;this function only modifies rax.
validateChar:

	mov 	rax, VALIDCHANGE ;assume char needs to be changed.

	cmp 	rsi, 2
	je	_twobytesvalidation
	cmp	rsi, 3
	je 	_threebytesvalidation
	cmp 	rsi, 4
	je	_fourbytesvalidation
	
	mov	rax, VALIDIGNORE ;if non cmp jumped, it means we are considering one byte char,
				  ;which we dont have to change by diakry.
	jmp 	_endvalid
	
;Check if unicode value wrritten on 2 bytes could be represented by 1 byte.
_twobytesvalidation:

	cmp	rdi, UNIONEBYTE
	jbe	_errorexit
	jmp 	_endvalid ;2 byte char definetly won't suprass char limit of 0x10FFFF.
	
;Check if unicode value written on 3 bytes could be represented by 1 or 2 bytes.
_threebytesvalidation:

	cmp 	rdi, UNITWOBYTE
	jbe	_errorexit
	jmp 	_endvalid ;3 byte char definetly won't suprass char limit of 0x10FFFF.
	
;Check if unicode value written on 4 bytes could be represented by 1, 2 or 3 bytes.
_fourbytesvalidation:

	cmp 	rdi, UNITHREEBYTE
	jbe	_errorexit
	cmp	rdi, VALIDCHARLIMIT ;only 4 byte chars can surpass our limit.
	ja	_errorexit
	jmp 	_endvalid
	
;End validation process.
_endvalid:

	ret

;-----------------------------------------;

;function that changes given char value to other using "diakrytynizator".
;diakry needs one argument, rdi (char unicode value). Result of diakry is stored in rax.
;diakry modifies rax, r8, rcx, r10, r9, rsi, rdx.
diakry:

	mov 	r8, [rbp] ;value of argc.
	dec 	r8 ;decrement arguments count to ignore program call argument.
	xor 	rcx, rcx ;result of diakry function.
	mov 	r10, 0 ;loop counter.
	mov	r9, MODULO
	mov	rax, 1 ;at the beggining power value is equal to one.
	mov 	rsi, 1 ;stores current power value.
	
_diakryloop:
	
	mul 	QWORD [rbp + 8 + 8 * (r10 + 1)] ;multiply rax by the argument value, argument value 
						 ;is stored n+1 bytes away from rbp, which
						 ;represents the stack pointer at the beginning of program.
	xor 	rdx, rdx
	div	r9 ;modulo the result
	mov	rax, rdx ;remainder is saved in rdx.
	add 	rax, rcx ;add previous calculations.
	xor 	rdx, rdx
	div 	r9 ;modulo.
	mov	rax, rdx ;remainder.
	mov	rcx, rax ;save the result.
	inc 	r10
	cmp 	r10, r8 ;leave if all arguments have been considered.
	je 	_diakryend
	
	;power calculation
	mov	rax, rsi
	mul	rdi ;multiply previous power by char's unicode value.
	div	r9
	mov	rax, rdx ;remainder stored in rdx.
	mov	rsi, rax
	
	jmp 	_diakryloop
	
_diakryend:

	mov 	rax, rcx
	ret
	
;-----------------------------------------;

;determines length of char produced by diakry, mostly for writing purposes.
;length is represented by bytes it takes to write char in utf-8.
;determineLen needs one argument, rdi (unicode char value). Result is stored in rax.
;only rax register is modified in this function.
determineLen:
	
	mov 	rax, 2 ;it needs to be at least 2 bytes long, as if it was only one 
			;it wouldnt end up here (its after diakry function).
	cmp 	rdi, UNITWOBYTE ;largest value 2 byte unicode can have.
	jbe	_determineend
	inc	rax ;increment the result as we know the number is bigger.
	cmp	rdi, UNITHREEBYTE ;largest value 3 byte unicode can have.
	jbe 	_determineend
	inc 	rax
	jmp 	_determineend
	
_determineend:
	
	ret
	
;-----------------------------------------;

;changes unicode value stored in rdi to utf-8 value for write purposes.
;changeToUTF needs 2 arguments, rdi (unicode char value) and rsi (number of bytes it takes to write rdi).
;changeToUTF result is stored inside rax. 
;This function modifies: r8, rax, rdx, rdi, r9, r10 (r10b) and r11.
changeToUTF:

	xor 	r8, r8
	xor 	rax, rax
	mov	rdx, 2 ;loop counter
	
_utfloop:

	mov 	r8b, dil ;move the 8 least significant bits.
			 ;in order to change this sequence to utf.
	shl	r8b, 2	;changing from unicode to utf.
	shr	r8b, 2
	add	r8b, 128 ;making the byte have an utf form of 10xxxxxx, 
			 ;where x are bits r8b value.
	mov 	r9, rdx ;loop counter.
	sub	r9, 2; make the counter show number of bytes we need to shift.
	
; Used to monitor number of byte shifts we need to perform before adding to result.
_shiftloop:

	cmp	r9, 0 ;leave if there is no byte to be shifted.
	je	_shiftend	
	shl 	r8, 8
	dec	r9
	jmp 	_shiftloop

;end of shifting the byte, add the result and move on.	
_shiftend:

	add	rax, r8 ;add result of byte to result.
	xor 	r8, r8 ;reset r8 register value.
	cmp	rsi, rdx ;if char was rdx byte long, proceed to fixing last byte.
	je	_lastbytefix
	inc	rdx
	shr	rdi, 6 ;shift rdi by 6 places, as we already considered those bits.
	jmp 	_utfloop

;determine the amount of bytes we need to fix and proceed accordingly.	
_lastbytefix:

	shr	rdi, 6 ;perform last shift.
	mov 	r8b, dil
	mov 	cl, 3 ;we need to shift that many significant bits.
	mov	r10b, 192 ;after the shift, we need to add this value to get first byte utf value.
	cmp	rsi, 2
	je	_endfix
	inc 	cl
	mov	r10b, 224 ;as number of bytes changes, so does the shift value and addition value.
	cmp	rsi, 3
	je	_endfix
	inc	cl
	mov	r10b, 240
	cmp	rsi, 4
	je 	_endfix
	
_endfix:
	
	shl	r8b, cl ;clear cl most significatnt bits.
	shr	r8b, cl
	add	r8b, r10b
	mov	r10b, 8 ;used later in multiplication.
	
	;adjust cl to represent number of bits we've already wrote to.
	mov 	r11, rax ;temporarily store the value in r11.
	mov	al, cl
	sub 	al, 2
	mul 	r10b
	mov 	cl, al
	shl	r8, cl ;its used in order to determine the last shift value.
	mov	rax, r11
	add 	rax, r8 ;add to result.
	ret

;-----------------------------------------;


;writes char stored in rdi of length stored in rsi.
;writeChar needs 2 arguments: rdi (char in utf-8) and rsi (number of bytes it takes to write rdi)
;writeChat does not return any values. This function modifies: r8, r10, rax, rdx, rsi, rdi
;and memory under wrtbuff address.
writeChar:

	mov	r8, rdi ;represents the char to be written.
	mov	r9, r13 ;offset created by existing chars in wrtbuff
	mov 	r10, rsi ;loop counter (number of bytes to write).
	dec	r10

;used to build proper output in wrtbuff, as wrtbuff content needs to be flipped.
_writeloop:
	mov 	[wrtbuff + r9 + r10], r8b ;write last 8 bits to last byte of wrtbuff of length rsi.
	inc	r13 ;monitor number of bytes in wrtbuff
	cmp	r10, 0 ;if that was the last byte to be written, leave.
	je	_writeend
	dec	r10
	shr 	r8, 8 ;get rid of last 8 bits and place next byte there.
	jmp 	_writeloop
	
_writeend:
	cmp	r13, 4092
	jbe	_skipwrite
	
	;syswrite config
	mov 	rax, SYSWRITE
	mov 	rdx, r13
	mov	rsi, wrtbuff
	mov 	rdi, STDOUT
	syscall
	xor	r13, r13
	
_skipwrite:
	ret

;-----------------------------------------;

;;Those two jumps are exits, they modify rax rdi, rsi and rdx don't need args and doesn't return anything.
	
;Exit with code 0.
_normexit:

	;wrtie remaining bytes stored in wrtbuff
	mov 	rax, SYSWRITE
	mov 	rdx, r13
	mov	rsi, wrtbuff
	mov 	rdi, STDOUT
	syscall

	mov 	rax, EXIT
	mov 	rdi, 0
	syscall

;Exit with code 1.
_errorexit:
	
	;write remaining bytes stored in wrtbuff
	mov 	rax, SYSWRITE
	mov 	rdx, r13
	mov	rsi, wrtbuff
	mov 	rdi, STDOUT
	syscall

	mov 	rax, EXIT
	mov 	rdi, 1
	syscall
