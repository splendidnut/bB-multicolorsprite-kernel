;---------------------------------------------------------------------------------
;- Example of Multi-colored variant of the batariBasic Multi-Sprite Kernel
;-
;- Kernel code based on modifications written for 1942.
;-     AtariAge topic: https://atariage.com/forums/topic/176639-1942-wip/
;-
;---------------------------------------------------------------------------------

    includesfile multisprite_superchip.inc
    set smartbranching on
    set optimization inlinerand
    set optimization noinlinedata
    set kernel multisprite
    set romsize 8k

;=======================
;--  Constants
;-----------------------

    const screenheight = 88

    ;--------------------------------------------------------------
    ;--- create a flag and include a color definition table
    ;--- to allow easy handling of NTSC & PAL color differences

    const IS_NTSC = 1                ; TV mode. IS_NTSC = 0 for PAL colors

    inline NTSC_PAL_colors.asm       ; Color constants are defined in external ASM file

    ; To use the ASM defined colors in bB assignments they have to be redefined,
    ; otherwise bB is using the ZP memory instead!

    const _Color_Blue_Sky            = _98
    const _Color_Forest              = _D4

    ;-----------------------------------------------------------------------------
    ;-- color table indexes into the color table stored in the kernel code area

    const _CI_WhitePlayerPlane  = <ct_white         - <SpriteColorTables
    const _CI_BlackPlane        = <ct_black         - <SpriteColorTables
    const _CI_RedFruit          = <ct_red_apple     - <SpriteColorTables
    const _CI_GreenFruit        = <ct_green_fruit   - <SpriteColorTables
    const _CI_OrangeFruit       = <ct_orange_fruit  - <SpriteColorTables
    const _CI_YellowFruit       = <ct_yellow_banana - <SpriteColorTables
    const _CI_Plane             = <ct_plane_colors  - <SpriteColorTables


    ;---------------------------------------------------------
    ;--- graphics pointers

    const _Player0_Plane_up_height   = 8
    const _Player0_Plane_up_high     = >_Player0_Plane_up
    const _Player0_Plane_up_low      = <_Player0_Plane_up

    const _Enemy1_Plane_up_height   = 7
    const _Enemy1_Plane_up_high     = >_Small_Plane_down
    const _Enemy1_Plane_up_low      = <_Small_Plane_down

    const _Apple_low = <_Apple
    const _Apple_high = >_Apple
    const _Apple_height = 10

    const _Orange_low = <_OrangeGfx
    const _Orange_high = >_OrangeGfx
    const _Orange_height = 8

    const _Banana_low = <_BananaGfx
    const _Banana_high = >_BananaGfx
    const _Banana_height = 9

    const _Pear_low = <_PearGfx
    const _Pear_high = >_PearGfx
    const _Pear_height = 9


    ;----------------------------
    ;--- Constants for Playfield

    const PLAYFIELD_HEIGHT  = 90
    const MAX_SCROLL_HEIGHT = 46    ;-- 90 - 44 (visible)


;==============================
;----- Variables
;------------------------------

    dim FireButtonPressedBit0 = a
    dim frameCounter = b

;===================================================================================
;--  Bank 1 - Game Code!

    bank 1

;---------------------------------
;-- {1} = sprite number
;-- {2} = data label
    asm
    macro setSpriteGraphics
.src = {2}
.dstLo = player{1}pointerlo
.dstHi = player{1}pointerhi
        LDA #<.src
        STA .dstLo
        LDA #>.src
        STA .dstHi
    endm
end

Start

    player0x = 76
    player0y = 25
    ;player0pointerlo = _Player0_Plane_up_low
    ;player0pointerhi = _Player0_Plane_up_high
    asm
    setSpriteGraphics  0, _Player0_Plane_up
