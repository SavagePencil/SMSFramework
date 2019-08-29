.include "vdpregisters.asm"
.include "vdpmemorymap.asm"

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

.DEFINE VDP_PATTERN_TABLE_START                         $0000  ; Constant
.DEFINE VDP_PATTERN_TABLE_SIZE                          $3800  ; Constant
.DEFINE VDP_NAMETABLE_SIZE                              $0700  ; 1792 bytes
.DEFINE VDP_SAT_SIZE                                    $0100  ; Includes the gap
.DEFINE VDP_SAT_UNUSED_GAP_LOC                          VDP_SAT_START_LOC + $0040
.DEFINE VDP_SAT_UNUSED_GAP_SIZE                         $40    ; 64 bytes
.DEFINE VDP_SAT_SECOND_HALF_LOC                         VDP_SAT_START_LOC + $0080
.DEFINE VDP_SAT_SECOND_HALF_SIZE                        $80    ; 128 bytes

.DEFINE VDP_PALETTE_NUM_PALETTES                        2       ; BG & Sprite
.DEFINE VDP_PALETTE_ENTRIES_PER_PALETTE                 16
.DEFINE VDP_PALETTE_BYTES_PER_ENTRY                     1       ; --BBGGRR
.DEFINE VDP_PALETTE_BG_PALETTE_INDEX                    0       ; BG palettes go first
.DEFINE VDP_PALETTE_SPRITE_PALETTE_INDEX                16      ; ...then sprite
.DEFINE VDP_PALETTE_BLUE_SHIFT                          4       ; --BB ----
.DEFINE VDP_PALETTE_BLUE_MASK                           3 << VDP_PALETTE_BLUE_SHIFT
.DEFINE VDP_PALETTE_GREEN_SHIFT                         2       ; ---- GG--
.DEFINE VDP_PALETTE_GREEN_MASK                          3 << VDP_PALETTE_GREEN_SHIFT
.DEFINE VDP_PALETTE_RED_SHIFT                           0       ; ---- --RR
.DEFINE VDP_PALETTE_RED_MASK                            3 << VDP_PALETTE_RED_SHIFT

.DEFINE VDP_TILE_PIXEL_WIDTH                            8
.DEFINE VDP_TILE_PIXEL_HEIGHT                           8
.DEFINE VDP_TILE_SIZE                                   32      ; 8*8 * 4bpp = 32 bytes
.DEFINE VDP_TILE_BITPLANES                              4
.DEFINE VDP_TILE_LSB                                    0       ; Bit plane 0
.DEFINE VDP_TILE_MSB                                    3       ; Bit plane 3

.DEFINE VDP_NAMETABLE_NUMCOLS                           32
.DEFINE VDP_NAMETABLE_NUMROWS                           28
.DEFINE VDP_NAMETABLE_NUMVISIBLEROWS                    24

.DEFINE VDP_NAMETABLE_ENTRY_BANKSELECT_SHIFT            0
.DEFINE VDP_NAMETABLE_ENTRY_USE_HIGH_BANK               1 << VDP_NAMETABLE_ENTRY_BANKSELECT_SHIFT
.DEFINE VDP_NAMETABLE_ENTRY_HFLIP_SHIFT                 1
.DEFINE VDP_NAMETABLE_ENTRY_HFLIP                       1 << VDP_NAMETABLE_ENTRY_HFLIP_SHIFT
.DEFINE VDP_NAMETABLE_ENTRY_VFLIP_SHIFT                 2
.DEFINE VDP_NAMETABLE_ENTRY_VFLIP                       1 << VDP_NAMETABLE_ENTRY_VFLIP_SHIFT
.DEFINE VDP_NAMETABLE_ENTRY_PALSELECT_SHIFT             3
.DEFINE VDP_NAMETABLE_ENTRY_USE_SPRITE_PAL              1 << VDP_NAMETABLE_ENTRY_PALSELECT_SHIFT
.DEFINE VDP_NAMETABLE_ENTRY_PRIORITYSELECT_SHIFT        4
.DEFINE VDP_NAMETABLE_ENTRY_BGPRIORITY                  1 << VDP_NAMETABLE_ENTRY_PRIORITYSELECT_SHIFT
.DEFINE VDP_NAMETABLE_USERBITS_SHIFT                    5
.DEFINE VDP_NAMETABLE_USERBITS_MASK                     7 << VDP_NAMETABLE_USERBITS_SHIFT

