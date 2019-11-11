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

.SECTION "Tile Routines - Inflate 1bpp to 4bpp RAM with Palette Remap" FREE
;==============================================================================
; Tile_Inflate1BPPto4BPPRAMWithPaletteRemap
; Inflates 1bpp data to 4bpp data in RAM, remapping 0 values to palette 
; index 0 and 1 values to a specified palette entry.
; INPUTS:  DE:  Dest loc for 4bpp data
;          HL:  Pointer to 1bpp src data
;           B:  Count of bytes in 1bpp src data
;           A:  4-bit palette index to substitute for "1" values in 1bpp data
; OUTPUTS: DE:  Points to byte PAST end of dest
;          HL:  Points to byte PAST end of src
;           B:  0
;           C:  Palette entry, mirrored into high nibble
; Destroys A
;==============================================================================
Tile_Inflate1BPPto4BPPRAMWithPaletteRemap:
    ; Mirror the low nibble in color to the high nibble.
    ld      c, a
    rrca
    rrca
    rrca
    rrca
    or      c
    ld      c, a    ; C has palette in high & low nibble.

    ; FALL THROUGH

;==============================================================================
; Tile_Inflate1BPPto4BPPRAMWithPaletteRemap_PalMirrored
; Inflates 1bpp data to 4bpp data in RAM, remapping 0 values to palette 
; index 0 and 1 values to a specified palette entry.  Assumes the palette
; nibble has been mirrored (e.g., if palette remap is 0111, we pass in
; 0111 0111).
; INPUTS:  DE:  Dest loc for 4bpp data
;          HL:  Pointer to 1bpp src data
;           B:  Count of bytes in 1bpp src data
;           C:  4-bit palette index mirrored in top and bottom nibbles
; OUTPUTS: DE:  Points to byte PAST end of dest
;          HL:  Points to byte PAST end of src
;           B:  0
;           C:  Palette entry, mirrored into high nibble
; Destroys A
;==============================================================================
Tile_Inflate1BPPto4BPPRAMWithPaletteRemap_PalMirrored:
-:
    ; Each row of pixels is 4 bytes
.REPT 4
    xor     a       ; Start with a clean slate.
    rrc     c       ; Is the bit for this plane's color set?
    jr      nc, +   ; No?  Skip and set all zeroes.
    ld      a, (hl) ; If it WAS set, get the 1bpp val.
+:
    ld      (de), a ; Output it.
    inc     de      ; Move to next plane
.ENDR
    inc     hl      ; Next byte in src
    djnz    -
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
    rrc     d       ; Move 1s bit to carry
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

.SECTION "Tile Routines - Inflate 1bpp to 4bpp RAM with Palette Remaps" FREE
.MACRO PRE_INTERLEAVE_1BPP_REMAP_ENTRIES_TO_C ARGS PAL_0, PAL_1
;                  W                      A                      X                     B                     Y                     C                     Z                     D
    ld c,  < ( ((PAL_1 & $8) << 4) | (((PAL_0 & $8)) << 3) | ((PAL_1 & $4) << 3) | ((PAL_0 & $4) << 2) | ((PAL_1 & $2) << 2) | ((PAL_0 & $2) << 1) | ((PAL_1 & $1) << 1) | ((PAL_0 & $1) << 0) )
.ENDM


;==============================================================================
; Tile_Inflate1BPPto4BPPRAMWithPaletteRemaps
; Inflates 1bpp data to 4bpp data in RAM, remapping 0 values to one palette 
; index and 1 values to another.
; INPUTS:  DE:  Dest loc for 4bpp data
;          HL:  Pointer to 1bpp src data
;           B:  Count of bytes in 1bpp src data
;           C:  4-bit palette index to substitute for "0" values in 1bpp data
;           A:  4-bit palette index to substitute for "1" values in 1bpp data
; OUTPUTS: DE:  Points to byte PAST end of dest
;          HL:  Points to byte PAST end of src
;           B:  0
;           C:  Interleaved color
; Destroys A
;==============================================================================
Tile_Inflate1BPPto4BPPRAMWithPaletteRemaps:
    ; Interleave the 0s palette with the 1s palette, so that:
    ; 0000 abcd <- 0s palette
    ; 0000 wxyz <- 1s palette
    ; ..becomes:
    ; waxb yczd
    push    de
        ld      d, a    ; C holds 0s, D holds 1s

        xor     a
    .REPT 4
        rrc     c       ; Move 0s bit to carry
        rr      a       ; Interleave
        rrc     d       ; Move 1s bit to carry
        rr      a       ; Interleave
    .ENDR
        ld      c, a    ; C holds our interleaved palette remaps

    pop     de
    ; FALL THROUGH

