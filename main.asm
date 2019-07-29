.include "boot.asm"
.include "interrupts.asm"

.section "Application Bootstrap" FREE
; This routine sets up an initial state as part of the bootstrapping.
; It should set a mode for the initial program.
Application_Bootstrap:
    ; Set our initial mode
    ld  de, gModeManagerDummyMode
    call ModeManager_Init

    ret
.ends