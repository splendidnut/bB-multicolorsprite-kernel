;----------------------------------------------------------------------------
;---    bBasic Multi-sprite kernel - customized to add multi-color support
;---
;----------------------------------------------------------------------------
; Provided under the CC0 license. See the included LICENSE.txt for details.
;----------------------------------------------------------------------------
;
;---------------------------------------------
;--- Some assumptions:
;---
;---    screenheight = 88       (176 scanlines for playfield)
;---                            (22  scanlines for status and score)
;---                            (198 total scanlines visible)
;---    pfheight = 0, 1, or 3
;--
;--  During the display kernel,
;--        COLUP0 starts off being whatever value the user set it to.
;--        COLUP0 will be switched to read from the color table 
;--           only when it's time to draw the player.

    align 256

__MCMSK_START:

_show_kernel_stats = 1     ;--- comment this out to hide kernel stats display during build

;--------------------------------------------------
;--- Constants

    ifnconst screenheight
screenheight = 88
    endif

    ifnconst overscan_time
overscan_time = 37
    endif

    ifnconst vblank_time
vblank_time   = 43
    endif


SCREEN_HEIGHT           = screenheight
PF_START_OFS            = ((88 - SCREEN_HEIGHT) / 4)
SPR_OFS                 = 2
KERNEL_OVERSCAN_TIME    = (overscan_time+5+128)
KERNEL_VBLANK_TIME      = (vblank_time+9+128)

CNT_SPRITES_SORT        = 4  ;-- how many sprites_to_sort-1



;--------------------------------------------------
;--- Temporary Variables

;--- NOTE:  $f6 is used as temporary storage of the Stack Pointer during the kernel, 
;             so it cannot be used here

;---- allow multicolor player0 --> loaded right before the kernel executes
player0colorP = $F7
player0colorPlo = $F7
player0colorPhi = $F8

;player1colorP = $F8
;player1colorPlo = $F8
;player1colorPhi = $F9

patchCOLP0_0  = $F9    ;-- patch in player 0 color
patchCOLP0_1  = $FA    ;-- patch in player 0 color
curCOLP1      = $FB
curRowPF      = $FC

;==================================================================
;==== CODE
;=============

PFStart
    .byte 87,43,0,21,0,0,0,10
blank_pf
    .byte 0,0,0,0,0,0,0,5

    ;--set initial P1 positions
multisprite_setup
    ldx #CNT_SPRITES_SORT
SetCopyHeight
    txa
    sta SpriteGfxIndex,X
    sta spritesort,X
    dex
    bpl SetCopyHeight

; since we can't turn off pf, point PF to zeros here
    lda #15
    sta pfheight

    lda #>blank_pf
    sta PF2pointer+1
    sta PF1pointer+1
    lda #<blank_pf
    sta PF2pointer
    sta PF1pointer
    rts


;=====================================================================
;---------------------------------------------------------------------


drawscreen
  ifconst debugscore
    jsr debugcycles
  endif

WaitForOverscanEnd
    lda INTIM
    bmi WaitForOverscanEnd

    lda #2
    sta WSYNC
    sta VSYNC
    sta WSYNC
    sta WSYNC
    lda #0
    sta WSYNC
    sta VSYNC        ;turn off VSYNC

    lda #KERNEL_OVERSCAN_TIME
    sta TIM64T

; run possible vblank bB code
  ifconst vblank_bB_code
    jsr vblank_bB_code
  endif

    jsr SetupP1Subroutine

    ;-------------
    ;--position P0, M0, M1, BL

    jsr PrePositionAllObjects

    ;--set up player 0 pointer

    ;---- setup temp7 with position to switch COLUP0
    lda player0y
    adc #2
    sta temp7


    ;------------------------ setup player0 positioning
    lda player0pointer ; player0: must be run every frame!
    sec
    sbc player0y
    clc
    adc player0height
    sta player0pointer

    ;-------------------------
    ;-- Setup color pointers to the color table for reading colors during the kernel

    lda #<SpriteColorTables
    ldx #>SpriteColorTables
    sta <player1colorP
    stx <player1colorP+1

    ;-- Setup color pointer for the player sprite (sprite0)
    ;-- player0colorP = SpriteColorTables + _COLUP0 - player0y + player0height
    clc
    adc _COLUP0
    bcc _no_colup0_inc
    inx
_no_colup0_inc:

    sec
    sbc player0y
    bcs _no_colup0_dec
    dex
_no_colup0_dec:

    clc
    adc player0height
    bcc _no_colup0_inc2
    inx
