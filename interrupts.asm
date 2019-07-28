.bank 0 slot 0
.org $0038
.section "SMSFramework Video Interrupts" FORCE
SMSFramework_VideoInterruptHandler:
    di

    ; TODO:  Pass this on to the mode handler
    ei
    reti
.ends

.bank 0 slot 0
.org $0066
.section "SMSFramework Non-Maskable Interrupts" FORCE
SMSFramework_NMIHandler:
    ; Are we initialized, or did this come in while we were booting?
    ld a, (SMSFrameWork_Initialized)
    and a
    ret z   ; Ignore it if we're not yet initialized.

    ; TODO:  Pass this on to the mode handler

    retn
.ends
