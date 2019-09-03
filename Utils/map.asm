; Constants for map meta tile
.ENUMID 0 EXPORT
    .ENUMID MAP_ENTRY_FLAT          ; No meta tiles, emulates tilemap
    .ENUMID MAP_ENTRY_METATILE_1x1  ; Meta tiles are 1x1
    .ENUMID MAP_ENTRY_METATILE_2x2  ; 2x2

.STRUCT MapDefinition
    MetatileType        DB      ; Pick from the MAP_ENTRY_* enums
    MetatileData        DW      ; Pointer to the meta tile entries
    MapWidthInEntries   DW      ; How wide is the map
    BytesPerEntry       DB      ; How many bytes per entry?
    MapWidthInBytes     DW      ; How many bytes wide is the map? (entries * bytes per entry)
    MapWidthBitShifts   DB      ; How many bit shifts does that make?
    MapHeight           DW      ; How tall is the map?
    MapData             DW      ; Where is the map's data?
    OnLoadData          DW      ; Function to call when getting the map's data
.ENDST

.STRUCT MapLoadRequest
    MapXPos         DW      ; X Position in the map
    MapYPos         DW      ; Y Position in the map
    Width           DW      ; Width of region to load
    Height          DB      ; Height of region to load
    Stride          DW      ; How big is each row of the destination?
.ENDST

.SECTION "Map Flat Get Cursor" FREE
;==============================================================================
; Map_Flat_GetCursor
; Gets a "cursor" for an X/Y entry position in a flat map.
; INPUTS:  IX: Map data structure
;          DE: X entry position in map.
;          HL: Y entry position of map.
; OUTPUTS:  HL:  Memory location of X/Y pos
; Does not preserve any registers.
;==============================================================================
Map_Flat_GetCursor:
    ; Find the upper left location.
    ld  b, (ix + MapDefinition.MapWidthBitShifts)
    ld  a, b

    ; If it's greater than 8, then just move the low byte up.
    sub 8
    jr  c, _Map_Flat_GetCursorShift
    ld  b, a
    ld  h, l
    ld  l, $00
    jr  z, _Map_Flat_GetCursorYPosFound ; Skip if precisely 8

_Map_Flat_GetCursorShift:
    ld  a, h

    ; Shift the remaining bits.
-:
    sla l
    rla
    djnz -

    ld  h, a

_Map_Flat_GetCursorYPosFound:
    ; HL now points to the right row, now add the column, which is in DE.
    ld  b, (ix + MapDefinition.BytesPerEntry)
    ; Add appropriate #/columns
-:
    add hl, de
    djnz -

    ; With our offset calculated, now add it to the base data ptr.
    ld  c, (ix + MapDefinition.MapData + 0)
    ld  b, (ix + MapDefinition.MapData + 1)
    add hl, bc

    ret

.ENDS

.SECTION "Map Flat Load Data" FREE
;==============================================================================
; Map_Flat_LoadDataToBlock
; Loads a section of data from a flat map structure (analogous to the name
; table) to a rectangular section of memory.
; INPUTS:  IX: Map data structure
;          IY: Map load request structure
;          DE: Destination buffer
; OUTPUTS:  None
; Does not preserve any registers.
;==============================================================================
Map_Flat_LoadDataToBlock:
    ; Preserve the destination
    push    de
        ; Get X/Y positions
        ld  e, (iy + MapLoadRequest.MapXPos + 0)
        ld  d, (iy + MapLoadRequest.MapXPos + 1)
        ld  l, (iy + MapLoadRequest.MapYPos + 0)
        ld  h, (iy + MapLoadRequest.MapYPos + 1)

        call Map_Flat_GetCursor

        ; HL is now pointing to the upper left of the src map structure.
    pop de  ; DE is now pointing to the start of the dest

    ld  b, (iy + MapLoadRequest.Height + 0)
-:
    push    bc
        push    hl  ; Preserve src
            push    de  ; Preserve dest
                ld  c, (iy + MapLoadRequest.Width + 0)
                ld  b, (iy + MapLoadRequest.Width + 1)
                ldir    ; Copy it

            pop hl  ; Confusing!  Get the dest into HL for now.
            ld  c, (iy + MapLoadRequest.Stride + 0)
            ld  b, (iy + MapLoadRequest.Stride + 1)
            add hl, bc
            ex  de, hl  ; Now DE points back to our dest.
        pop     hl  ; Restore src loc
        ld      c, (ix + MapDefinition.MapWidthInBytes + 0)
        ld      b, (ix + MapDefinition.MapWidthInBytes + 1)
        add     hl, bc  ; HL points to next loc in src map.
    pop bc
    djnz    -
    ret

.ENDS