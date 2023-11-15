		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
HEAP_TOP	EQU		0x20001000
HEAP_BOT	EQU		0x20004FE0
MAX_SIZE	EQU		0x00004000		; 16KB = 2^14
MIN_SIZE	EQU		0x00000020		; 32B  = 2^5
	
MCB_TOP		EQU		0x20006800      ; 2^10B = 1K Space
MCB_BOT		EQU		0x20006BFE
MCB_ENT_SZ	EQU		0x00000002		; 2B per entry
MCB_TOTAL	EQU		512				; 2^9 = 512 entries
	
INVALID		EQU		-1				; an invalid id
	
;
; Each MCB Entry
; FEDCBA9876543210
; 00SSSSSSSSS0000U					S bits are used for Heap size, U=1 Used U=0 Not Used

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Memory Control Block Initialization
; void _kinit( )
; this routine must be called from Reset_Handler in startup_TM4C129.s
; before you invoke main( ) in driver_keil
		EXPORT	_kinit
_kinit
		; you must correctly set the value of each MCB block
		; complete your code
		IMPORT _bzero
		PUSH 	{R0-R12, LR}		; save registers
		LDR 	R0, =MCB_TOP		; MCB space to zero-initialize
		LDR		R1, =MAX_SIZE		; load max size
		STR		R1, [R0], #4		; store max size in first MCB entry
		
		LDR		R1, =MCB_TOTAL		; load total MCB entries
		LSL		R1, R1, #1			; multiply by two to get MCB size
		SUBS	R1, R1, #4			; account for first MCB entry
		; maybe push lr???
		BL		_bzero				; zero-initialize MCB space
		
		POP 	{R0-R12, LR}		; resume register values
		BX		LR					; resume lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _kalloc( int size )
		EXPORT	_kalloc
_kalloc
		; complete your code
		; return value should be saved into r0
		; R0 = size
		LDR		R1, =MCB_TOP
		LDR		R2, =MCB_BOT
		PUSH	{LR}
		BL		_ralloc
		POP		{LR}
		BX		LR
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _ralloc( int size, int left_mcb_addr, int right_mcb_address )
		EXPORT	_ralloc
_ralloc
		; complete your code
		; return value should be saved into r0
		; R0 = size
		; R1 = left_mcb_addr
		; R2 = right_mcb_addr
		SUBS	R3, R2, R1
		ADDS	R3, R3, #0x00000002			; entire_mcb_addr_space
		LSR		R4, R3, #1					; half_mcb_addr_space
		ADDS	R5, R1, R4					; midpoint_mcb_addr
		MOVS	R6, #0						; heap_addr
		LSL		R7, R3, #4					; act_entire_heap_size
		LSL		R8, R4, #4					; act_half_heap_size
		
		
		
		BX		lr
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void *_kfree( void *ptr )
		EXPORT	_kfree
_kfree
		; complete your code
		; return value should be saved into r0
		BX		lr
		
		END