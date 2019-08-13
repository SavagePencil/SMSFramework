;==============================================================================
; VDP REGISTER 0
;==============================================================================
; Any flags that are REQUIRED to be set.
.DEFINE VDP_REGISTER0_REQUIRED_MASK                     0

; Disables vertical scrolling for columns 24-31.  
; Usually used as a status area in vertically-scrolling games.
.DEFINE VDP_REGISTER0_DISABLE_VERTICAL_STATUS_SCROLL    1 << 7

; Disables horizontal scrolling for rows 0-1.
; Usually used as a status bar in horizontally-scrolling games.
.DEFINE VDP_REGISTER0_DISABLE_HORIZONTAL_STATUS_SCROLL  1 << 6

; Masks column 0 with overscan color from register #7.
; Typically used for horizontally-scrolling games to allow smooth
; scrolling to conceal wrap-around.
.DEFINE VDP_REGISTER0_MASK_LEFT_COLUMN                  1 << 5

; Enables line interrupts (HBLANK interrupts).
; Usually used for fancy effects or time-critical events.
.DEFINE VDP_REGISTER0_ENABLE_HBLANK                     1 << 4

; Shifts sprites to the left by 8 pixels.
; Used by games to have sprites move in smoothly from screen edge.
.DEFINE VDP_REGISTER0_SHIFT_SPRITES_LEFT                1 << 3

; Set to use Mode 4 (most SMS games).  Clear to use TMS9918 modes.
.DEFINE VDP_REGISTER0_MODE_4_SELECT                     1 << 2

; Allows non-standard resolutions to change screen height.
.DEFINE VDP_REGISTER0_ENABLE_NONSTANDARD_HEIGHTS        1 << 1

; Sets an external sync mode, which renders monochrome.
.DEFINE VDP_REGISTER0_DISABLE_SYNC                      1 << 0

;==============================================================================
; VDP REGISTER 1
;==============================================================================
; Any flags that are REQUIRED to be set.
.DEFINE VDP_REGISTER1_REQUIRED_MASK                     0

; If set, makes the display visible, otherwise blanked.
.DEFINE VDP_REGISTER1_ENABLE_DISPLAY                    1 << 6

; When set, allows VBLANK interrupts.
.DEFINE VDP_REGISTER1_ENABLE_VBLANK                     1 << 5

; When set, coupled with VDP_REGISTER0_ENABLE_NONSTANDARD_HEIGHTS,
; allows 256x224 resolution mode.
.DEFINE VDP_REGISTER1_ENABLE_224_LINE_MODE              1 << 4

; When set, coupled with VDP_REGISTER0_ENABLE_NONSTANDARD_HEIGHTS,
; allows 256x240 resolution mode.
.DEFINE VDP_REGISTER1_ENABLE_240_LINE_MODE              1 << 3

; If in mode 4 (most games, with VDP_REGISTER0_MODE_4_SELECT set),
; sprites are 8x16 if this is set, 8x8 if cleared.  In legacy
; TMS9918 mode, sprites are 16x16 if set, 8x8 if cleared.
.DEFINE VDP_REGISTER1_INCREASED_SPRITE_HEIGHT           1 << 1

; If set, sprite pixels are doubled in size.
.DEFINE VDP_REGISTER1_DOUBLE_SPRITE_PIXELS              1 << 0

;==============================================================================
; VDP REGISTER 2:  Name table base address
;==============================================================================
; Any flags that are REQUIRED to be set.
.DEFINE VDP_REGISTER2_REQUIRED_MASK                     1

; We can set the individual bits of the name table
.DEFINE VDP_REGISTER2_NAMETABLEADDRESS_SET_BIT13        ( 1 << 3 )
.DEFINE VDP_REGISTER2_NAMETABLEADDRESS_SET_BIT12        ( 1 << 2 )
.DEFINE VDP_REGISTER2_NAMETABLEADDRESS_SET_BIT11        ( 1 << 1 )

; Helpful defines for standard (192-line) modes
.DEFINE VDP_REGISTER2_NAMETABLEADDRESS_0x0000           0
.DEFINE VDP_REGISTER2_NAMETABLEADDRESS_0x0800           VDP_REGISTER2_NAMETABLEADDRESS_SET_BIT11
.DEFINE VDP_REGISTER2_NAMETABLEADDRESS_0x1000           VDP_REGISTER2_NAMETABLEADDRESS_SET_BIT12
.DEFINE VDP_REGISTER2_NAMETABLEADDRESS_0x1800           ( VDP_REGISTER2_NAMETABLEADDRESS_SET_BIT12 | VDP_REGISTER2_NAMETABLEADDRESS_SET_BIT11 )
.DEFINE VDP_REGISTER2_NAMETABLEADDRESS_0x2000           VDP_REGISTER2_NAMETABLEADDRESS_SET_BIT13
.DEFINE VDP_REGISTER2_NAMETABLEADDRESS_0x2800           ( VDP_REGISTER2_NAMETABLEADDRESS_SET_BIT13 | VDP_REGISTER2_NAMETABLEADDRESS_SET_BIT11 )
.DEFINE VDP_REGISTER2_NAMETABLEADDRESS_0x3000           ( VDP_REGISTER2_NAMETABLEADDRESS_SET_BIT13 | VDP_REGISTER2_NAMETABLEADDRESS_SET_BIT12 )
.DEFINE VDP_REGISTER2_NAMETABLEADDRESS_0x3800           ( VDP_REGISTER2_NAMETABLEADDRESS_SET_BIT13 | VDP_REGISTER2_NAMETABLEADDRESS_SET_BIT12 | VDP_REGISTER2_NAMETABLEADDRESS_SET_BIT11 )

