.STRUCT ApplicationMode
    ; The video interrupt handler is special, for optimization purposes:
    ; 1. It is a JUMP TARGET rather than a subroutine.  You'll have to provide your own RET.
    ; 2. We need the tightest loops for handling HBLANKs.
    VideoInterruptJumpTarget    DW      ; Called when a video interrupt (V/HBlank) occurs.
    OnNMI                       DW      ; Called when a non-maskable interrupt (NMI) comes in.
    OnActive                    DW      ; Called when this mode is made active (pushed, old one above popped, etc.)
    OnInactive                  DW      ; Called when this mode goes inactive (popped, new mode pushed on, etc.)
    OnUpdate                    DW      ; Called when the application wants to update.
    OnRenderPrep                DW      ; Called when the application is prepping things for render.
    OnEvent                     DW      ; Called when a generic event occurs.
.ENDST

.DEFINE MODEMANAGER_MAX_MODE_DEPTH 4    ; Max #/modes allowed
.STRUCT ModeManager
    CurrMode            DW  ; Cache of pointer to current mode
    TopOfStack          DW  ; Pointer to current top of stack
    Stack               DSW MODEMANAGER_MAX_MODE_DEPTH  ; Stack entires
.ENDST

.RAMSECTION "Mode Manager" SLOT 3
    gModeManager INSTANCEOF ModeManager
.ENDS 

.SECTION "Mode Manager Routines" FREE

; Constants for mode going ACTIVE
.ENUMID 0 EXPORT
.ENUMID MODE_MADE_ACTIVE        ; You replaced what was on the top of the stack.  No push/pop.
.ENUMID MODE_PUSHED_ON          ; You were pushed onto the top of the stack, making you active.
.ENUMID MODE_OTHER_POPPED_OFF   ; Someone else was popped off, making you active.

; Constants for mode going INACTIVE.
.ENUMID 0 EXPORT
.ENUMID MODE_MADE_INACTIVE      ; You were replaced by something on the top of the stack.  No push/pop.
.ENUMID MODE_POPPED_OFF         ; You were popped off the top of the stack, making you inactive.
.ENUMID MODE_OTHER_POPPED_ON    ; Someone else was popped on, making you inactive.

;==============================================================================
; ModeManager_Init
; Initializes the global ModeManager.
; INPUTS:  DE:  Initial mode to switch to.
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
ModeManager_Init:
    ; Curr Mode is just a copy of the top of the stack.
    ld  hl, gModeManager.CurrMode
    ld  (hl), e
    inc hl
    ld  (hl), d

    ; Top of stack is the initial mode passed in.
    ld  hl, gModeManager.Stack
    ld  (gModeManager.TopOfStack), hl
    ld  (hl), e
    inc hl
    ld  (hl), d
    inc hl

    ; Fill the rest of the stack with 0xFFFFs
    ld  b, ( MODEMANAGER_MAX_MODE_DEPTH - 1 ) * 2
-:
    ld  (hl), $FF
    inc hl
    djnz -

    ; Get the mode into IX
    ld      ix, (gModeManager.CurrMode)

    ; Prep the video interrupt, which is held in HL' for speedy calling.
    exx
        ld  l', (ix + ApplicationMode.VideoInterruptJumpTarget + 0)
        ld  h', (ix + ApplicationMode.VideoInterruptJumpTarget + 1)
    exx

    ; Now call the OnActiveStateChanged for this mode.
    ld      l, (ix + ApplicationMode.OnActive)
    ld      h, (ix + ApplicationMode.OnActive + 1)
    ld      a, MODE_PUSHED_ON
    jp      (hl)

;==============================================================================
; ModeManager_SetActive
; Replaces the current top of stack with the new one.  Deactivates the old
; one and activates the new one.
; INPUTS:  DE:  New mode.
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
ModeManager_SetActive:
    ; Hang onto the new mode.
    push    de

    ; Tell the old active mode they are now inactive.
    ld      ix, (gModeManager.CurrMode)
    ld      l, (ix + ApplicationMode.OnInactive + 0)
    ld      h, (ix + ApplicationMode.OnInactive + 1)
    ld      a, MODE_MADE_INACTIVE
    call    CallHL      ; Execute the function, then return here.

    ; Record the new mode.
    pop     ix
    ld      (gModeManager.CurrMode), ix

    ; Prep the video interrupt, which is held in HL' for speedy calling.
    exx
        ld  l', (ix + ApplicationMode.VideoInterruptJumpTarget + 0)
        ld  h', (ix + ApplicationMode.VideoInterruptJumpTarget + 1)
    exx

    ; Tell the new mode that they are now active.
    ld      l, (ix + ApplicationMode.OnActive + 0)
    ld      h, (ix + ApplicationMode.OnActive + 1)
    ld      a, MODE_MADE_ACTIVE
    jp      (hl)