_no_colup0_inc2:

    sta player0colorPlo
    stx player0colorPhi

    ;---- calculate the top and bottom scanlines of the player sprite

    lda player0y
    sta P0Top
    sec
    sbc player0height
    clc
    adc #$80
    sta P0Bottom

    jsr setupColorPatchForP0



;-----------------------------

    ;--some final setup

    ldx #4
    lda #$80
cycle74_HMCLR
    sta HMP0,X
    dex
    bpl cycle74_HMCLR
;    sta HMCLR


    lda #0
    sta PF1
    sta PF2
    sta GRP0
    sta GRP1
    sta VDELP0
    sta VDELBL


    jsr KernelSetupSubroutine
    jmp NewStartForKernelRoutine


;----------------------------------------------------------------------
;--  Horizontal Position Routine
;----------------------------------------------------------------------
; Call this function with 
;       A == horizontal position (0-159)
;   and X == the object to be positioned (0=P0, 1=P1, 2=M0, etc.)
;
; If you do not wish to write to P1 during this function, make
; sure Y==0 before you call it.  This function will change Y, and A
; will be the value put into HMxx when returned.
; Call this function with at least 11 cycles left in the scanline 
; (jsr + sec + sta WSYNC = 11); it will return 9 cycles
; into the second scanline

PositionASpriteSubroutine        
    sec
    sta WSYNC                   ;begin line 1
    sta.w HMCLR                 ;+4         4
DivideBy15Loop
    sbc #15
    bcs DivideBy15Loop          ;+4/5        8/13.../58

    tay                         ;+2        10/15/...60
    lda FineAdjustTableEnd,Y    ;+5        15/20/...65

                                ;        15
    sta HMP0,X                  ;+4        19/24/...69
    sta RESP0,X                 ;+4        23/28/33/38/43/48/53/58/63/68/73
    sta WSYNC                   ;+3         0        begin line 2
    sta HMOVE                   ;+3
    rts                         ;+6         9

   

;-------------------------------------------------------------------------

PrePositionAllObjects

    ldx #4
    lda ballx
    jsr PositionASpriteSubroutine
    
    dex
    lda missile1x
    jsr PositionASpriteSubroutine
    
    dex
    lda missile0x
    jsr PositionASpriteSubroutine

    dex
    dex
    lda player0x
    jsr PositionASpriteSubroutine

    rts



ApplyPlayfieldScroll
    ;--- Load playfield pointers for the kernel

    lda #<PF1_data0
    clc
    adc playfieldpos
    sta PF1pointer
    lda #>PF1_data0
    adc #0
    sta PF1pointerHi

    lda #<PF2_data0
    clc
    adc playfieldpos
    sta PF2pointer
    lda #>PF2_data0
    adc #0
    sta PF2pointerHi
    rts



;------------------------------------------------------------------------------------------------

KernelSetupSubroutine
    jsr  ApplyPlayfieldScroll

    ;----- Adjust Y positions of Sprite1 .. Sprite5
    ;-----   and create PxBottom cache values for kernel use
    ldx #4
AdjustYValuesUpLoop
    lda NewSpriteY,X
    clc
    adc #SPR_OFS
    sta NewSpriteY,X

    sec                         ;2  [44]
    sbc spriteheight,X          ;4  [48]
    sta P1BottomCache,X         ;3  [51]

    dex
    bpl AdjustYValuesUpLoop

    ;------

    ldx temp3 ; first sprite displayed

    lda SpriteGfxIndex,x
    tay
    lda NewSpriteY,y
    sta RepoLine

    lda SpriteGfxIndex-1,x
    tay
    lda NewSpriteY,y
    sta tmpRepoLine

    inx                 ;--- use sprite 0 AS no more sprites indicator
    stx SpriteIndex


    ;------------------- initialize other kernel variables
    lda #255
    sta P1Bottom

    lda player0y

    cmp #SCREEN_HEIGHT + 1                ;--- screenheight + 1

    bcc nottoohigh
    lda P0Bottom
    sta P0Top                

    

nottoohigh

    ;------- setup an "empty index" which actually points to the first sprite
    lda #0
    sta EmptySpriteGfxIndex
    rts

;-------------------------------------------------------------------------
;------------------------------------------------------------------------
;-- FineAdjustTable - HMove table
;--
;-- NOTE:  This table needs to be here to prevent interference with
;--        the superchip due to the forced page-crossing used when
;--        accessing this table.

