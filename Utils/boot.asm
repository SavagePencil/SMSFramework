.RAMSECTION "Initialization State Variables" SLOT 3
    SMSFrameWork_Initialized DB
.ENDS

.BANK 0 SLOT 0
.ORG $0000
.SECTION "SMSFramework Boot" FORCE
;==============================================================================
; SMSFramework_Boot
; Our very first instructions.  Gets to the bootstrap quickly so that we can
; free up the rst_* instructions.
; INPUTS:  None
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
SMSFramework_Boot:
    ; Very first instructions.
    di                          ; Disable Interrupts
    im 1                        ; Set Interrupt mode 1
    jp SMSFramework_Bootstrap   ; Prepare for our bootstrap.  We do a jump here so that 
                                ; we can get out before all the rst_* instructions
.ENDS

.SECTION "SMSFramework Bootstrap" FREE
;==============================================================================
; SMSFramework_Boot
; Bookends the bootstrapping of the framework.  Let's the application
; initialize itself, then waits for the interrupt system to take over.
; INPUTS:  None
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
SMSFramework_Bootstrap:
    ; Indicate that we are NOT yet initialized.
    xor a
    ld  (SMSFrameWork_Initialized), a

    ; Set our stack pointer.
    ld sp, $dff0

    ; Call our application to setup anything it needs.
    call Application_Bootstrap

    ; Now we're initialized.
    ld a, 1
    ld (SMSFrameWork_Initialized), a

    ; Let the Application take over.
    jp Application_MainLoop_InitialEntry
.ENDS

.SECTION "Helper Function CallHL" FREE
;==============================================================================
; CallHL
; Helper function to set a return location immediately after a function pointer
; call.
; INPUTS:  HL = Function pointer to call.
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
CallHL:
    jp hl
.ENDS

.SECTION "Helper Function CallIX" FREE
;==============================================================================
; CallIX
; Helper function to set a return location immediately after a function pointer
; call.
; INPUTS:  IX = Function pointer to call.
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
CallIX:
    jp ix
.ENDS

.SECTION "Helper Function CallIY" FREE
;==============================================================================
; CallIY
; Helper function to set a return location immediately after a function pointer
; call.
; INPUTS:  IY = Function pointer to call.
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
CallIY:
    jp iy
.ENDS