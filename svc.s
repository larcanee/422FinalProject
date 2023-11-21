		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
SYSTEMCALLTBL	EQU		0x20007B00
SYS_EXIT		EQU		0x0		; address 20007B00
SYS_MALLOC		EQU		0x1		; address 20007B04
SYS_FREE		EQU		0x2		; address 20007B08

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Initialization
		EXPORT	_systemcall_table_init 
_systemcall_table_init
		LDR		R0, = SYSTEMCALLTBL
		
		; Initialize SYSTEMCALLTBL[0] = _sys_exit
		LDR		R1, = _sys_exit
		STR		R1, [R0]

		; Initialize_SYSTEMCALLTBL[1] = _sys_malloc
		; add your code here
		; your code may be of 2 to 6 lines
		LDR 	R1, =_sys_malloc
		STR 	R1, [R0, #4]
	
		; Initialize_SYSTEMCALLTBL[2] = _sys_free
		; add your code here
		; your code may be of 2 to 6 lines
		LDR 	R1, =_sys_free
		STR 	R1, [R0, #8]
		
		BX		LR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Jump Routine
; this is the function that will be callsed by SVC
        EXPORT    _systemcall_table_jump
_systemcall_table_jump
        LDR        R11, = SYSTEMCALLTBL    ; load the starting address of SYSTEMCALLTBL
        MOV        R10, R7            ; copy the system call number into r10
        LSL        R10, #0x2        ; system call number * 4
        ; complete the rest of the code
        ; your code may be of 4 to 8 lines
        LDR        R1, [R11, R10]	; load address of system call
        PUSH       {R1-R12, LR}		; save registers and lr
        BLX        R1				; jump to instruction based on address
        POP        {R1-R12, LR}		; resume lr and regs

        BX	       LR                ; return to SVC_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call 
; provided for you to use

_sys_exit
		PUSH 	{LR}		; save lr
		BLX		R11	
		POP 	{LR}		; resume lr
		BX		LR
		
_sys_malloc
		IMPORT	_kalloc
		LDR		R11, = _kalloc	
		PUSH 	{LR}		; save lr
		BLX		R11			; call the _kalloc function 
		POP 	{LR}		; resume lr
		BX		LR
		
_sys_free
		IMPORT	_kfree
		LDR		R11, = _kfree	
		PUSH 	{LR}		; save lr
		BLX		R11			; call the _kfree function 
		POP 	{LR}		; resume lr
		BX		LR
		
		END

		