FineAdjustTableBegin
    .byte %01100000                ;left 6
    .byte %01010000
    .byte %01000000
    .byte %00110000
    .byte %00100000
    .byte %00010000
    .byte %00000000                ;left 0
    .byte %11110000
    .byte %11100000
    .byte %11010000
    .byte %11000000
    .byte %10110000
    .byte %10100000
    .byte %10010000
    .byte %10000000                ;right 8

    ;-- label used when table is accessed via forced page-crossing
FineAdjustTableEnd        =        (FineAdjustTableBegin - 241)




;-------------------------------------------------------------------------
;----------------------Kernel Routine-------------------------------------
;-------------------------------------------------------------------------
    
START_OF_KERNEL_ROUTINES:

;-------------------------------------------------------------------------
; repeat $f147-*
; brk
; repend
;    org $F240

;-------------------------------------------------------------------------
NewStartForKernelRoutine:
    
    ldy  #SCREEN_HEIGHT         ;2  [41]  -- screenheight
WaitVblankEnd
    lda INTIM
    bmi WaitVblankEnd
    
    lda #0                      ;prep to turn off VBLANK - it was turned on by overscan
    sta WSYNC                   ;3  [0]
    sta VBLANK                  ;3  [3] - turn off VBLANK
    sta CXCLR                   ;3  [6]
    sta curCOLP1                ;3  [9]
    
    tsx                         ;2  [11]
    stx stack1                  ;3  [14]
    ldx #ENABL                  ;2  [16]
    txs                         ;2  [18]

    ldx #0                      ;2  [20]
    lda pfheight                ;3  [23] -- scanlines per playfield pixel
    bpl asdhj                   ;2,3  [25]
    .byte $24                   ;3  [28]    -- use 'BIT zp' to skip over TAX
asdhj
    tax                         ;2  [28]    -- skipped if branch not taken

    ;---
    lda  PFStart,x              ;4  [32] get pf pixel resolution for heights 15,7,3,1,0
    sec                         ;2  [34]
    sbc  #PF_START_OFS          ;2  [36]
    sta  curRowPF               ;3  [39]

    nop                         ;2  [41]

    jmp     KernelLoopA         ;3  [44]

;---------------------------------------------------------

SwitchDrawP0K1                  ;----- enter at 63
    lda P0Bottom                    ;3  [66]
    sta P0Top                       ;3  [69]
    sleep 8                         ;8  [1]
    jmp BackFromSwitchDrawP0K1      ;3  [4]

WaitDrawP0K1                    ;----- enter at 65
    lda    #0                       ;2  [67]
    sta.w  COLUP0                   ;4  [71]
    SLEEP 6                         ;6  [1]
    jmp BackFromSwitchDrawP0K1      ;3  [4]

;SkipDrawP1K1                    ;----- enter at 3
;    lda #0                          ;2  [5]
;    sta GRP1                        ;3  [8]        so Ball gets drawn
;    jmp BackFromSkipDrawP1          ;3  [11]

    
;---- Actual display kernel starts here
;--
;--- KernelLoopA is hit most of the time
;--- KernelLoopB is only hit when playfield row is changed
    
KernelLoopA                 ;----- enter at 44
    SLEEP 10                      ;10  [54]

    ;---- DRAWING line 1 -> player0, player1, playfield

KernelLoopB                 ;----- enter at 54
    sty tmpSprLine              ;3  [57]    -- save sprite Y counter

    cpy P0Top                   ;3  [60]
    beq SwitchDrawP0K1          ;2  [62]
    bpl WaitDrawP0K1            ;2  [64]    -- wait to draw P0

    lax (player0colorP),y       ;5  [69]    -- load in player color
    lda (player0pointer),Y      ;5  [74]
    sta GRP0                    ;3  [1]      VDEL because of repokernel
    stx COLUP0                  ;3  [4]

