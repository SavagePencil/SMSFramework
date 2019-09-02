.STRUCT SpriteChainHeader
    CurrCount       DB      ; #/entries in this chain
    MaxCount        DB      ; Max #/entries allowed
    NextChain       DW      ; Ptr to next one, if any
    YPosBegin       DW      ; Where does the Y table begin?
    XPosTileBegin   DW      ; Where does the X/Tile table begin?
.ENDST


.SECTION "Sprite Chain Init and Clear" FREE
;==============================================================================
; SpriteChain_Init
; Initializes a sprite chain header object.
; INPUTS:  A:  Max count of entries in this chain
;          BC: Pointer to next chain
;          DE: Pointer to YPos table
;          HL: Pointer to XPos/Tile Index table
;          IX: Pointer to sprite chain header
; OUTPUTS: NONE
;==============================================================================
SpriteChain_Init:
    ld      (ix + SpriteChainHeader.MaxCount), a
    ld      (ix + SpriteChainHeader.NextChain + 0), c
    ld      (ix + SpriteChainHeader.NextChain + 1), b
    ld      (ix + SpriteChainHeader.YPosBegin + 0), e
    ld      (ix + SpriteChainHeader.YPosBegin + 1), d
    ld      (ix + SpriteChainHeader.XPosTileBegin + 0), l
    ld      (ix + SpriteChainHeader.XPosTileBegin + 1), h

    ; FALL THROUGH

;==============================================================================
; SpriteChain_Clear
; Sets a sprite chain to have no entries
; INPUTS:  IX: Pointer to sprite chain header
; OUTPUTS: NONE
;==============================================================================
SpriteChain_Clear:
    ld      (ix + SpriteChainHeader.CurrCount), $00

    ret

.MACRO SPRITE_CHAIN_PREP_ENQUEUE_CHAIN_IN_IX ARGS Y_POS_TABLE, X_POS_TABLE
    ld  e, (ix + SpriteChainHeader.CurrCount)
    ld  d, $00
    ld  hl, Y_POS_TABLE
    add hl, de
    ex  de, hl          ; DE = Y Pos Loc, HL = Curr Count

    ld  bc, X_POS_TABLE
    add hl, hl          ; HL = 2 * Curr Count
    add hl, bc          ; HL = X/Tile Loc
.ENDM

.MACRO SPRITE_CHAIN_ENQUEUE_SPRITE
    ld  (de), a         ; Enqueue the Y pos
    inc de
    ld  (hl), b         ; Enqueue the X pos
    inc hl
    ld  (hl), c         ; Enqueue the tile
    inc hl

    inc (ix + SpriteChainHeader.CurrCount)
.ENDM

.ENDS

.SECTION "Sprite Manager Render Chain Sequence" FREE
;==============================================================================
; SpriteManager_RenderChainSequence
; Renders an entire sequence of sprite chains.
; INPUTS:  HL: Head of the chain
; OUTPUTS:  D: #/sprites remaining
; Destroys A, B, C, D, H, L, IX
;==============================================================================
SpriteManager_RenderChainSequence:
    push    hl      ; Save the initial chain

        ; Set the VRAM address for the X/Tile table.    
        ld      c, VDP_CONTROL_PORT

        ld      de, ( VDP_SAT_START_LOC + VDP_SAT_XTABLE_OFFSET ) | ( VDP_COMMAND_MASK_VRAM_WRITE << 8 )

        ; Low byte first
        out     (c), e
        ; High byte + command
        out     (c), d

        ld      c, VDP_DATA_PORT

        ; Keep track of how many sprites we're submitting so we don't go over
        ; and so that we can insert a sentinel appropriately.
        ld  d, VDP_SAT_MAX_SPRITES

_SpriteManager_RenderChainXPosTile:
        ; Are we out of sprite slots?
        ld      a, d
        and     a
        jr      z, _SpriteManager_RenderChainXPosTileDone

        ; Is the chain pointer empty?
        ld      a, l
        or      h
        jr      z, _SpriteManager_RenderChainXPosTileDone

        push    hl
        pop     ix

        ; How many do we intend to do?  If it's zero, skip.
        ld      a, (ix + SpriteChainHeader.CurrCount)
        and     a
        jp      z, _SpriteManager_NextXPosTileChain

        ; Ensure we have enough room.
        ld      b, a
        ld      a, d
        sub     b
        ld      d, a
        jp      nc, _SpriteManager_UploadXPosTileData
        
        ; Overrunning?  Go to our max, but no more.
        add     a, b
        ld      b, a
        ld      d, 0

_SpriteManager_UploadXPosTileData:
        ; Now let's point to our data
        ld      l, (ix + SpriteChainHeader.XPosTileBegin + 0)
        ld      h, (ix + SpriteChainHeader.XPosTileBegin + 1)

        ; Byte count is doubled because we're doing XPos + Tile
        sla     b

        ; Upload that data!
        otir

_SpriteManager_NextXPosTileChain:
        ; Move to the next chain, if there is one.
        ld      l, (ix + SpriteChainHeader.NextChain + 0)
        ld      h, (ix + SpriteChainHeader.NextChain + 1)
        jp      _SpriteManager_RenderChainXPosTile

_SpriteManager_RenderChainXPosTileDone:
    pop     hl      ; Restore original chain

    ; Set the VRAM address for the Y Pos table.    
    ld      c, VDP_CONTROL_PORT

    ld      de, ( VDP_SAT_START_LOC ) | ( VDP_COMMAND_MASK_VRAM_WRITE << 8 )

    ; Low byte first
    out     (c), e
    ; High byte + command
    out     (c), d

    ld      c, VDP_DATA_PORT

    ld      d, VDP_SAT_MAX_SPRITES  ; Start at the max again.

_SpriteManager_RenderChainYPos:
    ; Are we out of sprite slots?
    ld      a, d
    and     a
    jr      z, _SpriteManager_RenderChainYPosDone

    ; Is the chain pointer empty?
    ld      a, l
    or      h
    jr      z, _SpriteManager_RenderChainYPosDone

    push    hl
    pop     ix

    ; How many do we intend to do?  If it's zero, skip.
    ld      a, (ix + SpriteChainHeader.CurrCount)
    and     a
    jp      z, _SpriteManager_NextYPosChain

    ; Ensure we have enough room.
    ld      b, a
    ld      a, d
    sub     b
    ld      d, a
    jp      nc, _SpriteManager_UploadYPosData
    
    ; Overrunning?  Go to our max, but no more.
    add     a, b
    ld      b, a
    ld      d, 0

_SpriteManager_UploadYPosData:
    ; Now let's point to our data
    ld      l, (ix + SpriteChainHeader.YPosBegin + 0)
    ld      h, (ix + SpriteChainHeader.YPosBegin + 1)

    ; Upload that data!
    otir

_SpriteManager_NextYPosChain:
    ; Move to the next chain, if there is one.
    ld      l, (ix + SpriteChainHeader.NextChain + 0)
    ld      h, (ix + SpriteChainHeader.NextChain + 1)
    jp      _SpriteManager_RenderChainYPos

_SpriteManager_RenderChainYPosDone:
    ; If there's still room left in the SAT, output the sentinel marker.
    ld      a, d
    and     a
    ret     z

    ld      a, VDP_SAT_STOP_SPRITES_YVALUE
    out     (VDP_DATA_PORT), a
    ret

.ENDS