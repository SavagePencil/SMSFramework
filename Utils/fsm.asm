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

.SECTION "FSM Routines" FREE
;==============================================================================
; FSM_OnUpdate
; Updates the state machine and handles any state transitions.
; INPUTS:  IX:  Pointer to current FSM
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
FSM_OnUpdate:
    ; Get the pointer to the state.
    ld      l, (ix + sFSM.CurrentState + 0)
    ld      h, (ix + sFSM.CurrentState + 1)

    ; Get the OnUpdate pointer.
    ld      a, (hl)
    inc     hl
    ld      h, (hl)
    ld      l, a        ; HL now points to State.OnUpdate

    or      h
    ret     z           ; Early out if HL == 0000

    call    CallHL      ; Execute the function, then return here.

    ; If the carry flag is NOT set, we're done
    ret     nc
    ; If we're here, time to transition to a new state.
    ; HL points to the new state.
    jp      FSM_ChangeState


;==============================================================================
; FSM_ChangeState
; Changes the current state for the machine.  Exits current state and
; enters the new one, which may itself transition.
; INPUTS:  IX:  Pointer to FSM
;          HL:  New state to transition to.
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
FSM_ChangeState:
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
    jp      z, @NextState  ; Early out if HL == 0000

    call    CallHL      ; Execute the function, then return here.

@NextState:
    ; Store the new state as our current one.
    pop     hl          ; Get the new state.
    ; Fall through to the FSMInit

;==============================================================================
; FSM_Init
; Initializes an FSM with the desired state.  The new state may itself cause
; a transition.
; INPUTS:  IX:  Pointer to FSM
;          HL:  Pointer to state to initialize with.
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
FSM_Init:
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
    jp      FSM_ChangeState

;==============================================================================
; FSM_OnEvent
; Calls an arbitrary state function.  This allows FSM consumers to add as many
; state functions as desired to their particular FSM.  This function may result
; in the machine changing state, indicated by setting the Carry flag on return.
; How parameters are passed to the function is up to the caller.
; INPUTS:  IX:  Pointer to current FSM
;          DE:  Offset to State Event Function
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
FSM_OnEvent:
    ; Get the pointer to the state.
    ld      l, (ix + sFSM.CurrentState + 0)
    ld      h, (ix + sFSM.CurrentState + 1)

    ; Advance to the appropriate function pointer.
    add     hl, de

    ; Get the OnEvent pointer.
    ld      a, (hl)
    inc     hl
    ld      h, (hl)
    ld      l, a        ; HL now points to State.OnEvent

    or      h
    ret     z           ; Early out if HL == 0000

    call    CallHL      ; Execute the function, then return here.

    ; If the carry flag is NOT set, we're done
    ret     nc
    ; If we're here, time to transition to a new state.
    ; HL points to the new state.
    jp      FSM_ChangeState

.ENDS

.ENDIF  ;__FSM_ASM__