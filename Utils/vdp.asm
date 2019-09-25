.IFNDEF __VDP_ASM__
.DEFINE __VDP_ASM__

.include "Utils/vdpregisters.asm"

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

.DEFINE VDP_STATUS_PORT                                 $BF
.DEFINE VDP_STATUS_FRAME_INTERRUPT_MASK                 $80     ; Did a frame interrupt occur?
.DEFINE VDP_STATUS_SPRITE_OVERFLOW_MASK                 $40     ; > 8 sprites on a line?
.DEFINE VDP_STATUS_SPRITE_COLLISION_MASK                $20     ; Did any sprites' non-opaque pixels overlap?

.DEFINE VDP_PATTERN_TABLE_START                         $0000   ; Constant
.DEFINE VDP_PATTERN_TABLE_SIZE                          $3800   ; Constant
.DEFINE VDP_NAMETABLE_SIZE                              $0700   ; 1792 bytes
.DEFINE VDP_SAT_SIZE                                    $0100   ; Includes the gap
.DEFINE VDP_SAT_UNUSED_GAP_LOC                          VDP_SAT_START_LOC + $0040
.DEFINE VDP_SAT_UNUSED_GAP_SIZE                         $40     ; 64 bytes
.DEFINE VDP_SAT_SECOND_HALF_LOC                         VDP_SAT_START_LOC + $0080
.DEFINE VDP_SAT_SECOND_HALF_SIZE                        $80     ; 128 bytes

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

.DEFINE VDP_SAT_MAX_SPRITES                             64
.DEFINE VDP_SAT_YTABLE_OFFSET                           0   ; Y entries go first
.DEFINE VDP_SAT_XTABLE_OFFSET                           $80 ; X entries start after a gap
.DEFINE VDP_SAT_TILETABLE_OFFSET                        $81 ; Tile values follow the X
.DEFINE VDP_SAT_STOP_SPRITES_YVALUE                     $D0 ; A magic value indicating "no more sprites"

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

; If you already know the row and column you intend to write to, we can
; embed the destination VRAM address.
.MACRO VDP_NAMETABLE_CALC_VRAM_ADDRESS_DE ARGS ROW, COL, VDP_COMMAND
    ld  de, ( VDP_COMMAND << 8 ) | ( VDP_NAMETABLE_START_LOC + ( ROW * VDP_NAMETABLE_ROWSIZE_IN_BYTES ) + ( COL * _sizeof_NameTableEntry ) )
.ENDM

; If you want to go from tile index to VRAM loc.
.MACRO CALC_VRAM_LOC_FOR_TILE_INDEX_IN_HL
    .REPT 5         ; 2 ^ 5 == 32, which is how many bytes there are in a tile.
        add hl, hl
    .ENDR
.ENDM

; If you want to set VRAM to write mode from value in HL.
.MACRO SET_VRAM_WRITE_LOC_FROM_HL
    ; Set the VRAM pointer.
    ld      a, l
    out     (VDP_CONTROL_PORT), a           ; Set low byte of address in first byte
    ld      a, h
    or      VDP_COMMAND_MASK_VRAM_WRITE
    out     (VDP_CONTROL_PORT), a           ; Set high byte of address + command
.ENDM

; If you want to set VRAM to write mode from value in DE.
.MACRO SET_VRAM_WRITE_LOC_FROM_DE
    ; Set the VRAM pointer.
    ld      a, e
    out     (VDP_CONTROL_PORT), a           ; Set low byte of address in first byte
    ld      a, d
    or      VDP_COMMAND_MASK_VRAM_WRITE
    out     (VDP_CONTROL_PORT), a           ; Set high byte of address + command
.ENDM


;==============================================================================
; The sprite attribute table
;==============================================================================
.STRUCT SAT_YPosEntry
    YPos:               DB
.ENDST

.STRUCT SAT_XPosTileEntry
    XPos:               DB
    TileIndex:          DB
.ENDST

.STRUCT SAT_YTable:
    YPosEntries INSTANCEOF SAT_YPosEntry VDP_SAT_MAX_SPRITES
