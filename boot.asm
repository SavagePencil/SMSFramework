.include "bankdetails.asm"
.include "mode.asm"

;==============================================================
; SDSC tag and SMS rom header
;==============================================================
.SDSCTAG 1.2,"GAMENAME","SMSFrameWork Game Description","AUTHOR NAME"

.RAMSECTION "Initialization State Variables" SLOT 3
    SMSFrameWork_Initialized DB
.ENDS

.BANK 0 SLOT 0
.ORG $0000
.SECTION "SMSFramework Boot" FORCE
SMSFramework_Boot:
    ; Very first instructions.
    di                          ; Disable Interrupts
    im 1                        ; Set Interrupt mode 1
    jp SMSFramework_Bootstrap   ; Prepare for our bootstrap.  We do a jump here so that 
                                ; we can get out before all the rst_* instructions
.ENDS

.SECTION "SMSFramework Bootstrap" FREE
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
    ei              ; Start listening for interrupts.
    halt            ; Wait for one to come in!
.ENDS