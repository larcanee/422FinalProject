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
		MOV		R0, R6			; set r0 to heap address space
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
		PUSH	{R0-R5, R7-R8, LR}
		SUBS	R3, R2, R1
		ADDS	R3, R3, #0x00000002			; entire_mcb_addr_space
		LSRS	R4, R3, #1					; half_mcb_addr_space
		ADDS	R5, R1, R4					; midpoint_mcb_addr
		MOVS	R6, #0						; heap_addr
		LSLS	R7, R3, #4					; act_entire_heap_size
		LSLS	R8, R4, #4					; act_half_heap_size

		CMP		R0, R8						; compares size and actual half heap size
		BLE		fits_half
		BGT		no_fit_half

fits_half									; if requested size can fit in half of current mcb size
		PUSH	{R0-R5, R7-R8, LR}			
		LDR		R9, =MCB_ENT_SZ
		SUBS	R2, R5, R9					; calculate right address (midpoint - mcb entry size)
		BL		_ralloc						; call ralloc with adjusted register values
		POP		{R0-R5, R7-R8, LR}	
		
		CMP		R6, #0						; compares heap address to 0
		BEQ		alloc_failed				; if 0, allocation has failed
		
		LDRH	R9, [R5]
		TST		R9, #0x01					; compares midpoint's LSB to 0
		BNE		end_ralloc					; if not 0, midpoint is occupied
		
		STR		R8, [R5]					; set actual half heap size to midpoint
		B		end_ralloc

alloc_failed								; if heap address is 0
		PUSH	{R0-R5, R7-R8, LR}
		;PUSH {lr}
		MOV		R1, R5						; set midpoint to left address
		BL		_ralloc						; try to allocate again
		POP 	{R0-R5, R7-R8, LR}
		;POP {lr}
		B		end_ralloc
		
no_fit_half									; if requested size cannot fit in half of current mcb space
		LDRH	R9, [R1]
		TST		R9, #0x01					; compares left address's LSB to 0
		BNE 	occupied					; if leftt address's LSB is 1
		
		CMP		R9, R7						; compares left addr and entire heap space
		BLT		no_fit						; mcb's size stored in left address has less memory than requested
		
		ORR 	R7, R7, #1					; set entire heap size to in use			
		STR		R7, [R1]					; set left address to (in use) entire heap size
		
		LDR		R9, =MCB_TOP
		SUBS	R1, R1, R9					; left address - mcb top
		LSLS	R1, R1, #4					; (left addres - mcb top) * 16
		
		LDR		R9, =HEAP_TOP
		ADDS	R6, R1, R9					; heap top + ((left address - mcb top) * 16)
											; R6 = address of allocated memory
		B		end_ralloc
		
occupied
		MOVS	R6, #0						; current MCB address is in use
		B		end_ralloc
		
no_fit
		MOVS	R6, #0
		B		end_ralloc
	
end_ralloc	
		POP		{R0-R5, R7-R8, LR}
		BX		LR
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void *_kfree( void *ptr )
		EXPORT	_kfree
_kfree
		; complete your code
		; return value should be saved into r0
		; R0 = memory address to deallocate
		PUSH	{LR}
		LDR		R1, =HEAP_TOP
		CMP		R0, R1
		BLT		_kfree_exit
		
		LDR		R2, =HEAP_BOT
		CMP		R0, R2
		BGT		_kfree_exit
		
		SUBS	R0, R0, R1
		LSRS	R0, R0, #4
		LDR		R2, =MCB_TOP
		ADDS	R0, R0, R2
		
		BL		_rfree
		
		CMP		R0, #0
		BEQ		_kfree_exit
		
		POP		{LR}
		BX 		LR
		
_kfree_exit
		POP 	{R0, LR}
		BX 		LR
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void *_rfree( int mcb_addr )
		EXPORT	_rfree
_rfree
		; complete your code
		; R0 = mcb_addr
		LDR		R1, [R0]		; contents of MCB entry at address
		LDR		R2, =MCB_TOP
		SUBS	R2, R0, R2		; calculate the index of MCB entry
		LSRS	R3, R1, #4		; calculate mcb displacement
		LSLS	R4, R1, #4
		MOVS	R4, R1			; clear LSB of contents
		
		MOVS	R1, R0			; mcb addr's bit is cleared
		BX		lr
		
		END