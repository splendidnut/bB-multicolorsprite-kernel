# bB-multicolorsprite-kernel
A batariBasic kernel for handling multiple multi-colored sprites.

To use this kernel in your project, all you need to do is drop the files in your project folder.  The batariBasic compiler will automatically use these files (versus it's own) when the multisprite kernel option is selected in the BAS source file.

Overview of Files:
 - NTSC_PAL_colors.asm  - provides the typical underscore-hex-named color consts (_00.._FF) that make it easy to switch between PAL and NTSC colors in your project
 - exMultiSpriteColorKernel.bas - an example program showing how to use the kernel
 - multisprite.h - bBasic variable definition / allocation file
 - multisprite_kernel.asm - the Multi-color Multi-Sprite display kernel
 - multisprite_superchip.inc - the 'build' file which tells bBasic what libraries need to be included when building the project

​
---
Basic Setup and Usage:

The color table needs to be located in the last bank of project (kernel bank).  Using inlined ASM works best here, since you will want to define labels for each section of the color table.

 
<pre>
;-----------------------------------------------------------------------------------
;--  Color tables used for the shared P1 sprite
;
;-- These tables are accessed using the COLUx variable from each sprite as an index
;-- For each row in this table, the first color is the bottom color of the sprite, moving up towards the top

    asm
    PAD_BB_SPRITE_DATA (7*8)

    echo "Sprite Color tables start at ", *

SpriteColorTables:
ct_unused:              .byte 0,0,0,0,0,0,0,0,0,0   ;-- padding to support sprites going off top of screen

;-- Fruit colors
ct_red_apple:           .byte _22,_32,_32,_34,_34,_36,_38,_D8

   echo "Color tables end at ", *

end
</pre>
 

It works out if sprite graphics are defined in a similar fashion after the color tables from above:

<pre>
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
</pre>
 

You'll want to create constants to calculate the indexes for each of the color table labels.

<pre>
    ;-----------------------------------------------------------------------------
    ;-- color table indexes into the color table stored in the kernel code area

    const _CI_RedFruit          = &lt;ct_red_apple     - &lt;SpriteColorTables
</pre> 

And some constants for the sprite data:

<pre>
    const _Apple_low = &lt;_Apple
    const _Apple_high = &gt;_Apple
    const _Apple_height = 10
</pre>
 
Then to set the sprite (position, graphics data, and color):

<pre>
    player4x = 20
    player4y = 52
    player4height = _Apple_height
    player4pointerlo = _Apple_low
    player4pointerhi = _Apple_high
    COLUP4 = _CI_RedFruit
</pre>

​
