.IFNDEF __CONTROLLER_JOYPAD_ASM__
.DEFINE __CONTROLLER_JOYPAD_ASM__

.STRUCT ControllerData_Joypad
    CurrentButtons  DB
    PreviousButtons DB
.ENDST

.DEFINE CONTROLLER_JOYPAD_UP_RELEASED       1 << 0
.DEFINE CONTROLLER_JOYPAD_DOWN_RELEASED     1 << 1
.DEFINE CONTROLLER_JOYPAD_LEFT_RELEASED     1 << 2
.DEFINE CONTROLLER_JOYPAD_RIGHT_RELEASED    1 << 3
.DEFINE CONTROLLER_JOYPAD_BUTTON1_RELEASED  1 << 4
.DEFINE CONTROLLER_JOYPAD_BUTTON2_RELEASED  1 << 5

.SECTION "Controller Joypad" FREE

; State for joypad in port #1
.DSTRUCT Controller_Joypad_Port1_State INSTANCEOF State VALUES:
    OnEnter:    .DW Controller_Joypad_OnEnter
    OnExit:     .DW Controller_Joypad_OnExit
    OnEvent:    .DW Controller_Joypad_OnEvent
    OnUpdate:   .DW Controller_Joypad_Port1_OnUpdate
.ENDST

; State for joypad in port #2
.DSTRUCT Controller_Joypad_Port2_State INSTANCEOF State VALUES:
    OnEnter:    .DW Controller_Joypad_OnEnter
    OnExit:     .DW Controller_Joypad_OnExit
    OnEvent:    .DW Controller_Joypad_OnEvent
    OnUpdate:   .DW Controller_Joypad_Port2_OnUpdate
.ENDST


Controller_Joypad_OnEnter:
    ld  (ix + Controller.Joypad.Data.CurrentButtons), CONTROLLER_JOYPAD_UP_RELEASED | CONTROLLER_JOYPAD_DOWN_RELEASED | CONTROLLER_JOYPAD_LEFT_RELEASED | CONTROLLER_JOYPAD_RIGHT_RELEASED | CONTROLLER_JOYPAD_BUTTON1_RELEASED | CONTROLLER_JOYPAD_BUTTON2_RELEASED
    ld  (ix + Controller.Joypad.Data.PreviousButtons), CONTROLLER_JOYPAD_UP_RELEASED | CONTROLLER_JOYPAD_DOWN_RELEASED | CONTROLLER_JOYPAD_LEFT_RELEASED | CONTROLLER_JOYPAD_RIGHT_RELEASED | CONTROLLER_JOYPAD_BUTTON1_RELEASED | CONTROLLER_JOYPAD_BUTTON2_RELEASED

    and a   ; Clear carry (no transition)
    ret

Controller_Joypad_OnExit:
    ret

Controller_Joypad_OnEvent:
    and a   ; Clear carry (no transition)
    ret

; Different updates for port 1 vs. port 2
Controller_Joypad_Port1_OnUpdate:
    ; Current becomes the prev.
    ld  a, (ix + Controller.Joypad.Data.CurrentButtons)
    ld  (ix + Controller.Joypad.Data.PreviousButtons), a

    in  a, (IO_DATA_PORT_1)     ; Holds all data for Port 1 Joypad
    and IO_P1_JOYPAD_UP_MASK | IO_P1_JOYPAD_DOWN_MASK | IO_P1_JOYPAD_LEFT_MASK | IO_P1_JOYPAD_RIGHT_MASK | IO_P1_JOYPAD_BUTTON1_MASK | IO_P1_JOYPAD_BUTTON2_MASK
    ld  (ix + Controller.Joypad.Data.CurrentButtons), a

    and a   ; Clear carry (no transition)
    ret

; Different updates for port 1 vs. port 2
Controller_Joypad_Port2_OnUpdate:
    ; Current becomes the prev.
    ld  a, (ix + Controller.Joypad.Data.CurrentButtons)
    ld  (ix + Controller.Joypad.Data.PreviousButtons), a

    in  a, (IO_DATA_PORT_1)     ; Holds Up & Down dirs for Port 2 Joypad
    ld  c, a
    in  a, (IO_DATA_PORT_2)     ; Holds remaining inputs for Port 2 Joypad
    rl  c
    rla
    rl  c
    rla
    and IO_P1_JOYPAD_UP_MASK | IO_P1_JOYPAD_DOWN_MASK | IO_P1_JOYPAD_LEFT_MASK | IO_P1_JOYPAD_RIGHT_MASK | IO_P1_JOYPAD_BUTTON1_MASK | IO_P1_JOYPAD_BUTTON2_MASK
    ld  (ix + Controller.Joypad.Data.CurrentButtons), a

    and a   ; Clear carry (no transition)
    ret

.ENDS


.ENDIF  ;__CONTROLLER_JOYPAD_ASM__