BackFromSwitchDrawP0K1      ;-- enter at cycle 4

    sleep 8                     ;8  [12]
 
    ldy curRowPF                ;3  [15]    -- restore playfield row counter    
    lda (PF1pointer),y          ;5  [20]    -- load in playfield data
    sta PF1                     ;3  *23*  (needs to be < 28)
    lda (PF2pointer),y          ;5  [28]
    sta PF2                     ;3  *31*  (needs to be < 38)

    ;--- load P1 colors (do everything except the STA)

    ldy curCOLP1                ;3  [34]
    lda SpriteColorTables,y     ;4  [38]
    inc curCOLP1                ;5  [43]
    
    ldy tmpSprLine              ;3  [46]
    
    ;//------ DRAWING line 2 -> ball + 2 missiles,  store color for P1, 
    ;                             call repo if time to do that, switch P0 color,
    ;      --                         calc next repo, handle scanline / row counters

    ;--- Y currently has tmpSprLine
    ldx #ENABL                  ;2  [48]
    txs                         ;2  [50]
    cpy bally                   ;3  [53]
    php                         ;3  [56]        VDEL ball

    cpy missile1y               ;3  [59]
    php                         ;3  [62]

    cpy missile0y               ;3  [65]
    php                         ;3  [68]
    dey                         ;2  [70]

    sta COLUP1                  ;3  [73]    -- Apply p1 color update here
    
    cpy RepoLine                ;3  [76/0]
    beq RepoKernel              ;2  [2]        -- If we hit a reposition line, jump to that kernel

    ;---- continue regular kernel

    cpy P1Bottom                ;3  [5]        unless we mean to draw immediately, this should be set
                                ;                to a value greater than maximum Y value initially
    bcc SkipDrawP1K2            ;2  [7/8]
    lda (P1display),Y           ;5  [12]
    sta.w GRP1                  ;4  [16]
                                
BackFromSkipDrawP1_2
    ldx    SpriteIndex          ;3  [19] --  restore index into new sprite vars
    lda    SpriteGfxIndex-2,X   ;4  [23]
    tax                         ;2  [25]
    lda    NewSpriteY,x         ;4  [29]
    sta    tmpRepoLine          ;3  [32] -- save next RepoLine value for reposition kernel to use

    nop                         ;2  [34]
    nop                         ;2  [36]

BackFromRepoKernel              ;--- enter at 36
    tya                         ;2  [38]
    bit pfheight                ;3  [41]  -- do AND using BIT because we only care about the CPU flags
    bne KernelLoopA             ;2  [43/44]
    sleep 3                     ;3  [46]
    dec curRowPF                ;5  [51] -- next playfield row
    bpl KernelLoopB             ;+3 [54]

;-----
    jmp DoneWithKernel          ;3  [56] ---- Done with Kernel, so jump out

SkipDrawP1K2                    ;----- enter at 8
    lda #0                          ;2  [10]
    sta GRP1                        ;3  [13]        so Ball gets drawn
    jmp BackFromSkipDrawP1_2        ;3  [16]

;-----------------------------------------------------------
;--- Utility code blocks for Reposition Kernel
    align 256

SwitchDrawP0KR                  ;--- entered at cycle 28
    lda P0Bottom                    ;3  [31]
    sta P0Top                       ;3  [34]
    jmp BackFromSwitchDrawP0KR      ;3  [37]

WaitDrawP0KR                    ;--- entered at cycle 30
    SLEEP 4                         ;4  [34]
    jmp BackFromSwitchDrawP0KR      ;3  [37]

noUpdateXKR                     ;--- entered at cycle 16
    SLEEP 3                         ;3  [19]
    JMP retXKR                      ;3  [22]


    ;--------------------------------------------------------------------------
    ;--  RepoKernel  - Reposition P1 Kernel
    ;---------------------------------------
    ;
    ;   This kernel takes 4 scanlines:
    ;     - (2b) Prep and load P0, PF1, PF2 for DRAWING Line 1.
    ;     - (1)  Reposition P1
    ;     - (2)  Update M0,M1,BL right before display starts (DRAWING Line 2)
    ;               and then Prep for DRAWING Line 1 and do EARLY HMOVE
    ;     - (1)  Prepare everything for the new P1
    ;            Prep for line 2 (M0,M1,BL)
    ;
    ;--------------------------------------------------------------------------
    ;  This repositioning kernel is entered after the graphics updates for
    ;   DRAWING line 2 have occured
    ;--------------------------------------------------------------------------
RepoKernel                  ;--- enter at 2
    lda #0                      ;2  [4]
    sta.w GRP1                  ;4  [8]
    
    ;---- check if we need to move to next PF row...
    ;--    ... since we left the Main kernel before that check was done
    tya                         ;2  [10]
    and pfheight                ;3  [13]
    bne noUpdateXKR             ;2  [15/16]
    nop                         ;2  [17]  -- spare cycles
    dec curRowPF                ;5  [22]

retXKR                      ;--- enter at 22

    cpy P0Top                   ;3  [25]
    beq SwitchDrawP0KR          ;2  [27]
    bpl WaitDrawP0KR            ;2  [29]

    lda (player0pointer),Y      ;5  [34]
    sta GRP0                    ;3  [37]    -- VDEL used to hold update until GRP1 updated on DRAWING line 1

