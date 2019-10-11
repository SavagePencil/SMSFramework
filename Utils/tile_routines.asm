.IFNDEF __TILE_ROUTINES_ASM__
.DEFINE __TILE_ROUTINES_ASM__

.INCLUDE "Utils/vdp.asm"

.SECTION "Tile Routines - Upload 1bpp with Palette Remap" FREE
;==============================================================================
; Tile_Upload1BPPWithPaletteRemapToTilePos
; Writes 1bpp data to VRAM, remapping 0 values to palette index 0 and 1
; values to a specified palette entry.
; INPUTS:  HL:  Tile index (16-bit since tiles go 0..448)
;          BC:  Count of data to write, in bytes
;          DE:  Pointer to 1bpp data
;           A:  4-bit palette index to substitute for "1" values in 1bpp data
; OUTPUTS: BC is 0, HL points to next byte after tile data.
; Destroys A, D, E
;==============================================================================
Tile_Upload1BPPWithPaletteRemapToTilePos:
    CALC_VRAM_LOC_FOR_TILE_INDEX_IN_HL
    ex      de, hl

    ; FALL THROUGH

;==============================================================================
; Tile_Upload1BPPWithPaletteRemapToVRAMLoc
; Writes 1bpp data to VRAM, remapping 0 values to palette index 0 and 1
; values to a specified palette entry.
; INPUTS:  DE:  VRAM loc to upload to
;          BC:  Count of data to write, in bytes
;          HL:  Pointer to 1bpp data
;           A:  4-bit palette index to substitute for "1" values in 1bpp data
; OUTPUTS: BC is 0, HL points to next byte after tile data.
; Destroys A, D, E
;==============================================================================
Tile_Upload1BPPWithPaletteRemapToVRAMLoc:
    ; Set the VRAM write position.
    ; Preserve our palette index
    push    af
        SET_VRAM_WRITE_LOC_FROM_DE
    pop     af

    ; FALL THROUGH

;==============================================================================
; Tile_Upload1BPPWithPaletteRemap_VRAMPtr_Set
; Writes 1bpp data to VRAM, remapping 0 values to palette index 0 and 1
; values to a specified palette entry.  Assumes the VRAM pointer has already
; been set.
; INPUTS:  BC:  Count of data to write, in bytes
;          HL:  Pointer to 1bpp data
;           A:  4-bit palette index to substitute for "1" values in 1bpp data
; OUTPUTS: BC is 0, HL points to next byte after tile data.
; Destroys A, D, E
;==============================================================================
Tile_Upload1BPPWithPaletteRemap_VRAMPtr_Set:
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



.SECTION "Tile Routines - Upload 1bpp With Palette Remaps" FREE
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


;==============================================================================
; Tile_Upload1BPPWithPaletteRemaps_VRAMPtrSet
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
Tile_Upload1BPPWithPaletteRemaps_VRAMPtrSet:
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
; Tile_Upload1BPPWithPaletteRemaps_VRAMPtrSet_ColorsInterleaved
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
Tile_Upload1BPPWithPaletteRemaps_VRAMPtrSet_ColorsInterleaved:
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
    jp      nz, Tile_Upload1BPPWithPaletteRemaps_VRAMPtrSet_ColorsInterleaved
    ret

.ENDS

.SECTION "Tile Routines - Generate 1bpp Mask From Tile" FREE
;==============================================================================
; Tile_GenerateMaskFromTile_DefaultClearColor
; Given a 4bpp planar tile, generate a 1bpp mask wherever a non-zero pixel
; exists.  For example, assume this tile:
;
;   Plane 0  00110011
;   Plane 1  10101010
;   Plane 2  00000000
;   Plane 3  11110001
;
;   ..the mask looks like this:
;      Mask  11111011
; 
; INPUTS:  HL:  Src 4bpp tile data
;          DE:  Dest loc for 1bpp data
;           B:  Size of 1bpp data, in bytes
; OUTPUTS:  B:  Zero
;          HL:  Byte AFTER end of 4bpp tile
;          DE:  Byte AFTER end of 1bpp mask
; Destroys A
;==============================================================================
Tile_GenerateMaskFromTile_DefaultClearColor:
    xor     a       ; Start with empty mask

    .REPT 4
        or      (hl)    ; Add in next byte
        inc     hl
    .ENDR

    ld      (de), a ; Output mask byte
    inc     de
    djnz    Tile_GenerateMaskFromTile_DefaultClearColor
    ret

.ENDS

.SECTION "Tile Routines - Composite Tile" FREE
;==============================================================================
; Tile_CompositePlanarTilesWithMask_ToVRAM
; Composites one tile over another, uploading into VRAM.  The tiles are planar,
; 4bpp (same format as VRAM).  A 1bpp mask is provided to indicate which pixels
; are clear.
; INPUTS:  HL:  VRAM Loc to upload to
;          IY:  4bpp Bottom tile to composite
;          DE:  4bpp Top tile to composite
;           B:  Count of data in mask, in bytes
;          TOP OF STACK:  1bpp Mask for top tile
; OUTPUTS: IY:  Points to byte AFTER end of bottom tile
;          DE:  Poitns to byte AFTER end of top tile
;          HL:  Points to byte AFTER end of 1bpp mask
; Destroys A, C
;==============================================================================
Tile_CompositePlanarTiles_ToVRAM:
    ; Set the VRAM loc.
    SET_VRAM_WRITE_LOC_FROM_HL

    pop     hl                      ; Get ptr to mask

    ;FALL THROUGH

;==============================================================================
; Tile_CompositePlanarTiles_ToVRAM_VRAMPtrSet
; Composites one tile over another, uploading into VRAM.  The tiles are planar,
; 4bpp (same format as VRAM).  A 1bpp mask is provided to indicate which pixels
; are clear.  Assumes the VRAM pointer has already been set.
; INPUTS:  HL:  1bpp Mask for top tile
;          IY:  4bpp Bottom tile to composite
;          DE:  4bpp Top tile to composite
;           B:  Count of data in mask, in bytes
; OUTPUTS: IY:  Points to byte AFTER end of bottom tile
;          DE:  Poitns to byte AFTER end of top tile
;          HL:  Points to byte AFTER end of 1bpp mask
; Destroys A, C
;==============================================================================
Tile_CompositePlanarTiles_ToVRAM_VRAMPtrSet:
    .REPT 4
        ; Mask the bottom tile data
        ; We let bottom tile data through where the mask has 0s.
        ld      a, (hl)             ; Get mask
        cpl                         ; Invert mask.
        and     (iy+$00)            ; Mask against bottom tile data
        ld      c, a                ; C holds the masked bottom tile

        ; Get the top tile data.
        ; We let top tile data through where the mask has 1s.
        ld      a, (de)             ; Get top tile data
        and     (hl)                ; Mask it.

        or      c                   ; Composite masked top w/bottom

        out     (VDP_DATA_PORT), a

        inc     iy
        inc     de
    .ENDR

    inc     hl                      ; Move to next byte in mask
    djnz    Tile_CompositePlanarTiles_ToVRAM_VRAMPtrSet
    ret
.ENDS



.ENDIF  ;__TILE_ROUTINES_ASM__