end
    player0height = _Player0_Plane_up_height

    player1x = 76
    player1y = 76
    player1pointerlo = _Enemy1_Plane_up_low
    player1pointerhi = _Enemy1_Plane_up_high
    player1height = _Enemy1_Plane_up_height
    _COLUP1 = _CI_BlackPlane

    player2x = 10
    player2y = 10
    player2height = _Banana_height+1
    player2pointerlo = _Banana_low
    player2pointerhi = _Banana_high
    COLUP2 = _CI_YellowFruit

    player3x = 40
    player3y = 40
    player3height = _Orange_height+2
    player3pointerlo = _Orange_low
    player3pointerhi = _Orange_high
    COLUP3 = _CI_OrangeFruit

    player4x = 20
    player4y = 52
    player4height = _Apple_height
    player4pointerlo = _Apple_low
    player4pointerhi = _Apple_high
    COLUP4 = _CI_RedFruit

    player5x = 50
    player5y = 30
    player5height = _Pear_height
    player5pointerlo = _Pear_low
    player5pointerhi = _Pear_high
    COLUP5 = _CI_GreenFruit


    COLUPF = _Color_Forest
    COLUBK = _Color_Blue_Sky
    COLUP0 = #_1E
    COLUP1 = #_9E

    _COLUP0 = _CI_Plane ;_CI_WhitePlayerPlane

    pfheight = 1
    frameCounter = 55
    playfieldpos = 0

    goto setTestZone1

;----------------------------------
;-- Main Game loop
;----------------------------------
;
;-- check joystick direction, and move player accordingly
;--

MainLoop

    if !joy0up then goto _skip_move_up
    rem if frameCounter = MAX_SCROLL_HEIGHT then _skip_move_up
    if frameCounter = screenheight then _skip_move_up
    frameCounter = frameCounter + 1
    score = score + 1
_skip_move_up

    if !joy0down then goto _skip_move_down
    if frameCounter = 0 then _skip_move_down
    frameCounter = frameCounter - 1
    score = score - 1
_skip_move_down

    ;-----
    ;-- horizontal movement

    if !joy0right then goto _skip_move_right
    if player0x > 150 then _skip_move_right
    player0x = player0x + 1
_skip_move_right

    if !joy0left then goto _skip_move_left
    if player0x = 0 then _skip_move_left
    player0x = player0x - 1
_skip_move_left


    ;---- fun fire button code!
    if !joy0fire then goto _skip_fire
    if FireButtonPressedBit0{0} then goto _done_fire

    FireButtonPressedBit0{0} = 1
    score = score + 1
    frameCounter = frameCounter + 1
    goto _done_fire

_skip_fire
    FireButtonPressedBit0{0} = 0

_done_fire

    player1x = frameCounter ;/ 2
    if (player1x > 150) then player1x = 80

    player0y = frameCounter
    
    ;player0y = player0y + 1


    ;-----------------------------------------------------
    ;--  setup playfield pointer for multisprite kernel

    ;playfieldpos = frameCounter


    drawscreen
    goto MainLoop


;-------
;--- Subroutine to set multisprites in a pattern for display kernel testing

setTestZone1
    player1y = 55   ;-- Plane
    player2y = 33   ;-- banana
    player3y = 44   ;-- orange
    player4y = 22   ;-- apple
    player5y = 11   ;-- pear
    goto MainLoop

