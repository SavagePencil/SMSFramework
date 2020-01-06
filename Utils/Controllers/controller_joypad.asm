.IFNDEF __CONTROLLER_JOYPAD_ASM__
.DEFINE __CONTROLLER_JOYPAD_ASM__

.INCLUDE "Utils/controller.asm"
.INCLUDE "Utils/input.asm"

.STRUCT sControllerData_Joypad
    CurrentButtons  DB
    PreviousButtons DB
.ENDST

.DEFINE CONTROLLER_JOYPAD_UP_BITPOS         0
.DEFINE CONTROLLER_JOYPAD_DOWN_BITPOS       1
.DEFINE CONTROLLER_JOYPAD_LEFT_BITPOS       2
.DEFINE CONTROLLER_JOYPAD_RIGHT_BITPOS      3
.DEFINE CONTROLLER_JOYPAD_BUTTON1_BITPOS    4
.DEFINE CONTROLLER_JOYPAD_BUTTON2_BITPOS    5

.DEFINE CONTROLLER_JOYPAD_UP_RELEASED       1 << CONTROLLER_JOYPAD_UP_BITPOS
.DEFINE CONTROLLER_JOYPAD_DOWN_RELEASED     1 << CONTROLLER_JOYPAD_DOWN_BITPOS
.DEFINE CONTROLLER_JOYPAD_LEFT_RELEASED     1 << CONTROLLER_JOYPAD_LEFT_BITPOS
.DEFINE CONTROLLER_JOYPAD_RIGHT_RELEASED    1 << CONTROLLER_JOYPAD_RIGHT_BITPOS
.DEFINE CONTROLLER_JOYPAD_BUTTON1_RELEASED  1 << CONTROLLER_JOYPAD_BUTTON1_BITPOS
.DEFINE CONTROLLER_JOYPAD_BUTTON2_RELEASED  1 << CONTROLLER_JOYPAD_BUTTON2_BITPOS

.SECTION "Controller Joypad" FREE

; State for joypad in port #1
.DSTRUCT Controller_Joypad_Port1_State INSTANCEOF sState VALUES:
    OnEnter:    .DW Controller_Joypad_OnEnter
    OnUpdate:   .DW Controller_Joypad_Port1_OnUpdate
.ENDST

; State for joypad in port #2
.DSTRUCT Controller_Joypad_Port2_State INSTANCEOF sState VALUES:
    OnEnter:    .DW Controller_Joypad_OnEnter
    OnUpdate:   .DW Controller_Joypad_Port2_OnUpdate
.ENDST


Controller_Joypad_OnEnter:
    ld  (ix + sController.Joypad.Data.CurrentButtons), CONTROLLER_JOYPAD_UP_RELEASED | CONTROLLER_JOYPAD_DOWN_RELEASED | CONTROLLER_JOYPAD_LEFT_RELEASED | CONTROLLER_JOYPAD_RIGHT_RELEASED | CONTROLLER_JOYPAD_BUTTON1_RELEASED | CONTROLLER_JOYPAD_BUTTON2_RELEASED
    ld  (ix + sController.Joypad.Data.PreviousButtons), CONTROLLER_JOYPAD_UP_RELEASED | CONTROLLER_JOYPAD_DOWN_RELEASED | CONTROLLER_JOYPAD_LEFT_RELEASED | CONTROLLER_JOYPAD_RIGHT_RELEASED | CONTROLLER_JOYPAD_BUTTON1_RELEASED | CONTROLLER_JOYPAD_BUTTON2_RELEASED

    and a   ; Clear carry (no transition)
    ret

; Different updates for port 1 vs. port 2
Controller_Joypad_Port1_OnUpdate:
    ; Current becomes the prev.
    ld  a, (ix + sController.Joypad.Data.CurrentButtons)
    ld  (ix + sController.Joypad.Data.PreviousButtons), a

    in  a, (IO_DATA_PORT_1)     ; Holds all data for Port 1 Joypad
    and IO_P1_JOYPAD_UP_MASK | IO_P1_JOYPAD_DOWN_MASK | IO_P1_JOYPAD_LEFT_MASK | IO_P1_JOYPAD_RIGHT_MASK | IO_P1_JOYPAD_BUTTON1_MASK | IO_P1_JOYPAD_BUTTON2_MASK
    ld  (ix + sController.Joypad.Data.CurrentButtons), a

    and a   ; Clear carry (no transition)
    ret

; Different updates for port 1 vs. port 2
Controller_Joypad_Port2_OnUpdate:
    ; Current becomes the prev.
    ld  a, (ix + sController.Joypad.Data.CurrentButtons)
    ld  (ix + sController.Joypad.Data.PreviousButtons), a

    in  a, (IO_DATA_PORT_1)     ; Holds Up & Down dirs for Port 2 Joypad
    ld  c, a
    in  a, (IO_DATA_PORT_2)     ; Holds remaining inputs for Port 2 Joypad
    rl  c
    rla
    rl  c
    rla
    and IO_P1_JOYPAD_UP_MASK | IO_P1_JOYPAD_DOWN_MASK | IO_P1_JOYPAD_LEFT_MASK | IO_P1_JOYPAD_RIGHT_MASK | IO_P1_JOYPAD_BUTTON1_MASK | IO_P1_JOYPAD_BUTTON2_MASK
    ld  (ix + sController.Joypad.Data.CurrentButtons), a

    and a   ; Clear carry (no transition)
    ret

.ENDS


.ENDIF  ;__CONTROLLER_JOYPAD_ASM__