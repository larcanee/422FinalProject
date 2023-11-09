		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _bzero( void *s, int n )
; Parameters
;	s 		- pointer to the memory location to zero-initialize
;	n		- a number of bytes to zero-initialize
; Return value
;   none
		EXPORT	_bzero
_bzero
		; r0 = s
		; r1 = n 
		
		PUSH {R1-R12, LR}
		MOV R2, #0					; r2 = 0
b_loop	
		CMP R1, #0					; check for end of string
		BEQ end_b_loop
		SUBS R1, R1, #1				; decrement n
		STRB R2, [R0], #1			; replace current byte w/ 0
		B b_loop
end_b_loop
		POP {R1-R12, LR}
		BX LR




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; char* _strncpy( char* dest, char* src, int size )
; Parameters
;   dest 	- pointer to the buffer to copy to
;	src		- pointer to the zero-terminated string to copy from
;	size	- a total of n bytes
; Return value
;   dest
		EXPORT	_strncpy
_strncpy
		; r0 = dest
		; r1 = src
		; r2 = size (n)
		; r4 = src[i]
		PUSH {R1-R12, LR}
s_loop	
		CMP R2, #0					; check for end of string
		BEQ end_s_loop
		SUBS R2, R2, #1				; decrement n
		LDRB R4, [R1], #1			; load byte from src
		STRB R4, [R0], #1			; store byte in dest
		B s_loop
end_s_loop
		POP {R1-R12, LR}
		BX LR
				
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		END			