.ENDST

.STRUCT SAT_XTileTable:
    XPosEntries INSTANCEOF SAT_XPosTileEntry VDP_SAT_MAX_SPRITES
.ENDST

.SECTION "VDP Write Register" FREE
;==============================================================================
; VDP_WriteRegister
; Sets a VDP register value.
; INPUTS:  E:  Register to set
;          A:  Value to set
; OUTPUTS:  Alters A.  A is E masked with VDP command
;==============================================================================
VDP_WriteRegister:
    ; Output to the VDP
    out     (VDP_CONTROL_PORT), a               ; Data first
    ld      a, e
    or      VDP_COMMAND_MASK_REGISTER_WRITE     ; Mask in the command
    out     (VDP_CONTROL_PORT), a               ; Commands + register num
    ret
.ENDS

.SECTION "VDP Set Palette Entry" FREE
;==============================================================================
; VDP_SetPaletteEntry
; Sets a palette entry directly in the VDP.
; INPUTS:  E:  Entry to set (0..31)
;          C:  Color value to set
; OUTPUTS:  None
; Destroys A, D, HL.
;==============================================================================
VDP_SetPaletteEntry:
    ; Output to the VDP
    ld      a, e
    out     (VDP_CONTROL_PORT), a               ; Set pal entry in low byte
    ld      a, VDP_COMMAND_MASK_CRAM_WRITE      ; The command
    out     (VDP_CONTROL_PORT), a               ; Send the command

    ; Emit the color
    ld      a, c
    out     (VDP_DATA_PORT), a
    ret
.ENDS

.SECTION "VDP Set Palette Entries" FREE
;==============================================================================
; VDP_SetPaletteEntries
; Sets a series of palette entries in the VDP.
; INPUTS:  A:  Index of first palette entry to fill
;          B:  Count of entries to update
;          HL: Pointer to palette data
; OUTPUTS:  B is 0, HL points to end of data
; Destroys  A, B, C, HL.
;==============================================================================
VDP_SetPaletteEntries:
    ; Now output to the VDP
    out     (VDP_CONTROL_PORT), a               ; Set pal entry in low byte
    ld      a, VDP_COMMAND_MASK_CRAM_WRITE      ; The command
    out     (VDP_CONTROL_PORT), a               ; Send the command

    ; Now set the color values.
    ld      c, VDP_DATA_PORT
    otir
    ret
.ENDS

