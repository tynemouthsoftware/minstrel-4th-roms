; Lamdba 8300 for Minstrel 4th
; Dave Curran 2026-06-18

; TASM.EXE -t80 -fff -b Lamdba4th.asm Lamdba4th.bin

; Minstrel 4th Memory Map
; =======================

; RAM
; ---
; 2000 - 23FF 1K Video RAM mirror (not used)
; 2400 - 27FF 1K Video RAM 40x25 characters (read / write)
; 2800 - 2BFF 1K Font RAM mirror (not used)
; 2C00 - 2FFF 1K Font RAM 128 characters (write only)

; 3C00 - 3FFF 1K System RAM (not used)

; 4000 - FFFF 48K RAM (read / write)

; ROM
; ---
; 0000 - 1FFF 8K ROM
; 2000 - 27FF 2K (not accessible)
; 2800 - 3BFF 5K ROM
; 3C00 - 3FFF 1K (not accessible)


.ORG $0000
.INCLUDE "Lambda8300.asm"

;*****************************************
;** ROM PATCHES **
;*****************************************

; Changes here overlay the above ROM

.ORG $0000
; START
START:
    JP INIT_4TH                         ; Initialise the Minstrel 4th video RAM
    NOP                                 ; clear original startcode
    NOP                                 ;
    NOP                                 ;

.ORG $0038
; --------------------------------
; THE 'MASKABLE INTERRUPT' ROUTINE
; --------------------------------
; Called once every frame

; MASK-INT
; Called once every frame either halted in fast mode or user code in slow
    PUSH AF                             ; store the accumulator andflags.
 
    LD A,($403B)                        ; getCDFLAG
    BIT 7,A                             ; check for slowmode

    JR NZ,RET_SLOW                      ; skip if SLOWmode
 
    POP AF                              ; restore the accumulator andflags.
    RET                                 ; return for the next frame if FASTmode

; Slow mode interrupt - we have interrupted users code
RET_SLOW:
 
    ; stackcontains:
    ; * User code returnaddress
    ; ** Previously pushedAF
    PUSH BC                             ; *** Remaining MainRegisters
    PUSH DE                             ;****
    PUSH HL                             ;*****
 
    JP L_029D                           ; ready for the start of the nextframe
 
    NOP                                 ; clear remains of originalcode

.ORG $0066
    RETN                                ; no NMI on 4th

.ORG $007B
    ; Deal with bottom rowshift
    .BYTE $1B                           ;.
    .BYTE $3F                           ;Z
    .BYTE $3D                           ;X
    .BYTE $28                           ;C
.ORG $009E
    .BYTE $32                           ;M
    .BYTE $33                           ;N
    .BYTE $27                           ;B
    .BYTE $3B                           ;V

.ORG $00A2
    .BYTE $77                           ; Shift + . =RUBOUT
    .BYTE $F5                           ; Shift + Z = PRINT
    .BYTE $7A                           ; Shift + X = Lineno
    .BYTE $70                           ; Shift + C =cursor-up
.ORG $00C5
    .BYTE $75                           ; Shift + M =EDIT
    .BYTE $73                           ; Shift + N =cursor-right
    .BYTE $72                           ; Shift + B =cursor-left
    .BYTE $71                           ; Shift + V =cursor-down

.ORG $00C9
    .BYTE $77                           ; Graphics + . =RUBOUT
    .BYTE $83                           ; Graphics + Z =graphic
    .BYTE $03                           ; Graphics + X =graphic
    .BYTE $05                           ; Graphics + C =graphic
.ORG $00EC
    .BYTE $78                           ; Graphics + M =KL
    .BYTE $86                           ; Graphics + N =graphic
    .BYTE $06                           ; Graphics + B =graphic
    .BYTE $85                           ; Graphics + V =graphic

.ORG $0226
    CALL PATCH_FONT                     ; If patching a ZX81 program, patch the font aswell

.ORG $0293
    JR L_029D                           ; BypassPRE-DISPLAY-1
    NOP                                 ; clear remains of originalcode
    NOP                                 ;
    NOP                                 ;
    NOP                                 ;
    NOP                                 ;
    NOP                                 ;
    NOP                                 ;

.ORG $0314
    RET                                 ; DISPLAY-3 - Nothing to do on the Minstrel4th
    NOP                                 ;

.ORG $0337
    JP DISPLAY_ROUTINE                  ; Jump to displayroutine

.ORG $0362
    RRA                                 ; Rotate bit 6 (PAL/NTSC) tocarry

.ORG $0375 
    EI                                  ; Enableinterrupts
    HALT                                ; Halt and wait for the nextinterrupt
    NOP                                 ;

.ORG $04F2
    JP SHOW_BANNER                      ; show banner atinit
    NOP                                 ; clear autostart ROM at $2000code
    NOP                                 ;
    NOP                                 ;
    NOP                                 ;
    NOP                                 ;
    NOP                                 ;
    NOP                                 ;

.ORG $0460
    JP PLAY_NOTE                        ; replacement play-notefunction
    JP PLAY_NOTE_2                      ; alternate entry point forMUSIC
    NOP                                 ; clear remains of originalcode
    NOP                                 ;
    NOP                                 ;
    NOP                                 ;

.ORG $0A44
    JP GET_CHAR_BITS                    ; Replacement rountie to read ROMfont
    NOP                                 ; clear remains of originalcode
    NOP                                 ;
    NOP                                 ;
    NOP                                 ;
    NOP                                 ;
    NOP                                 ;
    NOP                                 ;
    NOP                                 ;
    NOP                                 ;
    NOP                                 ;

.ORG $0DFE
    .WORD NEW_LOAD                      ; New LOADroutine

.ORG $0E01
    .WORD NEW_SAVE                      ; New SAVEroutine

.ORG $0E23
    .WORD NEW_FAST                      ; New FASTroutine

.ORG $2000

; video RAM is here

.ORG $2800
.INCLUDE "Font.asm"
.INCLUDE "ZX81Font8-F.asm"
.INCLUDE "Display.asm"
.INCLUDE "LoadSave.asm"
.INCLUDE "Sound.asm"
.INCLUDE "Strings.asm"

.ORG $3C00

; 1K system RAM (unused) is here

.ORG $3FFF
.BYTE $FF
.END

