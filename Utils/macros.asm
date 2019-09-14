;==============================================================================
; ADD_A_TO_PTR
; Adds the value in A as an offset to a 16-bit pointer, returned in HL.  
; Useful for indexing into a jump table.  Does not need to use an intermediary 
; 16-bit register like DE, etc.
; INPUTS:  PTR:  16-bit pointer
;            A:  Offset
; OUTPUTS:  HL = PTR + A
; Destroys A
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
; Destroys A
;==============================================================================
.MACRO ADD_2A_TO_PTR ARGS PTR
    add a, a
    ADD_A_TO_PTR PTR
.ENDM