BackFromSwitchDrawP0KR      ;--- enter at 37

    ldx #ENABL                  ;2  [39]
    txs                         ;2  [41]

    ldy SpriteIndex             ;3  [44]
    ldx SpriteGfxIndex-1,y      ;4  [48]

    sec                         ;2  [50]

    lda patchCOLP0_0            ;3  [53] -- patch in player 0 color
    sta COLUP0                  ;3  [56]

    ldy curRowPF                ;3  [59]    -- restore playfield row counter
    lda (PF2pointer),y          ;5  [64]    -- load in playfield data
    sta PF2                     ;3  *67*
    lda (PF1pointer),y          ;5  [72]
    sta PF1                     ;3  *75*

    ;------------------------- DRAWING Line 1 -> use GRP1 to trigger GRP0.... then reposition!

    lda #0                      ;2  [1]
    sta GRP1                    ;3  [4] --     to display player 0
    lda NewSpriteX,X            ;4  [8]
 
DivideBy15LoopK                 ;--- first entered at 8        (carry set above)
    sbc #15                     ;2         8
    bcs DivideBy15LoopK         ;+2/3      10/15.../60

    tax                         ;+2        12/17/...62
    lda FineAdjustTableEnd,X    ;+5        17/22/...67

    sta HMP1                    ;+3        20/25/...70
    sta RESP1                   ;+3        23/28/33/38/43/48/53/58/63/68/73

    ;---------------------- DRAWING Line 2 -> M0, M1, BL

    sta WSYNC                   ;+3 *0*        begin line 2
    
    ldy RepoLine                ;3  [3]      restore y

    cpy bally                   ;3  [6]
    php                         ;3  [9]        VDEL ball

    cpy missile1y               ;3  [12]
    php                         ;3  [15]

    cpy missile0y               ;3  [18]
    php                         ;3  [21]

    ;----- determine which cached playfield data to use  (15 cycles + potential page crossing branch)
    ;--- *13* cycles to determine whether if on last scanline of playfield row

    ;----------------------- Early PERP for DRAWING Line 1 -> P0, P1, PF
    dey                         ;2  [23]
    cpy P0Top                   ;3  [26]
    beq SwitchDrawP0KV          ;2  [28]
    bpl WaitDrawP0KV            ;2  [30]

    lda (player0pointer),Y      ;5  [35]
    sta GRP0                    ;3  [38]        VDEL

BackFromSwitchDrawP0KV      ;---- enter at 38
    sty tmpSprLine              ;3  [41]

    ;--- need to check if it's time to move to the next PF row
    tya                         ;2  [43]
    ldy curRowPF                ;3  [46]    -- restore playfield row counter
    and pfheight                ;3  [49]
    bne noUpdateXKR1            ;2  [51]
    dey                         ;2  [53]
    nop                         ;2  [55]  -- spare cycles
retXKR1                      ;--- enter at 55

    ldx #ENABL                  ;2  [57]
    txs                         ;2  [59]
    
    lax (PF2pointer),y          ;5  [64]    -- load in playfield data
    lda (PF1pointer),y          ;5  [69]
    sta HMOVE                   ;4  *72*  --- EARLY HMOVE    
    stx PF2                     ;3  [75]
    sta PF1                     ;3  [2]
    
    lda #0                      ;2  [4]
    sta GRP1                    ;3  [7]  --        to display GRP0

    lda patchCOLP0_1            ;3  [10] -- patch in player 0 color
    sta COLUP0                  ;3  [13]

    
    
    ;---------------------------------------------------------------------------
    ;--   now, set all new variables and return to main kernel loop

    ldy SpriteIndex             ;3  [16] --  restore index into new sprite vars
    ldx SpriteGfxIndex-1,y      ;4  [20]

    lda NewNUSIZ,X              ;4  [24]    -- load in size and color for new sprite
    sta NUSIZ1                  ;3  [27]
    sta REFP1                   ;3  [30]
    lda NewCOLUP1,X             ;4  [34]
    sta curCOLP1                ;3  [37]

    sec                         ;2  [39]

    lda P1BottomCache,X         ;4  [43]    -- load in bottom of new sprite
    sta P1Bottom                ;3  [46]

    lda player1pointerlo,X      ;4  [50]
    sbc P1Bottom                ;3  [53]    carry should still be set
    sta P1display               ;3  [56]
    lda player1pointerhi,X      ;4  [60]
    sta P1display+1             ;3  [63]

    ;--- restore kernel scanline counter
    ldy tmpSprLine              ;3  [66]

    ;---------------------------- DRAWING Line 2 -> M0, M1, BL

    cpy bally                   ;3  [69]
    php                         ;3  [72]        VDELed

    cpy missile1y               ;3  [75]
    php                         ;3  [2]

    cpy missile0y               ;3  [5]
    php                         ;3  [8]

