.include "vdpregisters.asm"

.DEFINE VDP_VCOUNTER_PORT                               $7E
.DEFINE VDP_HCOUNTER_PORT                               $7F

.DEFINE VDP_DATA_PORT                                   $BE
.DEFINE VDP_CONTROL_PORT                                $BF

.DEFINE VDP_COMMAND_MASK_VRAM_READ                      0 << 6
.DEFINE VDP_COMMAND_MASK_VRAM_WRITE                     1 << 6
.DEFINE VDP_COMMAND_MASK_REGISTER_WRITE                 2 << 6
.DEFINE VDP_COMMAND_MASK_CRAM_WRITE                     3 << 6

.DEFINE VDP_COMMMAND_MASK_REGISTER0                     0
.DEFINE VDP_COMMMAND_MASK_REGISTER1                     1
.DEFINE VDP_COMMMAND_MASK_REGISTER2                     2
.DEFINE VDP_COMMMAND_MASK_REGISTER3                     3
.DEFINE VDP_COMMMAND_MASK_REGISTER4                     4
.DEFINE VDP_COMMMAND_MASK_REGISTER5                     5
.DEFINE VDP_COMMMAND_MASK_REGISTER6                     6
.DEFINE VDP_COMMMAND_MASK_REGISTER7                     7
.DEFINE VDP_COMMMAND_MASK_REGISTER8                     8
.DEFINE VDP_COMMMAND_MASK_REGISTER9                     9
.DEFINE VDP_COMMMAND_MASK_REGISTER10                    $A

; Maintains a copy of the VDP registers
.STRUCT VDPRegisterShadow
    Register0  DB
    Register1  DB
    Register2  DB
    Register3  DB
    Register4  DB
    Register5  DB
    Register6  DB
    Register7  DB
    Register8  DB
    Register9  DB
    Register10 DB
.ENDST

.STRUCT VDPPalette
    BGOnlyPalette DSB 16        ; First palette can only be used by the BG
    SpritePalette DSB 16        ; Second palette can be used by sprite or BG
.ENDST

.STRUCT VDPManager
    ; Maintain a shadow copy of each of the VDP registers
    Registers INSTANCEOF VDPRegisterShadow

    ; Maintain a copy of the palettes, since CRAM can't be read
    Palette INSTANCEOF VDPPalette
.ENDST

.RAMSECTION "VDP Manager" SLOT 3
    gVDPManager INSTANCEOF VDPManager
.ENDS 

.SECTION "VDP Manager Routines" FREE
;==============================================================================
; VDPManager_Init
; Initializes the global VDPManager.
; INPUTS:  None
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
VDPManager_Init:
    ; Initialize the VDP registers with some defaults.
    ld      hl, VDPDefaults_Begin
    ld      b, ( VDPDefaults_End - VDPDefaults_Begin ) / 2  ; Count
-:
    ld      e, (hl)
    inc     hl
    ld      a, (hl)
    inc     hl
    push    hl
    call    VDPManager_WriteRegister
    pop     hl
    djnz    -

    ; Clear the VRAM
    ; Set the VRAM address to the start, $0000, and then mask with the command
    ; to write to VRAM.
    xor     a
    out     (VDP_CONTROL_PORT), a   ; Low byte first
    ld      a, $00 | VDP_COMMAND_MASK_VRAM_WRITE
    out     (VDP_CONTROL_PORT), a   ; High bits + command

    ; Now clear 16K of VRAM.  
    ; Each write to the data port increments the address.
    xor     a
    ld      bc, $0040
-:
        out     (VDP_DATA_PORT), a
        djnz    -
    dec     c
    jr      nz, -
    ret

; Some VDP defaults.
VDPDefaults_Begin:
    ; R0:  Start in standard SMS mode 4.  No interrupts.
    .db VDP_COMMMAND_MASK_REGISTER0, VDP_REGISTER0_REQUIRED_MASK | VDP_REGISTER0_MODE_4_SELECT
    ; R1:  Display is OFF.  Regular 256x192 mode.
    .db VDP_COMMMAND_MASK_REGISTER1, VDP_REGISTER1_REQUIRED_MASK
    ; R2:  Set Name Table to 0x3800
    .db VDP_COMMMAND_MASK_REGISTER2, VDP_REGISTER2_REQUIRED_MASK | VDP_REGISTER2_NAMETABLEADDRESS_0x3800
    ; R3:  Nothing special
    .db VDP_COMMMAND_MASK_REGISTER3, VDP_REGISTER3_REQUIRED_MASK
    ; R4:  Nothing special
    .db VDP_COMMMAND_MASK_REGISTER4, VDP_REGISTER4_REQUIRED_MASK
    ; R5:  SAT at 0x3F00 (just after the name table, running to the edge of 16K)
    .db VDP_COMMMAND_MASK_REGISTER5, VDP_REGISTER5_REQUIRED_MASK | VDP_REGISTER5_SAT_BIT8 | VDP_REGISTER5_SAT_BIT9 | VDP_REGISTER5_SAT_BIT10 | VDP_REGISTER5_SAT_BIT11 | VDP_REGISTER5_SAT_BIT12 | VDP_REGISTER5_SAT_BIT13
    ; R6:  Sprite generator at 0x0000.  Sprite tiles draw from the lower 8K.
    .db VDP_COMMMAND_MASK_REGISTER6, VDP_REGISTER6_REQUIRED_MASK | VDP_REGISTER6_SPRITEGENERATOR_0x0000
    ; R7:  Use Sprite Pal Entry 0 as Overdraw color.
    .db VDP_COMMMAND_MASK_REGISTER7, VDP_REGISTER7_REQUIRED_MASK
    ; R8:  X Scroll is 0
    .db VDP_COMMMAND_MASK_REGISTER8, VDP_REGISTER8_REQUIRED_MASK
    ; R9:  Y Scroll is 0
    .db VDP_COMMMAND_MASK_REGISTER9, VDP_REGISTER9_REQUIRED_MASK
    ; R10:  Line interrupt is 0
    .db VDP_COMMMAND_MASK_REGISTER10, VDP_REGISTER10_REQUIRED_MASK
VDPDefaults_End

;==============================================================================
; VDPManager_WriteRegister
; Sets a register value, and maintains a shadow copy of it.
; INPUTS:  E:  Register to set
;          A:  Value to set
; OUTPUTS:  None
; Destroys D, HL.
;==============================================================================
VDPManager_WriteRegister:
    ; Store to the shadow register first.
    ld      d, 0
    ld      hl, gVDPManager.Registers
    add     hl, de
    ld      (hl), a

    ; Now output to the VDP
    out     (VDP_CONTROL_PORT), a               ; Data first
    ld      a, e
    or      VDP_COMMAND_MASK_REGISTER_WRITE     ; Mask in the command
    out     (VDP_CONTROL_PORT), a               ; Commands + register num
    ret

.ENDS