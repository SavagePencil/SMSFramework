.STRUCT FSM
    CurrentState    DW
.ENDST

.STRUCT State
    OnUpdate        DW
    OnEvent         DW
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
    ; Set our return location.
    ld      hl, _FSM_OnUpdateReturnLoc
    push    hl

    ; Get the pointer to the state.
    ld      l, (ix + FSM.CurrentState + 0)
    ld      h, (ix + FSM.CurrentState + 1)

    ; Get the OnUpdate pointer.
    ld      a, (hl)
    inc     hl
    ld      h, (hl)
    ld      l, a        ; HL now points to State.OnUpdate
    jp      (hl)

_FSM_OnUpdateReturnLoc:
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

    ld      hl, _FSM_ChangeStateOnExitReturnLoc
    push    hl

    ; Get the pointer to the *current* state.
    ld      l, (ix + FSM.CurrentState + 0)
    ld      h, (ix + FSM.CurrentState + 1)

    ; Advance to the OnExit function pointer.
    .REPEAT State.OnExit
        inc     hl
    .ENDR

    ; Exit the current state.
    ld      a, (hl)
    inc     hl
    ld      h, (hl)
    ld      l, a        ; HL now points to top of state

    jp      (hl)        ; Call the current state's OnExit.

_FSM_ChangeStateOnExitReturnLoc:    
    ; Store the new state as our current one.
    pop     hl          ; Get the new state.
    ; Fall through to the FSMInit

;==============================================================================
; FSM_Init
; Initializes an FSM with the desired state.  The new state may itself cause
; a transition.
; INPUTS:  IX:  Pointer to FSM
;          HL:  New state to initialize with.
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
FSM_Init:
    ; Store the state in the FSM
    ld      (ix + FSM.CurrentState + 0), l
    ld      (ix + FSM.CurrentState + 1), h

    ; Advance to the OnEnter function pointer.
    .REPEAT State.OnEnter
        inc     hl
    .ENDR

    ; Enter the new state.
    ld      a, (hl)
    inc     hl
    ld      h, (hl)
    ld      l, a        ; HL now points to top of state

    ; Set return loc
    ld      de, _FSM_InitOnEnterReturnLoc
    push    de

    jp      (hl)        ; Call the new state's OnEnter

_FSM_InitOnEnterReturnLoc:
    ; If the carry flag is NOT set, we're done.
    ret     nc

    ; If we're here, we need to transition again.
    jp      FSM_ChangeState

;==============================================================================
; FSM_OnEvent
; Passes an event to the current state of the machine and handles any
; transitions that may occur.  How the event is passed is up to the caller.
; INPUTS:  IX:  Pointer to current FSM
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
FSM_OnEvent:
    ; Set our return location.
    ld      hl, _FSM_OnEventReturnLoc
    push    hl

    ; Get the pointer to the state.
    ld      l, (ix + FSM.CurrentState + 0)
    ld      h, (ix + FSM.CurrentState + 1)

    ; Advance to the OnEvent function pointer.
    .REPEAT State.OnEvent
        inc     hl
    .ENDR
    ; Get the OnEvent pointer.
    ld      a, (hl)
    inc     hl
    ld      h, (hl)
    ld      l, a        ; HL now points to State.OnEvent
    jp      (hl)

_FSM_OnEventReturnLoc:
    ; If the carry flag is NOT set, we're done
    ret     nc
    ; If we're here, time to transition to a new state.
    ; HL points to the new state.
    jp      FSM_ChangeState

.ENDS