;==============================================================================
; Tile_Inflate1BPPto4BPPRAMWithPaletteRemap_ColorsInterleaved
; Inflates 1bpp data to 4bpp data in RAM, remapping 0 values to palette 
; index 0 and 1 values to a specified palette entry.  Assumes the palette
; entries have already been interleaved.
; INPUTS:  DE:  Dest loc for 4bpp data
;          HL:  Pointer to 1bpp src data
;           B:  Count of bytes in 1bpp src data
;           C:  Interleaved palette remaps (0s are even bits, 1s are odd bits)
; OUTPUTS: DE:  Points to byte PAST end of dest
;          HL:  Points to byte PAST end of src
;           B:  0
;           C:  Palette entry, interleaved
; Destroys A
;==============================================================================
Tile_Inflate1BPPto4BPPRAMWithPaletteRemap_ColorsInterleaved:
-:
    ; Each row of pixels is 4 bytes
.REPT 4
    xor     a       ; Start with a clean slate.

    ; Check if the palette bit is set for the 0s
    rrc     c       ; Get next 0s palette bit into carry.
    jr      nc, +   ; Not set?  Skip and set all zeroes.
    ld      a, (hl) ; If it WAS set, get the 1bpp val.
    cpl             ; Invert since these are the 0s becoming 1s
+:
    ; Now check if the palette bit is set for the 1s.  If it is, we'll mask
    ; it into what we currently have.
    rrc     c
    jr      nc, ++  ; Not set?  Skip.
    or      (hl)    ; Bring in the 1s data
++:
    ld      (de), a ; Output the new val.
    inc     de      ; Move to next byte in dest
.ENDR
    inc     hl      ; Next byte in src
    djnz    -
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

.SECTION "Tile Routines - Composite Tile to VRAM" FREE
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
;          DE:  Points to byte AFTER end of top tile
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

.SECTION "Tile Routines - Composite Tiles In Place In RAM" FREE
;==============================================================================
; Tile_CompositePlanarTiles_InPlaceInRAM
; Composites one tile over another in RAM.  The tiles are planar,
; 4bpp (same format as VRAM).  A 1bpp mask is provided to indicate which pixels
; are clear.  IMPORTANT:  Overwrites the contents of the bottom tile!
; INPUTS:  HL:  1bpp Mask for top tile
;          IY:  4bpp Bottom tile to composite (this is the destination tile)
;          DE:  4bpp Top tile to composite
;           B:  Count of data in mask, in bytes
; OUTPUTS: IY:  Points to byte AFTER end of top area copied in src
;          DE:  Points to byte AFTER end of top area copied
;          HL:  Points to byte AFTER end of 1bpp mask area copied
; Destroys A, C
;==============================================================================
Tile_CompositePlanarTiles_InPlaceInRAM:
-:
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

        ld      (iy+$00), a         ; Store back into bottom tile

        inc     iy
        inc     de
    .ENDR

    inc     hl                      ; Move to next byte in mask
    djnz    -
    ret
.ENDS

.SECTION "Tile Routines - Composite Tiles to New RAM Tile" FREE
;==============================================================================
; Tile_CompositePlanarTiles_ToNewRAMTile
; Composites one tile over another, storing the results in a new location in 
; RAM.  The tiles are planar, 4bpp (same format as VRAM).  A 1bpp mask is 
; provided to indicate which pixels are clear.
; INPUTS:  HL:  1bpp Mask for top tile
;          IY:  4bpp Bottom tile to composite
;          DE:  4bpp Top tile to composite
;           B:  Count of data in mask, in bytes
;          IX:  Loc in RAM to write the output to.
; OUTPUTS: IY:  Points to byte AFTER end of top area copied in src
;          DE:  Points to byte AFTER end of top area copied
;          HL:  Points to byte AFTER end of 1bpp mask area copied
;          IX:  Points to byte AFTER the last destination write
; Destroys A, C
;==============================================================================
Tile_CompositePlanarTiles_ToNewRAMTile:
-:
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

        ld      (ix+$00), a         ; Store into the dest tile in RAM

        inc     iy
        inc     de
        inc     ix
    .ENDR

    inc     hl                      ; Move to next byte in mask
    djnz    -
    ret
.ENDS


.ENDIF  ;__TILE_ROUTINES_ASM__