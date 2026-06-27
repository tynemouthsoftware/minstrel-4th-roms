;##############################################################################
; Strings for Lambda 8300 BASIC for the Minstrel 4th
; Dave Curran 2026-06-17
;##############################################################################

;##############################################################################
; Strings
__              .EQU $00
_SPACE          .EQU $00
_SNOW           .EQU $08
_DASH           .EQU $16
_DOT            .EQU $1B
_0 	        .EQU $1C
_1 	        .EQU $1D
_2 	        .EQU $1E
_3 	        .EQU $1F
_4 	        .EQU $20
_5 	        .EQU $21
_6 	        .EQU $22
_7 	        .EQU $23
_8 	        .EQU $24
_9 	        .EQU $25
_A 	        .EQU $26
_B 	        .EQU $27
_C 	        .EQU $28
_D 	        .EQU $29
_E 	        .EQU $2A
_F 	        .EQU $2B
_G 	        .EQU $2C
_H 	        .EQU $2D
_I 	        .EQU $2E
_J 	        .EQU $2F
_K 	        .EQU $30
_L 	        .EQU $31
_M 	        .EQU $32
_N 	        .EQU $33
_O 	        .EQU $34
_P 	        .EQU $35
_Q 	        .EQU $36
_R 	        .EQU $37
_S 	        .EQU $38
_T 	        .EQU $39
_U 	        .EQU $3A
_V 	        .EQU $3B
_W 	        .EQU $3C
_X 	        .EQU $3D
_Y 	        .EQU $3E
_Z 	        .EQU $3F

_UDG_00         .EQU $40
; ...
_UDG_3F         .EQU $7F

_NEW_LINE       .EQU $76

LINE1_POS       .EQU     $2549          ; $2400+32*10+9
LINE2_POS       .EQU     $2569          ; $2400+32*11+9
LINE3_POS       .EQU     $2589          ; $2400+32*12+9
DIGITS_POS      .EQU     LINE2_POS+$09
BOX_LENGTH      .EQU     $0E

;##########################################################

BOX_TOP:
        .BYTE    $07, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $84

LOADING_DOTS:
        .BYTE    $05, _L, _O, _A, _D, _I, _N, _G, __, _DOT, _DOT, _DOT, _DOT, $85

SAVING_DOTS:
        .BYTE    $05, _S, _A, _V, _I, _N, _G, __, __, _DOT, _DOT, _DOT, _DOT, $85

BOX_BOTTOM:
        .BYTE    $82, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $81

BANNER_TEXT:
        ; "LAMBDA 8300 - MINSTREL 4TH Vx.y "
        .BYTE    _L, _A, _M, _B, _D, _A, __, _8, _3, _0, _0, __
        .BYTE    _DASH, __, _M, _I, _N, _S, _T, _R, _E, _L, __
        .BYTE    _4, _T, _H, __, _V, _1, _DOT, _0, __
BANNER_TEXT_END:

;##########################################################