;==============================================================================
; VDP Memory Summary:
; * The Palette lives in CRAM.  The VDP has 32 entries for palette entries.  
;   This is stored in separate write-only CRAM memory.
;   It has the following layout:
;    + SMS:  1 byte per entry:  --BBGGRR.  6 bits per entry.
;    + GG:  2 bytes per entry:  ----BBBB GGGGRRRR.  12 bits per entry.
;   There are two palettes of 16 entries each:
;    + Entries 0..15 cannot be used by Sprites, only the BG.
;    + Entries 16..31 can be used by either Sprites or the BG.
; * The VDP has 16K (0x4000) of VRAM that is shared by the following:
;    + The Sprite Attribute Table (SAT):                256 bytes (ish)
;    + The Name Table (usually a 32x28 screen map):    1792 bytes
;    + The Pattern Table (~448 tiles, 32 bytes each): 14336 bytes
; * The Sprite Attribute Table (SAT) is in VRAM and holds data for 64 sprites.  
;   It can be located at any 256-byte boundary (e.g., $0000, $0100, etc.).
;   It contains the following data for each sprite:
;    + The Y position (1 byte)
;    + The X position (1 byte)
;    + The Tile Index (1 byte)
;   ...it holds them in a block of 256 bytes, with a gap of 64 unused bytes 
;   in the middle:
;      Byte Offset   Meaning
;         0x00       Sprite #0 Y pos
;         0x01       Sprite #1 Y pos
;          .
;          .
;         0x3F       Sprite #63 Y pos
;         0x40       <Unused>
;          .
;          .
;         0x7F       <End of unused section>
;         0x80       Sprite #0 X pos
;         0x81       Sprite #0 Tile Index
;         0x82       Sprite #1 X pos
;         0x83       Sprite #1 Tile Index
;          .
;          .
;         0xFE       Sprite #63 X Pos
;         0xFF       Sprite #63 Tile Index
; * The Name Table lives in VRAM and holds data for the background.  This is
;   usually a 32x28 grid of tiles, with only 32x24 tiles visibile at any
;   given time.
;   For the standard 256x192 resolution mode, it can be located at any 
;   2K-byte boundary (e.g., 0x0800, 0x1000, etc.).
;   Each cell is 2 bytes.  32x28x2 bytes = 1792 bytes.
;   It contains the following data for each cell of the grid:
;     + Bits 0-8:   Index of tile to use (0..512) from the Pattern Table
;     + Bit 9:      Horizontally flip the tile?
;     + Bit 10:     Vertically flip the tile?
;     + Bit 11:     Should this use the BG palette, or the Sprite palette?
;     + Bit 12:     Should this tile be in front of, or behind Sprites?
;     + Bits 13-15: Unused.
; * The Pattern Table lives in VRAM and holds the tile data.  
;   In theory, it could hold 512 tiles worth of data, but because of the
;   SAT and the Name Table, this is reduced to 448 tiles.  Each tile is
;   32 bytes (8 pixels wide x 8 pixels tall x 4 bits per pixel).
;   We get a final size of (32 bytes x 512 tiles) - (SAT + Name Table) or
;   16384 - (256 + 1792) = 14336 bytes.
;   The Pattern Table MUST begin at 0x0000 in VRAM.
;   Patterns are 4 planes of 8 bits each, and look like this:
;     + Bits 0..7:   Least-significant bits of palette entry, right-to-left
;     + Bits 8..15:  Bit 1 of each pixel's palette entry.
;     + Bits 16..23: Bit 2 of each pixel's palette entry.
;     + Bits 24..31: Bit 3 of each pixel's palette entry.
;==============================================================================

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