.SECTION "VDP Upload Tile Data" FREE
;==============================================================================
; VDP_UploadTileDataToTilePos
; Uploads the tile data starting at the tile index specified.  Assumes data is
; all 4bpp (no bitplane skips, etc.)
; INPUTS:  DE:  Start of tile data
;          BC:  Size of tile data, in bytes
;          HL:  Index of tile to begin at (16-bit because it's 0..448)
; OUTPUTS:  HL points to end of data.  D, B are 0.  C is the Data Port.
;          Destroys B, C, D, E
;==============================================================================
VDP_UploadTileDataToTilePos:
    ; Find offset in VRAM.
    CALC_VRAM_LOC_FOR_TILE_INDEX_IN_HL

    ex      de, hl  ; HL now points to tile data, DE points to VRAM loc
    jp      VDP_UploadDataToVRAMLoc

.ENDS

.SECTION "VDP Upload Data Routines" FREE
;==============================================================================
; VDP_UploadDataToVRAMLoc
; Uploads data starting at the VRAM loc specified.
; INPUTS:  DE:  VRAM loc to write to
;          BC:  Size of data, in bytes
;          HL:  Pointer to src data
; OUTPUTS:  HL points to end of data.  D, B are 0.  C is the Data Port.
;          Destroys B, C, D, E
;==============================================================================
VDP_UploadDataToVRAMLoc:
    ; Set the VRAM pointer.
    SET_VRAM_WRITE_LOC_FROM_DE

    ld      d, b
    ld      e, c

    ; FALL THROUGH

;==============================================================================
; VDP_UploadData_VDPPtrSet
; General-purpose method to upload up to 64K of data to the VDP (VRAM or CRAM).  
; It's assumed that the VDP is already prepped for writing.
; INPUTS:  HL:  Start of data to write
;          DE:  Size of data size to upload
; OUTPUTS:  HL points to end of data.  D, B are 0.  C is the Data Port.
;          Destroys B, C, D, E
;==============================================================================
VDP_UploadData_VDPPtrSet:
    ; Ensures we roll over correctly:  
    ;   If DE == $00FF, we only want one otir.
    ;   If DE == $0100, we *also* only want one otir.
    ;   If DE == $0101, we want two otirs (one for 1 byte, one for 256 bytes)
    ld  b, e                                ; B gets low byte count
    dec de
    inc d

    ld  c, VDP_DATA_PORT                    ; Port for OTIR        
VDP_UploadData_VDPPtrSet_WriteLoop:
    otir
    dec d
    jp  nz, VDP_UploadData_VDPPtrSet_WriteLoop
    ret
.ENDS

.SECTION "VDP Upload Name Table Entry" FREE
;==============================================================================
; VDP_UploadNameTableEntry
; Uploads a single entry to the name table, at the column and row specfied.
; INPUTS:  D:   Row
;          E:   Column (range 0..31)
;          HL:  Name Table entry
; OUTPUTS: DE = VRAM address + command
;          Destroys A, C
;==============================================================================
VDP_UploadNameTableEntry:
    ; Calculate the VRAM position.

    ; Remember that b << 6 is easier to rotate right twice
    ; H = 00rr rrrr       ; High byte = Row * 64
    ; L = rrcc cccc       ; Low byte = low bits from Row * 64 | column
    ; H |= NameTable|Cmd  ; Add in nametable offset and "write to VRAM" command

    ; Start with row.  This should be VDP_NAMETABLE_ROWSIZE_IN_BYTES * row.
    xor     a
    srl     d           ; Low bit of Row -> CY
    rra                 ; A = r000 0000
    srl     d           ; Low bit of Row -> CY
    rra                 ; A = rr00 0000
    sla     e           ; Col = col * 2 bytes per entry
    or      e           ; A = rrcc ccc0
    ld      e, a
    ld      a, (VDP_NAMETABLE_START_LOC >> 8) | VDP_COMMAND_MASK_VRAM_WRITE
    or      d
    ld      d, a        ; Row = Nametable + Row * 64

    ; FALL THROUGH

;==============================================================================
; VDP_UploadNameTableEntry_AddressCalculated
; Uploads a single entry to the name table, at the VRAM address specified.
; INPUTS:  DE:  VRAM address + command
;          HL:  Name Table entry
; OUTPUTS: DE = VRAM address + command
;          Destroys A, C
;==============================================================================
VDP_UploadNameTableEntry_AddressCalculated:

    ; We've calculated the offset, so actually write it.
    ; Prep the VRAM for writing.
    ld      c, VDP_CONTROL_PORT
    out     (c), e           ; Set low byte of address in first byte
    out     (c), d           ; Set high byte of address + command

    ; Now write the data.
    ld      c, VDP_DATA_PORT
    out     (c), l
    out     (c), h
    ret
.ENDS

.SECTION "VDP Upload Name Table Entries" FREE
;==============================================================================
; VDP_UploadNameTableEntries
; Uploads a sequence of entries to the name table, starting at the column 
; and row specfied.
; INPUTS:  D:   Row
;          E:   Column (range 0..31)
;          HL:  Pointer to name table entries
;          BC:  Total size in bytes (remember 1 entry = 2 bytes!)
; OUTPUTS: HL points to end of data.  D, B are 0.  C is the Data Port.
;          Destroys B, C, D, E
;==============================================================================
VDP_UploadNameTableEntries:
    ; Calculate the VRAM position.

    ; Remember that b << 6 is easier to rotate right twice
    ; D = 00rr rrrr       ; High byte = Row * 64
    ; E = rrcc cccc       ; Low byte = low bits from Row * 64 | column
    ; D |= NameTable|Cmd  ; Add in nametable offset and "write to VRAM" command

    ; Start with row.  This should be VDP_NAMETABLE_ROWSIZE_IN_BYTES * row.
    xor     a
    srl     d           ; Low bit of Row -> CY
    rra                 ; A = r000 0000
    srl     d           ; Low bit of Row -> CY
    rra                 ; A = rr00 0000
    sla     e           ; Col = col * 2 bytes per entry
    or      e           ; A = rrcc ccc0
    ld      e, a
    ld      a, (VDP_NAMETABLE_START_LOC >> 8) | VDP_COMMAND_MASK_VRAM_WRITE
    or      d
    ld      d, a        ; Row = Nametable + row * 64

    jp      VDP_UploadDataToVRAMLoc
.ENDS

.SECTION "VDP Upload String to Name Table" FREE
;==============================================================================
; VDP_UploadStringToNameTable
; Uploads a string of bytes to the name table, starting at the column 
; and row specfied.  Standard Name Table uses two bytes per entry, here you
; can use one register to specify the attribute to apply for each character.
; INPUTS:  D:   Row
;          E:   Column (range 0..31)
;          HL:  Pointer to string
;          B:   Length of string
;          C:   Attribute to apply to every other byte
; OUTPUTS: HL points to end of data.  B are 0.  A is the attribute.  C is the
;          data port.
;          Destroys A, B, C, D, E
;==============================================================================
VDP_UploadStringToNameTable:
    ; Calculate the VRAM position.

    ; Remember that b << 6 is easier to rotate right twice
    ; D = 00rr rrrr       ; High byte = Row * 64
    ; E = rrcc cccc       ; Low byte = low bits from Row * 64 | column
    ; D |= NameTable|Cmd  ; Add in nametable offset and "write to VRAM" command

    ; Start with row.  This should be VDP_NAMETABLE_ROWSIZE_IN_BYTES * row.
    xor     a
    srl     d           ; Low bit of Row -> CY
    rra                 ; A = r000 0000
    srl     d           ; Low bit of Row -> CY
    rra                 ; A = rr00 0000
    sla     e           ; Col = col * 2 bytes per entry
    or      e           ; A = rrcc ccc0
    ld      e, a
    ld      a, (VDP_NAMETABLE_START_LOC >> 8) | VDP_COMMAND_MASK_VRAM_WRITE
    or      d
    ld      d, a        ; Row = Nametable + row * 64

    ; Set the VRAM pointer.
    ld      a, e
    out     (VDP_CONTROL_PORT), a           ; Set low byte of address in first byte
    ld      a, d
    or      VDP_COMMAND_MASK_VRAM_WRITE
    out     (VDP_CONTROL_PORT), a           ; Set high byte of address + command

    ; Now interleave the chars from the string with the attribute
    ld      a, c
    ld      c, VDP_DATA_PORT
-:
    outi                        ; Char from string
    out     (VDP_DATA_PORT), a  ; Attribute

    jp      nz, -

    ret
    
.ENDS

.SECTION "VDP Upload Sprite Data Routines" FREE
;==============================================================================
; VDP_UploadSpriteData
; Uploads the Y values and X/Tile Index values to the SAT.  Trusts caller to
; have entered the appropriate sentinel value to terminate Y values.
; INPUTS:  HL:  Pointer to Y table for sprites (SAT_YTable)
;          DE:  Pointer to X/Tile Index table for sprites (SAT_XTileTable)
;          B:   #/sprites
; OUTPUTS: HL points to end of X/Tile Index table
;          DE points to the end of the Y Pos table.
;          B = 0, C = VDP_DATA_PORT, A = High byte of VRAM + write command
;==============================================================================
VDP_UploadSpriteData:
    ; Both tables will use the same register for the out port.
    ld      c, VDP_DATA_PORT

    ; Set the VRAM address for the Y table first.
    ; Low byte first
    ld      a, VDP_SAT_START_LOC & $FF    ; Slam to 8-bit :(
    out     (VDP_CONTROL_PORT), a
    ; High byte + command
    ld      a, (VDP_SAT_START_LOC >> 8) | VDP_COMMAND_MASK_VRAM_WRITE
    out     (VDP_CONTROL_PORT), a

    ; Preserve our count; we'll need it for the second table.
    ld      a, b

    ; Upload that data!
    otir

    ; Now the X pos/Tile Index table.
    ; A has been holding our count, double it since this table is twice as big.
    add     a, a
    ld      b, a

    ; Set the VRAM address
    ; Low byte first
    ld      a, (VDP_SAT_START_LOC & $FF) + VDP_SAT_XTABLE_OFFSET    ; Slam to 8-bit
    out     (VDP_CONTROL_PORT), a
    ; High byte + command
    ld      a, (VDP_SAT_START_LOC >> 8) | VDP_COMMAND_MASK_VRAM_WRITE
    out     (VDP_CONTROL_PORT), a
    
    ; Put the other table into HL
    ex      de, hl

    ; Upload that data!
    otir

    ret
.ENDS

.SECTION "VDP Upload 1bpp with Palette Remap" FREE
;==============================================================================
; VDP_Upload1BPPWithPaletteRemapToTilePos
; Writes 1bpp data to VRAM, remapping 0 values to palette index 0 and 1
; values to a specified palette entry.
; INPUTS:  HL:  Tile index (16-bit since tiles go 0..448)
;          BC:  Count of data to write, in bytes
;          DE:  Pointer to 1bpp data
;           A:  4-bit palette index to substitute for "1" values in 1bpp data
; OUTPUTS: BC is 0, HL points to next byte after tile data.
; Destroys A, D, E
;==============================================================================
VDP_Upload1BPPWithPaletteRemapToTilePos:
    CALC_VRAM_LOC_FOR_TILE_INDEX_IN_HL
    ex      de, hl

    ; FALL THROUGH

;==============================================================================
; VDP_Upload1BPPWithPaletteRemapToVRAMLoc
; Writes 1bpp data to VRAM, remapping 0 values to palette index 0 and 1
; values to a specified palette entry.
; INPUTS:  DE:  VRAM loc to upload to
;          BC:  Count of data to write, in bytes
;          HL:  Pointer to 1bpp data
;           A:  4-bit palette index to substitute for "1" values in 1bpp data
; OUTPUTS: BC is 0, HL points to next byte after tile data.
; Destroys A, D, E
;==============================================================================
VDP_Upload1BPPWithPaletteRemapToVRAMLoc:
    ; Set the VRAM write position.
    ; Preserve our palette index
    push    af
        SET_VRAM_WRITE_LOC_FROM_DE
    pop     af

    ; FALL THROUGH

;==============================================================================
; VDP_Upload1BPPWithPaletteRemap_VRAMPtr_Set
; Writes 1bpp data to VRAM, remapping 0 values to palette index 0 and 1
; values to a specified palette entry.  Assumes the VRAM pointer has already
; been set.
; INPUTS:  BC:  Count of data to write, in bytes
;          HL:  Pointer to 1bpp data
;           A:  4-bit palette index to substitute for "1" values in 1bpp data
; OUTPUTS: BC is 0, HL points to next byte after tile data.
; Destroys A, D, E
;==============================================================================
VDP_Upload1BPPWithPaletteRemap_VRAMPtr_Set:
    ld      e, a    ; Cache the remap palette

-:
    ld      d, e    ; Reload our remap palette

    ; Each row of pixels is 4 bytes.
.REPT 4
    xor     a                   ; Start with a clean slate of pixels
    rrc     d                   ; Next palette remap bit to Carry
    jr      nc, +
    ld      a, (hl)             ; We had a palette bit set, so load the 1s data from 1bpp stream.
+:
    out     (VDP_DATA_PORT), a  ; Emit data
.ENDR
    inc     hl                  ; Next byte
    dec     bc                  ; Are we done?
    ld      a, b
    or      c
    jp      nz, -
    ret
.ENDS


; If we know palette values at assembling time, we can pre-interleave them.
; If the palette to remap for 0s is abcd, and the palette for 1s is wxyz,
; we want waxbyczd.
;         76543210
;             abcd <- 0s
;             wxyz <- 1s
.MACRO PRE_INTERLEAVE_1BPP_REMAP_ENTRIES_TO_E ARGS PAL_0, PAL_1
;                  W                      A                      X                     B                     Y                     C                     Z                     D
ld e,  < ( ((PAL_1 & $8) << 4) | (((PAL_0 & $8)) << 3) | ((PAL_1 & $4) << 3) | ((PAL_0 & $4) << 2) | ((PAL_1 & $2) << 2) | ((PAL_0 & $2) << 1) | ((PAL_1 & $1) << 1) | ((PAL_0 & $1) << 0) )
.ENDM


.SECTION "VDP Upload 1bpp With Palette Remaps" FREE
;==============================================================================
; VDP_Upload1BPPWithPaletteRemaps_VRAMPtrSet
; Writes 1bpp data to VRAM, remapping 0 values to one palette index and 1
; values to a second palette entry.  Assumes that the VRAM pointer has already
; been set.
; INPUTS:  HL:  Src 1bpp tile data
;          BC:  Count of data to write, in bytes
;           E:  4-bit palette index to substitute for "0" values in 1bpp data
;           D:  4-bit palette index to substitute for "1" values in 1bpp data
; OUTPUTS: BC is 0, E is the interleaved palette data.  HL points to next byte
;          after tile data.
; Destroys A, D
;==============================================================================
VDP_Upload1BPPWithPaletteRemaps_VRAMPtrSet:
    ; Interleave the 0s palette with the 1s palette, so that:
    ; 0000 abcd <- 0s palette
    ; 0000 wxyz <- 1s palette
    ; ..becomes:
    ; waxb yczd
    xor     a
.REPT 4
    rrc     e       ; Move 0s bit to carry
    rr      a       ; Interleave
    rrc     d       ; Move 1st bit to carry
    rr      a       ; Interleave
.ENDR
    ld      e, a    ; E holds our interleaved palette remaps

    ; Colors are interleaved.  Now upload the darn data.
    ; FALL THROUGH

;==============================================================================
; VDP_Upload1BPPWithPaletteRemaps_VRAMPtrSet_ColorsInterleaved
; Writes 1bpp data to VRAM, remapping 0 values to one palette index and 1
; values to a second palette entry.  Assumes that the VRAM pointer has already
; been set, and that the palette entries are interleaved.
; INPUTS:  HL:  Src 1bpp tile data
;          BC:  Count of data to write, in bytes
;           E:  Interleaved palette remaps (0s are even bits, 1s are odd bits)
; OUTPUTS: BC is 0, E is the interleaved palette data.  HL points to next byte
;          after tile data.
; Destroys A, D
;==============================================================================
VDP_Upload1BPPWithPaletteRemaps_VRAMPtrSet_ColorsInterleaved:
    ld      d, (hl)             ; Get 1 bpp bitmap data.

    ; We'll do this 4 times, since each pixel row is 4 bytes.
.REPT 4
    xor     a                   ; Start with a clean slate in our pixel data.

    rrc     e                   ; Get next 0s palette bit into carry.
    jr      nc, +               ; Not set?  Skip.
    ld      a, d                ; 0s palette bit *WAS* set...
    cpl                         ; ...so mask the 0s in as 1s.
+:
    rrc     e                   ; Get the next 1s palette bit into carry.
    jr      nc, ++              ; Not set?  Skip.
    or      d                   ; 1s palette *WAS* set, so mask them in.
++:
    out     (VDP_DATA_PORT), a  ; Emit the data.
.ENDR
    inc     hl                  ; Point to next byte
    dec     bc
    ld      a, b
    or      c
    jp      nz, VDP_Upload1BPPWithPaletteRemaps_VRAMPtrSet_ColorsInterleaved
    ret

.ENDS

.ENDIF  ;__VDP_ASM__