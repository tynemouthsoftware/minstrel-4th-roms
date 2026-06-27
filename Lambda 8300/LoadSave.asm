;###############################################################################
; Replacement LOAD and SAVE functions for Lambda 8300 BASIC for the Minstrel 4th
; Dave Curran 2026-06-17
;###############################################################################

;###############################################################################
; replacement SAVE function with countdown
NEW_SAVE: 

    CALL SUB_0370                       ; routine SET-FAST

    CALL GET_NAME                       ; get user supplied program name
    JR C,F02F4                          ; back with null name to REPORT-F above.

    PUSH AF                             ; Save registers
    PUSH BC                             ; 
    PUSH DE                             ; 
    PUSH HL                             ; 

    CALL DRAW_BOX

    LD DE, LINE2_POS                    ; draw the SAVING message
    LD HL, SAVING_DOTS 
    LD BC, BOX_LENGTH
    LDIR

    POP HL                              ; Restore registers
    POP DE                              ; 
    POP BC                              ; 
    POP AF                              ; 

;; SAVE
    LD (IY+$09),$FF                     ; Set version to $FF, indicating Lambda 8300 program
    EX DE,HL                            ;
    LD DE,$12CB                         ; five seconds timing value

;; HEADER
F02FF: CALL SUB_113B                    ; routine BREAK-1
    JR NC,F0332                         ; to BREAK-2

;; DELAY-1
F0304: DJNZ F0304                       ; to DELAY-1

    DEC DE                              ;
    LD A,D                              ;
    OR E                                ;
    JR NZ,F02FF                         ; back for delay to HEADER

;; OUT-NAME
F030B: CALL F031E                       ; routine OUT-BYTE
    BIT 7,(HL)                          ; test for inverted bit.
    INC HL                              ; address next character of name.
    JR Z,F030B                          ; back if not inverted to OUT-NAME

; now start saving the system variables onwards.

    LD HL,$4009                         ; set start of area to VERSN thereby
                                        ; preserving RAMTOP etc.

;; OUT-PROG
F0316: CALL F031E                       ; routine OUT-BYTE

;; Check if finished
    INC HL                              ; next byte
    PUSH HL                             ; store HL
    EX DE,HL                            ; move the pointer value to DE
    LD HL,($4014)                       ; load HL with E_LINE - the location following
                                        ; the variables end-marker.
    SCF                                 ; set carry
    SBC HL,DE                           ; trial subtraction.
    JR C,SAVE_FINISHED                  ; finished, return to main loop

    CALL DISPLAY_HL                     ; not finished, show the progress

    POP HL                              ; restore pointer.

    JR F0316                            ; else back to do another byte.

SAVE_FINISHED:
    POP HL                              ; remove byte address from stack
    JP L_0221                           ; LOAD/SAVE-COMPLETE

; -------------------------
; THE 'OUT-BYTE' SUBROUTINE
; -------------------------
; This subroutine outputs a byte a bit at a time to a domestic tape recorder.

;; OUT-BYTE
F031E: LD E,(HL)                        ; fetch byte to be saved.
    SCF                                 ; set carry flag - as a marker.

;; EACH-BIT
F0320: RL E                             ; C < 76543210 < C
    RET Z                               ; return when the marker bit has passed 
                                        ; right through. >>

    SBC A,A                             ; $FF if set bit or $00 with no carry.
    AND $05                             ; $05 $00
    ADD A,$04                           ; $09 $04
    LD C,A                              ; transfer timer to C. a set bit has a longer
                                        ; pulse than a reset bit.

;; PULSES
F0329: LD A, $08                        ; set save output high
    OUT ($FE),A                         ; 

    LD B,$23                            ; set timing constant

;; DELAY-2
F032D: DJNZ F032D                       ; self-loop to DELAY-2

    XOR A                               ; set save output low
    OUT ($FE), A                        ;

    CALL SUB_113B                       ; routine BREAK-1 test for BREAK key. 

;; BREAK-2
F0332: JR NC,F03A6                      ; forward with break to REPORT-D

    LD B,$1E                            ; set timing value.

;; DELAY-3
F0336: DJNZ F0336                       ; self-loop to DELAY-3

    DEC C                               ; decrement counter
    JR NZ,F0329                         ; loop back to PULSES

