.STRUCT ApplicationMode
    ; The video interrupt handler is special, for optimization purposes:
    ; 1. It is ALWAYS the first entry in the structure so that we don't have to calculate
    ;    any math offsets to find it.
    ; 2. It is a JUMP TARGET rather than a subroutine.  You'll have to provide your own RET.
    ; 3. We need the tightest loops for handling HBLANKs.
    VideoInterruptJumpTarget    DW
    OnNMI                       DW      ; Called when a non-maskable interrupt (NMI) comes in.
    OnEnter                     DW      ; Called when this mode is entered.
    OnExit                      DW      ; Called when exited.
    OnUpdate                    DW      ; Called when the application wants to update.
    OnRender                    DW      ; Called when the application is about to render.
    OnEvent                     DW      ; Called when a generic event occurs.
.ENDST

.DEFINE MODEMANAGER_MAX_MODE_DEPTH 4    ; Max #/modes allowed
.STRUCT ModeManagerDefinition
    ModeManager_CurrMode            DW  ; Pointer to current mode
    ModeManager_CurrVideoInterrupt  DW  ; Pointer to current interrupt handler
    ModeManager_CurrModeIndex       DB  ; Depth of stack
    ModeManager_Stack               DSW MODEMANAGER_MAX_MODE_DEPTH  ; Stack entires
.ENDST

.RAMSECTION "Mode Manager" SLOT 3
    gModeManager INSTANCEOF ModeManagerDefinition
.ENDS 

.SECTION "Mode Manager Routines" FREE

.DSTRUCT gModeManagerDummyMode INSTANCEOF ApplicationMode ModeManagerDefaultHandler, ModeManagerDefaultHandler, ModeManagerDefaultHandler, ModeManagerDefaultHandler, ModeManagerDefaultHandler, ModeManagerDefaultHandler, ModeManagerDefaultHandler

ModeManagerDefaultHandler:
    ret

;==============================================================================
; ModeManager_Init
; Initializes the gModeManager.
; INPUTS:  DE:  Initial mode to switch to.
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
ModeManager_Init:
    ld  a, MODEMANAGER_MAX_MODE_DEPTH - 1
    ld  (gModeManager.ModeManager_CurrModeIndex), a

    ; Fill all but the latest entry in the stack with 0xFFFFs
    ld  a, $FF
    ld  b, ( MODEMANAGER_MAX_MODE_DEPTH - 1 ) * 2
    ld  hl, gModeManager.ModeManager_Stack
-:
    ld  (hl), a
    inc hl
    djnz -

    ; Top of stack is the initial mode passed in.
    ld  (hl), e
    inc hl
    ld  (hl), d

    ; Curr Mode is just a copy of the top of the stack.
    ld  hl, gModeManager.ModeManager_CurrMode
    ld  (hl), e
    inc hl
    ld  (hl), d

    ; Pre-cache the video interrupt for optimized calling
    push    de
    pop     ix

    ld      l, (ix + ApplicationMode.VideoInterruptJumpTarget)
    ld      h, (ix + ApplicationMode.VideoInterruptJumpTarget + 1)
    ld      (gModeManager.ModeManager_CurrVideoInterrupt), hl

    ; Now call the OnEnter for this mode.
    ld      l, (ix + ApplicationMode.OnEnter)
    ld      h, (ix + ApplicationMode.OnEnter + 1)
    jp (hl)
.ENDS