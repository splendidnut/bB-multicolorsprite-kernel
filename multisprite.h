; Provided under the CC0 license. See the included LICENSE.txt for details.

; multisprite stuff below - 5 bytes each starting with spritex

SpriteIndex = $80

objectx     = $81
player0x    = objectx
NewSpriteX  = objectx + 1		;		X position
player1x    = objectx + 1
player2x    = objectx + 2
player3x    = objectx + 3
player4x    = objectx + 4
player5x    = objectx + 5

missile0x   = objectx + 6
missile1x   = objectx + 7
ballx       = objectx + 8

objecty     = $8A

player0y    = objecty
NewSpriteY  = objecty + 1		;		Y position
player1y    = objecty + 1
player2y    = objecty + 2
player3y    = objecty + 3
player4y    = objecty + 4
player5y    = objecty + 5

missile0y   = objecty + 6
missile1y   = objecty + 7
bally       = objecty + 8

NewNUSIZ    = $93
_NUSIZ1     = NewNUSIZ
NUSIZ2      = NewNUSIZ + 1
NUSIZ3      = NewNUSIZ + 2
NUSIZ4      = NewNUSIZ + 3
NUSIZ5      = NewNUSIZ + 4

_COLUP0     = $98
NewCOLUP1   = $99
_COLUP1     = NewCOLUP1
COLUP2      = NewCOLUP1 + 1
COLUP3      = NewCOLUP1 + 2
COLUP4      = NewCOLUP1 + 3
COLUP5      = NewCOLUP1 + 4

player0pointer = $9E
player0pointerlo = player0pointer
player0pointerhi = player0pointer + 1

player1pointerlo = $A0
player2pointerlo = $A1
player3pointerlo = $A2
player4pointerlo = $A3
player5pointerlo = $A4

player1pointerhi = $A5
player2pointerhi = $A6
player3pointerhi = $A7
player4pointerhi = $A8
player5pointerhi = $A9

player0height = $AA
spriteheight = $AB ; heights of multiplexed player sprite
player1height = $AB
player2height = $AC
player3height = $AD
player4height = $AE
player5height = $AF


statusbarlength = $B0
lifecolor       = $B1
pfscorecolor    = $B1
lifepointer     = $B2
lives           = $B3
pfscore1        = $B2       ;--- use playfield in score area
pfscore2        = $B3

aux3 = $B0
aux4 = $B1
aux5 = $B2
aux6 = $B3

score       = $B4  ;+B5,B6
scorecolor  = $B7
rand        = $B8

playfieldpos  = $B9       ;--- used for scrolling
pfheight      = $BA       ;-- define height of playfield blocks

; playfield is now a pointer to graphics
playfield       = $BC
PF1pointer      = $BC
PF1pointerHi    = PF1pointer + 1
PF2pointer      = $BE
PF2pointerHi    = PF2pointer + 1


;--------------------------------------------------------------------
;-- General Variables available to the user program

A = $c0
a = $c0
B = $c1
b = $c1
C = $c2
c = $c2
D = $c3
d = $c3
E = $c4
e = $c4
F = $c5
f = $c5
G = $c6
g = $c6
H = $c7
h = $c7
I = $c8
i = $c8
J = $c9
j = $c9
K = $ca
k = $ca
L = $cb
l = $cb
M = $cc
m = $cc
N = $cd
n = $cd
O = $ce
o = $ce
P = $cf
p = $cf
Q = $d0
q = $d0
R = $d1
r = $d1
S = $d2
s = $d2
T = $d3
t = $d3
U = $d4
u = $d4
V = $d5
v = $d5
W = $d6
w = $d6
X = $d7
x = $d7
Y = $d8
y = $d8
Z = $d9
z = $d9

;-------------------------------------------------------------------
;-- Temporary variables - used by kernel, 
;--       but can be used by user program.
;-
;-- NOTE:  These are obliterated when drawscreen is called

temp1 = $DA
temp2 = $DB
temp3 = $DC
temp4 = $DD
temp5 = $DE
temp6 = $DF


temp7 = $F0 ; This is used to aid in bankswitching


;-----------------------------------------------
;-- Kernel Variables

tmpSprLine          = $DA
tmpRepoLine         = $DB
RepoLine            = $DC
P0Top               = $DD
P1display           = $DE ;and $DF  -- pointer to P1 sprite data

scorepointers       = $E0 ;-- uses 6

P0Bottom            = $E0
P1Bottom            = $E1

player1colorP       = $E2 ;and $E3

;player0color        = $E2

P1BottomCache       = $E4 ;..$E9

EmptySpriteGfxIndex = $EA
SpriteGfxIndex      = $EB    ;..$EF --- sorted sprite indices (5 sprites)

;---


spritesort = $f1 ; helps with flickersort
spritesort2 = $f2 ; helps with flickersort
spritesort3 = $f3
spritesort4 = $f4
spritesort5 = $f5

stack1 = $f6
stack2 = $f7
stack3 = $f8
stack4 = $f9
; the stack bytes above may be used in the kernel
; stack = F6-F7, F8-F9, FA-FB, FC-FD, FE-FF

 MAC RETURN	; auto-return from either a regular or bankswitched module
   ifnconst bankswitch
     rts
   else
     jmp BS_return
   endif
 ENDM