;-- move to next sprite 
    dec SpriteIndex             ;5  [13]

    lda tmpRepoLine             ;3  [16]
    sta RepoLine                ;3  [19]

    tya                         ;2  [21]
    dey                         ;2  [23]

    ;sleep 4                     ;4  [23]

    and pfheight                ;3  [26]
    bne nodec                   ;2  [28]
    dec curRowPF                ;5  [33]
    jmp BackFromRepoKernel      ;3  [36]        -->>>  RETURN to main kernel

nodec                       ;-- enter at cycle 29
    sleep 4                     ;4  [33]
    jmp BackFromRepoKernel      ;3  [36]        -->>>  RETURN to main kernel

;------------------------------------------------------------

noUpdateXKR1                ;----- enter at cycle 50
    JMP retXKR1                 ;3  [53]

SwitchDrawP0KV              ;-- enter at cycle 48
    lda P0Bottom                ;3  [51]
    sta P0Top                   ;3  [54]
    jmp BackFromSwitchDrawP0KV  ;3  [57]

WaitDrawP0KV                ;----- enter at cycle 50
    sec
    nop
    ;SLEEP 4                     ;4  [54]
    jmp BackFromSwitchDrawP0KV  ;3  [57]

;------------------------------------------------------------


END_OF_KERNEL_ROUTINES:



;-------------------------------------------------------------------------

DoneWithKernel

BottomOfKernelLoop

    sta WSYNC
    ldx stack1
    txs
    ldx #0
    STx GRP0
    STx GRP1 ; seems to be needed because of vdel

    jsr setscorepointers
    jsr sixdigscore ; set up score

    sta WSYNC
    sta HMCLR               ;3  [3]

    lda #$01                ;2  [5]
    sta CTRLPF              ;3  [8]

    ldy #7                  ;2  [10]
    sty VDELP0              ;3  [13]
    sty VDELP1              ;3  [16]
    LDA #$10                ;2  [18]
    STA HMP1                ;3  [21]
    LDA scorecolor          ;3  [24]
    STA COLUP0              ;3  [27]
    STA COLUP1              ;3  [30]
    
    LDA #$03                ;2  [32]
    STA NUSIZ0              ;3  [35]
    STA NUSIZ1              ;3  [38]

    STA RESP0               ;3  *41*
    STA RESP1               ;3  *44*

    sleep 4                 ;4  [48]

    lda  (scorepointers),y  ;5  [53]
    sta  GRP0               ;3  [56]
  ifconst pfscore
    lda pfscorecolor        ;3  [59]
    sta COLUPF              ;3  [62]
  else
    sleep 6                 ;6  [62]
  endif

    lda  (scorepointers+8),y;5  [67]

    sleep 3                 ;3  [70]
    STA.w HMOVE             ;4  [74]  Early HMOVE
    jmp beginscore          ;3  [1]

 align 64

loop2
    lda  (scorepointers),y     ;+5  68  204
    sta  GRP0            ;+3  71  213      D1     --      --     --
  ifconst pfscore
  if pfscore = 1 || pfscore = 3
    lda pfscore1
    sta PF1
  else
    lda #0
    sta PF1
    nop
  endif
  else
    sleep 6
  endif
    ; cycle 0
    lda  (scorepointers+$8),y   ;+5   5   15
beginscore
    sta  GRP1                   ;+3   8   24      D1     D1      D2     --
    lda  (scorepointers+$6),y   ;+5  13   39
    sta  GRP0                   ;+3  16   48      D3     D1      D2     D2
    lax  (scorepointers+$2),y   ;+5  29   87
    txs
    lax  (scorepointers+$4),y   ;+5  36  108
    sleep 4
  ifconst pfscore
  if pfscore > 1
    lda statusbarlength
    sta PF1
  else
    lda #0
    sta.w PF1
  endif
  else
    sleep 6
  endif
    lda  (scorepointers+$A),y   ;+5  21   63
    stx  GRP1                   ;+3  44  132      D3     D3      D4     D2!
    tsx
    stx  GRP0                   ;+3  47  141      D5     D3!     D4     D4     ..[42,43,44]
    sta  GRP1                   ;+3  50  150      D5     D5      D6     D4!
    sty  GRP0                   ;+3  53  159      D4*    D5!     D6     D6
    dey
    bpl  loop2           ;+2  60  180