;==============================================================================
; ModeManager_PushMode
; Pushes a new mode onto the stack.  Lets the previous top deactivate, then 
; activates the new top.  Barfs if stack depth goes too far.
; INPUTS:  DE:  New mode.
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
ModeManager_PushMode:
    ; Hang onto the new mode.
    push    de

    ; Tell the old active mode that they are inactive; someone
    ; else got pushed on top of them.
    ld      ix, (gModeManager.CurrMode)
    ld      l, (ix + ApplicationMode.OnInactive + 0)
    ld      h, (ix + ApplicationMode.OnInactive + 1)
    ld      a, MODE_OTHER_POPPED_ON
    call    CallHL      ; Execute the function, then return here.

    ; Update the new top of stack.
    ld      hl, (gModeManager.TopOfStack)
    inc     hl
    inc     hl
    ld      (gModeManager.TopOfStack), hl

    ; Set the new mode on the stack, then on the cache.
    pop     de          ; Get new mode

    ; Store to stack
    ld      (hl), e
    inc     hl
    ld      (hl), d

    ; Store to cache
    ex      de, hl
    ld      (gModeManager.CurrMode), hl

    ; Get it into IX
    ld      ix, (gModeManager.CurrMode)

    ; Prep the video interrupt, which is held in HL' for speedy calling.
    exx
        ld  l', (ix + ApplicationMode.VideoInterruptJumpTarget + 0)
        ld  h', (ix + ApplicationMode.VideoInterruptJumpTarget + 1)
    exx

    ; Now call the OnActiveStateChanged for the new mode.
    ld      l, (ix + ApplicationMode.OnActive + 0)
    ld      h, (ix + ApplicationMode.OnActive + 1)
    ld      a, MODE_PUSHED_ON
    jp      (hl)

;==============================================================================
; ModeManager_PopMode
; Pops the top mode from the stack.  Lets the previous top deactivate, then 
; activates the new top.  Barfs if stack depth goes too far.
; INPUTS:  None
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
ModeManager_PopMode:
    ; Tell the old active mode that they are inactive; they
    ; just got popped off.
    ld      ix, (gModeManager.CurrMode)
    ld      l, (ix + ApplicationMode.OnInactive + 0)
    ld      h, (ix + ApplicationMode.OnInactive + 1)
    ld      a, MODE_POPPED_OFF
    call    CallHL      ; Execute the function, then return here.

    ; Clear out the old mode and decrement the top of stack
    ld      hl, (gModeManager.TopOfStack)
    inc     hl          ; Get to high byte
    ld      (hl), $FF
    dec     hl          ; Low byte
    ld      (hl), $FF
    dec     hl
    dec     hl
    ld      (gModeManager.TopOfStack), hl

    ; Make this one the cached one.
    ld      a, (hl)
    inc     hl
    ld      h, (hl)
    ld      l, a
    ld      (gModeManager.CurrMode), hl

    ; Get the new mode into IX
    ld      ix, (gModeManager.CurrMode)

    ; Prep the video interrupt, which is held in HL' for speedy calling.
    exx
        ld  l', (ix + ApplicationMode.VideoInterruptJumpTarget + 0)
        ld  h', (ix + ApplicationMode.VideoInterruptJumpTarget + 1)
    exx

    ; Now call the OnActiveStateChanged for the new mode.
    ld      l, (ix + ApplicationMode.OnActive + 0)
    ld      h, (ix + ApplicationMode.OnActive + 1)
    ld      a, MODE_OTHER_POPPED_OFF
    jp      (hl)


;==============================================================================
; ModeManager_OnNMI
; Called when an NMI occurs
; INPUTS:  None
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
ModeManager_OnNMI:
    ld  ix, (gModeManager.CurrMode)
    ld  l, (ix + ApplicationMode.OnNMI + 0)
    ld  h, (ix + ApplicationMode.OnNMI + 1)
    jp (hl)

;==============================================================================
; ModeManager_OnUpdate
; Called when the current mode needs to update
; INPUTS:  None
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
ModeManager_OnUpdate:
    ld  ix, (gModeManager.CurrMode)
    ld  l, (ix + ApplicationMode.OnUpdate + 0)
    ld  h, (ix + ApplicationMode.OnUpdate + 1)
    jp (hl)

;==============================================================================
; ModeManager_OnRenderPrep
; Called when the current mode needs to prep for render
; INPUTS:  None
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
ModeManager_OnRenderPrep:
    ld  ix, (gModeManager.CurrMode)
    ld  l, (ix + ApplicationMode.OnRenderPrep + 0)
    ld  h, (ix + ApplicationMode.OnRenderPrep + 1)
    jp (hl)

;==============================================================================
; ModeManager_OnEvent
; Called when an event happened that the current mode may want to handle
; INPUTS:  None
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
ModeManager_OnEvent:
    ld  ix, (gModeManager.CurrMode)
    ld  l, (ix + ApplicationMode.OnEvent + 0)
    ld  h, (ix + ApplicationMode.OnEvent + 1)
    jp (hl)

.ENDS