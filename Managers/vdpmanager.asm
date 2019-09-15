.INCLUDE "Utils/vdp.asm"
.INCLUDE "Utils/vdpregisters.asm"

; Maintains a copy of the VDP registers
.STRUCT VDPRegisterShadow
    .UNION
        Register0           DB
    .NEXTU
        VideoModeControl1   DB      ; Interrupts, scroll behavior, etc.
    .ENDU

    .UNION
        Register1  DB
    .NEXTU
        VideoModeControl2   DB      ; Sprites, display state, etc.
    .ENDU

    .UNION
        Register2           DB
    .NEXTU
        NameTableAddress    DB      ; Where the name table (tilemap) lives
    .ENDU

    .UNION
        Register3  DB
    .NEXTU
        ColorTableAddress   DB      ; Where colors live (no effect)
    .ENDU

    .UNION
        Register4  DB
    .NEXTU
        BGPatternAddress    DB      ; Where BG patterns live (no effect)
    .ENDU

    .UNION
        Register5  DB
    .NEXTU
        SpriteTableAddress  DB      ; Where data on active sprites lives
    .ENDU

    .UNION
        Register6  DB
    .NEXTU
        SpriteTileAddress   DB      ; Where sprite tiles originate
    .ENDU

    .UNION
        Register7           DB
    .NEXTU
        OverscanColor       DB      ; Which sprite pal entry is the overscan
    .ENDU

    .UNION
        Register8           DB
    .NEXTU
        ScrollX             DB      ; Horizontal scroll
    .ENDU

    .UNION
        Register9           DB
    .NEXTU
        ScrollY             DB      ; Vertical scroll
    .ENDU
    
    .UNION
        Register10          DB
    .NEXTU
        HBlankCounter       DB      ; Line counter for HBlank timing
    .ENDU
.ENDST

.STRUCT VDPPalette
    BGOnlyPalette DSB 16        ; First palette can only be used by the BG
    SpritePalette DSB 16        ; Second palette can be used by sprite or BG
.ENDST

;==============================================================================
; The VDP Manager maintains a local copy of registers so that code can query
; current state without having to go to VRAM (or when the values themselves
; aren't queryable, as in the case of CRAM).
;==============================================================================
.STRUCT VDPManager
    ; Maintain a shadow copy of each of the VDP registers
    Registers INSTANCEOF VDPRegisterShadow

    ; Maintain a copy of the palettes, since CRAM can't be read
    Palette INSTANCEOF VDPPalette
.ENDST

.RAMSECTION "VDP Manager" SLOT 3
    gVDPManager INSTANCEOF VDPManager
.ENDS 

.SECTION "VDP Manager Init" FREE
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
    call    VDPManager_WriteRegisterImmediate
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

    ; Clear the palette.
    ld      b, VDP_PALETTE_NUM_PALETTES * VDP_PALETTE_ENTRIES_PER_PALETTE
    ld      c, 0    ; Color 0
-:
    ld      e, b
    dec     e       ; Entry is 0..31
    call    VDPManager_SetPaletteEntryImmediate

    djnz -
    ret

; Some VDP defaults.
VDPDefaults_Begin:
    ; R0:  Start in standard SMS mode 4.  No interrupts.
    .db VDP_COMMMAND_MASK_REGISTER0, VDP_REGISTER0_REQUIRED_MASK | VDP_REGISTER0_MODE_4_SELECT
    ; R1:  Display is OFF.  Regular 256x192 mode.
    .db VDP_COMMMAND_MASK_REGISTER1, VDP_REGISTER1_REQUIRED_MASK
    ; R2:  Set Name Table to loc specified in VDP Memory Map
    .db VDP_COMMMAND_MASK_REGISTER2, VDP_REGISTER2_REQUIRED_MASK | ( VDP_NAMETABLE_START_LOC >> 10 )
    ; R3:  Nothing special
    .db VDP_COMMMAND_MASK_REGISTER3, VDP_REGISTER3_REQUIRED_MASK
    ; R4:  Nothing special
    .db VDP_COMMMAND_MASK_REGISTER4, VDP_REGISTER4_REQUIRED_MASK
    ; R5:  SAT at loc indicated from the VDP Memory Map.
    .db VDP_COMMMAND_MASK_REGISTER5, VDP_REGISTER5_REQUIRED_MASK | ( VDP_SAT_START_LOC >> 7 )
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
.ENDS

.SECTION "VDP Manager Write Register Immediate" FREE
;==============================================================================
; VDPManager_WriteRegisterImmediate
; Immediately sets a register value, and maintains a shadow copy of it.
; INPUTS:  E:  Register to set
;          A:  Value to set
; OUTPUTS:  None
; Destroys D, HL, A.
;==============================================================================
VDPManager_WriteRegisterImmediate:
    ; Store to the shadow register first.
    ld      d, 0
    ld      hl, gVDPManager.Registers
    add     hl, de
    ld      (hl), a

    jp      VDP_WriteRegister
.ENDS

.SECTION "VDP Manager Set Palette Entry Immediate" FREE
;==============================================================================
; VDPManager_SetPaletteEntryImmediate
; Immediately sets a palette entry, and maintains a shadow copy of it.
; INPUTS:  E:  Entry to set (0..31)
;          C:  Color value to set
; OUTPUTS:  None
; Destroys A, D, HL.
;==============================================================================
VDPManager_SetPaletteEntryImmediate:
    ; Store to the shadow register first
    ld      d, 0
    ld      hl, gVDPManager.Palette
    add     hl, de
    ld      (hl), c

    jp      VDP_SetPaletteEntry
.ENDS

.SECTION "VDP Manager Set Palette Entries Immediate" FREE
;==============================================================================
; VDPManager_SetPaletteEntriesImmediate
; Immediately sets a series of palette entries, and updates shadow entries.
; INPUTS:  C:  Index of first palette entry to fill
;          A:  Count of entries to update
;          DE: Pointer to palette data
; OUTPUTS:  B is 0
; Destroys A, BC, DE, HL.
;==============================================================================
VDPManager_SetPaletteEntriesImmediate
    ; Get index to shadow registers.
    ld      hl, gVDPManager.Palette
    ld      b, 0
    add     hl, bc  ; HL points to the first shadow register

    ld      b, a    ; Prep our counter

    ; Now output to the VDP
    ld      a, c
    out     (VDP_CONTROL_PORT), a               ; Set pal entry in low byte
    ld      a, VDP_COMMAND_MASK_CRAM_WRITE      ; The command
    out     (VDP_CONTROL_PORT), a               ; Send the command

    ; Now set the color values.
-:
    ld      a, (de)                             ; Get the color
    ld      (hl), a                             ; Set the shadow register
    out     (VDP_DATA_PORT), a
    inc     de
    inc     hl
    djnz    -
    ret
.ENDS