_done_with_score_loop

    ldx stack1
    txs

    LDA #0   
    STA GRP0
    STA GRP1
    sta PF1 
    sta PF0
    STA VDELP0
    STA VDELP1;do we need these
    STA NUSIZ0
    STA NUSIZ1


;-------------------------------------------------------------------------
;------------------------Overscan Routine---------------------------------
;-------------------------------------------------------------------------

OverscanRoutine



skipscore
  ifconst qtcontroller
    lda qtcontroller
    lsr    ; bit 0 in carry
    lda #4
    ror    ; carry into top of A
  else
    lda #2
  endif ; qtcontroller
    sta WSYNC
    sta VBLANK        ;turn on VBLANK

;--------------------------------
;---- KernelCleanupSubroutine
;--------------------------------

    ldx #4
AdjustYValuesDownLoop
    lda NewSpriteY,X
    sec
    sbc #SPR_OFS
    sta NewSpriteY,X
    dex
    bpl AdjustYValuesDownLoop

    ; restore P0pointer

    lda player0pointer
    clc
    adc player0y
    sec
    sbc player0height
    sta player0pointer
    ;inc player0y


    RETURN        ;--- Display kernel is done, return to appropriate address


;-------------------------------------------------------------------------
;----------------------------End Main Routines----------------------------
;-------------------------------------------------------------------------




MaskTable
    .byte 1,3,7,15,31

    ; shove 6-digit score routine here

sixdigscore
    lda #0
    sta PF0
    sta PF1
    sta PF2
    sta ENABL
    sta ENAM0
    sta ENAM1

    ;end of main kernel here


    ; 6 digit score routine

    sta WSYNC
    sta REFP0
    sta REFP1
    STA GRP0
    STA GRP1
    sta HMCLR


    ;--- Start VBLANK timer

    lda  #KERNEL_VBLANK_TIME
    sta  TIM64T

  ifconst minikernel
    jsr minikernel
  endif
  ifconst noscore
    pla
    pla
    jmp skipscore
  endif

    ;--- set high bytes of score pointers

    lda #>scoretable
    sta scorepointers+1
    sta scorepointers+3
    sta scorepointers+5
    sta scorepointers+7;temp2
    sta scorepointers+9;temp4
    sta scorepointers+11;temp6

    rts


; room here for score?

setscorepointers
    lax score+2
    jsr scorepointerset
    sty scorepointers+10;5
    stx scorepointers+2
    lax score+1
    jsr scorepointerset
    sty scorepointers+4
    stx scorepointers+6;1
    lax score
    jsr scorepointerset
    sty scorepointers+8;3
    stx scorepointers
    rts

scorepointerset
    and #$0F
    asl
    asl
    asl
    adc #<scoretable
    tay
    txa
    and #$F0
    lsr
    adc #<scoretable
    tax
    rts
;    align 256


;-------------------------------------------------------------------------
;----------------------Begin Subroutines----------------------------------
;-------------------------------------------------------------------------




SetupP1Subroutine
; flickersort algorithm
; count 4-0
; table2=table1 (?)
; detect overlap of sprites in table 2
; if overlap, do regular sort in table2, then place one sprite at top of table 1, decrement # displayed
; if no overlap, do regular sort in table 2 and table 1
fsstart
    ldx #255
copytable
    inx
    lda spritesort,x
    sta SpriteGfxIndex,x
    cpx #CNT_SPRITES_SORT
    bne copytable

    stx temp3 ; highest displayed sprite
    dex
    stx temp2
sortloop
    ldx temp2
    lda spritesort,x
    tax
    lda NewSpriteY,x
    sta temp1

    ldx temp2
    lda spritesort+1,x
    tax
    lda NewSpriteY,x
    sec
    clc
    sbc temp1
    bcc largerXislower

; larger x is higher (A>=temp1)
    cmp spriteheight,x
    bcs countdown
; overlap with x+1>x
;    
; stick x at end of gfxtable, dec counter
overlapping
    dec temp3
    ldx temp2
;    inx
    jsr shiftnumbers
    jmp skipswapGfxtable

largerXislower ; (temp1>A)
    tay
    ldx temp2
    lda spritesort,x
    tax
    tya
    eor #$FF
    sbc #1
    bcc overlapping
    cmp spriteheight,x
    bcs notoverlapping

    dec temp3
    ldx temp2
;    inx
    jsr shiftnumbers
    jmp skipswapGfxtable 
