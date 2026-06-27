;##############################################################################
; Init and display functions for Lambda 8300 BASIC for the Minstrel 4th
; Dave Curran 2026-06-18
;##############################################################################

;##############################################################################
; Initialisation code for the 4th
;
; Clear the video RAM and load the Lambda 8300 font into the font RAM
; Display a banner, which will remain until first actual CLS
;

INIT_4TH:

; setup UDG $7F as all ones, so the inverted $FF appears like a space
    LD B, $FF                           ; set character bitmap in B
    LD C, B                             ; and C
    LD ($2FF8),BC                       ; write 8 rows, 2 at a time
    LD ($2FFA),BC                       ;
    LD ($2FFC),BC                       ;
    LD ($2FFE),BC                       ;

; now fill the screen with $ff, which should clear it
INITIAL_SCREEN_CLEAR:
    LD HL, $2400                        ; start of character video RAM
    LD DE, $2401                        ; the next byte
    LD BC, $02FF                        ; number of bytes to clear - 1
    LD (HL), $FF                        ; set the first byte
    LDIR                                ; clear all the rest

    XOR A                               ; A = 0
    LD (DE), A                          ; make $2700 (first location after screen) zero.
    INC DE                              ; make $2701 zero, to indicate initial boot
    LD (DE), A                          ; 

; copy the 8300 font into the first half of font RAM - should be no conflicts, none of these characters are on screen
COPYFONT: 
    LD DE, $2C00                        ; Destination is write only font RAM
    LD HL, FONT                         ; Lambda 8300 font in ROM
    LD BC, $0200                        ; There are 64 bit-mapped 8x8 characters
    LDIR                                ; Copy font from ROM to RAM

; copy a banner message to the top of the screen
BANNER:
    LD DE, $2400                        ; top of 4TH video RAM 
    LD HL, BANNER_TEXT                  ; banner message
    LD BC, $20                          ; 32 characters
    LDIR

; the screen at this point has the banner and the rest are $FF characters
; when the Lambda 8300 init is complete, the first display cycle will overwrite this
; also with the banner, but all the rest of the characters will be $00 as normal
; apart from the inverse K on the edit line

; resume where the initial reset function
ON_TO_RAM_CHECK:
    LD BC,$FFFF                         ; top of possible RAM.
    JP L_0489                           ; on to RAM-CHECK.


;###########################################################
; Called during clear after init and also after loading
; Check if this is init and display the banner
SHOW_BANNER:
    CALL SUB_16A5                       ; CURSOR-IN, set cursor on edit line
    CALL SUB_0BD0                       ; CLS function

    LD A, ($2701)                       ; Check if this is the initial boot
    AND A                               ; Test
    JP NZ, BANNER_DONE                  ; skip if not

    LD DE, $407D                        ; set DFILE as the destination
    INC DE                              ; step over the first NL
 
    LD HL, BANNER_TEXT                  ; Banner message
    LD BC, $20                          ; 32 characters
    LDIR                                ; copy banner

    LD HL, $2701                        ; set $2701 to 1 so banner will not be redrawn
    INC (HL)                            ;

BANNER_DONE:
    CALL SUB_0285                       ; SLOW-FAST to set SLOW mode
    JP L_04FF+3                         ; jump back in just after the CLS

;##########################################################
; Copy the Lambda 8300 display file to the 4th screen RAM

; Optimised for fully expanded fixed locate DFILE

DISPLAY_ROUTINE:
    LD HL,$407D                         ; Set HL to the Display File location
    LD DE,$2400                         ; Set DE to the Minstrel 4th screen RAM 
    LD A,$18                            ; 24 lines

COPY_LINE:
    INC HL                              ; skip the HALT / newline
    LD BC,$0020                         ; 32 characters per line
    LDIR                                ; copy line

    DEC A                               ; finished?
    JR NZ,COPY_LINE                     ; no, more lines

 

; waste time to be 100% Lambda 8300 speed
; yes, I did just keep adding and removing delays until it matched.
; LD B, $E3                             ; initial delay count

; WASTE_TIME:
; NOP
; NOP
; NOP
; DJNZ WASTE_TIME 

; end of frame
 
    LD A,($403B)                        ; get CDFLAG - DO NOT USE IY HERE
    BIT 7,A                             ; check for slow mode

    JP NZ, END_SLOW                     ; fast mode?

; End the frame in fast mode. 
; Waste time until for the interrupt then go onto the next frame
END_FAST:
    EI                                  ; enable interrupts.
    HALT                                ; halt and wait for the next interrupt
 
    RET                                 ; onto DISPLAY-1, start of the next frame

; End the frame in slow mode.
; return to users code until interrupted by the IRQ
END_SLOW
    POP HL                              ; Throw away the call address 

    POP HL                              ; ****
    POP DE                              ; ***
    POP BC                              ; **
    POP AF                              ; * Restore Main Registers

    EI                                  ; enable frame interrupts

    RET                                 ; return - end of interrupt. Return is to 
                                        ; user's program - BASIC or machine code.
                                        ; which will be interrupted by every NMI.



;###########################################################
; clear the screen to indicate "fast" mode where the ZX80/1 
; would have stopped producing a television picture

NEW_FAST:
    CALL SUB_0370                       ; routine SET-FAST
    RES 6,(IY+$3B)                      ; Clear request CDFLAG

    PUSH HL
    PUSH DE
    PUSH BC

    LD HL, $2400                        ; start of video RAM
    LD DE, $2401                        ; the next byte
    LD BC, $02FF                        ; number of bytes to clear -1
    XOR A                               ; clear A
    LD (HL), A                          ; clear the first byte
    LDIR                                ; set all the rest to match

    POP BC
    POP DE
    POP HL

    RET

;###################################################################
; The load routine detects if the program originated from a ZX81. 
; If it did, it patches it up to run.
; Extra routine to patch the font to reinstate 6 altered characters
; (also overwrites two unchanged characters to save having two loops)
PATCH_FONT: 
    LD DE, $2C40                        ; Destination is write only font RAM
    LD HL, ZX81_FONT                    ; zx81 font characters $08-$0F in ROM
    LD BC, $0040                        ; There are 8 bit-mapped 8x8 characters
    LDIR                                ; Copy font from ROM to RAM

                                        ; this is the line of code we replaced
    LD HL,($400C)                       ; Location of the ZX81 DFILE (loaded with program)

    RET                                 ; back to LOAD/SAVE

;###################################################################
; A variation of the ZX81 function in the second half of COPY_NEXT
; Read character data from the font in ROM ($2800-$29FF in this case)
GET_CHAR_BITS:
    SLA A                               ; (?) multiply by two
    ADD A,A                             ; multiply by four
    ADD A,A                             ; multiply by eight

    LD H,$14                            ; load H with half the address of character set.
    RL H                                ; now $28 or $29 (with carry)
    ADD A,E                             ; add byte offset 0-7
    LD L,A                              ; now HL addresses character source byte

    RL C                                ; test character, setting carry if inverse.
    SBC A,A                             ; accumulator now $00 if normal, $FF if inverse.

    XOR (HL)                            ; combine with bit pattern at end or ROM.

    JP L_0A51                           ; Back to original code (matches ZX81 from here)
