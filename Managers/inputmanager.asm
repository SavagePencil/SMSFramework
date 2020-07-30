.IFNDEF __INPUT_MANAGER_ASM__
.DEFINE __INPUT_MANAGER_ASM__

.INCLUDE "Utils/input.asm"
.INCLUDE "Utils/controller.asm"

; Maintain a copy of the I/O status.
.STRUCT sIOShadow
    ControlPort     DB
.ENDST

; Regions
.ENUMID 0 EXPORT
.ENUMID REGION_JAPAN
.ENUMID REGION_EXPORT

; System type
.ENUMID 0 EXPORT
.ENUMID SYSTEM_TYPE_SMS1

;==============================================================================
; The Input Manager maintains a local copy of I/O state so that code can query
; and modify the current state.  It maintains controller state through an
; abstraction layer, giving the application access without having to deal
; with the underlying implementation. 
;==============================================================================
.STRUCT sInputManager
    ; Maintain a shadow copy of each of the VDP registers
    IOPortState INSTANCEOF sIOShadow

    ; Maintain instances of each controller
    Controller1 INSTANCEOF sController
    Controller2 INSTANCEOF sController

    ; Region (US, JP, etc.)
    Region      DB

    ; System Type (SMS, Genesis, etc.)
    SystemType  DB
.ENDST

.RAMSECTION "Input Manager" SLOT 3
    gInputManager INSTANCEOF sInputManager
.ENDS 

.SECTION "Input Manager Init" FREE
;==============================================================================
; InputManager_Init
; Initializes the global InputManager.
; INPUTS:  None
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
InputManager_Init:
    ; Start with all pins as inputs
    ld      a, IO_CONTROL_PORT_P1_TR_DIR_MASK | IO_CONTROL_PORT_P1_TH_DIR_MASK | IO_CONTROL_PORT_P2_TR_DIR_MASK | IO_CONTROL_PORT_P2_TH_DIR_MASK
    call    InputManager_SetIOControlPortImmediate

    ; TODO:  Determine region
    ld      a, REGION_EXPORT
    ld      (gInputManager.Region), a

    ; TODO:  Determine system type
    ld      a, SYSTEM_TYPE_SMS1
    ld      (gInputManager.SystemType), a

    ; Start with no controllers
    and     a                           ; 0 == Port 1
    ld      b, CONTROLLER_TYPE_NONE
    ld      hl, Controller_None_State
    call    InputManager_SetController

    ld      a, 1                        ; 1 == Port 2
    ld      b, CONTROLLER_TYPE_NONE
    ld      hl, Controller_None_State
    call    InputManager_SetController

    ret
.ENDS

.SECTION "Input Manager OnUpdate" FREE
;==============================================================================
; InputManager_OnUpdate
; Updates the global InputManager, ticking any controllers.
; INPUTS:  None
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
InputManager_OnUpdate:
    ld      ix, gInputManager.Controller1.ControllerFSM
    call    FSM_IX@OnUpdate

    ld      ix, gInputManager.Controller2.ControllerFSM
    call    FSM_IX@OnUpdate

    ret
.ENDS

.SECTION "Input Manager Set Controller Type" FREE
;==============================================================================
; InputManager_SetController
; Assigns the controller to the port in question, and initializes it.
; INPUTS:   A:  Port # (0 == Port 1, 1 == Port 2)
;           B:  Controller type
;          HL:  Initial state for controller
; OUTPUTS:  None
; Potentially affects all registers
;==============================================================================
InputManager_SetController:
    ld  iy, gInputManager.Controller1
    ld  ix, gInputManager.Controller1.ControllerFSM
    and a   ; Check port
    jr  z, __InputManager_SetController_PortDetermined

    ; Must be port #2
    ld  iy, gInputManager.Controller2
    ld  ix, gInputManager.Controller2.ControllerFSM
__InputManager_SetController_PortDetermined:
    ; Store the controller type.
    ld  (iy + sController.ControllerType), b

    ; Initialize the FSM.
    call FSM_IX@Init
    ret

.ENDS

.SECTION "Input Manager Set IO Control Port Immediate" FREE
;==============================================================================
; InputManager_SetIOControlPortImmediate
; Sets the IO Control port, and preserves in shadow.
; INPUTS:   A:  Combination of IO_CONTROL_PORT* flags
; OUTPUTS:  None
; Does not alter any registers.
;==============================================================================
InputManager_SetIOControlPortImmediate:
    ld  (gInputManager.IOPortState.ControlPort), a
    out (IO_CONTROL_PORT), a
    ret
.ENDS

.ENDIF ;__INPUT_MANAGER_ASM__