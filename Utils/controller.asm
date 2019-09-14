.IFNDEF __CONTROLLER_ASM__
.DEFINE __CONTROLLER_ASM__

.INCLUDE "Utils/Controllers/controller_none.asm"
.INCLUDE "Utils/Controllers/controller_joypad.asm"

; Types of controller
.ENUMID 0 EXPORT
.ENUMID CONTROLLER_TYPE_NONE        ; No controller in use
.ENUMID CONTROLLER_TYPE_SMS_JOYPAD  ; D-Pad + 1 & 2 buttons

; Keeps an FSM for the controller--whatever its type--and data relevant to it.
.STRUCT Controller
    ControllerFSM   INSTANCEOF FSM
    ControllerType  DB

    .UNION Joypad
        Data INSTANCEOF ControllerData_Joypad
    .ENDU
.ENDST

.ENDIF  ;__CONTROLLER_ASM__