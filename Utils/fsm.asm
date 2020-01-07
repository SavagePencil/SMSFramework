.IFNDEF __FSM_ASM__
.DEFINE __FSM_ASM__

.STRUCT sFSM
    CurrentState    DW
.ENDST

.STRUCT sState
    OnUpdate        DW
    OnEnter         DW
    OnExit          DW
.ENDST

.SECTION "FSM IX Routines" FREE
; Routines for dealing with an FSM that is in the IX register
FSM_IX:
;==============================================================================
; FSM_IX@OnUpdate
; Updates the state machine and handles any state transitions.
; INPUTS:  IX:  Pointer to current FSM
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
@OnUpdate:
    ; Get the pointer to the state.
    ld      l, (ix + sFSM.CurrentState + 0)
    ld      h, (ix + sFSM.CurrentState + 1)

    ; Get the OnUpdate pointer.
    ld      a, (hl)
    inc     hl
    ld      h, (hl)
    ld      l, a        ; HL now points to sState.OnUpdate

    or      h
    ret     z           ; Early out if HL == 0000

    call    CallHL      ; Execute the function, then return here.

    ; If the carry flag is NOT set, we're done
    ret     nc
    ; If we're here, time to transition to a new state.
    ; HL points to the new state.
    jp      @ChangeState


;==============================================================================
; FSM_IX@ChangeState
; Changes the current state for the machine.  Exits current state and
; enters the new one, which may itself transition.
; INPUTS:  IX:  Pointer to FSM
;          HL:  New state to transition to.
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
@ChangeState:
    push    hl      ; Save new state to transition to.

    ; Get the pointer to the *current* state.
    ld      l, (ix + sFSM.CurrentState + 0)
    ld      h, (ix + sFSM.CurrentState + 1)

    ; Advance to the OnExit function pointer.
    .REPEAT sState.OnExit
        inc     hl
    .ENDR

    ; Exit the current state.
    ld      a, (hl)
    inc     hl
    ld      h, (hl)
    ld      l, a        ; HL now points to the OnExit

    or      h
    jp      z, @@NextState  ; Early out if HL == 0000

    call    CallHL      ; Execute the function, then return here.

@@NextState:
    ; Store the new state as our current one.
    pop     hl          ; Get the new state.
    ; Fall through to the @Init

;==============================================================================
; FSM_IX@Init
; Initializes an FSM with the desired state.  The new state may itself cause
; a transition.
; INPUTS:  IX:  Pointer to FSM
;          HL:  Pointer to state to initialize with.
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
@Init:
    ; Store the state in the FSM
    ld      (ix + sFSM.CurrentState + 0), l
    ld      (ix + sFSM.CurrentState + 1), h

    ; Advance to the OnEnter function pointer.
    .REPEAT sState.OnEnter
        inc     hl
    .ENDR

    ; Enter the new state.
    ld      a, (hl)
    inc     hl
    ld      h, (hl)
    ld      l, a        ; HL now points to the OnEnter

    or      h
    ret     z           ; Early out if HL == 0000

    call    CallHL      ; Execute the function, then return here.

    ; If the carry flag is NOT set, we're done.
    ret     nc

    ; If we're here, we need to transition again.
    jp      @ChangeState

;==============================================================================
; FSM_IX@OnEvent
; Calls an arbitrary state function.  This allows FSM consumers to add as many
; state functions as desired to their particular FSM.  This function may result
; in the machine changing state, indicated by setting the Carry flag on return.
; How parameters are passed to the function is up to the caller.
; INPUTS:  IX:  Pointer to current FSM
;          DE:  Offset to State Event Function
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
@OnEvent:
    ; Get the pointer to the state.
    ld      l, (ix + sFSM.CurrentState + 0)
    ld      h, (ix + sFSM.CurrentState + 1)

    ; Advance to the appropriate function pointer.
    add     hl, de

    ; Get the OnEvent pointer.
    ld      a, (hl)
    inc     hl
    ld      h, (hl)
    ld      l, a        ; HL now points to sState.OnEvent

    or      h
    ret     z           ; Early out if HL == 0000

    call    CallHL      ; Execute the function, then return here.

    ; If the carry flag is NOT set, we're done
    ret     nc
    ; If we're here, time to transition to a new state.
    ; HL points to the new state.
    jp      @ChangeState

