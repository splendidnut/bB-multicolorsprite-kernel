# bB-multicolorsprite-kernel
A batariBasic kernel for handling multiple multi-colored sprites.

To use this kernel in your project, drop the files in your project folder.  The batariBasic compiler will use automatically use these files versus it's own when the multisprite kernel option is selected in the BAS file.

Overview of Files:
 - NTSC_PAL_colors.asm  - provides the typical underscore-hex-named color consts (_00.._FF) that make it easy to switch between PAL and NTSC colors in your project
 - exMultiSpriteColorKernel.bas - an example program showing how to use the kernel
 - multisprite.h - bBasic variable definition / allocation file
 - multisprite_kernel.asm - the Multi-color Multi-Sprite display kernel
 - multisprite_superchip.inc - the 'build' file which tells bBasic what libraries need to be included when building the project