notoverlapping
;    ldx temp2 ; swap display table
;    ldy SpriteGfxIndex+1,x
;    lda SpriteGfxIndex,x
;    sty SpriteGfxIndex,x
;    sta SpriteGfxIndex+1,x 

skipswapGfxtable
    ldx temp2 ; swap sort table
    ldy spritesort+1,x
    lda spritesort,x
    sty spritesort,x
    sta spritesort+1,x 

countdown
    dec temp2
    bpl sortloop

checktoohigh
    ldx temp3
    lda SpriteGfxIndex,x
    tax
    lda NewSpriteY,x
    cmp #$55            ; screenheight-3
    bcc nonetoohigh
    dec temp3
    bne checktoohigh

nonetoohigh
    rts


shiftnumbers
 ; stick current x at end, shift others down
 ; if x=4: don't do anything
 ; if x=3: swap 3 and 4
 ; if x=2: 2=3, 3=4, 4=2
 ; if x=1: 1=2, 2=3, 3=4, 4=1
 ; if x=0: 0=1, 1=2, 2=3, 3=4, 4=0
;    ldy SpriteGfxIndex,x
swaploop
    cpx #4
    beq shiftdone 
    lda SpriteGfxIndex+1,x
    sta SpriteGfxIndex,x
    inx
    jmp swaploop
shiftdone
;    sty SpriteGfxIndex,x
    rts


;------------------------------------------------------
;--- Debug subroutine -> display cycles left in score
;------------------------------------------------------

  ifconst debugscore
debugcycles
    ldx #14
    lda INTIM ; display # cycles left in the score

  ifconst mincycles
    lda mincycles 
    cmp INTIM
    lda mincycles
    bcc nochange
    lda INTIM
    sta mincycles
nochange
  endif

;    cmp #$2B
;    bcs no_cycles_left
    bmi cycles_left
    ldx #64
    eor #$ff ;make negative
cycles_left
    stx scorecolor
    and #$7f ; clear sign bit
    tax
    lda scorebcd,x
    sta score+2
    lda scorebcd1,x
    sta score+1
    rts

scorebcd
    .byte $00, $64, $28, $92, $56, $20, $84, $48, $12, $76, $40
    .byte $04, $68, $32, $96, $60, $24, $88, $52, $16, $80, $44
    .byte $08, $72, $36, $00, $64, $28, $92, $56, $20, $84, $48
    .byte $12, $76, $40, $04, $68, $32, $96, $60, $24, $88
scorebcd1
    .byte 0, 0, 1, 1, 2, 3, 3, 4, 5, 5, 6
    .byte 7, 7, 8, 8, 9, $10, $10, $11, $12, $12, $13
    .byte $14, $14, $15, $16, $16, $17, $17, $18, $19, $19, $20
    .byte $21, $21, $22, $23, $23, $24, $24, $25, $26, $26
  endif

;------------------------------------------------------------------------
;---- Setup the color patch values for player0 to use in the RepoKernel
;-
;-- These are the player 0 colors that will get set during the RepoKernel.
;-
;-- This is done to save cycles reading the colors, because timing is
;--   VERY tight during the reposition kernel.

setupColorPatchForP0:
    ldx #CNT_SPRITES_SORT
    lda P0Top
NextColorPatchSprite:
    ldy SpriteGfxIndex,x        ;-- get next Sprite index number from sorted table
    cmp NewSpriteY,y
    bcs P0ColorPatch            ;-- branch if we found the place where we need to patch
    dex
    bne NextColorPatchSprite
    ldy SpriteGfxIndex,x

P0ColorPatch:

    ;---- Create the patch colors
    lda NewSpriteY,y
    tay
    iny
    lda (player0colorP),y
    sta patchCOLP0_1
    iny
    lda (player0colorP),y
    sta patchCOLP0_0

NoColorPatch:
    rts

;-----------------------------------------------------------------------
__MCMSK_END:
  ifconst _show_kernel_stats
    echo "---------------------------------------------------------"
    echo "Multi-sprite code starts at ", __MCMSK_START

    echo " Find Adjust table at:      ", FineAdjustTableBegin
    echo " Find Adjust accessed at:   ", FineAdjustTableEnd

    echo "Multi-Sprite Kernel at      ", START_OF_KERNEL_ROUTINES, "..", END_OF_KERNEL_ROUTINES
    echo "     Size of kernel(s)       ", (END_OF_KERNEL_ROUTINES - START_OF_KERNEL_ROUTINES)

    echo "Multi-sprite code ends at   ", __MCMSK_END
    echo "---------------------------------------------------------"
  endif