; Helpful defines for non-standard (224- or 240-line) modes
.DEFINE VDP_REGISTER2_NAMETABLEADDRESS_NONSTANDARD_0x0700  0 
.DEFINE VDP_REGISTER2_NAMETABLEADDRESS_NONSTANDARD_0x1700  VDP_REGISTER2_NAMETABLEADDRESS_SET_BIT12
.DEFINE VDP_REGISTER2_NAMETABLEADDRESS_NONSTANDARD_0x2700  VDP_REGISTER2_NAMETABLEADDRESS_SET_BIT13
.DEFINE VDP_REGISTER2_NAMETABLEADDRESS_NONSTANDARD_0x3700  ( VDP_REGISTER2_NAMETABLEADDRESS_SET_BIT13 | VDP_REGISTER2_NAMETABLEADDRESS_SET_BIT12 )

;==============================================================================
; VDP REGISTER 3:  Color Table Base Address
;==============================================================================
; Any flags that are REQUIRED to be set.
.DEFINE VDP_REGISTER3_REQUIRED_MASK                     $FF

;==============================================================================
; VDP REGISTER 4:  Background Generator Address
;==============================================================================
; Any flags that are REQUIRED to be set.
.DEFINE VDP_REGISTER4_REQUIRED_MASK                     $07

;==============================================================================
; VDP REGISTER 5:  Sprite Attribute Table Base Address
;==============================================================================
; Any flags that are REQUIRED to be set.
.DEFINE VDP_REGISTER5_REQUIRED_MASK                     $01

.DEFINE VDP_REGISTER5_SAT_BIT13                         1 << 6
.DEFINE VDP_REGISTER5_SAT_BIT12                         1 << 5
.DEFINE VDP_REGISTER5_SAT_BIT11                         1 << 4
.DEFINE VDP_REGISTER5_SAT_BIT10                         1 << 3
.DEFINE VDP_REGISTER5_SAT_BIT9                          1 << 2
.DEFINE VDP_REGISTER5_SAT_BIT8                          1 << 1

;==============================================================================
; VDP REGISTER 6:  Sprite Pattern Generator Base Address
;==============================================================================
; Any flags that are REQUIRED to be set.
.DEFINE VDP_REGISTER6_REQUIRED_MASK                     $03

; This determines where sprite patterns come from.  Sprites can only access up
; to 256 individual tiles (8K).  By setting this, you can have sprites draw
; from the second half of VRAM.  Normally, sprites use the lower 8K while BG
; uses the upper 8K for additional tiles, sharing space with the tile map and
; sprite attirbute table.
; You might use this to have sprites use BG-only tiles.
.DEFINE VDP_REGISTER6_SPRITEGENERATOR_0x0000            0
.DEFINE VDP_REGISTER6_SPRITEGENERATOR_0x2000            ( VDP_REGISTER6_REQUIRED_MASK | ( 1 << 2 ) )

;==============================================================================
; VDP REGISTER 7:  Overscan color index (taken from Sprite palette)
;==============================================================================
; Any flags that are REQUIRED to be set.
.DEFINE VDP_REGISTER7_REQUIRED_MASK                     $00

.DEFINE VDP_REGISTER7_OVERSCANPALENTRY_BIT0             1 << 0
.DEFINE VDP_REGISTER7_OVERSCANPALENTRY_BIT1             1 << 1
.DEFINE VDP_REGISTER7_OVERSCANPALENTRY_BIT2             1 << 2
.DEFINE VDP_REGISTER7_OVERSCANPALENTRY_BIT3             1 << 3

;==============================================================================
; VDP REGISTER 8:  Background X Scroll
;==============================================================================
; Any flags that are REQUIRED to be set.
.DEFINE VDP_REGISTER8_REQUIRED_MASK                     $00

;==============================================================================
; VDP REGISTER 9:  Background Y Scroll
;==============================================================================
; Any flags that are REQUIRED to be set.
.DEFINE VDP_REGISTER9_REQUIRED_MASK                     $00

;==============================================================================
; VDP REGISTER 10:  Line Interrupt
;==============================================================================
; Any flags that are REQUIRED to be set.
.DEFINE VDP_REGISTER10_REQUIRED_MASK                     $00