;==============================================================================
; Tiles are 4bpp arranged in bitplanes, like so:
; 
;                    76543210  <- Rightmost pixel
; Row 0, Bitplane 0  0  
; Row 0, Bitplane 1  1
; Row 0, Bitplane 2  0
; Row 0, Bitplane 3  1
;        .
;        .
;        .
; Row 7, Bitplane 3
;
; The upper left pixel is color %1010. 
;==============================================================================
.STRUCT Tile
    .UNION
        Data            DSB 32  ; 32 bytes of data, if you know what you're doing.
    .NEXTU
        Row0            DSB 4   ; Each row is spread across 4 bitplanes
        Row1            DSB 4
        Row2            DSB 4
        Row3            DSB 4
        Row4            DSB 4
        Row5            DSB 4
        Row6            DSB 4
        Row7            DSB 4
        Row8            DSB 4
    .NEXTU
        Row0Bitplane0   DB      ; Super granular   
        Row0Bitplane1   DB
        Row0Bitplane2   DB
        Row0Bitplane3   DB

        Row1Bitplane0   DB      
        Row1Bitplane1   DB
        Row1Bitplane2   DB
        Row1Bitplane3   DB

        Row2Bitplane0   DB      
        Row2Bitplane1   DB
        Row2Bitplane2   DB
        Row2Bitplane3   DB

        Row3Bitplane0   DB      
        Row3Bitplane1   DB
        Row3Bitplane2   DB
        Row3Bitplane3   DB

        Row4Bitplane0   DB      
        Row4Bitplane1   DB
        Row4Bitplane2   DB
        Row4Bitplane3   DB

        Row5Bitplane0   DB      
        Row5Bitplane1   DB
        Row5Bitplane2   DB
        Row5Bitplane3   DB

        Row6Bitplane0   DB      
        Row6Bitplane1   DB
        Row6Bitplane2   DB
        Row6Bitplane3   DB

        Row7Bitplane0   DB      
        Row7Bitplane1   DB
        Row7Bitplane2   DB
        Row7Bitplane3   DB
    .ENDU
.ENDST

;==============================================================================
; A nametable entry is 16-bits and comprised of two things:
;   byte 0: tile index
;   byte 1: <user flags><priority><palette><vflip><hflip><bank select>
;
; You can think of the bank select + tile index as a 9th bit for 0..511.
;==============================================================================
.STRUCT NameTableEntry
    .UNION
        Data            DW
    .NEXTU
        TileIndex       DB
        Flags           DB
    .ENDU
.ENDST

.DEFINE VDP_NAMETABLE_ROWSIZE_IN_BYTES                  VDP_NAMETABLE_NUMCOLS * _sizeof_NameTableEntry


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
; Destroys D, HL.
;==============================================================================
VDPManager_WriteRegisterImmediate:
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

    ; Now output to the VDP
    ld      a, e
    out     (VDP_CONTROL_PORT), a               ; Set pal entry in low byte
    ld      a, VDP_COMMAND_MASK_CRAM_WRITE      ; The command
    out     (VDP_CONTROL_PORT), a               ; Send the command

    ; Emit the color
    ld      a, c
    out     (VDP_DATA_PORT), a
    ret
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

