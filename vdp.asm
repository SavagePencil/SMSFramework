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




.STRUCT VDPManager
    Dummy   DB
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
    ld  hl, VDPDefaults_Begin
    ld  b, VDPDefaults_End - VDPDefaults_Begin
    ld  c, VDP_CONTROL_PORT
    otir
    ret

; Some VDP defaults.
VDPDefaults_Begin:
; R0:  Start in standard SMS mode 4.  No interrupts.
.db VDP_REGISTER0_REQUIRED_MASK | VDP_REGISTER0_MODE_4_SELECT, VDP_COMMAND_MASK_REGISTER_WRITE | VDP_COMMMAND_MASK_REGISTER0
; R1:  Display is OFF.  Regular 256x192 mode.
.db VDP_REGISTER1_REQUIRED_MASK, VDP_COMMAND_MASK_REGISTER_WRITE | VDP_COMMMAND_MASK_REGISTER1
; R2:  Set Name Table to 0x3800
.db VDP_REGISTER2_REQUIRED_MASK | VDP_REGISTER2_NAMETABLEADDRESS_0x3800, VDP_COMMAND_MASK_REGISTER_WRITE | VDP_COMMMAND_MASK_REGISTER2
; R3:  Nothing special
.db VDP_REGISTER3_REQUIRED_MASK, VDP_COMMAND_MASK_REGISTER_WRITE | VDP_COMMMAND_MASK_REGISTER3
; R4:  Nothing special
.db VDP_REGISTER4_REQUIRED_MASK, VDP_COMMAND_MASK_REGISTER_WRITE | VDP_COMMMAND_MASK_REGISTER4
; R5:  SAT at 0x3F00 (just after the name table, running to the edge of 16K)
.db VDP_REGISTER5_REQUIRED_MASK | VDP_REGISTER5_SAT_BIT8 | VDP_REGISTER5_SAT_BIT9 | VDP_REGISTER5_SAT_BIT10 | VDP_REGISTER5_SAT_BIT11 | VDP_REGISTER5_SAT_BIT12 | VDP_REGISTER5_SAT_BIT13, VDP_COMMAND_MASK_REGISTER_WRITE | VDP_COMMMAND_MASK_REGISTER5
; R6:  Sprite generator at 0x0000.  Sprite tiles draw from the lower 8K.
.db VDP_REGISTER6_REQUIRED_MASK | VDP_REGISTER6_SPRITEGENERATOR_0x0000, VDP_COMMAND_MASK_REGISTER_WRITE | VDP_COMMMAND_MASK_REGISTER6
; R7:  Use Sprite Pal Entry 0 as Overdraw color.
.db VDP_REGISTER7_REQUIRED_MASK, VDP_COMMAND_MASK_REGISTER_WRITE | VDP_COMMMAND_MASK_REGISTER7
; R8:  X Scroll is 0
.db VDP_REGISTER8_REQUIRED_MASK, VDP_COMMAND_MASK_REGISTER_WRITE | VDP_COMMMAND_MASK_REGISTER8
; R9:  Y Scroll is 0
.db VDP_REGISTER9_REQUIRED_MASK, VDP_COMMAND_MASK_REGISTER_WRITE | VDP_COMMMAND_MASK_REGISTER9
; R10:  Line interrupt is 0
.db VDP_REGISTER10_REQUIRED_MASK, VDP_COMMAND_MASK_REGISTER_WRITE | VDP_COMMMAND_MASK_REGISTER10
VDPDefaults_End

.ENDS