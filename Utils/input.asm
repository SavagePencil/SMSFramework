.IFNDEF __INPUT_ASM__
.DEFINE __INPUT_ASM__

.DEFINE IO_CONTROL_PORT                     $3F     ; Sets the behavior of I/O, defining which pins are inputs and which are outputs.

.DEFINE IO_CONTROL_PORT_P1_TR_DIR_MASK      1 << 0  ; Is the TR pin of player 1 being used as an input, or an output? 1 == as input.
.DEFINE IO_CONTROL_PORT_P1_TH_DIR_MASK      1 << 1  ; TH pin direction for player 1
.DEFINE IO_CONTROL_PORT_P2_TR_DIR_MASK      1 << 2  ; TR pin direction for player 2
.DEFINE IO_CONTROL_PORT_P2_TH_DIR_MASK      1 << 3  ; TH pin direction for player 2

.DEFINE IO_CONTROL_PORT_P1_TR_OUTPUT_MASK   1 << 4  ; If set to an output, the value for player 1's TR pin.
.DEFINE IO_CONTROL_PORT_P1_TH_OUTPUT_MASK   1 << 5  ; If set to an output, the value for player 1's TH pin.
.DEFINE IO_CONTROL_PORT_P2_TR_OUTPUT_MASK   1 << 6  ; If set to an output, the value for player 2's TR pin.
.DEFINE IO_CONTROL_PORT_P2_TH_OUTPUT_MASK   1 << 7  ; If set to an output, the value for player 2's TH pin.

; There are two ports for getting data back in.  They both hold data for both player 1 and player 2, but this is totally dependent
; on which controller is being used.
.DEFINE IO_DATA_PORT_1                      $DC
.DEFINE IO_DATA_PORT_1_P1_TL_MASK           1 << 4  ; Value for player 1's TL pin
.DEFINE IO_DATA_PORT_1_P1_TR_MASK           1 << 5  ; Value for player 1's TR pin
.DEFINE IO_DATA_PORT_1_P1_MASK              $3F     ; Mask for the bits relevant to player 1 in this port.
.DEFINE IO_DATA_PORT_1_P2_MASK              $C0     ; Mask for the bits relevant to player 2 in this port.

.DEFINE IO_DATA_PORT_2                      $DD
.DEFINE IO_DATA_PORT_2_P2_TL_MASK           1 << 2  ; Value for player 2's TL pin
.DEFINE IO_DATA_PORT_2_P2_TR_MASK           1 << 3  ; Value for player 2's TR pin
.DEFINE IO_DATA_PORT_2_P1_TH_MASK           1 << 6  ; Value for player 2's TH pin
.DEFINE IO_DATA_PORT_2_P2_TH_MASK           1 << 7  ; Value for player 2's TH pin
.DEFINE IO_DATA_PORT_2_P1_MASK              $40     ; Mask for the bits relevant to player 1 in this port.
.DEFINE IO_DATA_PORT_2_P2_MASK              $8F     ; Mask for the bits relevant to player 2 in this port

.DEFINE IO_DATA_PORT_2_RESET_MASK           1 << 4  ; Reset button pin
.DEFINE IO_DATA_PORT_2_CONT_MASK            1 << 5  ; Cartridge Slot CONT pin

; Joypads are pretty straightforward.
;         IO Data 1       IO Data 2
; bit 7  P2 Down             N/A
; bit 6  P2 Up               N/A
; bit 5  P1 Button 2         N/A
; bit 4  P1 Button 1         N/A
; bit 3  P1 Right        P2 Button 2
; bit 2  P1 Left         P2 Button 1
; bit 1  P1 Down         P2 Right
; bit 0  P1 Up           P2 Left
.DEFINE IO_P1_JOYPAD_UP_MASK                1 << 0
.DEFINE IO_P1_JOYPAD_DOWN_MASK              1 << 1
.DEFINE IO_P1_JOYPAD_LEFT_MASK              1 << 2
.DEFINE IO_P1_JOYPAD_RIGHT_MASK             1 << 3
.DEFINE IO_P1_JOYPAD_BUTTON1_MASK           IO_DATA_PORT_1_P1_TL_MASK
.DEFINE IO_P1_JOYPAD_BUTTON2_MASK           IO_DATA_PORT_1_P1_TR_MASK

.DEFINE IO_P2_JOYPAD_UP_MASK                1 << 6                      ; In IO Data 1
.DEFINE IO_P2_JOYPAD_DOWN_MASK              1 << 7                      ; In IO Data 1
.DEFINE IO_P2_JOYPAD_LEFT_MASK              1 << 0                      ; In IO Data 2
.DEFINE IO_P2_JOYPAD_RIGHT_MASK             1 << 1                      ; In IO Data 2      
.DEFINE IO_P2_JOYPAD_BUTTON1_MASK           IO_DATA_PORT_2_P2_TL_MASK   ; In IO Data 2
.DEFINE IO_P2_JOYPAD_BUTTON2_MASK           IO_DATA_PORT_2_P2_TR_MASK   ; In IO Data 2

; The light gun is a little more complicated.
; When the trigger is pulled, it needs to scan to see when the light sensor
; picks up a signal.
;         IO Data 1        IO Data 2
; bit 7      N/A        P2 Light Sensor
; bit 6      N/A        P1 Light Sensor
; bit 5      N/A              N/A
; bit 4    P1 Trigger         N/A
; bit 3      N/A              N/A
; bit 2      N/A           P2 Trigger
; bit 1      N/A              N/A
; bit 0      N/A              N/A
.DEFINE IO_P1_LIGHTGUN_TRIGGER_MASK        IO_DATA_PORT_1_P1_TL_MASK    ; In IO Data 1
.DEFINE IO_P1_LIGHTGUN_SENSOR_MASK         IO_DATA_PORT_2_P1_TH_MASK    ; In IO Data 2
.DEFINE IO_P2_LIGHTGUN_TRIGGER_MASK        IO_DATA_PORT_2_P2_TL_MASK    ; In IO Data 2
.DEFINE IO_P2_LIGHTGUN_SENSOR_MASK         IO_DATA_PORT_2_P2_TH_MASK    ; In IO Data 2

.ENDIF  ;__INPUT_ASM__