;; DELAY-4
F033B: AND A                            ; clear carry for next bit test.
    DJNZ F033B                          ; self loop to DELAY-4 (B is zero - 256)

    JR F0320                            ; loop back to EACH-BIT

; --------------
; THE 'REPORT-F'
; --------------

;; REPORT-F
F02F4: RST 08H                          ; ERROR-1
    .BYTE $0E                           ; Error Report: No Program Name supplied.

;; REPORT-D
F03A6: RST 08H                          ; ERROR-1
    .BYTE $0C                           ; Error Report: BREAK - CONT repeats


;###############################################################################
; replacement LOAD function with countdown

NEW_LOAD: 

    CALL SUB_0370                       ; routine SET-FAST

    CALL DRAW_BOX

    LD DE, LINE2_POS                    ; draw the LOADING message
    LD HL, LOADING_DOTS
    LD BC, BOX_LENGTH
    LDIR

    CALL GET_NAME                       ; get user supplied program name
    JR C,SKIP_NAME                      ; carry set if LOAD ""

                                        ; carry clear so LOAD "name"
                                        ; DE points to start of name, last character has bit 7 set

    LD B, D                             ; save address in BC
    LD C, E                             ;

WAIT_FOR_NAME:
    LD H, B                             ; load address from BC
    LD L, C                             ;
 
CHECK_NAME: 
    CALL LOAD_BYTE                      ; load a byte
    JR C, F03A6                         ; break pressed before load started, recover
    CP (HL)                             ; check if it matches name
    JR NZ, WAIT_FOR_NAME                ; no match, wait again - add delay???

    INC HL                              ; address next character of name
    RLA                                 ; test bit 7
    JR NC,CHECK_NAME                    ; no, continue checking
    JR LOAD_PROG                        ; name matched, now load the program

SKIP_NAME:
    CALL LOAD_BYTE                      ; load a byte
    JR C, F03A6                         ; break pressed before load started, recover

    RLA                                 ; bit 7 -> carry
    JR NC, SKIP_NAME                    ; loop back until name skipped

LOAD_PROG:
                                        ; name has been skipped / matched, now start loading the program
 
    INC (IY+$15)                        ; increment E_LINE_MSB to avoid load fail before it is overwritten
    LD HL, $4009                        ; set start load location

LOADING:
    CALL LOAD_BYTE                      ; load a byte
    JP C, INIT_4TH                      ; break pressed after load started, reset

    LD (HL),A                           ; store byte

    INC HL                              ; next byte
    PUSH HL                             ; store HL
    EX DE,HL                            ; move the pointer value to DE
    LD HL,($4014)                       ; load HL with E_LINE - the location following
                                        ; the variables end-marker.
    SCF                                 ; set carry
    SBC HL,DE                           ; trial subtraction.
 
    JR C,LOAD_FINISHED                  ; finished

    CALL DISPLAY_HL                     ; not finished, show the progress

    POP HL                              ; restore load pointer
    JR LOADING                          ; else for more

LOAD_FINISHED:
    POP HL                              ; remove byte address from stack
    JP L_0221                           ; LOAD/SAVE-COMPLETE


;##########################################################
; Load a byte
; count transitions
; """"VVVV""""" = 0
; """"VVVVVVVVV""""" = 1
 
; A scratch
; B pulse timer
; C transition counter
; D previous value of the io port (masked)
; E bit counter
; L byte store

; returns byte in A
; carry set if break pressed
;##########################################################

IO_FE_MASK .EQU %00100001               ; mask for tape and space column

LOAD_BYTE:
    EXX                                 ; swap to backup register set

LOAD_AGAIN:
    LD E, $08                           ; load bit counter
 
LOAD_BIT:
    LD C, $00                           ; clear transition counter

LOAD_WAIT:
                                        ; wait for the next bit to start
    LD A,$7F                            ; read from port $7FFE.
    IN A,($FE)                          ; the keyboard row with space.
    AND IO_FE_MASK                      ; mask all but the tape and space column bits

    CP D                                ; test if this is the same as the previous byte
    JP Z, LOAD_WAIT                     ; if the same, keep waiting
 
    BIT 0, A                            ; has this changed becase of the space key?
    JP Z, LOAD_BREAK                    ; yes space / break pressed

    LD D, A                             ; store previous value

LOAD_PULSE:
    LD B, $14                           ; number of tests before bit transitions over