.ENDS

.SECTION "FSM IY Routines" FREE
; Routines for dealing with an FSM that is in the IY register
FSM_IY:
;==============================================================================
; FSM_IY@OnUpdate
; Updates the state machine and handles any state transitions.
; INPUTS:  IY:  Pointer to current FSM
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
@OnUpdate:
    ; Get the pointer to the state.
    ld      l, (iy + sFSM.CurrentState + 0)
    ld      h, (iy + sFSM.CurrentState + 1)

    ; Get the OnUpdate pointer.
    ld      a, (hl)
    inc     hl
    ld      h, (hl)
    ld      l, a        ; HL now points to sState.OnUpdate

    or      h
    ret     z           ; Early out if HL == 0000

    call    CallHL      ; Execute the function, then return here.

    ; If the carry flag is NOT set, we're done
    ret     nc
    ; If we're here, time to transition to a new state.
    ; HL points to the new state.
    jp      @ChangeState


;==============================================================================
; FSM_IY@ChangeState
; Changes the current state for the machine.  Exits current state and
; enters the new one, which may itself transition.
; INPUTS:  IY:  Pointer to FSM
;          HL:  New state to transition to.
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
@ChangeState:
    push    hl      ; Save new state to transition to.

    ; Get the pointer to the *current* state.
    ld      l, (iy + sFSM.CurrentState + 0)
    ld      h, (iy + sFSM.CurrentState + 1)

    ; Advance to the OnExit function pointer.
    .REPEAT sState.OnExit
        inc     hl
    .ENDR

    ; Exit the current state.
    ld      a, (hl)
    inc     hl
    ld      h, (hl)
    ld      l, a        ; HL now points to the OnExit

    or      h
    jp      z, @@NextState  ; Early out if HL == 0000

    call    CallHL      ; Execute the function, then return here.

@@NextState:
    ; Store the new state as our current one.
    pop     hl          ; Get the new state.
    ; Fall through to the @Init

;==============================================================================
; FSM_IY@Init
; Initializes an FSM with the desired state.  The new state may itself cause
; a transition.
; INPUTS:  IY:  Pointer to FSM
;          HL:  Pointer to state to initialize with.
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
@Init:
    ; Store the state in the FSM
    ld      (iy + sFSM.CurrentState + 0), l
    ld      (iy + sFSM.CurrentState + 1), h

    ; Advance to the OnEnter function pointer.
    .REPEAT sState.OnEnter
        inc     hl
    .ENDR

    ; Enter the new state.
    ld      a, (hl)
    inc     hl
    ld      h, (hl)
    ld      l, a        ; HL now points to the OnEnter

    or      h
    ret     z           ; Early out if HL == 0000

    call    CallHL      ; Execute the function, then return here.

    ; If the carry flag is NOT set, we're done.
    ret     nc

    ; If we're here, we need to transition again.
    jp      @ChangeState

;==============================================================================
; FSM_IY@OnEvent
; Calls an arbitrary state function.  This allows FSM consumers to add as many
; state functions as desired to their particular FSM.  This function may result
; in the machine changing state, indicated by setting the Carry flag on return.
; How parameters are passed to the function is up to the caller.
; INPUTS:  IY:  Pointer to current FSM
;          DE:  Offset to State Event Function
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
@OnEvent:
    ; Get the pointer to the state.
    ld      l, (iy + sFSM.CurrentState + 0)
    ld      h, (iy + sFSM.CurrentState + 1)

    ; Advance to the appropriate function pointer.
    add     hl, de

    ; Get the OnEvent pointer.
    ld      a, (hl)
    inc     hl
    ld      h, (hl)
    ld      l, a        ; HL now points to sState.OnEvent

    or      h
    ret     z           ; Early out if HL == 0000

    call    CallHL      ; Execute the function, then return here.

    ; If the carry flag is NOT set, we're done
    ret     nc
    ; If we're here, time to transition to a new state.
    ; HL points to the new state.
    jp      @ChangeState

.ENDS