.SECTION "VDP Manager Upload Tile Data" FREE
;==============================================================================
; VDPManager_UploadTileDataToTilePos
; Uploads the tile data starting at the tile index specified.  Assumes data is
; all 4bpp (no bitplane skips, etc.)
; INPUTS:  DE:  Start of tile data
;          BC:  Size of tile data, in bytes
;          HL:  Index of tile to begin at (16-bit because it's 0..448)
; OUTPUTS:  HL points to end of data.  D, B are 0.  C is the Data Port.
;          Destroys B, C, D, E
;==============================================================================
VDPManager_UploadTileDataToTilePos:
    ; Find offset in VRAM.
    .REPT 5         ; 2 ^ 5 == 32, which is how many bytes there are in a tile.
        add hl, hl
    .ENDR
    ex      de, hl  ; HL now points to tile data, DE points to VRAM loc
    jp      VDPManager_UploadDataToVRAMLoc

.ENDS

.SECTION "VDP Manager Upload Data Routines" FREE
;==============================================================================
; VDPManager_UploadDataToVRAMLoc
; Uploads data starting at the VRAM loc specified.
; INPUTS:  DE:  VRAM loc to write to
;          BC:  Size of data, in bytes
;          HL:  Pointer to src data
; OUTPUTS:  HL points to end of data.  D, B are 0.  C is the Data Port.
;          Destroys B, C, D, E
;==============================================================================
VDPManager_UploadDataToVRAMLoc:
    ; Set the VRAM pointer.
    ld      a, e
    out     (VDP_CONTROL_PORT), a           ; Set low byte of address in first byte
    ld      a, d
    or      VDP_COMMAND_MASK_VRAM_WRITE
    out     (VDP_CONTROL_PORT), a           ; Set high byte of address + command

    ld      d, b
    ld      e, c

    ; FALL THROUGH

;==============================================================================
; VDPManager_UploadData_VDPPtrSet
; General-purpose method to upload up to 64K of data to the VDP (VRAM or CRAM).  
; It's assumed that the VDP is already prepped for writing.
; INPUTS:  HL:  Start of data to write
;          DE:  Size of data size to upload
; OUTPUTS:  HL points to end of data.  D, B are 0.  C is the Data Port.
;          Destroys B, C, D, E
;==============================================================================
VDPManager_UploadData_VDPPtrSet:
    ; Ensures we roll over correctly:  
    ;   If DE == $00FF, we only want one otir.
    ;   If DE == $0100, we *also* only want one otir.
    ;   If DE == $0101, we want two otirs (one for 1 byte, one for 256 bytes)
    ld  b, e                                ; B gets low byte count
    dec de
    inc d

    ld  c, VDP_DATA_PORT                    ; Port for OTIR        
VDPManager_UploadData_VDPPtrSet_WriteLoop:
    otir
    dec d
    jp  nz, VDPManager_UploadData_VDPPtrSet_WriteLoop
    ret
.ENDS

.SECTION "VDP Manager Upload Name Table Entry" FREE
;==============================================================================
; VDPManager_UploadNameTableEntry
; Uploads a single entry to the name table, at the column and row specfied.
; INPUTS:  B:   Row
;          C:   Column (range 0..31)
;          DE:  Name Table entry
; OUTPUTS: HL = VRAM address
;          Destroys A, C
;==============================================================================
VDPManager_UploadNameTableEntry:
    ; Calculate the VRAM position.

    ; Remember that b << 6 is easier to rotate right twice
    ; H = 00rr rrrr       ; High byte = Row * 64
    ; L = rrcc cccc       ; Low byte = low bits from Row * 64 | column
    ; H |= NameTable|Cmd  ; Add in nametable offset and "write to VRAM" command

    ; Start with row.  This should be VDP_NAMETABLE_ROWSIZE_IN_BYTES * row.
    xor     a
    srl     h           ; Low bit of B -> CY
    rra                 ; A = r000 0000
    srl     h           ; Low bit of B -> CY
    rra                 ; A = rr00 0000
    sla     l           ; C = col * 2 bytes per entry
    or      l           ; A = rrcc ccc0
    ld      l, a
    ld      a, (VDP_NAMETABLE_START_LOC >> 8) | VDP_COMMAND_MASK_VRAM_WRITE
    or      h
    ld      h, a        ; H = Nametable + row * 64


    ; We've calculated the offset, so actually write it.
    ; Prep the VRAM for writing.
    ld      c, VDP_CONTROL_PORT
    out     (c), l           ; Set low byte of address in first byte
    out     (c), h           ; Set high byte of address + command

    ; Now write the data.
    ld      c, VDP_DATA_PORT
    out     (c), e
    out     (c), d
    ret
.ENDS