LOAD_TEST:
    LD A,$7F                            ; read from port $7FFE.
    IN A,($FE)                          ; the keyboard row with space.
    AND IO_FE_MASK                      ; mask all but the tape and space column bits

    CP D                                ; test if this is the same as the previous byte
    JP Z, LOAD_SAME                     ; if the same, different skip forward
 
    BIT 0, A                            ; has this changed becase of the space key?
    JP Z, LOAD_BREAK                    ; yes space / break pressed

    INC C                               ; transition detected, increment counter
    LD D, A                             ; store previous value

    JR LOAD_PULSE                       ; loop back for more

LOAD_SAME:
    DJNZ LOAD_TEST                      ; keep looping up to 16 times

                                        ; no transition has been detected for 16 tests, end of this bit

    LD A, C                             ; check the transition count
 
    CP $04                              ; is it < 4
    JR C, LOAD_AGAIN                    ; error, start again

    CP $0A                              ; is C < 10
    JR C, LOAD_ZERO                     ; it's a zero

    CP $14                              ; is C < 20
    JR C, LOAD_ONE                      ; it's a one

    JR LOAD_AGAIN                       ; error, start again

LOAD_ZERO:
    AND A                               ; clear carry flag
    JR LOAD_NEXT

LOAD_ONE:
                                        ; carry already set

LOAD_NEXT:
    RL L                                ; rotate the bit into position in the byte store
 
    DEC E                               ; decrememnt bit counter
    JR NZ, LOAD_BIT                     ; get next bit

                                        ; 8 bits complete

    LD A, L                             ; received byte to A
    EXX                                 ; restore normal registers 
    AND A                               ; clear carry flag
    RET                                 ;

LOAD_BREAK:
    EXX                                 ; restore normal registers 
    SCF                                 ; set the carry flag to indicate break pressed
    RET                                 ; 


;###############################################################################
; GET_NAME
; parse the user input to get the program name

GET_NAME:
    CALL SUB_114A                       ; routine SCANNING
    LD A,($4001)                        ; sv FLAGS
    ADD A,A                             ;
    JP M,L_0433                         ; to REPORT-C

    POP HL                              ;
    RET NC                              ;

    PUSH HL                             ;
    CALL SUB_15ED                       ; routine STK-FETCH
    LD H,D                              ;
    LD L,E                              ;
    DEC C                               ;
    RET M                               ;

    ADD HL,BC                           ;
    SET 7,(HL)                          ;
    RET                                 ;

;###############################################################################
; display loading screen
; /------------\
; |LOADING ....|
; \------------/

DRAW_BOX:
 
    XOR A                               ; clear the screen, using A=0
    LD HL, $2400                        ; start of video RAM
    LD DE, $2401                        ; the next byte
    LD BC, $0300                        ; number of bytes to clear (including $2700)
    LD (HL), A                          ; Clear the first byte
    LDIR                                ; Clear all the rest
 
    LD DE, LINE1_POS                    ; draw the top of the box
    LD HL, BOX_TOP 
    LD BC, BOX_LENGTH
    LDIR

    LD DE, LINE3_POS                    ; draw the bottom of the box
    LD HL, BOX_BOTTOM
    LD BC, BOX_LENGTH
    LDIR

    RET

;###############################################################################
; diplay the current value of HL in the loading / saving box
; works from right to left, updating as few digits as necessary
; (if a digit is not 0, then don't update anything to it's left)

DISPLAY_HL: 
    LD DE, DIGITS_POS+3
DISPLAY_HL2:
    LD C, $0F                           ; 0F is used a lot, so preload it 
 
                                        ; start with the LSB ...L
    LD A, L
    AND C
    ADD A, _0
    LD (DE), A
    DEC DE

                                        ; display ..L.
    LD A, L
    RRA
    RRA
    RRA
    RRA
    AND C
    JR Z, DISPLAY_HL_END                ; skip to the end if this is non-zero


    ADD A, _0
    LD (DE), A
    DEC DE

                                        ; display .H..
    LD A, H
    AND C
    ADD A, _0
    LD (DE), A
    DEC DE

                                        ; display H
    LD A, H
    RRA
    RRA
    RRA
    RRA
    AND $0F

DISPLAY_HL_END: 
    ADD A, _0
    LD (DE), A
 
    RET
    