.SECTION "FSM DE Routines" FREE
; Routines for dealing with an FSM that is in the DE register
FSM_DE:
;==============================================================================
; FSM_DE@OnUpdate
; Updates the state machine and handles any state transitions.
; INPUTS:  DE:  Pointer to current sFSM
; OUTPUTS: DE:  Pointer to current sFSM
; Does not preserve any registers.
;==============================================================================
@OnUpdate:
    push    de
        ld      a, (de)
        ld      l, a
        inc     de
        ld      a, (de)
        ld      h, a

        ; HL now points to the current sState.
        ld      a, (hl)
        inc     hl
        ld      h, (hl)
        ld      l, a        ; HL now points to sState.OnUpdate

        or      h
        jr      z, @@Done   ; Early out if HL == 0000

        inc     de          ; DE points to the byte AFTER our sFSM

        call    CallHL
        jr      c, @@NeedToChangeState

    ; If the carry flag is NOT set, we're done.
@@Done:
    pop     de
    ret

@@NeedToChangeState:
    ; Get our ptr to our FSM back.
    pop     de

    ; HL points to new state.
    ; **** FALL THROUGH ****

;==============================================================================
; FSM_DE@ChangeState
; Changes the current state for the machine.  Exits current state and
; enters the new one, which may itself transition.
; INPUTS:  DE:  Pointer to sFSM
;          HL:  New sState to transition to.
; OUTPUTS: DE:  Pointer to sFSM
; Does not preserve any registers.
;==============================================================================
@ChangeState:
    ; Save our sFSM
    push    de
        ; Save the new state to transition to.
        push    hl
            ; Get the pointer to the *current* state.
            ld      a, (de)
            ld      l, a
            inc     de
            ld      a, (de)
            ld      h, a

            ; Advance to the OnExit function pointer.
            .REPEAT sState.OnExit
                inc     hl
            .ENDR

            ; Exit the current state.
            ld      a, (hl)
            inc     hl
            ld      h, (hl)
            ld      l, a        ; HL now points to the OnExit

            or      h
            call    nz, CallHL  ; Skips if HL == 0000     

@@EnterNextState:
        pop     hl
    pop     de

    ; **** FALL THROUGH ****

;==============================================================================
; FSM_DE@Init
; Initializes an FSM with the desired state.  The new state may itself cause
; a transition.
; INPUTS:  DE:  Pointer to sFSM
;          HL:  Pointer to sState to initialize with.
; OUTPUTS: DE:  Pointer to sFSM
; Does not preserve any registers.
;==============================================================================
@Init:
    push    de
        ; Store the state in the sFSM
        ld      a, l
        ld      (de), a
        inc     de
        ld      a, h
        ld      (de), a
        dec     de

        ;Advance to the OnEnter function pointer
        .REPEAT sState.OnEnter
            inc     hl
        .ENDR

        ; Enter the new state
        ld      a, (hl)
        inc     hl
        ld      h, (hl)
        ld      l, a        ; HL now points to the OnEnter

        or      h
        jr      z, @@Done   ; Skip if HL == 0000

        call    CallHL      ; Execute the function, then return here.

        ; If the carry flag is NOT set, we're done.
        jr      nc, @@Done

    ; Else, it's set.  Transition again.
    pop     de
    jp      @ChangeState

@@Done:
    pop     de
    ret

;==============================================================================
; FSM_DE@OnEvent
; Calls an arbitrary state function.  This allows FSM consumers to add as many
; state functions as desired to their particular FSM.  This function may result
; in the machine changing state, indicated by setting the Carry flag on return.
; How parameters are passed to the function is up to the caller.
; INPUTS:  DE:  Pointer to current sFSM
;          BC:  Offset to State Event Function
; OUTPUTS: DE:  Pointer to current sFSM
; Does not preserve any registers.
;==============================================================================
@OnEvent:
    push    de
        ; Get the pointer to the sState.
        ld      a, (de)
        inc     de
        ld      l, a
        ld      a, (de)
        ld      h, a
        dec     de

        ; Now add in the offset.
        add     hl, bc

        ; Get the pointer to the function.
        ld      a, (hl)
        inc     hl
        ld      h, (hl)
        ld      l, a        ; HL now points to the event.

        or      h
        jr      z, @@Done   ; Early out if HL == 0000

        call    CallHL      ; Execute the function

        ; If the carry flag is NOT set, we're done.
        jr      nc, @@Done

        ; If we're here, time to transition to a new state.
        ; HL points to the new state.
    pop     de
    jp      @ChangeState

@@Done:
    pop     de
    ret

.ENDS


.ENDIF  ;__FSM_ASM__