;-------------------------------------------------------------------------
; bB playfield definition can be anywhere.
; We are setting and changing the PF pointer manually in the game loop.
; So the code generated here (16 bytes) don't needs to be execute.

        ;--- This playfield is 90 lines tall
    playfield:
    ................
    ................
    ................
    ................
    .X.....X........
    XXX...XXX..X....
    .X.....X..XXX...
    XXX...XXX..X....
    XXX.X..X..XXX...
    XXXXXXXXXXXXX...
    .X..X..X...X....
    .X..X..X...X....
    ................
    ................
    ................
    ................
    ...X.....X......
    ..XXX...XXX..X..
    ...X.....X..XXX.
    ..XXX...XXX..X..
    ..XXX.X..X..XXX.
    ..XXXXXXXXXXXXX.
    ...X..X..X...X..
    ...X..X..X...X..
    ................
    ................
    ................
    ......X......X..
    .....XXX....XXX.
    ....XXXXX...XXX.
    ...XXXXXXX...X..
    ..XXXXXXXXX..X..
    XXXXXXXXXXXXXXXX
    ................
    ......X.........
    .....XXX.....X..
    ....XXXXX...XXX.
    ...XXXXXXX.XXXXX
    ..XXXXXXXXXXXXXX
    ................
    .X...X..........
    XXX.XXX...X.....
    XXXXXXXX.XXX..X.
    XXXXXXXXXXXX.XXX
    XXXXXXXXXXXXXXXX
end



;====================================================================================
;-----------------------------------------------------------------------------------
;--  Bank 2 - bB drawscreen and sprites (and playfield)
;--
;---  NOTE: This should always be the last bank

    bank 2


;---
;--- The following macro helps keep sprite graphics contained within a page.
;---
    asm
      MAC PAD_BB_SPRITE_DATA
.SPRITE_HEIGHT  SET {1}
      if	(<*) > (<(*+.SPRITE_HEIGHT))
      repeat	($100-<*)
      .byte	0
      repend
      endif
      if (<*) < 90
	   repeat (90-<*)
	   .byte 0
	   repend
	   endif
   ENDM

;-----------------------------------------------------------------------------------
;--  Color tables used for the shared P1 sprite
;
;-- These tables are accessed using the COLUx variable from each sprite as an index
;-- For each row in this table, the first color is the bottom color of the sprite, moving up towards the top

    PAD_BB_SPRITE_DATA (7*8)

    echo "Sprite Color tables start at ", *

SpriteColorTables:

;-- B&W palettes (dark and light)
ct_black:               .byte _00,_00,_02,_04,_00,_02,_02,_04
ct_white:               .byte _0A,_0A,_0C,_0E,_0A,_0C,_0C,_0E

;-- Fruit colors
ct_green_fruit:         .byte _D6,_D6,_D8,_D8,_D8,_DA,_DA,_24
ct_yellow_banana:       .byte _14,_16,_18,_1A,_1E,_1E,_1E,_24
ct_orange_fruit:        .byte _24,_26,_26,_28,_28,_2A,_2C,_2E
ct_red_apple:           .byte _22,_32,_32,_34,_34,_36,_38,_D8

ct_plane_colors:        .byte _06,_08,_0A,_8C,_4A,_DA,_2C,_1E

   echo "Color tables end at ", *

end

;=======================================================
;--  Sprite Graphics Data

    asm
    PAD_BB_SPRITE_DATA 5
end
  data _Small_Plane_down
   %00011000
   %01111110
   %01111110
   %00011000
   %00111100
   0
end

   asm
   PAD_BB_SPRITE_DATA 8
end
   data _Player0_Plane_up
   0
   %00111100
   %00011000
   %00011000
   %00111100
   %11111111
   %11111111
   %00011000
end

    asm
    PAD_BB_SPRITE_DATA 8
end
    data _Apple
    %00101000
    %01111100
    %11111110
    %11111110
    %11111110
    %01111100
    %00010000
    %00001000
    0
end

    asm
    PAD_BB_SPRITE_DATA 7
end
    data _OrangeGfx
    %00111000
    %01111100
    %11111110
    %11111110
    %11111110
    %01111100
    %00111000
    0
end

    asm
    PAD_BB_SPRITE_DATA 8
end
    data _BananaGfx
    %00110000
    %01100000
    %11000000
    %11000000
    %11000000
    %01100000
    %00110000
    0
end

    asm
    PAD_BB_SPRITE_DATA 8
end
    data _PearGfx
    %00111100
    %01111110
    %01111110
    %00111100
    %00111100
    %00011000
    %00100000
    0
end


