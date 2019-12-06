;==============================================================================
; ADD_A_TO_PTR
; Adds the value in A as an offset to a 16-bit pointer, returned in HL.  
; Useful for indexing into a jump table.  Does not need to use an intermediary 
; 16-bit register like DE, etc.
; INPUTS:  PTR:  16-bit pointer
;            A:  Offset
; OUTPUTS:  HL = PTR + A
;            A = High byte of HL
;==============================================================================
.MACRO ADD_A_TO_PTR ARGS PTR
    add a, PTR & $FF
    ld  l, a
    adc a, PTR >> 8
    sub l
    ld  h, a
.ENDM

;==============================================================================
; ADD_2A_TO_PTR
; Adds the value 2 * A as an offset to a 16-bit pointer, returned in HL.  
; Useful for indexing into a jump table.  Does not need to use an intermediary 
; 16-bit register like DE, etc.
; INPUTS:  PTR:  16-bit pointer
;            A:  Offset
; OUTPUTS:  HL = PTR + A
;            A = High byte of HL
;==============================================================================
.MACRO ADD_2A_TO_PTR ARGS PTR
    add a, a
    ADD_A_TO_PTR PTR
.ENDM

;==============================================================================
; PUSH_ALL_REGS
; Pushes all registers, including index regs.  Useful for a context switch.
; INPUTS:  NONE
; OUTPUTS: NONE
;==============================================================================
.MACRO PUSH_ALL_REGS
    push    af
    push    bc
    push    de
    push    hl
    push    ix
    push    iy
.ENDM

;==============================================================================
; POP_ALL_REGS
; Pops all registers, including index regs.  Useful for a context switch.
; INPUTS:  NONE
; OUTPUTS: NONE
;==============================================================================
.MACRO POP_ALL_REGS
    pop     iy
    pop     ix
    pop     hl
    pop     de
    pop     bc
    pop     af
.ENDM