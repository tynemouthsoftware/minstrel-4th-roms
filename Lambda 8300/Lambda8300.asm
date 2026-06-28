; Disassembly of the Lambda 8300 ROM
; Dave Curran 2026-06-12

; Latest version at:
; https://github.com/tynemouthsoftware/Lambda8300

; Where functions are identical to ZX81, only the function names are commented
; Refer to the ZX81 assembly listing by Geoff Wearmouth for further comments
; https://web.archive.org/web/20111004151617/http://www.wearmouth.demon.co.uk/zx81.htm

; assemble with TASM
; TASM.EXE -t80 -b Lambda8300.asm Lambda8300.bin

; Z80 @ 3.25MHz
; 8K of ROM
; 2K of RAM
; expandable to 32k of RAM

; Memory Map
; $0000-1FFF        - ROM
; $2000-3FFF        - Option ROM
; $4000     ERR.NR  - Current report code -1
; $4001     FLAGS   - Some flags
; $4002/03  ERR.SP  - Address of top of GOSUB stack
; $4004/05  RAMTOP  - Address of reserved area
; $4006     MODE    - Cursor mode
; $4007/08  PPC     - Line number being executed
; $4009     VERSN   - Version (from tape $00 = ZX81, $FF = Lambda)
; $400A/0B  NXTLIN  - Address of next line to be executed (ZX81 has E.PPC here)
; $400C/0D  PRGRM   - Start of user program = $4396 (ZX81 has DFILE here)
; $400E/0F  DF.CC   - Display file current character
; $4010/11  VARS    - Start of variable area
; $4012/13  DEST    - Address of variable being assigned
; $4014/15  E.LINE  - Address of edit line
; $4016/17  CH.ADD  - Next character to interpret
; $4018/19  X.PTR   - Addess of character before syntax error
; $401A/1B  STKBOT  - Address of calculator stack
; $401C/1D  STKEND  - End of calculator stack
; $401E     BREG    - Floating point B register
; $401F/20  MEM     - Address of calc memory area = MEMBOT
; $4021     TEMPO   - Setting of music tempo (was SPARE1)
; $4022     DF.SZ   - Size of editor part of screen
; $4023/24  S.TOP   - Line number at top of screen
; $4025/26  LAST.K  - Last keyboard scan
; $4027     DB.ST   - Keyboard debounce status
; $4028     MARGIN  - Number of lines in margin
; $4029/2A  E.PPC   - Line number of line with cursor (ZX81 has NXTLIN here)
; $402B/2C  OLDPPC  - Address of line where CONT jumps
; $402D     FLAGX   - Some more flags
; $402E/F   STRLEN  - String length
; $4030/31  T.ADDR  - Next item in syntax table
; $4032/33  SEED    - Seed for RND
; $4034/35  FRAMES  - Frame counter
; $4035/37  COORDS  - Last point plotted (to add for DRAW?)
; $4038     PR.CC   - Address of LPRINT position
; $4039/3A  S.POSN  - Current PRINT position
; $403B     CDFLAG  - Compute Display Flags for FAST/SLOW mode (Bit 7 = 1 for SLOW, Bit 6 = 1 to request SLOW mode)
; $403C-5C  PRBUFF  - Printer buffer
; $405D-7A  MEMBOT  - Calculator memory
; $407B-7C  BLINK   - Cursor blink
; $407D-$4395       - Display file
; $4396-RAMTOP      - User Program memory

; no DFILE variable - Location of display file, that is hard coded at $407D
DFILE .EQU $407D

.ORG $0000

; -----------
; THE 'START'
; -----------

; START
L_0000:
    OUT ($FD),A                         ; Turn off NMI
    LD A,$BF
    IN A,($FE)                          ; Keyboard read (hold down key for ROM at $2000?)
    JR L_0025                           ; Jump to START-3 via START-2

; -------------------
; THE 'ERROR' RESTART
; -------------------

; ERROR-1
L_0008:
    LD HL,($4016)                       ; CH.ADD - Address of next character to interpret
    LD ($4018),HL                       ; X.PTR - Address of character before error
    JR L_0057                           ;

; -------------------------------
; THE 'PRINT A CHARACTER' RESTART
; -------------------------------

; PRINT-A
L_0010:
    AND A
    JP NZ,L_0992
    JP L_0996

    .BYTE $FF                           ; Unused

; ---------------------------------
; THE 'COLLECT A CHARACTER' RESTART
; ---------------------------------

; GET-CHAR
L_0018:
    LD HL,($4016)
    LD A,(HL)
L_001C:
    AND A
    RET NZ
    NOP
    NOP

; ------------------------------------
; THE 'COLLECT NEXT CHARACTER' RESTART
; ------------------------------------

; NEXT-CHAR
L_0020:
    CALL SUB_004A
    JR L_001C

; start continued

; START-2
L_0025:
    JP L_046E

; ---------------------------------------
; THE 'FLOATING POINT CALCULATOR' RESTART
; ---------------------------------------

; FP-CALC
L_0028:
    JP L_1B94

; end-calc
SUB_002B:
    POP AF
    EXX
    EX (SP),HL
    EXX
    RET

; -----------------------------
; THE 'MAKE BC SPACES'  RESTART
; -----------------------------

; BC-SPACES
L_0030:
    PUSH BC
    LD HL,($4014)
    PUSH HL
    JP L_167D

; -----------------------
; THE 'INTERRUPT' RESTART
; -----------------------

; INTERRUPT
L_0038:
    DEC C
    JR NZ,L_0045
    POP HL
    DEC B
    RET Z
    RET Z                               ; Extra delay? not in ZX81
    LD C,$08                            ; Faster than SET 3,C (but is that a good thing here?)

; WAIT-INT
L_0041:
    LD R,A
    EI
    JP (HL)                             ; Jump into display file mirror

; SCAN-LINE
L_0045:
    POP DE
    NOP                                 ; Different timing to ZX81
    JR L_0041

    .BYTE $00                           ; Unused (which moved $004A-$0065 1 byte away from ZX81)

; ---------------------------------
; THE 'INCREMENT CH-ADD' SUBROUTINE
; ---------------------------------

; CH-ADD+1
SUB_004A:
    LD HL,($4016)

; TEMP-PTR1
L_004D:
    INC HL

; TEMP-PTR2
SUB_004E:
    LD ($4016),HL
    LD A,(HL)
    CP $7F
    RET NZ
    JR L_004D

; --------------------
; THE 'ERROR-2' BRANCH
; --------------------

; ERROR-2
L_0057:
    POP HL                              ; Get error code
    LD L,(HL)                           ; Extract error byte

; ERROR-3
L_0059:
    LD (IY+$00),L                       ; Set ERR_NR, system error number
    LD SP,($4002)                       ; Reset stack pointer to top of GOSUB stack
    CALL SUB_0285                       ; SLOW mode
    JP L_16B4                           ; Exit via SET_MIN to clear calculator stack

; ------------------------------------
; THE 'NON MASKABLE INTERRUPT' ROUTINE
; ------------------------------------

; NMI
L_0066:
    EX AF,AF'                           ; NMI uses the alternate A&F
    INC A                               ; Incrememnt line count
    JP Z,L_006E                         ; Jump if line count has reached 0
    NOP                                 ; NMI test removed (ROM will not run on ZX80 hardware)

; NMI-RET
    EX AF,AF'                           ; Return to normal A&F
    RET                                 ; Return to user code

; NMI-CONT
L_006E:
    EX AF,AF'                           ; Return to normal A&F
    PUSH AF                             ; Save the main registers
    PUSH BC                             ;
    PUSH DE                             ;
    PUSH HL                             ;
    LD HL,$407D + $8000                 ; Set HL to fixed DFILE mirror location (not ($400C) with bit 7 set)
    HALT                                ; Sync with NMI

    OUT ($FD),A                         ; Stop the NMI generator
    JP (IX)                             ; Forward to R-IX-1 (after top) or R-IX-2


; ****************
; ** KEY TABLES **
; ****************

; -------------------------------
; THE 'UNSHIFTED' CHARACTER CODES
; -------------------------------

; K-UNSHIFT
L_007B:

    .BYTE $3F                           ; Z
    .BYTE $3D                           ; X
    .BYTE $28                           ; C
    .BYTE $3B                           ; V

    .BYTE $26                           ; A
    .BYTE $38                           ; S
    .BYTE $29                           ; D
    .BYTE $2B                           ; F
    .BYTE $2C                           ; G

    .BYTE $36                           ; Q
    .BYTE $3C                           ; W
    .BYTE $2A                           ; E
    .BYTE $37                           ; R
    .BYTE $39                           ; T

    .BYTE $1D                           ; 1
    .BYTE $1E                           ; 2
    .BYTE $1F                           ; 3
    .BYTE $20                           ; 4
    .BYTE $21                           ; 5

    .BYTE $1C                           ; 0
    .BYTE $25                           ; 9
    .BYTE $24                           ; 8
    .BYTE $23                           ; 7
    .BYTE $22                           ; 6

    .BYTE $35                           ; P
    .BYTE $34                           ; O
    .BYTE $2E                           ; I
    .BYTE $3A                           ; U
    .BYTE $3E                           ; Y

    .BYTE $76                           ; NEWLINE
    .BYTE $31                           ; L
    .BYTE $30                           ; K
    .BYTE $2F                           ; J
    .BYTE $2D                           ; H

    .BYTE $00                           ; SPACE
    .BYTE $1B                           ; .
    .BYTE $32                           ; M
    .BYTE $33                           ; N
    .BYTE $27                           ; B

; -----------------------------
; THE 'SHIFTED' CHARACTER CODES
; -----------------------------

; K-SHIFT
L_00A2:
    .BYTE $F5                           ; Shift + Z = PRINT
    .BYTE $7A                           ; Shift + X = Line no
    .BYTE $70                           ; Shift + C = cursor-up
    .BYTE $71                           ; Shift + V = cursor-down

    .BYTE $C6                           ; Shift + A = ASN
    .BYTE $C7                           ; Shift + S = ACS
    .BYTE $C8                           ; Shift + D = ATN
    .BYTE $CA                           ; Shift + F = EXP
    .BYTE $CE                           ; Shift + G = ABS

    .BYTE $C3                           ; Shift + Q = SIN
    .BYTE $C4                           ; Shift + W = COS
    .BYTE $C5                           ; Shift + E = TAN
    .BYTE $C9                           ; Shift + R = LOG
    .BYTE $CD                           ; Shift + T = SGN

    .BYTE $0F                           ; Shift + 1 = ?
    .BYTE $0C                           ; Shift + 2 = £
    .BYTE $0E                           ; Shift + 3 = :
    .BYTE $0D                           ; Shift + 4 = $
    .BYTE $0B                           ; Shift + 5 = "

    .BYTE $14                           ; Shift + 0 = =
    .BYTE $11                           ; Shift + 9 = )
    .BYTE $10                           ; Shift + 8 = (
    .BYTE $1A                           ; Shift + 7 = ,
    .BYTE $19                           ; SHIFT + 6 = ;

    .BYTE $12                           ; Shift + P = >
    .BYTE $13                           ; Shift + O = <
    .BYTE $45                           ; Shift + I = PI
    .BYTE $43                           ; Shift + U = RND
    .BYTE $CC                           ; Shift + Y = SQR

    .BYTE $74                           ; Shift + N/L = GRAPHICS
    .BYTE $15                           ; Shift + L = +
    .BYTE $16                           ; Shift + K = -
    .BYTE $17                           ; Shift + J = *
    .BYTE $18                           ; Shift + H = /

    .BYTE $79                           ; Shift + SPACE = FUNCTION
    .BYTE $77                           ; Shift + . = RUBOUT
    .BYTE $75                           ; Shift + M = EDIT
    .BYTE $73                           ; Shift + N = cursor-right
    .BYTE $72                           ; Shift + B = cursor-left


; -----------------------------
; THE 'GRAPHIC' CHARACTER CODES
; -----------------------------

; K-GRAPH
; 00c9
    .BYTE $83                           ; Graphics + Z = graphic
    .BYTE $03                           ; Graphics + X = graphic
    .BYTE $05                           ; Graphics + C = graphic
    .BYTE $85                           ; Graphics + V = graphic

    .BYTE $08                           ; Graphics + A = graphic
    .BYTE $0A                           ; Graphics + S = graphic
    .BYTE $09                           ; Graphics + D = graphic
    .BYTE $8A                           ; Graphics + F = graphic
    .BYTE $89                           ; Graphics + G = graphic

    .BYTE $01                           ; Graphics + Q = graphic
    .BYTE $02                           ; Graphics + W = graphic
    .BYTE $04                           ; Graphics + E = graphic
    .BYTE $87                           ; Graphics + R = graphic
    .BYTE $81                           ; Graphics + T = graphic

    .BYTE $8F                           ; Graphics + 1 = graphic
    .BYTE $8C                           ; Graphics + 2 = graphic
    .BYTE $8E                           ; Graphics + 3 = graphic
    .BYTE $8D                           ; Graphics + 4 = inverse $
    .BYTE $8B                           ; Graphics + 5 = inverse "

    .BYTE $94                           ; Graphics + 0 = inverse =
    .BYTE $91                           ; Graphics + 9 = inverse )
    .BYTE $90                           ; Graphics + 8 = inverse (
    .BYTE $9A                           ; Graphics + 7 = inverse ,
    .BYTE $99                           ; Graphics + 6 = inverse ;

    .BYTE $92                           ; Graphics + P = inverse >
    .BYTE $93                           ; Graphics + O = inverse <
    .BYTE $07                           ; Graphics + I = graphic
    .BYTE $84                           ; Graphics + U = graphic
    .BYTE $82                           ; Graphics + Y = graphic

    .BYTE $78                           ; Graphics + N/L = KL
    .BYTE $95                           ; Graphics + L = inverse +
    .BYTE $96                           ; Graphics + K = inverse -
    .BYTE $97                           ; Graphics + J = inverse *
    .BYTE $98                           ; Graphics + H = inverse /

    .BYTE $78                           ; Graphics + SPACE =
    .BYTE $77                           ; Graphics + . = RUBOUT
    .BYTE $78                           ; Graphics + M = KL
    .BYTE $86                           ; Graphics + N = graphic
    .BYTE $06                           ; Graphics + B = graphic

; ------------------
; THE 'TOKEN' TABLES
; ------------------

; TOKENS
L_00F0:
    .BYTE $1B+$80                       ; '.' + $80 ?
L_00F1:
    .BYTE $28,$34,$29,$2A+$80           ; CODE
    .BYTE $3B,$26,$31+$80               ; VAL
    .BYTE $31,$2A,$33+$80               ; LEN
    .BYTE $38,$2E,$33+$80               ; SIN
    .BYTE $28,$34,$38+$80               ; COS
    .BYTE $39,$26,$33+$80               ; TAN
    .BYTE $26,$38,$33+$80               ; ASN
    .BYTE $26,$28,$38+$80               ; ACS
    .BYTE $26,$39,$33+$80               ; ATN
    .BYTE $31,$34,$2C+$80               ; LOG
    .BYTE $2A,$3D,$35+$80               ; EXP
    .BYTE $2E,$33,$39+$80               ; INT
    .BYTE $38,$36,$37+$80               ; SQR
    .BYTE $38,$2C,$33+$80               ; SGN
    .BYTE $26,$27,$38+$80               ; ABS
    .BYTE $35,$2A,$2A,$30+$80           ; PEEK
    .BYTE $3A,$38,$37+$80               ; USR
    .BYTE $38,$39,$37,$0D+$80           ; STR$
    .BYTE $28,$2D,$37,$0D+$80           ; CHR$
    .BYTE $33,$34,$39+$80               ; NOT
    .BYTE $26,$39+$80                   ; AT
    .BYTE $39,$26,$27+$80               ; TAB
    .BYTE $17,$17+$80                   ; **
    .BYTE $34,$37+$80                   ; OR
    .BYTE $26,$33,$29+$80               ; AND
    .BYTE $13,$14+$80                   ; <=
    .BYTE $12,$14+$80                   ; >=
    .BYTE $13,$12+$80                   ; <>

    .BYTE $39,$2A,$32,$35,$34+$80       ; TEMPO
    .BYTE $32,$3A,$38,$2E,$28+$80       ; MUSIC
    .BYTE $38,$34,$3A,$33,$29+$80       ; SOUND
    .BYTE $27,$2A,$2A,$35+$80           ; BEEP
    .BYTE $33,$34,$27,$2A,$2A,$35+$80   ; NOBEEP
    .BYTE $31,$35,$37,$2E,$33,$39+$80   ; LPRINT
    .BYTE $31,$31,$2E,$38,$39+$80       ; LLIST
    .BYTE $38,$39,$34,$35+$80           ; STOP
    .BYTE $38,$31,$34,$3C+$80           ; SLOW
    .BYTE $2B,$26,$38,$39+$80           ; FAST
    .BYTE $33,$2A,$3C+$80               ; NEW
    .BYTE $38,$28,$37,$34,$31,$31+$80   ; SCROLL
    .BYTE $28,$34,$33,$39+$80           ; CONT
    .BYTE $29,$2E,$32+$80               ; DIM
    .BYTE $37,$2A,$32+$80               ; REM
    .BYTE $2B,$34,$37+$80               ; FOR
    .BYTE $2C,$34,$39,$34+$80           ; GOTO
    .BYTE $2C,$34,$38,$3A,$27+$80       ; GOSUB
    .BYTE $2E,$33,$35,$3A,$39+$80       ; INPUT
    .BYTE $31,$34,$26,$29+$80           ; LOAD
    .BYTE $31,$2E,$38,$39+$80           ; LIST
    .BYTE $31,$2A,$39+$80               ; LET
    .BYTE $35,$26,$3A,$38,$2A+$80       ; PAUSE
    .BYTE $33,$2A,$3D,$39+$80           ; NEXT
    .BYTE $35,$34,$30,$2A+$80           ; POKE
    .BYTE $35,$37,$2E,$33,$39+$80       ; PRINT
    .BYTE $35,$31,$34,$39+$80           ; PLOT
    .BYTE $37,$3A,$33+$80               ; RUN
    .BYTE $38,$26,$3B,$2A+$80           ; SAVE
    .BYTE $37,$26,$33,$29+$80           ; RAND
    .BYTE $2E,$2B+$80                   ; IF
    .BYTE $28,$31,$38+$80               ; CLS
    .BYTE $3A,$33,$35,$31,$34,$39+$80   ; UNPLOT
    .BYTE $28,$31,$2A,$26,$37+$80       ; CLEAR
    .BYTE $37,$2A,$39,$3A,$37,$33+$80   ; RETURN
    .BYTE $28,$34,$35,$3E+$80           ; COPY

    .BYTE $39,$2D,$2A,$33+$80           ; THEN
    .BYTE $39,$34+$80                   ; TO
    .BYTE $38,$39,$2A,$35+$80           ; STEP
    .BYTE $37,$33,$29+$80               ; RND
    .BYTE $2E,$33,$30,$2A,$3E,$0D+$80   ; INKEY$
    .BYTE $35,$2E+$80                   ; PI

; ---------------------------
; THE 'ERROR MESSAGES' TABLES
; ---------------------------

; table of error messages, used by function at $07E1
L_01F2:
    .BYTE $34,$30                       ; FF = OK - OK
    .BYTE $33,$2B                       ; 00 = NF - NEXT without FOR
    .BYTE $3A,$3B                       ; 01 = UV - Unidentified Variable
    .BYTE $27,$38                       ; 02 = BS - Bad Subscript
    .BYTE $34,$32                       ; 03 = OM - Out of Memory
    .BYTE $38,$2B                       ; 04 = SF - Screen Full
    .BYTE $34,$3B                       ; 05 = OV - OVerflow
    .BYTE $37,$2C                       ; 06 = RG - RETURN without GOSUB
    .BYTE $2E,$2E                       ; 07 = II - Illegal INPUT
    .BYTE $38,$39                       ; 08 = ST - STop
    .BYTE $26,$2C                       ; 09 = AG - invalid ArGument
    .BYTE $2E,$37                       ; 0A = IR - Integer out of Range
    .BYTE $2E,$2A                       ; 0B = IE - Invalid Expression
    .BYTE $27,$30                       ; 0C = BK - BreaK
    .BYTE $33,$26                       ; 0D = NA - no program NAme
    .BYTE $32,$2B                       ; 0E = MF - Music Format incorrect

; the " IN " message
L_0212:
    .BYTE $00,$2E,$33,$00               ; " IN " ("OK IN 10")


; ------------------------------
; THE 'LOAD-SAVE UPDATE' ROUTINE
; ------------------------------

; LOAD/SAVE
SUB_0216:
    INC HL                              ; Step destination
    EX DE,HL                            ; Backup to DE
    LD HL,($4014)                       ; Get E-LINE
    SCF                                 ; Check if they match
    SBC HL,DE                           ; Is the last byte the end of the file?
    EX DE,HL                            ; Restore destination
    RET NC                              ; Return if the end has not been reached
    POP HL                              ; Drop the return address and continue
; ZX81 drops to SLOW here

; LOAD/SAVE-COMPLETE
L_0221:
    INC (IY+$09)                        ; Increment version (from tape Lambda = $FF, ZX81 = $00. normal Lambda = $00, ZX81 = $01)
    JR Z,SUB_0285                       ; If it was $FF, a Lambda program, go straight to FAST/SLOW

; This code converts a ZX81 program to the Lambda 8300
    LD HL,($400C)                       ; Location of the ZX81 DFILE (loaded with program)
    INC HL                              ; +1
    LD ($4010),HL                       ; Store this as
    LD HL,DFILE                         ; Hard coded DFILE location
    LD BC,$0319                         ; Length of DFILE + 1 extra blank row to make SCROLL a block copy
    CALL SUB_0B30                       ; MAKE-ROOM for BC bytes at location in HL
    EX DE,HL                            ; HL is now at the program location
; ZX81-CONV-1
L_0237:
    INC HL                              ; Step through memory
    LD A,$C0
    AND (HL)                            ; Mask off the top two bits
    INC HL
    INC HL
    INC HL
    JR Z,L_0248                         ; If it was <$30, skip to ZX81-CONV-4
    LD HL,$4396                         ; Hard coded number we worked out before (start of program)
    JP L_04AC                           ; Re-initialise after loading and clear screen etc.

; ZX81-CONV-2
L_0246:
    ADD A,B                             ; Modify the command token from ZX81 to Lambda tokens

; ZX81-CONV-3
L_0247:
    LD (HL),A                           ; Update the token in the copde

; ZX81-CONV-4
L_0248:
    INC HL                              ; Step through program
    LD A,(HL)
    CALL SUB_0955                       ; Routine NUMBER
    JR Z,L_0248                         ; Skip through numbers

    CP $76                              ; Is it a newline?
    JR Z,L_0237                         ; Skip back for next line number
    CP $E1                              ; Is it a command over $E1?
    JR NC,L_0248                        ; Continue scanning
    CP $40                              ; Is it a number character below $40?
    JR C,L_0248                         ; Continue scanning
    LD B,$03
    CP $43                              ; Is it a command below $43?
    JR C,L_0246                         ; Add 3
    LD B,$62
    CP $DE                              ; Is it a command above $DE?
    JR NC,L_0246                        ; Add $62
    LD B,$FE
    CP $D8                              ; Is it cpmmand $D8?
    JR NC,L_0246                        ; Add $FE
    LD B,$FC
    CP $C4                              ; Is it above $C4?
    JR NC,L_0246                        ; Add $FC
    LD B,$13
    CP $C1                              ; Is it above $C1?
    JR NC,L_0246                        ; Add $13
    CP $C0
    JR NZ,L_0248                        ; Is it not $C0?
    LD A,$17                            ; Replace with dummy command
    JR L_0247                           ; Loop back to write the new value

; --------------------------
; THE 'SLOW' COMMAND ROUTINE
; --------------------------

; SLOW
SUB_0281:
    SET 6,(IY+$3B)                      ; Request slow mode ()

; SLOW/FAST
SUB_0285:
    LD HL,$403B                         ; Load the CDFLAG
    LD A,(HL)
    RLA                                 ; Bit 6 (request) -> bit 7 (current state)
    XOR (HL)                            ; XOR with actual current state
    RLA                                 ; Result -> carry
    RET NC                              ; Return if already in requested mode

    SET 7,(HL)                          ; Set slow mode - compute and display
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL

; Called where DISPLAY-1 usually was
; PRE-DISPLAY-1
SUB_0293:
    XOR A                               ; Clear the line counter
    EX AF,AF'
    OUT ($FE),A                         ; Enable NMI generator
    HALT                                ; Wait for interrupt
    OUT ($FD),A                         ; Disable NMI generator
    LD A,(HL)                           ; Waste cycles
    LD A,(HL)
    NOP

; -----------------------
; THE 'MAIN DISPLAY' LOOP
; -----------------------
; This routine is executed once for every frame displayed.

;; DISPLAY-1
L_029D:
    LD HL,($4034)                       ; Get the frame count from FRAMES
    DEC HL
    LD A,$7F                            ; Mask bit 7
    AND H                               ; Of H
    OR L                                ; And OR with L
    LD A,H                              ;
    JR NZ,L_02AB                        ; Jump if frame counter bits 0-14 are zero
    RLA                                 ; Bit 15 of frame counter (1 if paused) to carry
    JR L_02AD                           ; Skip

; ANOTHER
L_02AB:
    LD B,(HL)                           ; Dummy timing
    SCF                                 ; Set carry

; OVER-NC
L_02AD:
    LD H,A
    LD ($4034),HL                       ; Save the new frame count to FRAMES
    RET NC                              ; Return if FRAMES is in use by PAUSE command

; ZX81 goes string to                   ; DISPLAY-2

; Bit 7 of the cursor character is inverted every 16 frames
; That makes it flashe approximately 2 times a second
; BLINK-CURSOR
    LD A,L                              ; A = LSB of FRAMES
    LD HL,($407B)                       ; Address of blinking cursor
    SLA (HL)                            ; Rotate cursor character
    RLA                                 ;
    RLA                                 ;
    RLA                                 ;
    RLA                                 ; Rotate A bit 4 into carry
    RR (HL)                             ; Rotate carry back into character

; DISPLAY-2
    CALL SUB_033D                       ; KEYBOARD - scan keyboard and start VSYNC
    LD BC,($4025)                       ; Get LAST_K
    LD ($4025),HL                       ; Update LAST_K
    LD A,B
    ADD A,$02
    SBC HL,BC
    LD A,($4027)                        ; Check DEBOUNCE
    OR H
    OR L
    LD E,B
    LD B,$09                            ; ZX81 used $0B
    LD HL,$403B                         ; Get CDFLAG
    RES 0,(HL)
    JR NZ,L_02E4
    BIT 7,(HL)
    SET 0,(HL)
    RET Z                               ; Return if in FAST mode
    DEC B
    DEC B                               ; Extra DEC B, ZX81 was NOP
    SCF

; NO-KEY
L_02E4:
    RL B                                ; Reordered from ZX81

; LOOP-B
L_02E6:
    DJNZ L_02E6
    LD HL,$4027
    LD B,(HL)                           ; Get DEBOUCE
    LD A,E
    CP $FE
    SBC A,A
    LD B,$0F                            ; ZX81 has $1F
    OR (HL)
    AND B
    RRA
    LD (HL),A
    ADD HL,HL
    INC HL
    OUT ($FF),A                         ; End VSYNC pulse

    LD HL,$407D + $8000                 ; Hard coded DFILE location
    CALL SUB_0314

; ---------------------
; THE 'VIDEO-1' ROUTINE
; ---------------------

; R-IX-1 (timing altered)
    LD BC,$1901                         ; B=25 lines, C=1 scanline
    LD A,($0000)                        ; Wasting cycles
    LD A,$F5                            ; Preset value to go into R to cause trigger at correct time
    CALL SUB_0337                       ; DISPLAY-5, border complete, generate text display
    NOP
    NOP
    DEC HL                              ; Back to the previous HALT character
    CALL SUB_0314                       ; DISPLAY-3, bottom border
    JP L_029D                           ; Back to DISPLAY-1

; ---------------------------------
; THE 'DISPLAY BLANK LINES' ROUTINE
; ---------------------------------

; DISPLAY-3
SUB_0314:
    POP IX
    LD C,(IY+$28)                       ; Load C with MARGIN value
    BIT 7,(IY+$3B)                      ; Check CDFLAG
    JR Z,L_032B                         ; To DISPLAY-4 in FAST mode

    LD A,C                              ; A = 31 (NTSC) or 55 (PAL)
    NEG
    INC A
    EX AF,AF'                           ; Set NMI's A register to $FF-MARGIN

    OUT ($FE),A                         ; Enable the NMI generator

    POP HL                              ; Restore main registers
    POP DE
    POP BC
    POP AF
    RET                                 ; Return to users code until interrupted

; ------------------------
; THE 'FAST MODE' ROUTINES
; ------------------------

; DISPLAY-4
L_032B:
    LD A,$FC                            ; Set delay
    LD B,$01                            ; For 1 row
    CALL SUB_0337                       ; To DISPLAY-5
    DEC HL                              ; Back to previous HALT
    EX (SP),HL                          ; Waste cycles
    EX (SP),HL
    JP (IX)                             ; Back to R-IX-1 or R-IX-2

; --------------------------
; THE 'DISPLAY-5' SUBROUTINE
; --------------------------

; DISPLAY-5
SUB_0337:
    LD R,A                              ; R= $FC (SLOW mode) or $FC (FAST mode)
    LD A,$DD                            ; Preload next R
    EI                                  ; Enable interrupts at the end of lines
    JP (HL)                             ; Jump into the echo display file

; ----------------------------------
; THE 'KEYBOARD SCANNING' SUBROUTINE
; ----------------------------------

; KEYBOARD
SUB_033D:
    LD HL,$FFFF
    LD BC,$FEFE
    IN A,(C)                            ; Read port $FE, starts VSync pulse
    OR $01                              ; Ignore shift

; EACH-LINE
L_0347:
    OR $E0
    LD D,A
    CPL
    CP $01
    SBC A,A
    OR B
    AND L
    LD L,A
    LD A,H
    AND D
    LD H,A
    RLC B
    IN A,(C)
    JR C,L_0347
    RRA
    RL H

; GET_REGION
    LD A,$FF                            ; Read port $7E
    IN A,($7E)                          ; Will return the same as $FE unless there is something different in the Lambda
    RRA                                 ; Bit 7 => carry (Bit 7 that is the tape input???)
    CCF                                 ; Carry = !carry
    SBC A,A                             ; A = $FF (PAL) or $00 (NTSC)
    AND $18                             ; A = $18       or $00
    ADD A,$1F                           ; A = $37       or $1F
    LD ($4028),A                        ; Save this as MARGIN
    RET

; --------------------------
; THE 'FAST' COMMAND ROUTINE
; --------------------------
; FAST
SUB_036C:
    RES 6,(IY+$3B)                      ; Request FAST mode

; ------------------------------
; THE 'SET FAST MODE' SUBROUTINE
; ------------------------------

; SET-FAST
SUB_0370:
    BIT 7,(IY+$3B)                      ; Test FAST mode
    RET Z                               ; Already in Fast mode
    HALT                                ; Synchronise with interrupt

    OUT ($FD),A                         ; Disable NMI generator (value of A unimportant)
    RES 7,(IY+$3B)                      ; Set FAST mode
    RET

; --------------
; THE 'REPORT-F'
; --------------

;; REPORT-F
L_037D:
    RST 08H                             ; ERROR-1
    .BYTE $0D                           ; NA - po program NAme supplied.

; --------------------------
; THE 'SAVE COMMAND' ROUTINE
; --------------------------

; SAVE
SUB_037F:
    CALL SUB_0435
    JR C,L_037D
    LD (IY+$09),$FF                     ; Set version to $FF, indicating Lambda 8300 program
    EX DE,HL
    LD DE,$12CB                         ; Five seconds timing value

; HEADER
L_038C:
    CALL SUB_113B
    JR NC,L_03BF

; DELAY-1
L_0391:
    DJNZ L_0391
    DEC DE
    LD A,D
    OR E
    JR NZ,L_038C

; OUT-NAME
L_0398:
    CALL SUB_03AB
    BIT 7,(HL)
    INC HL
    JR Z,L_0398
    LD HL,$4009                         ; Set HL to first address to go, VERSN

; OUT-PROG
L_03A3:
    CALL SUB_03AB
    CALL SUB_0216
    JR L_03A3

; -------------------------
; THE 'OUT-BYTE' SUBROUTINE
; -------------------------

; OUT-BYTE
SUB_03AB:
    LD E,(HL)
    SCF

; EACH-BIT
L_03AD:
    RL E
    RET Z
    SBC A,A
    AND $05
    ADD A,$04
    LD C,A

; PULSES
L_03B6:
    OUT ($FF),A
    LD B,$23

; DELAY-2
L_03BA:
    DJNZ L_03BA
    CALL SUB_113B

; BREAK-2
L_03BF:
    JR NC,L_0433
    LD B,$1E

; DELAY-3
L_03C3:
    DJNZ L_03C3
    DEC C
    JR NZ,L_03B6

; DELAY-4
L_03C8:
    AND A
    DJNZ L_03C8
    JR L_03AD

; --------------------------
; THE 'LOAD COMMAND' ROUTINE
; --------------------------

; LOAD
SUB_03CD:
    CALL SUB_0435                       ; Routine NAME
                                        ; DE points to start of name in RAM
    RL D                                ; Pick up carry
    RRC D                               ; Carry now in bit 7

; NEXT-PROG
L_03D4:
    CALL SUB_03D9                       ; Routine IN-BYTE
    JR L_03D4                           ; Loop to NEXT-PROG

; ------------------------
; THE 'IN-BYTE' SUBROUTINE
; ------------------------

; IN-BYTE
SUB_03D9:
    LD C,$01                            ; Byte counter

; NEXT-BIT
L_03DB:
    LD B,$00                            ; Loop 256 times

; BREAK-3
L_03DD:
    LD A,$7F                            ; Check the space key
    IN A,($FE)                          ;
    OUT ($FF),A                         ; IO Write triggers VYsnc pulses on screen
    RRA                                 ; Check for space pressed (bit 0->Carry)
    JR NC,L_042F                        ; To BREAK-4 if so
    RLA                                 ; Carry->bit 0
    RLA                                 ; Bit 7->Carry
    JR C,L_0412                         ; Forward to GET-BIT if there is data
    DJNZ L_03DD                         ; Loop back and keep checking
    POP AF                              ; Drop return address
    CP D                                ; But A holds the value from port FE?

; RESTART
L_03EE:
    JP NC,L_04A3
    LD H,D
    LD L,E

; IN-NAME
L_03F3:
    CALL SUB_03D9
    BIT 7,D
    LD A,C
    JR NZ,L_03FE
    CP (HL)
    JR NZ,L_03D4

; MATCHING
L_03FE:
    INC HL
    RLA
    JR NC,L_03F3
    INC (IY+$15)
    LD HL,$4009

; IN-PROG
L_0408:
    LD D,B
    CALL SUB_03D9
    LD (HL),C
    CALL SUB_0216
    JR L_0408

; GET-BIT
L_0412:
    PUSH DE
    LD E,$94

; TRAILER
L_0415:
    LD B,$1A

; COUNTER
L_0417:
    DEC E
    IN A,($FE)
    RLA
    BIT 7,E
    LD A,E
    JR C,L_0415
    DJNZ L_0417
    POP DE
    JR NZ,L_0429
    CP $56
    JR NC,L_03DB

; BIT-DONE
L_0429:
    CCF
    RL C
    JR NC,L_03DB
    RET

; BREAK-4
L_042F:
    LD A,D                              ; Get D
    AND A                               ; Test it
    JR Z,L_03EE                         ; If there has been data, then restart

; REPORT-D
L_0433:
    RST 08H                             ; ERROR-1
    .BYTE $0C                           ; Error Report: BREAK - CONT repeats

; -----------------------------
; THE 'PROGRAM NAME' SUBROUTINE
; -----------------------------

; NAME
SUB_0435:
    CALL SUB_114A                       ; Routine SCANNING
    LD A,($4001)
    ADD A,A
    JP M,L_0F17                         ; To REPORT-C - Invalid Expression
    POP HL
    RET NC
    PUSH HL
    CALL SUB_0370                       ; Routine SET-FAST
    CALL SUB_15ED                       ; Routine STK-FETCH
    LD H,D
    LD L,E
    DEC C
    RET M
    ADD HL,BC
    SET 7,(HL)
    RET

; --------------------------
; THE 'MAKE A NOISE' ROUTINE
; --------------------------

; MAKE-NOISE
SUB_0450:
    LD E,$20                            ; Note = 32500/32 = 1.02KHz
    LD BC,$1800                         ; Duration = 6144/65 = 94ms
    JR L_0460                           ; Routine PLAY-NOTE

; ----------------------------
; THE 'SOUND' COMMAND ROUTINE
; ----------------------------

; SOUND
SUB_0457:
    CALL SUB_1088                       ; Routine FIND-INT => BC
    PUSH BC
    CALL SUB_1083                       ; Routine FIND-SHORT => A
    POP BC
    LD E,A                              ; INT => E

; PLAY-NOTE
; E = note, defined as 32500Hz/E, so (0=256=>127Hz) to (1=>32.5KHz)
; BC = duration, defined as BC/65ms, so (1=>15ms) to (0=65536=>1 second)
; Appox 4 times slower in SLOW mode
L_0460:
    IN A,($F5)                          ; Toggle beeper on read of $F5
    LD D,E                              ; Note
; PLAY-NOTE-2
L_0463:
    DEC BC                              ; Duration
    LD A,B
    OR C
    RET Z                               ; Return when BC=0
    DEC D
    JR Z,L_0460                         ; Toggle speaker when note countdown complete
    NOP
    NOP
    JR L_0463                           ; Loop until complete


; ---------------
; START CONTINUED
; ---------------

; START-3
L_046E:
    RRA                                 ; A was read from FE, column 0 -> C
    CPL
    LD ($4006),A                        ; Set mode
    LD BC,$BFFF                         ; Top of possible RAM, making max RAM 32K
    JR NC,L_0489                        ; Skip RAM test if key in column 0 held? autostart expansion ROM?
    LD A,(DFILE)                        ; Check of there is a DFILE
    CP $76                              ; Should start with a NL/HALT
    JR NZ,L_0489                        ; No DFILE, so do a cold start
    JR Z,L_04C0                         ; DFILE present, warm start, skip RAM test

; -------------------------
; THE 'NEW' COMMAND ROUTINE
; -------------------------

; NEW
SUB_0481:
    CALL SUB_0370                       ; Set FAST mode
    LD BC,($4004)                       ; RAMTOP top of detected / protected RAM
    DEC BC

; -----------------------
; THE 'RAM CHECK' ROUTINE
; -----------------------

; RAM-CHECK
L_0489:
    LD H,B                              ; HL = BC = last byte to test
    LD L,C
    LD A,$3F                            ; Stop point, check RAM down to $4000

; RAM-FILL
L_048D:
    LD (HL),$02                         ; Write 2 to every address in RAM.
    DEC HL
    CP H                                ; Stop when H=A=$3F
    JR NZ,L_048D

; RAM-READ
L_0493:
    AND A                               ; Reset carry flag
    SBC HL,BC                           ; Compare HL and BC
    ADD HL,BC                           ;
    INC HL                              ; HL = 4000 - what was the point in all that?
    JR NC,L_04A0                        ; If HL=BC, we're finished?
    DEC (HL)                            ; Decrement RAM
    JR Z,L_04A0                         ; Test if RAM was 1, but it would be picked up by the next test anyway?
                                        ; I wonder if this was original a test for mirrors? but it doesn't do that now
    DEC (HL)                            ; Decrement RAM
    JR Z,L_0493                         ; It was 2 previously, zero now, good RAM, keep checking

; SET-TOP
L_04A0:
    LD ($4004),HL                       ; Set RAMTOP, top of usable RAM

; ----------------------------------
; THE 'DFILE INITIALIZATION' ROUTINE
; ----------------------------------

; INIT-DFILE
L_04A3:
    LD HL,$4397                         ; Set VARS, starts of variable area
    LD ($4010),HL                       ; VARS = $4397 - fixed location after DFILE
    DEC HL                              ; HL = 4396, start of program
    LD (HL),$FF
L_04AC:
    LD ($400C),HL                       ; Set PRGRM

; CREATE-DFILE
    LD C,$19                            ; 24 lines + 1 extra NL
    XOR A                               ; A = 0 = Space

; NEXT-LINE
L_04B2:
    DEC HL
    LD (HL),$76                         ; Start / end with newline / halt
    DEC C                               ; Line counter
    JR Z,L_04C0                         ; Finished?

; FILL-LINE
    LD B,$20                            ; Fill line with 32 spaces
L_04BA:
    DEC HL                              ; Step backwards
    LD (HL),A                           ; Write a space
    DJNZ L_04BA                         ; Loop until done
    JR L_04B2                           ; Back for more

; ----------------------------
; THE 'INITIALIZATION' ROUTINE
; ----------------------------

; INITIAL
L_04C0:
    LD HL,($4004)                       ; Get RAMTOP
    DEC HL                              ; Move to last system byte
    LD (HL),$3E                         ; Set GOSUB end marker
    DEC HL                              ; Move down again
    LD SP,HL                            ; Set stack here
    DEC HL                              ; Move to first location in stack
    DEC HL                              ;
    LD ($4002),HL                       ; Set error stack pointer ERR_SP
                                        ; I register is setup here on ZX81, not used on the Lambda,
                                        ; The character ROM is inside the ULA
    IM 1                                ; Z80 interrupt mode 1
    LD IY,$4000                         ; Set IY to start of SYS VARS to make access easier
    LD (IY+$3B),$40                     ; CDFLAG - compute and display mode requested
    LD (IY+$21),$19                     ; Set TEMPO to 25 (25*3.94ms = ~ 100ms)
    XOR A                               ; Clear more flags
    LD ($4019),A                        ; X_PTR_lo = 0
    LD ($402D),A                        ; FLAGX = 0
    LD ($4001),A                        ; FLAGS = 0
    LD ($407C),A                        ; SPARE3 = 0
    DEC A                               ; A now $FF
    LD ($4035),A                        ; FRAMES_lo = $FF
    CALL SUB_1692                       ; CLEAR
    CALL SUB_0450                       ; MAKE-NOISE
    CALL SUB_0285                       ; SLOW-FAST to set SLOW mode
    LD A,($4006)                        ; Check mode
    RRA
    JP C,$2000                          ; Autostart expansion ROM?

L_04FC:
    CALL SUB_16A5                       ; CURSOR-IN, set cursor on edit line

; ---------------------------
; THE 'BASIC LISTING' SECTION
; ---------------------------

; UPPER
L_04FF:
    CALL SUB_0BD0                       ; CLS
    LD HL,($4029)                       ; E.PPC line number with cursor on (was $400A on ZX81)
    LD DE,($4023)
    AND A
    SBC HL,DE
    EX DE,HL
    JR NC,L_0513
    ADD HL,DE
    LD ($4023),HL

; ADDR-TOP
L_0513:
    CALL SUB_0B6A
    JR Z,L_0519
    EX DE,HL

; LIST-TOP
L_0519:
    CALL SUB_08CD
    DEC (IY+$1E)
    JR NZ,L_0558                        ; Routine LOWER
    LD HL,($4029)                       ; E.PPC line number with cursor on (was $400A on ZX81)
    CALL SUB_0B6A
    LD HL,($4016)
    SCF
    SBC HL,DE
    LD HL,$4023
    JR NC,L_053D
    EX DE,HL
    LD A,(HL)
    INC HL
    LDI
    LD (DE),A
    JR L_04FF

; DOWN-KEY
SUB_053A:
    LD HL,$4029                         ; E.PPC line number with cursor on (was $400A on ZX81)

; INC-LINE
L_053D:
    LD E,(HL)
    INC HL
    LD D,(HL)
    PUSH HL
    EX DE,HL
    INC HL
    CALL SUB_0B6A
    CALL SUB_0677
    POP HL

; KEY-INPUT
L_054A:
    BIT 5,(IY+$2D)
    JR NZ,L_0558                        ; Routine LOWER
    LD (HL),D
    DEC HL
    LD (HL),E
    JR L_04FF

; ----------------------------
; THE 'EDIT LINE COPY' SECTION
; ----------------------------

; EDIT-INP
L_0555:
    CALL SUB_16A5                       ; CURSOR-IN, set cursor on edit line

; LOWER
L_0558:
    LD HL,($4014)

; EACH-CHAR
L_055B:
    LD A,(HL)
    CP $7E
    JR NZ,L_0568
    LD BC,$0006
    CALL SUB_0BF5                       ; Routine RECLAIM-2
    JR L_055B

; END-LINE
L_0568:
    CP $76
    INC HL
    JR NZ,L_055B

; EDIT-LINE
                                        ; ZX81 sets K or L here - we don't have that

; EDIT-ROOM
L_056D:
    CALL SUB_0BC2                       ; Routine LINE-ENDS
    LD HL,($4014)                       ; Get E.LINE, the address of edit line
    LD (IY+$00),$FF                     ; Set error to $FF (OK)
    CALL SUB_08FC                       ; Routine COPY-LINE
    BIT 7,(IY+$00)                      ; Check if there was an error
    JR NZ,L_058D                        ; To DISPLAY-6 if OK
    LD A,($4022)                        ; Check DF.SZ, size of editor section
    CP $18                              ; Is it >24 lines
    JR NC,L_058D                        ; To DISPLAY-6
    INC A                               ; Add a line
    LD ($4022),A                        ; Update value
    JR L_056D                           ; Simplified loop back compared to ZX81

; --------------------------
; THE 'WAIT FOR KEY' SECTION
; --------------------------

; DISPLAY-6
L_058D:
    LD HL,$0000                         ; Clear X.PTR   - Addess of character before syntax error
    LD ($4018),HL                       ;
    LD HL,$403B                         ; Get CDFLAGS
    BIT 7,(HL)                          ; Check FAST/SLOW mode
    CALL Z,SUB_0293                     ; Routine PRE-DISPLAY-1 if FAST

; SLOW-DISP
L_059B:
    BIT 0,(HL)
    JR Z,L_059B                         ; Loop unti bit 0 of (HL) is 1
    LD BC,($4025)
    CALL SUB_1140                       ; Routine DEBOUNCE
    CALL SUB_095E                       ; Routine DECODE
    JR NC,L_0558                        ; Routine LOWER
    BIT 5,(IY+$3B)                      ; Check if we should beep
    JR NZ,L_05CE

; KEY-BEEP
    PUSH DE                             ; Save DE and HL
    PUSH HL
    CALL SUB_0370                       ; Routine SET-FAST
    ADD A,$14                           ; Add $14 to the key value
    LD E,A                              ; Set the note to that
    LD BC,$04CE                         ; Set the duration to 18.9ms
    BIT 5,(IY+$28)                      ; Test bit 5 of MARGIN to check region
    JR NZ,L_05C5                        ; Skip if PAL
    LD BC,$0406                         ; Change duration to 15.9ms
L_05C5:
    CALL L_0460                         ; Routine PLAY-NOTE
    CALL SUB_0285                       ; FAST/SLOW
    POP HL                              ; Restore DE and HL
    POP DE
    LD A,E                              ; And A is restored to what it was + $14 (is that intentional?)

; variation on FETCH-2
L_05CE:
    BIT 2,(IY+$01)                      ; Check FLAG K mode = 0, L = 1
    JR Z,L_05DC                         ; Skip for K mode
    CP $28                              ; Check for ?
    JR C,L_05F2                         ; Skip
    LD HL,$00A1
    ADD HL,DE

; FETCH-3
L_05DC:
    LD A,(HL)

; TEST-CURS
L_05DD:
    CP $F0
    JP PE,L_05FB                        ; Routine KEY-SORT

; ENTER
    LD E,A
    CALL SUB_0605                       ; Routine CURSOR
    LD A,E
    CALL SUB_05ED                       ; Routine ADD-CHAR

; BACK-NEXT
L_05EA:
    JP L_0558                           ; Back to LOWER

; ------------------------------
; THE 'ADD CHARACTER' SUBROUTINE
; ------------------------------

; ADD-CHAR
SUB_05ED:
    CALL SUB_0B2D
    LD (DE),A
    RET

; more variation on FETCH-2
L_05F2:
    LD A,(HL)
    CP $76                              ; Check for NEWLINE
    SET 7,A
    JR NZ,L_05DD                        ; Routine TEST-CURS
    LD A,$78

; KEY-SORT
L_05FB:
    LD E,A                              ; DE = key
    LD HL,L_0618 - $E0                  ; Reference to ED-KEYS table
    ADD HL,DE                           ; HL = table base - $E0 + 2x key
    ADD HL,DE
    LD C,(HL)                           ; BC = function address
    INC HL
    LD B,(HL)
    PUSH BC                             ; Push handler function onto stack

; CURSOR
SUB_0605:
    LD HL,($4014)

; cut down version of TEST-CHAR
L_0608:
    LD A,(HL)
    CP $7F
    RET Z
    INC HL
    CALL SUB_0955
    JR L_0608

; --------------------------
; THE 'CLEAR-ONE' SUBROUTINE
; --------------------------

; CLEAR-ONE
SUB_0612:
    LD BC,$0001
    JP SUB_0BF5                         ; Routine RECLAIM-2

; ------------------------
; THE 'EDITING KEYS' TABLE
; ------------------------

; ED-KEYS
L_0618:
    .WORD SUB_0657                      ; UP_KEY
    .WORD SUB_053A                      ; DOWN-KEY
    .WORD SUB_062E                      ; LEFT-KEY
    .WORD SUB_0637                      ; RIGHT-KEY
    .WORD SUB_0667                      ; SET-L-MODE
    .WORD SUB_0680                      ; EDIT-KEY
    .WORD SUB_0713                      ; NEWLINE-KEY
    .WORD SUB_0643                      ; RUBOUT
    .WORD SUB_066D                      ; SET-K-MODE
    .WORD SUB_0700                      ; FUNCTION
    .WORD SUB_06C8                      ; FUNCTION

; -------------------------
; THE 'CURSOR LEFT' ROUTINE
; -------------------------

; LEFT-KEY
SUB_062E:
    CALL SUB_064B                       ; Routine LEFT-EDGE
    LD A,(HL)
    LD (HL),$7F
    INC HL
    JR L_0640

; --------------------------
; THE 'CURSOR RIGHT' ROUTINE
; --------------------------

; RIGHT-KEY
SUB_0637:
    INC HL
    LD A,(HL)
    CP $76
    JR Z,L_0655                         ; Routine ENDED-2
    LD (HL),$7F
    DEC HL

; GET-CODE
L_0640:
    LD (HL),A

; ENDED-1
L_0641:
    JR L_05EA

; --------------------
; THE 'RUBOUT' ROUTINE
; --------------------

; RUBOUT
SUB_0643:
    CALL SUB_064B
    CALL SUB_0612
    JR L_0641

; ------------------------
; THE 'ED-EDGE' SUBROUTINE
; ------------------------

; LEFT-EDGE
SUB_064B:
    DEC HL
    LD DE,($4014)
    LD A,(DE)
    CP $7F
    RET NZ
    POP DE

; ENDED-2
L_0655:
    JR L_0641

; -----------------------
; THE 'CURSOR UP' ROUTINE
; -----------------------

; UP-KEY
SUB_0657:
    LD HL,($4029)                       ; E.PPC line number with cursor on (was $400A on ZX81)
    CALL SUB_0B6A
    EX DE,HL
    CALL SUB_0677
    LD HL,$402A
    JP L_054A


; --------------------------
; THE 'FUNCTION KEY' ROUTINE
; --------------------------

; Alternatives to the FUNCTION key routine

; SET-L-MODE
SUB_0667:
    SET 2,(IY+$01)                      ; Enter L mode
    JR L_0655

; SET-K-MODE
SUB_066D:
    RES 2,(IY+$01)                      ; Enter K mode
    JR L_0655

; ------------------------------------
; THE 'COLLECT LINE NUMBER' SUBROUTINE
; ------------------------------------

; ZERO-DE
L_0673:
    EX DE,HL
    LD DE,L_058D+1                      ; Points to code containing $0000

; LINE-NO
SUB_0677:
    LD A,(HL)
    AND $C0
    JR NZ,L_0673
    LD D,(HL)
    INC HL
    LD E,(HL)
    RET

; ----------------------
; THE 'EDIT KEY' ROUTINE
; ----------------------

; EDIT-KEY
SUB_0680:
    CALL SUB_0BC2                       ; Routine LINE-ENDS
    LD HL,L_0555                        ; Routine EDIT-INP
    PUSH HL
    BIT 5,(IY+$2D)
    RET NZ
    LD HL,($4014)
    LD ($400E),HL
    LD HL,$1821
    LD ($4039),HL
    LD HL,($4029)                       ; E.PPC line number with cursor on (was $400A on ZX81)
    CALL SUB_0B6A
    CALL SUB_0677
    LD A,D
    OR E
    RET Z
    DEC HL
    CALL SUB_0C35
    INC HL
    LD C,(HL)
    INC HL
    LD B,(HL)
    INC HL
    LD DE,($400E)
    LD A,$7F
    LD (DE),A
    INC DE
    PUSH HL
    LD HL,$001D
    ADD HL,DE
    ADD HL,BC
    SBC HL,SP
    POP HL
    RET NC
    LDIR
    EX DE,HL
L_06C2:
    POP DE
    CALL SUB_169E
L_06C6:
    JR L_0655
                                        ; ZX81 dropped through to N/L-KEY here

; ----------------------
; THE 'EDIT KEY' ROUTINE
; ----------------------

; variation on EDIT-KEY
SUB_06C8:
    BIT 5,(IY+$2D)                      ; Test FLAGX
    JR NZ,L_06C6                        ; Jump back if in INPUT mode

    LD HL,L_0555                        ; Address of EDIT-INP routine
    PUSH HL                             ; Pushed onto stack

    LD HL,($4014)                       ; Fetch E-LINE
    LD ($400E),HL                       ; Update cursor DF-CC

    LD HL,$1821                         ; Line 0, column 0
    LD ($4039),HL                       ; Update S-POSN

    LD HL,($4029)                       ; Fetch E.PPC line number with cursor on (was $400A on ZX81)
    LD BC,0$0A
    ADD HL,BC
    LD B,H
    LD C,L
    LD HL,$270F
    AND A
    SBC HL,BC
    JR NC,L_06F2
    LD BC,$270F
L_06F2:
    CALL SUB_0C2D                       ; OUT-NUM, print line number
    LD HL,($400E)
    LD (HL),$7F
    INC HL
    LD (HL),$76
    INC HL
    JR L_06C2

; ?
SUB_0700:
    LD HL,$402D                         ; FLAGX
    BIT 5,(HL)                          ; Check bit 5
    JP Z,L_04FC
    RES 5,(HL)
    CALL SUB_0BC2                       ; Routine LINE-ENDS
    LD HL,$4000
    JP L_07BC

; -------------------------
; THE 'NEWLINE KEY' ROUTINE
; -------------------------

; sort of N/L-KEY
SUB_0713:
    CALL SUB_0BC2                       ; Routine LINE-ENDS
    LD HL,L_0558                        ; Routine LOWER
    BIT 5,(IY+$2D)                      ; Check FLAGS
    JR NZ,L_0722
    LD HL,L_04FF                        ; Routine UPPER

L_0722:
    PUSH HL
    CALL SUB_084A
    BIT 5,(IY+$2D)
    JR NZ,L_073A
    LD HL,($4014)
    LD A,(HL)
    CP $FF
    JR Z,L_073A
    CALL SUB_0A81
    CALL SUB_0BD0                       ; CLS

; Similar to NOW_SCAN
L_073A:
    CALL SUB_0E3B
    POP HL
    CALL SUB_0605
    CALL SUB_0612
    CALL SUB_0C08
    JR NZ,L_075D
    LD A,B
    OR C
    JP NZ,L_0809
    DEC BC
    DEC BC
    LD ($4007),BC
    LD (IY+$22),$02
    LD DE,DFILE                         ; Hard coded DFILE location
    JR L_0770

; N/L-INP
L_075D:
    CP $76
    JR Z,L_0773
    LD BC,($4030)
    CALL SUB_0AB7                       ; Routine LOC-ADDR
    LD DE,($400A)
    LD (IY+$22),$02

; TEST-NULL
L_0770:
    RST 18H
    CP $76

; N/L-NULL
L_0773:
    JP Z,L_04FC
    LD (IY+$01),$81
    EX DE,HL

; NEXT-LINE
L_077B:
    LD ($400A),HL                       ; NXTLIN - Address of next line to be executed (ZX81 was $4029)
    EX DE,HL
    CALL SUB_004E
    CALL SUB_0E42
    RES 1,(IY+$01)
    LD A,$C0
    LD (IY+$19),$00
    CALL SUB_169B
    RES 5,(IY+$2D)
    BIT 7,(IY+$00)
    JR Z,L_07BE
    LD HL,($400A)                       ; NXTLIN - Address of next line to be executed (ZX81 was $4029)
    AND (HL)
    JR NZ,L_07BE
    LD D,(HL)
    INC HL
    LD E,(HL)
    LD ($4007),DE
    INC HL
    LD E,(HL)
    INC HL
    LD D,(HL)
    INC HL
    EX DE,HL
    ADD HL,DE
    CALL SUB_113B
    JR C,L_077B
    LD HL,$4000
    BIT 7,(HL)
    JR Z,L_07BE
L_07BC:
    LD (HL),$0C

; STOP-LINE
L_07BE:
    BIT 7,(IY+$38)
    CALL Z,SUB_0A11
    LD BC,$0121
    CALL SUB_0AB7                       ; Routine LOC-ADDR
    LD A,($4000)
    LD BC,($4007)
    INC A
    JR Z,L_07E1
    CP $09
    JR NZ,L_07DA
    INC BC

; CONTINUE
L_07DA:
    LD ($402B),BC                       ; Set OLDPPC
    JR NZ,L_07E1
    DEC BC

; REPORT (different to ZX81)
L_07E1:
    RLCA                                ; A = 2 * error code
    LD E,A
    LD D,$00
    LD HL,L_01F2                        ; Address of error code table
    ADD HL,DE                           ; HL = table + 2 * error code

    LD A,(HL)                           ; Print the first letter of the error code
    RST 10H

    INC HL                              ; Print the second letter of the error code
    LD A,(HL)
    RST 10H

    BIT 7,B                             ; Check bit 7 of return address (check for immediate mode?)
    JR NZ,L_0800

; IN_LINE
    LD E,$04                            ; 4 characters
    LD HL,L_0212                        ; Table containing " IN "
L_07F7:
    LD A,(HL)                           ; Get character
    INC HL
    RST 10H                             ; Print character
    DEC E
    JR NZ,L_07F7                        ; Loop until all done

    CALL SUB_0C2D                       ; OUT-NUM, print line number
L_0800:
    CALL SUB_16A5                       ; CURSOR-IN, set cursor on edit line
    CALL SUB_1140                       ; Routine DEBOUNCE
    JP L_058D

; N/L-LINE (sort of)
L_0809:
    LD ($4029),BC                       ; E.PPC line number with cursor on (was $400A on ZX81)
    LD HL,($4016)
    EX DE,HL
    LD HL,L_04FC
    PUSH HL
    LD HL,($401A)
    SBC HL,DE
    PUSH HL
    LD H,B
    LD L,C
    CALL SUB_0B6A
    JR NZ,L_0828
    CALL SUB_0B84
    CALL SUB_0BF5                       ; Routine RECLAIM-2

; COPY-OVER
L_0828:
    POP BC
    LD A,C
    DEC A
    OR B
    RET Z
    PUSH BC
    INC BC
    INC BC
    INC BC
    INC BC
    CALL SUB_0B30                       ; MAKE-ROOM
    POP BC
    PUSH BC
    LD HL,($401A)
    DEC HL
    LDDR
    LD HL,($4029)                       ; E.PPC line number with cursor on (was $400A on ZX81)
    EX DE,HL
    POP BC
    LD (HL),B
    DEC HL
    LD (HL),C
    DEC HL
    LD (HL),E
    DEC HL
    LD (HL),D
    RET

; Not LLIST ?
SUB_084A:
    LD HL,($4014)
L_084D:
    LD ($4016),HL
    RST 18H
L_0851:
    CP $0B
    JR NZ,L_085F
L_0855:
    RST 20H
    CP $0B
    JR Z,L_0875
    CP $76
    RET Z
    JR L_0855
L_085F:
    CP $76
    RET Z
    LD DE,L_00F1                        ; Token table
    LD C,$00
    JR L_0878
L_0869:
    LD A,(DE)
    BIT 7,A
    INC DE
    JR Z,L_0869
    INC C
    LD A,$45
    CP C
    JR NC,L_0878
L_0875:
    RST 20H
    JR L_0851
L_0878:
    LD HL,($4016)
L_087B:
    LD A,(DE)
    LD B,A
    AND $7F
    CP (HL)
    JR NZ,L_0869
    INC HL
    INC DE
    BIT 7,B
    JR Z,L_087B
L_0888:
    LD A,(HL)
    AND A
    JR NZ,L_088F
    INC HL
    JR L_0888
L_088F:
    LD DE,($4016)
    LD ($4016),HL
    LD HL,($4014)
    AND A
L_089A:
    SBC HL,DE
    ADD HL,DE
    JR NC,L_08A5
    DEC DE
    LD A,(DE)
    AND A
    JR Z,L_089A
    INC DE
L_08A5:
    LD A,C
    BIT 6,A
    JR NZ,L_08AC
    OR $C0
L_08AC:
    LD (DE),A
    INC DE
    LD HL,($4016)
    PUSH AF
    CALL SUB_0BF2
    POP AF
    CP $EA
    RET Z
    JR L_084D

; ---------------------------------------
; THE 'LIST' AND 'LLIST' COMMAND ROUTINES
; ---------------------------------------

; LLIST
SUB_08BB:
    SET 1,(IY+$01)

; LIST
SUB_08BF:
    CALL SUB_1088
    LD A,B
    AND $3F
    LD H,A
    LD L,C
    LD ($4029),HL                       ; E.PPC line number with cursor on (was $400A on ZX81)
    CALL SUB_0B6A

; LIST-PROG
SUB_08CD:
    LD E,$00

; UNTIL-END
L_08CF:
    CALL SUB_08D4
    JR L_08CF

; -----------------------------------
; THE 'PRINT A BASIC LINE' SUBROUTINE
; -----------------------------------

; OUT-LINE
SUB_08D4:
    LD BC,($4029)                       ; E.PPC line number with cursor on (was $400A on ZX81)
    CALL SUB_0B7C
    LD D,$97
    JR Z,L_08E4
    LD DE,$0000
    RL E

; TEST-END
L_08E4:
    LD (IY+$1E),E
    LD A,(HL)
    CP $40
    POP BC
    RET NC
    PUSH BC                             ; Rest of function different to ZX81
    LD ($4016),HL                       ; CH.ADD - Address of next character to interpret
    CALL SUB_0C35
    LD A,D
    RST 10H
    LD HL,($4016)
    INC HL
    INC HL
    INC HL
    INC HL

; COPY-LINE
SUB_08FC:
    LD ($4016),HL
    SET 0,(IY+$01)

; MORE-LINE
L_0903:
    LD BC,($4018)
    LD HL,($4016)
    AND A
    SBC HL,BC
    JR NZ,L_0918
    LD A,$AA                            ; Inverse E
    RST 10H                             ; Print character

    CALL SUB_094D                       ; SET-CURSOR
    CALL SUB_0450                       ; MAKE-NOISE

; TEST-NUM
L_0918:
    LD HL,($4016)
    LD A,(HL)
    INC HL
    CALL SUB_0955
    LD ($4016),HL
    JR Z,L_0903
    CP $7F
    JR Z,L_0939
    CP $76
    JR Z,L_098F
    BIT 6,A
    JR Z,L_0936
    CALL SUB_0AD7
    JR L_0903

; NOT-TOKEN
L_0936:
    RST 10H
    JR L_0903

; different to ZX81 from here
L_0939:
    LD A,$80
    BIT 2,(IY+$01)
    JR Z,L_0943
    LD A,$AC
L_0943:
    DEC B
    INC B
    CALL Z,SUB_094A
    JR L_0903
SUB_094A:
    CALL L_0996

; SET-CURSOR
SUB_094D:
    LD HL,($400E)                       ; Get current character address
    DEC HL                              ; Move one before that
    LD ($407B),HL                       ; Set the blinking cursor to that address
    RET

; -----------------------
; THE 'NUMBER' SUBROUTINE
; -----------------------

; NUMBER
SUB_0955:
    CP $7E
    RET NZ
    INC HL
    INC HL
    INC HL
    INC HL
    INC HL
    RET

; --------------------------------
; THE 'KEYBOARD DECODE' SUBROUTINE
; --------------------------------

; DECODE
SUB_095E:
    LD D,$00
    SRA B
    SBC A,A
    OR $26
    LD L,$05
    SUB L

; KEY-LINE
L_0968:
    ADD A,L
    SCF
    RR C
    JR C,L_0968
    INC C
    RET NZ
    LD C,B
    DEC L
    LD L,$01
    JR NZ,L_0968
    LD HL,$007A
    LD E,A
    ADD HL,DE
    SCF
    RET

; -------------------------
; THE 'PRINTING' SUBROUTINE
; -------------------------

; LEAD-SP
L_097D:
    LD A,E
    AND A
    RET M
    JR L_0992

; OUT-DIGIT
SUB_0982:
    XOR A

; DIGIT-INC
L_0983:
    ADD HL,BC
    INC A
    JR C,L_0983
    SBC HL,BC
    DEC A
    JR Z,L_097D

; OUT-CODE
SUB_098C:
    LD E,$1C
    ADD A,E

; OUT-CH
L_098F:
    AND A
    JR Z,L_0996

; PRINT-CH
L_0992:
    RES 0,(IY+$01)

; PRINT-SP
L_0996:
    EXX
    PUSH HL
    BIT 1,(IY+$01)
    JR NZ,L_09A3
    CALL SUB_09A9
    JR L_09A6

; LPRINT-A
L_09A3:
    CALL SUB_09F2

; PRINT-EXX
L_09A6:
    POP HL
    EXX
    RET

; ENTER-CH
SUB_09A9:
    LD D,A
    LD BC,($4039)
    LD A,C
    CP $21
    JR Z,L_09CD

; TEST-N/L
L_09B3:
    LD A,$76
    CP D
    JR Z,L_09E8
    LD HL,($400E)
    CP (HL)
    LD A,D
    JR NZ,L_09DF
    DEC C
    JR NZ,L_09DB
    INC HL
    LD ($400E),HL
    LD C,$21
    DEC B
    LD ($4039),BC

; TEST-LOW
L_09CD:
    LD A,B
    CP (IY+$22)
    JR Z,L_09D6
    AND A
    JR NZ,L_09B3

; REPORT-5
L_09D6:
    LD L,$04
    JP L_0059

; EXPAND-1
L_09DB:
    CALL SUB_0B2D
    EX DE,HL

; WRITE-CH
L_09DF:
    LD (HL),A
    INC HL
    LD ($400E),HL
    DEC (IY+$39)
    RET

; WRITE-N/L
L_09E8:
    LD C,$21
    DEC B
    SET 0,(IY+$01)
    JP SUB_0AB7                         ; Routine LOC-ADDR

; --------------------------
; THE 'LPRINT-CH' SUBROUTINE
; --------------------------

; LPRINT-CH
SUB_09F2:
    CP $76
    JR Z,SUB_0A11
    LD C,A
    LD A,($4038)
    AND $7F
    CP $5C
    LD L,A
    LD H,$40
    CALL Z,SUB_0A11
    LD (HL),C
    INC L
    LD (IY+$38),L
    RET

; --------------------------
; THE 'COPY' COMMAND ROUTINE
; --------------------------

; COPY
SUB_0101:
    LD D,$16
    LD HL,$407E
    JR L_0A16

; COPY-BUFF
SUB_0A11:
    LD D,$01
    LD HL,$403C

; COPY*D
L_0A16:
    CALL SUB_0370                       ; Routine SET-FAST
    PUSH BC

; COPY-LOOP
L_0A1A:
    PUSH HL
    XOR A
    LD E,A

; COPY-TIME
L_0A1D:
    OUT ($FB),A
    POP HL

; COPY-BRK
L_0A20:
    CALL SUB_113B
    JR C,L_0A2A
    RRA
    OUT ($FB),A
; REPORT-D2
    RST 08H                             ; ERROR-1
    .BYTE $0C                           ; BK - BreaK

; COPY-CONT
L_0A2A:
    IN A,($FB)
    ADD A,A
    JP M,L_0A7D
    JR NC,L_0A20
    PUSH HL
    PUSH DE
    LD A,D
    CP $02
    SBC A,A
    AND E
    RLCA
    AND E
    LD D,A

; COPY-NEXT
L_0A3C:
    LD C,(HL)                           ; Load character from screen or buffer
    LD A,C                              ; Save a copy in C for later test
    INC HL                              ; Update pointer for next time
    CP $76                              ; Is this a newline?
    JR Z,L_0A66                         ; Forward to COPY-N/L if it is
    PUSH HL                             ; No NL, so preserve the counter
; different to ZX81 from here
    OUT ($F6),A                         ; Write character code to $F6
    LD A,E                              ; Get byte offset (0-7)
    OUT ($F5),A                         ; Write byte offset to F5
    IN A,($F6)                          ; Read character data from ULA? (or custom printer?)
    RL C                                ; Test backup character code
    JR NC,L_0A51                        ; Skip if bit 7 was not set
    XOR $FF                             ; Bit7 set, invert bits

; back to ZX81 code from here
L_0A51:
    LD C,A
    LD B,$08

; COPY-BITS
L_0A54:
    LD A,D
    RLC C
    RRA
    LD H,A

; COPY-WAIT
L_0A59:
    IN A,($FB)
    RRA
    JR NC,L_0A59
    LD A,H
    OUT ($FB),A
    DJNZ L_0A54
    POP HL
    JR L_0A3C

; COPY-N/L
L_0A66:
    IN A,($FB)
    RRA
    JR NC,L_0A66
    LD A,D
    RRCA
    OUT ($FB),A
    POP DE
    INC E
    BIT 3,E
    JR Z,L_0A1D
    POP BC
    DEC D
    JR NZ,L_0A1A
    LD A,$04
    OUT ($FB),A

; COPY-END
L_0A7D:
    CALL SUB_0285                       ; FAST/SLOW
    POP BC

; -------------------------------------
; THE 'CLEAR PRINTER BUFFER' SUBROUTINE
; -------------------------------------

; CLEAR-PRB
SUB_0A81:
    LD HL,$405C
    LD (HL),$76
    LD B,$20

; PRB-BYTES
L_0A88:
    DEC HL
    LD (HL),$00
    DJNZ L_0A88
    LD A,L
    SET 7,A
    LD ($4038),A
    RET

; -------------------------
; THE 'PRINT AT' SUBROUTINE
; -------------------------

; PRINT-AT
SUB_0A94:
    LD A,$17
    SUB B
    JR C,L_0AA4

; TEST-VAL
SUB_0A99:
    CP (IY+$22)
    JP C,L_09D6
    INC A
    LD B,A
    LD A,$1F
    SUB C

; WRONG-VAL
L_0AA4:
    JP C,L_108E
    ADD A,$02
    LD C,A

; SET-FIELD
SUB_0AAA:
    BIT 1,(IY+$01)
    JR Z,SUB_0AB7                       ; Routine LOC-ADDR
    LD A,$5D
    SUB C
    LD ($4038),A
    RET

; ----------------------------
; THE 'LOCATE ADDRESS' ROUTINE
; ----------------------------

; LOC-ADDR  different to ZX81
SUB_0AB7:
    LD ($4039),BC                       ; Set S.POSN - Current PRINT position
    LD A,$21
    SUB C
    LD C,A
    LD A,$18
    SUB B
    LD L,A
    LD H,$00
    LD B,$05
L_0AC7:
    ADD HL,HL
    DJNZ L_0AC7
    ADD HL,BC
    LD C,A
    ADD HL,BC
    LD BC,$407E                         ; Position of top left character (fixed DFILE location)
    ADD HL,BC                           ; Add offset to get address of character
    LD ($400E),HL                       ; Set DF.CC - Display file current character
    LD B,$00
    RET

; ------------------------------
; THE 'EXPAND TOKENS' SUBROUTINE
; ------------------------------

; TOKENS
SUB_0AD7:
    PUSH AF
    CALL SUB_0B07
    JR NC,L_0AE5
    BIT 0,(IY+$01)
    JR NZ,L_0AE5
    XOR A
    RST 10H

; ALL-CHARS - different to ZX81
L_0AE5:
    LD A,(BC)
    AND $3F
    RST 10H
    LD A,(BC)
    INC BC
    ADD A,A
    JR NC,L_0AE5
    LD C,A
    POP AF
    CP $C0
    JR NC,L_0AF7
    CP $43
    RET NC
L_0AF7:
    LD A,C
    CP $1A
    JR Z,L_0AFF
    CP $38
    RET C

; TRAIL-SP
L_0AFF:
    XOR A
    SET 0,(IY+$01)
    JP L_0996

; TOKEN-ADD
SUB_0B07:
    PUSH HL
    LD HL,L_00F0                        ; Tokens table
    BIT 7,A
    JR Z,L_0B11
    AND $3F

; TEST-HIGH
L_0B11:
    CP $46                              ; $46 tokens in table
    JR NC,L_0B25
    LD B,A
    INC B

; WORDS
L_0B17:
    BIT 7,(HL)
    INC HL
    JR Z,L_0B17
    DJNZ L_0B17
    CP $43                              ; Different offsets here
    JR NC,L_0B25
    CP $16                              ; And here

; COMP-FLAG
    CCF

; FOUND
L_0B25:
    LD B,H
    LD C,L
    POP HL
    RET NC
    LD A,(BC)
    ADD A,$E4
    RET

; --------------------------
; THE 'ONE SPACE' SUBROUTINE
; --------------------------

; ONE-SPACE
SUB_0B2D:
    LD BC,$0001

; --------------------------
; THE 'MAKE ROOM' SUBROUTINE
; --------------------------

; Make room for DE bytes at HL

; MAKE-ROOM
SUB_0B30:
    PUSH HL                             ; Save HL
    CALL SUB_10A0                       ; Routine TEST-ROOM
    POP HL                              ; Restore HL
    CALL SUB_0B3F                       ; Routine POINTERS
    LD HL,($401C)                       ; STKEND - End of calculator stack
    EX DE,HL                            ; DE=STKEND, HL=Location of bytes to be moved, BC=number of bytes to move
    LDDR                                ; Move bytes
    RET

; -------------------------
; THE 'POINTERS' SUBROUTINE
; -------------------------

; POINTERS
SUB_0B3F:
    PUSH AF                             ; Save the Carry from the result of TEST-ROM
    PUSH HL                             ; Save HL, the destination
    LD HL,$400A                         ; NXTLIN - Address of next line to be executed (ZX81 was $4029)
    LD A,$0A                            ; Number of pointers to test

; NEXT-PTR
L_0B46:
    LD E,(HL)
    INC HL
    LD D,(HL)
    EX (SP),HL                          ; Get destination from stack
    AND A                               ; Clear carry flag
    SBC HL,DE                           ; Subtract and restore to set flags
    ADD HL,DE                           ;
    EX (SP),HL                          ; Restore destination to stack
    JR NC,L_0B5A                        ; Skip to PTR-DONE if pointer below destination
; pointer is after point of insertion, so update pointer
    PUSH DE                             ; Save DE
    EX DE,HL
    ADD HL,BC                           ; Move pointer up by BC bytes
    EX DE,HL
    LD (HL),D                           ; Update the pointer
    DEC HL
    LD (HL),E
    INC HL
    POP DE                              ; Restore DE

; PTR-DONE
L_0B5A:
    INC HL                              ; Next pointer
    DEC A                               ; Reduce number of pointers left to test
    JR NZ,L_0B46                        ; Back to NEXT-PTR if there are more to do

; all pointers updated
    EX DE,HL                            ; HL now contains the end of the space to add + overheads
    POP DE                              ; DE contains the location of the new space
    POP AF
    AND A
    SBC HL,DE                           ; HL now contains the number of bytes required
    LD B,H                              ; BC=HL
    LD C,L
    INC BC                              ; +1
    ADD HL,DE                           ; Add back
    EX DE,HL                            ; Finally DE=End of space, HL=Start of space, BC=Size of space
    RET

; -----------------------------
; THE 'LINE ADDRESS' SUBROUTINE
; -----------------------------

; LINE-ADDR
SUB_0B6A:
    PUSH HL
    LD HL,($400C)                       ; PRGRM, start of user program
    LD D,H
    LD E,L

; NEXT-TEST
L_0B70:
    POP BC
    CALL SUB_0B7C
    RET NC
    PUSH BC
    CALL SUB_0B84
    EX DE,HL
    JR L_0B70

; -------------------------------------
; THE 'COMPARE LINE NUMBERS' SUBROUTINE
; -------------------------------------

; CP-LINES
SUB_0B7C:
    LD A,(HL)
    CP B
    RET NZ
    INC HL
    LD A,(HL)
    DEC HL
    CP C
    RET

; --------------------------------------
; THE 'NEXT LINE OR VARIABLE' SUBROUTINE
; --------------------------------------

; NEXT-ONE
SUB_0B84:
    PUSH HL
    LD A,(HL)
    CP $40
    JR C,L_0BA1
    BIT 5,A
    JR Z,L_0BA2
    ADD A,A
    JP M,L_0B93
    CCF

; NEXT+FIVE
L_0B93:
    LD BC,$0005
    JR NC,L_0B9A
    LD C,$11

; NEXT-LETT
L_0B9A:
    RLA
    INC HL
    LD A,(HL)
    JR NC,L_0B9A
    JR L_0BA7

; LINES
L_0BA1:
    INC HL

; NEXT-O-4
L_0BA2:
    INC HL
    LD C,(HL)
    INC HL
    LD B,(HL)
    INC HL

; NEXT-ADD
L_0BA7:
    ADD HL,BC
    POP DE

; ---------------------------
; THE 'DIFFERENCE' SUBROUTINE
; ---------------------------

; DIFFER
SUB_0BA9:
    AND A
    SBC HL,DE
    LD B,H
    LD C,L
    ADD HL,DE
    EX DE,HL
    RET

; -------------------------------
; THE 'SCROLL COMMAND' SUBROUTINE
; -------------------------------

; scrolling is easy with a fully expanded DFILE
; copy lines 2-24 to 1-23

; SCROLL
SUB_0BB1:
    LD HL,DFILE+$22                     ; Source, start of line 2
    LD DE,DFILE+1                       ; Destination, start of line 1
    LD BC,$02F6                         ; 23*33-1, 23 lines to copy
    LDIR                                ; Copy
    LD B,(IY+$22)                       ; Get DF.SZ - Size of editor part of screen
    INC B                               ; Increase by 1 row
    JR L_0BD2                           ; Routine B-LINES, clear the editor lines

; --------------------------
; THE 'LINE-ENDS' SUBROUTINE
; --------------------------

; LINE-ENDS
SUB_0BC2:
    LD B,(IY+$22)
    PUSH BC
    CALL L_0BD2
    POP BC
    DEC B
    LD C,$21
    JP SUB_0AB7                         ; Routine LOC-ADDR

; -------------------------
; THE 'CLS' COMMAND ROUTINE
; -------------------------

; Different as there is no collapsed display file

; CLS
SUB_0BD0:
    LD B,$18                            ; 24 lines

; B-LINES
L_0BD2:
    RES 1,(IY+$01)                      ; Clear FLAG - printer not in use
    LD (IY+$7C),$00                     ; Clear address of blinking curosr
    SET 0,(IY+$01)                      ; Set FLAG  - Suppress leading space
    LD C,$21
    PUSH BC
    CALL SUB_0AB7                       ; Routine LOC-ADDR
    POP BC
    LD C,B

; CLEAR-SCREEN
    XOR A                               ; A = 0 = SPACE
L_0BE7:
    LD B,$20                            ; 32 characters
L_0BE9:
    LD (HL),A                           ; Clear character
    INC HL
    DJNZ L_0BE9                         ; Loop until EOL
    INC HL                              ; Skip over NEWLINE
    DEC C                               ; Line counter
    JR NZ,L_0BE7                        ; Loop back until complete
    RET

; ----------------------------
; THE 'RECLAIMING' SUBROUTINES
; ----------------------------

; RECLAIM-1
SUB_0BF2:
    CALL SUB_0BA9

; RECLAIM-2
SUB_0BF5:
    PUSH BC
    LD A,B
    CPL
    LD B,A
    LD A,C
    CPL
    LD C,A
    INC BC
    CALL SUB_0B3F
    EX DE,HL
    POP HL
    ADD HL,DE
    PUSH DE
    LDIR
    POP HL
    RET

; ------------------------------
; THE 'E-LINE NUMBER' SUBROUTINE
; ------------------------------

; E-LINE-NO
SUB_0C08:
    LD HL,($4014)
    CALL SUB_004E
    RST 18H
;SUB_0C0F:
    BIT 5,(IY+$2D)
    RET NZ
    LD HL,$405D
    LD ($401C),HL
    CALL SUB_1740
    CALL SUB_1782
    JR C,L_0C26
    LD HL,$D8F0
    ADD HL,BC

; NO-NUMBER
L_0C26:
    JP C,L_0F17                         ; To REPORT-C - Invalid Expression
    CP A
    JP L_16B4

; -------------------------------------------------
; THE 'REPORT AND LINE NUMBER' PRINTING SUBROUTINES
; -------------------------------------------------

; OUT-NUM
SUB_0C2D:
    PUSH DE
    PUSH HL
                                        ; Missing call to UNITS here
    LD H,B
    LD L,C
    LD E,$FF
    JR L_0C3D

; OUT-NO
SUB_0C35:
    PUSH DE
    LD D,(HL)
    INC HL
    LD E,(HL)
    PUSH HL
    EX DE,HL
    LD E,$00

; THOUSAND
L_0C3D:
    LD BC,$FC18
    CALL SUB_0982
    LD BC,$FF9C
    CALL SUB_0982
    LD C,$F6
    CALL SUB_0982
    LD A,L

; UNITS
    CALL SUB_098C
    POP HL
    POP DE
    RET

; --------------------------
; THE 'UNSTACK-Z' SUBROUTINE
; --------------------------

; UNSTACK-Z
SUB_0C55:
    CALL SUB_0F23
    POP HL
    RET Z
    JP (HL)

; ----------------------------
; THE 'LPRINT' COMMAND ROUTINE
; ----------------------------

; LPRINT
SUB_0C5B:
    SET 1,(IY+$01)

; ---------------------------
; THE 'PRINT' COMMAND ROUTINE
; ---------------------------

; PRINT
SUB_0C5F:
    LD A,(HL)
    CP $76
    JP Z,L_0D0B

; PRINT-1
L_0C65:
    SUB $1A
    ADC A,$00
    JR Z,L_0CD1
    CP $BA
    JR NZ,L_0C8A
    RST 20H
    CALL SUB_0F0F
    CP $1A
    JP NZ,L_0F17                        ; To REPORT-C - Invalid Expression
    RST 20H
    CALL SUB_0F0F
    CALL SUB_0CDB
    RST 28H                             ; FP-CALC
    .BYTE $01                           ; Exchange
    .BYTE $34                           ; End-calc
    CALL SUB_0D7A
    CALL SUB_0A94
    JR L_0CC4

; NOT-AT
L_0C8A:
    CP $BB                              ; Different token on ZX81
    JR NZ,L_0CBE
    RST 20H
    CALL SUB_0F0F
    CALL SUB_0CDB
    CALL SUB_1083
    AND $1F
    LD C,A
    BIT 1,(IY+$01)
    JR Z,L_0CAB
    SUB (IY+$38)
    SET 7,A
    ADD A,$3C
    CALL NC,SUB_0A11

; TAB-TEST
L_0CAB:
    ADD A,(IY+$39)
    CP $21
    LD A,($403A)
    SBC A,$01
    CALL SUB_0A99
    SET 0,(IY+$01)
    JR L_0CC4

; NOT-TAB
L_0CBE:
    CALL SUB_114A                       ; Routine SCANNING
    CALL SUB_0CE2

; PRINT-ON
L_0CC4:
    RST 18H
    SUB $1A
    ADC A,$00
    JR Z,L_0CD1
    CALL SUB_0E9A                       ; Routine CHECK-END
    JP L_0D0B

; SPACING
L_0CD1:
    CALL NC,SUB_0D12
    RST 20H
    CP $76
    RET Z
    JP L_0C65

; SYNTAX-ON
SUB_0CDB:
    CALL SUB_0F23
    RET NZ
    POP HL
    JR L_0CC4

; PRINT-STK
SUB_0CE2:
    CALL SUB_0C55
    BIT 6,(IY+$01)                      ; Check FLAGS - 0 = string or 1 = numeric result
    CALL Z,SUB_15ED                     ; Routine STK-FETCH
    JR Z,L_0CF6
    JP L_17D3

; PR-STR-1
; missing ?

; PR-STR-2
L_0CF1:
    RST 10H

; PR-STR-3
L_0CF2:
    LD DE,($4018)

; PR-STR-4
L_0CF6:
    LD A,B
    OR C
    DEC BC
    RET Z
    LD A,(DE)
    INC DE
    LD ($4018),DE
    BIT 6,A
    JR Z,L_0CF1
    PUSH BC
    CALL SUB_0AD7
    POP BC
    JR L_0CF2

; PRINT-END
L_0D0B:
    CALL SUB_0C55
    LD A,$76
    RST 10H
    RET

; FIELD
SUB_0D12:
    CALL SUB_0C55
    SET 0,(IY+$01)
    XOR A
    RST 10H
    LD BC,($4039)
    LD A,C
    BIT 1,(IY+$01)
    JR Z,L_0D2B
    LD A,$5D
    SUB (IY+$38)

; CENTRE
L_0D2B:
    LD C,$11
    CP C
    JR NC,L_0D32
    LD C,$01

; RIGHT
L_0D32:
    CALL SUB_0AAA
    RET

; --------------------------------------
; THE 'PLOT AND UNPLOT' COMMAND ROUTINES
; --------------------------------------

; PLOT/UNP
SUB_0D36:
    CALL SUB_0D7A
    LD ($4036),BC
    LD A,$2B
    SUB B
    JP C,L_108E
    LD B,A
    LD A,$01
    SRA B
    JR NC,L_0D4C
    LD A,$04

; COLUMNS
L_0D4C:
    SRA C
    JR NC,L_0D51
    RLCA

; FIND-ADDR
L_0D51:
    PUSH AF
    CALL SUB_0A94
    LD A,(HL)
    RLCA
    CP $10
    JR NC,L_0D61
    RRCA
    JR NC,L_0D60
    XOR $8F

; SQ-SAVED
L_0D60:
    LD B,A

; TABLE-PTR
L_0D61:
    LD DE,L_0E12                        ; Address: P-UNPLOT
    LD A,($4030)
    SUB E
    JP M,L_0D70
    POP AF
    CPL
    AND B
    JR L_0D72

; PLOT
L_0D70:
    POP AF
    OR B

; UNPLOT
L_0D72:
    CP $08
    JR C,L_0D78
    XOR $8F

; PLOT-END
L_0D78:
                                        ; Missing EXX before and after RST 10H
    RST 10H
                                        ;
    RET

; ----------------------------
; THE 'STACK-TO-BC' SUBROUTINE
; ----------------------------

; STK-TO-BC
SUB_0D7A:
    CALL SUB_1083
    LD B,A
    PUSH BC
    CALL SUB_1083
    POP BC                              ; Missing setting E and D to previous values of C
    LD C,A
    RET

; -------------------
; THE 'SYNTAX' TABLES
; -------------------

; i) The Offset table

; offset-t
L_0D85:
    .BYTE L_0DA9 - $                    ; Offset of $24 for TEMPO
    .BYTE L_0DAD - $                    ; Offset of $27 for MUSIC
    .BYTE L_0DB0 - $                    ; Offset of $29 for SOUND
    .BYTE L_0DB6 - $                    ; Offset of $2E for BEEP
    .BYTE L_0DB9 - $                    ; Offset of $30 for NOBEEP
    .BYTE L_0E28 - $                    ; Offset of $9E for LPRINT
    .BYTE L_0E2B - $                    ; Offset of $A0 for LLIST
    .BYTE L_0DCC - $                    ; Offset of $40 for STOP
    .BYTE L_0E1F - $                    ; Offset of $92 for SLOW
    .BYTE L_0E22 - $                    ; Offset of $94 for FAST
    .BYTE L_0DEB - $                    ; Offset of $5C for NEW
    .BYTE L_0E18 - $                    ; Offset of $88 for SCROLL
    .BYTE L_0E03 - $                    ; Offset of $72 for CONT
    .BYTE L_0DE5 - $                    ; Offset of $53 for DIM
    .BYTE L_0DE8 - $                    ; Offset of $55 for REM
    .BYTE L_0DD2 - $                    ; Offset of $3E for FOR
    .BYTE L_0DBF - $                    ; Offset of $2A for GOTO
    .BYTE L_0DC8 - $                    ; Offset of $32 for GOSUB
    .BYTE L_0DE1 - $                    ; Offset of $4A for INPUT
    .BYTE L_0DFD - $                    ; Offset of $65 for LOAD
    .BYTE L_0DF1 - $                    ; Offset of $58 for LIST
    .BYTE L_0DBC - $                    ; Offset of $22 for LET
    .BYTE L_0E1B - $                    ; Offset of $80 for PAUSE
    .BYTE L_0DDA - $                    ; Offset of $3E for NEXT
    .BYTE L_0DF4 - $                    ; Offset of $57 for POKE
    .BYTE L_0DDE - $                    ; Offset of $40 for PRINT
    .BYTE L_0E0C - $                    ; Offset of $6D for PLOT
    .BYTE L_0DEE - $                    ; Offset of $4E for RUN
    .BYTE L_0E00 - $                    ; Offset of $5F for SAVE
    .BYTE L_0DFA - $                    ; Offset of $58 for RAND
    .BYTE L_0DC3 - $                    ; Offset of $20 for IF
    .BYTE L_0E09 - $                    ; Offset of $65 for CLS
    .BYTE L_0E12 - $                    ; Offset of $6D for UNPLOT
    .BYTE L_0E06 - $                    ; Offset of $60 for CLEAR
    .BYTE L_0DCF - $                    ; Offset of $28 for RETURN
    .BYTE L_0E25 - $                    ; Offset of $7D for COPY

; P-TEMPO
L_0DA9:
    .BYTE $06                           ; Class-06 - A numeric expression must follow.
    .BYTE $00                           ; Class-00 - No further operands.
    .WORD SUB_105C                      ; TEMPO

; P-MUSIC
L_0DAD:
    .BYTE $05                           ; Class-05 - Variable syntax checked entirely by routine.
    .WORD SUB_0F4D                      ; MUSIC

; P-SOUND
L_0DB0:
    .BYTE $06                           ; Class-06 - A numeric expression must follow.
    .BYTE $1A                           ; Separator:  ','
    .BYTE $06                           ; Class-06 - A numeric expression must follow.
    .BYTE $00                           ; Class-00 - No further operands.
    .WORD SUB_0457                      ; SOUND

L_0DB6:
; P-BEEP
    .BYTE $00                           ; Class-00 - No further operands.
    .WORD SUB_1131                      ; BEEP

; P-NOBEEP
L_0DB9:
    .BYTE $00                           ; Class-00 - No further operands.
    .WORD SUB_1136                      ; NOBEEP

; P-LET
L_0DBC:
    .BYTE $01                           ; Class-01 - A variable is required.
    .BYTE $14                           ; Separator:  '='
    .BYTE $02                           ; Class-02 - An expression, numeric or string, must follow.
                                        ; No function to call
; P-GOTO
L_0DBF:
    .BYTE $06                           ; Class-06 - A numeric expression must follow.
    .BYTE $00                           ; Class-00 - No further operands.
    .WORD SUB_1068                      ; GOTO

; P-IF
L_0DC3:
    .BYTE $06                           ; CLASS-06 - A NUMERIC EXPRESSION MUST FOLLOW.                                                                   ;
    .BYTE $40                           ; Separator:  'THEN' ($DE on ZX81)
    .BYTE $05                           ; Class-05 - Variable syntax checked entirely by routine.
    .WORD SUB_0E2E                      ; IF

; P-GOSUB
L_0DC8:
    .BYTE $06                           ; Class-06 - A numeric expression must follow.
    .BYTE $00                           ; Class-00 - No further operands.
    .WORD SUB_1090                      ; GOSUB

; P-STOP
L_0DCC:
    .BYTE $00                           ; CLASS-00 - NO FURTHER OPERANDS.                                                         ;
    .WORD SUB_0E91                      ; STOP

; P-RETURN
L_0DCF:
    .BYTE $00                           ; Class-00 - No further operands.
    .WORD SUB_10B3                      ; RETURN

; P-FOR
L_0DD2:
    .BYTE $04                           ; Class-04 - A single character variable must follow.
    .BYTE $14                           ; Separator:  '='
    .BYTE $06                           ; Class-06 - A numeric expression must follow.
    .BYTE $41                           ; Separator:  'TO' (was $DF on ZX81)
    .BYTE $06                           ; Class-06 - A numeric expression must follow.
    .BYTE $05                           ; Class-05 - Variable syntax checked entirely by routine.
    .WORD SUB_0FC9                      ; FOR

; P-NEXT
L_0DDA:
    .BYTE $04                           ; Class-04 - A single character variable must follow.
    .BYTE $00                           ; Class-00 - No further operands.
    .WORD SUB_100E                      ; NEXT

; P-PRINT
L_0DDE:
    .BYTE $05                           ; Class-05 - Variable syntax checked entirely by routine.
    .WORD SUB_0C5F                      ; PRINT

; P-INPUT
L_0DE1:
    .BYTE $01                           ; Class-01 - A variable is required.
    .BYTE $00                           ; Class-00 - No further operands.
    .WORD SUB_10C4                      ; INPUT

; P-DIM
L_0DE5:
    .BYTE $05                           ; Class-05 - Variable syntax checked entirely by routine.
    .WORD SUB_15FE                      ;

; P-REM
L_0DE8:
    .BYTE $05                           ; Class-05 - Variable syntax checked entirely by routine.
    .WORD SUB_0EE7                      ; REM

; P-NEW
L_0DEB:
    .BYTE $00                           ; Class-00 - No further operands.
    .WORD SUB_0481                      ; NEW

; P-RUN
L_0DEE:
    .BYTE $03                           ; Class-03 - A numeric expression may follow else default to zero.
    .WORD SUB_168F                      ; RUN

; P-LIST
L_0DF1:
    .BYTE $03                           ; Class-03 - A numeric expression may follow else default to zero.
    .WORD SUB_08BF                      ; LIST

; P-POKE
L_0DF4:
    .BYTE $06                           ; Class-06 - A numeric expression must follow.
    .BYTE $1A                           ; Separator:  ','
    .BYTE $06                           ; Class-06 - A numeric expression must follow.
    .BYTE $00                           ; Class-00 - No further operands.
    .WORD SUB_1079                      ; POKE

; P-RAND
L_0DFA:
    .BYTE $03                           ; Class-03 - A numeric expression may follow else default to zero.
    .WORD SUB_104C                      ; RAND

; P-LOAD
L_0DFD:
    .BYTE $05                           ; Class-05 - Variable syntax checked entirely by routine.
    .WORD SUB_03CD                      ; LOAD

; P-SAVE
L_0E00:
    .BYTE $05                           ; Class-05 - Variable syntax checked entirely by routine.
    .WORD SUB_037F                      ; SAVE

; P-CONT
L_0E03:
    .BYTE $00                           ; Class-00 - No further operands.
    .WORD SUB_1063                      ; CONT

; P-CLEAR
L_0E06:
    .BYTE $00                           ; Class-00 - No further operands.
    .WORD SUB_1692                      ; CLEAR

; P-CLS
L_0E09:
    .BYTE $00                           ; Class-00 - No further operands.
    .WORD SUB_0BD0                      ; CLS

; P-PLOT
L_0E0C:
    .BYTE $06                           ; Class-06 - A numeric expression must follow.
    .BYTE $1A                           ; Separator:  ','
    .BYTE $06                           ; Class-06 - A numeric expression must follow.
    .BYTE $00                           ; Class-00 - No further operands.
    .WORD SUB_0D36                      ; PLOT/UNPLOT

; P-UNPLOT
L_0E12:
    .BYTE $06                           ; Class-06 - A numeric expression must follow.
    .BYTE $1A                           ; Separator:  ','
    .BYTE $06                           ; Class-06 - A numeric expression must follow.
    .BYTE $00                           ; Class-00 - No further operands.
    .WORD SUB_0D36                      ; PLOT/UNPLOT

; P-SCROLL
L_0E18:
    .BYTE $00                           ; Class-00 - No further operands.
    .WORD SUB_0BB1                      ; SCROLL

; P-PAUSE
L_0E1B:
    .BYTE $06                           ; Class-06 - A numeric expression must follow.
    .BYTE $00                           ; Class-00 - No further operands.
    .WORD SUB_10FE                      ; PAUSE

; P-SLOW
L_0E1F:
    .BYTE $00                           ; Class-00 - No further operands.
    .WORD SUB_0281                      ; SLOW

; P-FAST
L_0E22:
    .BYTE $00                           ; Class-00 - No further operands.
    .WORD SUB_036C                      ; FAST

; P-COPY
L_0E25:
    .BYTE $00                           ; Class-00 - No further operands.
    .WORD SUB_0101                      ; COPY

; P-LPRINT
L_0E28:
    .BYTE $05                           ; Class-05 - Variable syntax checked entirely by routine.
    .WORD SUB_0C5B                      ; LPRINT

; P-LLIST
L_0E2B:
    .BYTE $03                           ; Class-03 - A numeric expression may follow else default to zero.
    .WORD SUB_08BB                      ; LLIST

; ------------------------
; THE 'IF' COMMAND ROUTINE
; ------------------------

; IF
SUB_0E2E
    CALL SUB_0F23
    JR Z,L_0E39
    RST 28H                             ; FP-CALC
    .BYTE $02                           ; Delete
    .BYTE $34                           ; End-calc
    LD A,(DE)
    AND A
    RET Z

; IF-END
L_0E39:
    JR L_0E53

; ---------------------------
; THE 'LINE SCANNING' ROUTINE
; ---------------------------

; LINE-SCAN
SUB_0E3B:
    LD (IY+$01),$01
    CALL SUB_0C08

; LINE-RUN    
SUB_0E42:
    CALL L_16B4
    LD HL,$4000
    LD (HL),$FF
    LD HL,$402D
    BIT 5,(HL)
    LD A,(HL)
    JP NZ,L_0EEC

; LINE-NULL    
L_0E53:
    RST 18H                             ; GET-CHAR
    LD B,$00
    CP $76
    RET Z
    LD C,A
    CP $40                              ; Different to ZX81
    LD A,$F1                            ;
    JR C,L_0E62                         ;

    RST 20H                             ; NEXT-CHAR advances
    LD A,C
L_0E62:
    SUB $DC                             ; Subtract lower command (Was $E1, LPRINT in ZX81)
    JR C,L_0EA3                         ; Different
    LD C,A                              ;
    LD HL,L_0D85                        ;
    ADD HL,BC

    LD C,(HL)
    ADD HL,BC
    JR L_0E72

; SCAN-LOOP    
L_0E6F:
    LD HL,($4030)

; GET-PARAM    
L_0E72:
    LD A,(HL)
    INC HL
    LD ($4030),HL
    LD BC,L_0E6F
    PUSH BC
    LD C,A
    CP $0B
    JR NC,L_0E8B
    LD HL,L_0E93                        ; Command class table             
    LD B,$00
    ADD HL,BC
    LD C,(HL)
    ADD HL,BC
    PUSH HL
    RST 18H
    RET
L_0E8B:
    RST 18H
    CP C
    JR NZ,L_0EA3
    RST 20H                             ; Was RST 18H on ZX81
    RET

; --------------------------
; THE 'STOP' COMMAND ROUTINE
; --------------------------

; STOP
SUB_0E91:
    RST 08H                             ; ERROR-1
    .BYTE $08                           ; ST - STopped

; -------------------------
; THE 'COMMAND CLASS' TABLE
; -------------------------

; class-tbl
L_0E93:
    .BYTE SUB_0EAA - $                  ; Offset of $17 to CLASS-0
    .BYTE SUB_0EB9 - $                  ; Offset of $25 to CLASS-1
    .BYTE SUB_0EE8 - $                  ; Offset of $53 to CLASS-2
    .BYTE SUB_0EA5 - $                  ; Offset of $0F to CLASS-3
    .BYTE SUB_0F02 - $                  ; Offset of $6B to CLASS-4
    .BYTE SUB_0EAB - $                  ; Offset of $13 to CLASS-5
    .BYTE SUB_0F0F - $                  ; Offset of $76 to CLASS-6

; --------------------------
; THE 'CHECK END' SUBROUTINE
; --------------------------

; CHECK-END
SUB_0E9A:
    CALL SUB_0F23
    RET NZ
    POP BC

; CHECK-2
L_0E9F:
    LD A,(HL)
    CP $76
    RET Z

; REPORT-C2
L_0EA3:
    JR L_0F17                           ; To REPORT-C - Invalid Expression

; --------------------------
; COMMAND CLASSES 03, 00, 05
; --------------------------

; CLASS-3
SUB_0EA5:
    CP $76
    CALL SUB_0F19

; CLASS-0
SUB_0EAA:
    CP A

; CLASS-5
SUB_0EAB:
    POP BC
    CALL Z,SUB_0E9A                     ; Routine CHECK-END
    EX DE,HL
    LD HL,($4030)
    LD C,(HL)
    INC HL
    LD B,(HL)
    EX DE,HL

; CLASS-END
L_0EB7:
    PUSH BC
    RET

; ------------------------------
; COMMAND CLASSES 01, 02, 04, 06
; ------------------------------

; CLASS-1
SUB_0EB9:
    CALL $1311

; CLASS-4-2
L_0EBC:
    LD (IY+$2D),$00
    JR NC,$+10
    SET 1,(IY+$2D)
    JR NZ,L_0EE0


; REPORT-2
L_0EC8:
    RST 08H                             ; ERROR-1
    .BYTE $01                           ; UV - Unidentified Variable

; SET-STK
    CALL Z,SUB_139C
    BIT 6,(IY+$01)                      ; Check FLAGS - 0 = string or 1 = numeric result
    JR NZ,L_0EE0
    XOR A
    CALL SUB_0F23
    CALL NZ,SUB_15ED                    ; Routine STK-FETCH
    LD HL,$402D
    OR (HL)
    LD (HL),A
    EX DE,HL

; SET-STRLN
L_0EE0:
    LD ($402E),BC
    LD ($4012),HL
                                        ; Drops through

; THE 'REM' COMMAND ROUTINE

; REM
SUB_0EE7:
    RET

; CLASS-2
SUB_0EE8:
    POP BC
    LD A,($4001)

; INPUT-REP
L_0EEC:
    PUSH AF
    CALL SUB_114A                       ; Routine SCANNING
    POP AF
    LD BC,L_1516
    LD D,(IY+$01)
    XOR D
    AND $40
    JR NZ,L_0F17                        ; To REPORT-C - Invalid Expression
    BIT 7,D
    JR NZ,L_0EB7
    JR L_0E9F

; CLASS-4
SUB_0F02:
    CALL $1311
    PUSH AF
    LD A,C
    OR $9F
    INC A
    JR NZ,L_0F17                        ; To REPORT-C - Invalid Expression
    POP AF
    JR L_0EBC

; CLASS-6
SUB_0F0F:
    CALL SUB_114A                       ; Routine SCANNING
    BIT 6,(IY+$01)                      ; Check FLAGS - 0 = string or 1 = numeric result
    RET NZ

; REPORT-C
L_0F17:
    RST 08H                             ; ERROR-1
    .BYTE $0B                           ; IE - Invalid Expression

; --------------------------------
; THE 'NUMBER TO STACK' SUBROUTINE
; --------------------------------

; NO-TO-STK
SUB_0F19:
    JR NZ,SUB_0F0F
    CALL SUB_0F23
    RET Z
    RST 28H                             ; FP-CALC
    .BYTE $A0                           ; Stk-zero
    .BYTE $34                           ; End-calc
    RET

; -------------------------
; THE 'SYNTAX-Z' SUBROUTINE
; -------------------------

; SYNTAX-Z
SUB_0F23:
    BIT 7,(IY+$01)
    RET

; ---------------------
; MORE 'MUSIC' ROUTINES
; ---------------------

; MUSIC-TABLE
L_0F28:
    .BYTE $94                           ; A
    .BYTE $8B                           ; A#
    .BYTE $84                           ; B
    .BYTE $7C                           ; B#
    .BYTE $F8                           ; C
    .BYTE $EB                           ; C#
    .BYTE $DD                           ; D
    .BYTE $D1                           ; D#
    .BYTE $C5                           ; E
    .BYTE $BA                           ; (=F)
    .BYTE $BA                           ; F
    .BYTE $B0                           ; F#
    .BYTE $A6                           ; G
    .BYTE $9D                           ; G#

; MUSIC-9
SUB_0F36:
    CP $26
    RET NC
    SUB $1C
    CCF
    RET

; MUSIC-10
L_0F3D:
    LD A,B
    OR C
    RET Z                               ; Return if A and B are 0
    LD A,(HL)                           ; Get character
    INC HL                              ; Step pointer
    DEC BC                              ; Decrement length
    AND A                               ; Check character
    RET NZ                              ; Return if not a space
    JR L_0F3D                           ; To MUSIC-10

; MUSIC-11
SUB_0F47:
    CALL L_0F3D                         ; To MUSIC-10
    RET NZ

; REPORT-MF
L_0F4B:
    RST 08H                             ; ERROR-1
    .BYTE $0E                           ; MF - Music Format incorrect

; ---------------------------
; THE 'MUSIC' COMMAND ROUTINE
; ---------------------------

; MUSIC
SUB_0F4D:
    CALL SUB_114A                       ; Routine SCANNING
    BIT 6,(IY+$01)                      ; Check FLAGS - 0 = string or 1 = numeric result
    JR NZ,L_0F17                        ; To REPORT-C - Invalid Expression
    CALL SUB_0E9A                       ; Routine CHECK-END
    CALL SUB_15ED                       ; Routine STK-FETCH
    EX DE,HL                            ; DE now start address, HL string length
    CALL SUB_0370                       ; Routine SET-FAST

; MUSIC-1
L_0F60:
    CALL L_0F3D                         ; Routine MUSIC-10 (get next character)
    JP Z,SUB_0285                       ; Check in FAST mode
    CP $1B                              ; Is character '"'
    LD E,$01
    JR Z,L_0F8E                         ; To MUSIC-2 if it is
    RLCA                                ; Character x2
    CP $5A                              ; Before the rotate, A would have been $2D, 'H', so checking A-G
    JR NC,L_0F4B                        ; To REPORT, Music Format incorrect
    SUB $4C
    JR C,L_0F4B                         ; To REPORT, Music Format incorrect

; get note
    PUSH HL
    LD D,$00
    LD E,A
    LD HL,L_0F28                        ; Address of MUSIC-TABLE
    ADD HL,DE                           ; Offset by 2x letter - 4C
    LD E,(HL)                           ; Get note
    POP HL

    CALL SUB_0F47                       ; Routine MUSIC-11
    CP $13                              ; Is character '<'
    JR Z,L_0F8E                         ; To MUSIC-2 if it is
    SRL E                               ; Down an octave
    CP $12                              ; Is character '>'
    JR NZ,L_0F91                        ; To MUSIC-3 if it isn't
    SRL E                               ; Down an octave

; MUSIC-2
L_0F8E:
    CALL SUB_0F47                       ; Routine MUSIC-11

; MUSIC-3 - get duration
L_0F91:
    CALL SUB_0F36                       ; Routine MUSIC-9
    JR NC,L_0F4B                        ; To REPORT, Music Format incorrect
    LD D,A
    CALL L_0F3D                         ; Routine MUSIC-10
    JR Z,L_0FAE                         ; To MUSIC-5
    CALL SUB_0F36                       ; Routine MUSIC-9
    JR C,L_0FA5
    DEC HL
    INC BC
    JR L_0FAE                           ; To MUSIC-5

; MUSIC-4
L_0FA5:
    SLA D
    ADD A,D
    SLA D
    SLA D
    ADD A,D
    LD D,A

; MUSIC-5 - play note
L_0FAE:
    PUSH HL
    PUSH BC
    LD H,D                              ; Prepare note
    LD L,(IY+$21)                       ; TEMPO
    LD C,$00
    LD D,E

; MUSIC-6
L_0FB7:
    LD B,L
; by this point E = note (adjusted from table), BC = duration (from TEMPO)
    CALL L_0463                         ; Routine PLAY-NOTE-2
    DEC H
    JR NZ,L_0FB7                        ; Loop back to MUSIC-6
    LD B,$05

; MUSIC-7
L_0FC0:
    DEC BC
    LD A,B
    OR C
    JR NZ,L_0FC0                        ; Loop until BC = 0
    POP BC
    POP HL
    JR L_0F60                           ; Back to MUSIC-1


; -------------------------
; THE 'FOR' COMMAND ROUTINE
; -------------------------

; FOR
SUB_0FC9:
    CP $42                              ; STEP ($E0 on ZX81)
    JR NZ,L_0FD6
    RST 20H
    CALL SUB_0F0F
    CALL SUB_0E9A                       ; Routine CHECK-END
    JR L_0FDC

; F-USE-ONE
L_0FD6:
    CALL SUB_0E9A                       ; Routine CHECK-END
    RST 28H                             ; FP-CALC
    .BYTE $A1                           ; Stk-one
    .BYTE $34                           ; End-calc

; F-REORDER
L_0FDC:
    RST 28H                             ; FP-CALC      v, l, s.
    .BYTE $C0                           ; St-mem-0      v, l, s.
    .BYTE $02                           ; Delete        v, l.
    .BYTE $01                           ; Exchange      l, v.
    .BYTE $E0                           ; Get-mem-0     l, v, s.
    .BYTE $01                           ; Exchange      l, s, v.
    .BYTE $34                           ; End-calc      l, s, v.
    CALL L_1516
    LD ($401F),HL
    DEC HL
    LD A,(HL)
    SET 7,(HL)
    LD BC,$0006
    ADD HL,BC
    RLCA
    JR C,L_0FFA
    SLA C
    CALL SUB_0B30                       ; MAKE-ROOM
    INC HL

; F-LMT-STP
L_0FFA:
    PUSH HL
    RST 28H                             ; FP-CALC
    .BYTE $02                           ; Delete
    .BYTE $02                           ; Delete
    .BYTE $34                           ; End-calc
    POP HL
    EX DE,HL
    LD C,$0A
    LDIR
    LD HL,($4007)
    EX DE,HL
    INC DE
    LD (HL),E
    INC HL
    LD (HL),D
    RET                                 ; Skips call to NEXT-LOOP

; --------------------------
; THE 'NEXT' COMMAND ROUTINE
; --------------------------

; NEXT
SUB_100E:
    BIT 1,(IY+$2D)
    JP NZ,L_0EC8
    LD HL,($4012)
    BIT 7,(HL)
    JR Z,L_1038
    INC HL
    LD ($401F),HL
    RST 28H                             ; FP-CALC
    .BYTE $E0                           ; Get-mem-0
    .BYTE $E2                           ; Get-mem-2
    .BYTE $0F                           ; Addition
    .BYTE $C0                           ; St-mem-0
    .BYTE $02                           ; Delete
    .BYTE $34                           ; End-calc
    CALL SUB_103A
    RET C
    LD HL,($401F)
    LD DE,$000F
    ADD HL,DE
    LD E,(HL)
    INC HL
    LD D,(HL)
    EX DE,HL
    JR L_106D

; REPORT-1
L_1038:
    RST 08H                             ; ERROR-1
    .BYTE $00                           ; NF - Next without For

; --------------------------
; THE 'NEXT-LOOP' SUBROUTINE
; --------------------------

; NEXT-LOOP
SUB_103A:
    RST 28H                             ; FP-CALC
    .BYTE $E1                           ; Get-mem-1
    .BYTE $E0                           ; Get-mem-0
    .BYTE $E2                           ; Get-mem-2
    .BYTE $32                           ; Less-0
    .BYTE $00                           ; Jump-true
    .BYTE $02                           ; To LMT-V-VAL
    .BYTE $01                           ; Exchange
; LMT-V-VAL
    .BYTE $03                           ; Subtract
    .BYTE $33                           ; Greater-0
    .BYTE $00                           ; Jump-true
    .BYTE $04                           ; To L0E69, IMPOSS
    .BYTE $34                           ; End-calc

    AND A
    RET

; ?
    INC (HL)
    SCF
    RET

; --------------------------
; THE 'RAND' COMMAND ROUTINE
; --------------------------

; RAND
SUB_104C:
    CALL SUB_1088
    LD A,B
    OR C
    JR NZ,L_1057
    LD BC,($4034)                       ; If 0, use FRAMES value

; SET-SEED
L_1057:
    LD ($4032),BC                       ; Store SEED
    RET


; ---------------------------
; THE 'TEMPO' COMMAND ROUTINE
; ---------------------------

; TEMPO
SUB_105C:
    CALL SUB_1083
    LD ($4021),A
    RET

; --------------------------
; THE 'CONT' COMMAND ROUTINE
; --------------------------

; CONT
SUB_1063:
    LD HL,($402B)
    JR L_106D

; --------------------------
; THE 'GOTO' COMMAND ROUTINE
; --------------------------

; GOTO
SUB_1068:
    CALL SUB_1088
    LD H,B
    LD L,C

; GOTO-2
L_106D:
    LD A,H
    CP $28
    JR NC,L_108E
    CALL SUB_0B6A
    LD ($400A),HL                       ; NXTLIN - Address of next line to be executed (ZX81 was $4029)
    RET

; --------------------------
; THE 'POKE' COMMAND ROUTINE
; --------------------------
; POKE
SUB_1079
    CALL SUB_1083
                                        ; Missing negative checks
    PUSH AF
    CALL SUB_1088
    POP AF
                                        ; Missing code that was in the ZX81 ROM, left over from the ZX80 and not requried
    LD (BC),A
    RET

; FIND-SHORT
SUB_1083:
    CALL SUB_17C5                       ; Routine FP-TO-A
    JR L_108B

; -----------------------------
; THE 'FIND INTEGER' SUBROUTINE
; -----------------------------

; FIND-INT
SUB_1088:
    CALL SUB_1782                       ; Routine FP-TO-BC
L_108B:
    JR C,L_108E                         ; Error
    RET Z                               ; Return if valid (0-65535)

; REPORT-B
L_108E:
    RST 08H                             ; ERROR-1
    .BYTE $0A                           ; IR - Integer out of Range

; ---------------------------
; THE 'GOSUB' COMMAND ROUTINE
; ---------------------------

; GOSUB
SUB_1090:
    LD HL,($4007)
    INC HL
    EX (SP),HL
    PUSH HL
    LD ($4002),SP
    CALL SUB_1068
    LD BC,$0006

; --------------------------
; THE 'TEST ROOM' SUBROUTINE
; --------------------------

; TEST-ROOM
SUB_10A0:
    LD HL,($401C)                       ; Get STKEND - End of calculator stack
    ADD HL,BC                           ; Add the number of bytes space needed
    JR C,L_10AE                         ; To REPORT-4
    EX DE,HL                            ; Save HL
    LD HL,$0024                         ; Safety margin past the end of stack?
    ADD HL,DE                           ; Add this margin to the bytes required
    SBC HL,SP                           ; Subtract the she stack pointer from the new total
    RET C                               ; Return with carry set if there is room, if not OM error

; REPORT-4
L_10AE:
    LD L,$03                            ; Raise OM - Out of Memory
    JP L_0059                           ; To ERROR-3

; ----------------------------
; THE 'RETURN' COMMAND ROUTINE
; ----------------------------

; RETURN
SUB_10B3:
    POP HL
    EX (SP),HL
    LD A,H
    CP $3E
    JR Z,L_10C0
    LD ($4002),SP
    JR L_106D

; REPORT-7
L_10C0:
    EX (SP),HL
    PUSH HL
    RST 08H                             ; ERROR-1
    .BYTE $06                           ; RG - RETURN without GOSUB

; ---------------------------
; THE 'INPUT' COMMAND ROUTINE
; ---------------------------

; INPUT
SUB_10C4:
    BIT 7,(IY+$08)
    JR NZ,L_10FC
    CALL SUB_169B
    LD HL,$402D
    SET 5,(HL)
    RES 6,(HL)
    LD A,($4001)
    AND $40
    LD BC,$0002
    JR NZ,L_10E0
    LD C,$04
L_10E0:
    OR (HL)
    LD (HL),A
    RST 30H
    LD (HL),$76
    LD A,C
    RRCA
L_10E7:
    RRCA
    JR C,L_10EF
    LD A,$0B
    LD (DE),A
    DEC HL
    LD (HL),A
L_10EF:
    DEC HL
    LD (HL),$7F
    LD HL,($4039)
    LD ($4030),HL
    POP HL
    JP L_0558                           ; Routine LOWER

L_10FC:
    RST 08H                             ; ERROR-1
    .BYTE $07                           ; II - Illegal Input

; ---------------------------
; THE 'PAUSE' COMMAND ROUTINE
; ---------------------------

; PAUSE
SUB_10FE:
    CALL SUB_1088                       ; Routine FIND-INT => BC
    LD HL,$403B                         ; CDFLAG
    BIT 7,(HL)                          ; Check FAST mode
    JR NZ,L_1116                        ; Skip to PAUSE-3 if slow
    INC BC                              ; Pause value++
    LD ($4034),BC                       ; Store this in the frame counter
    CALL SUB_0293                       ; Routine PRE-DISPLAY-1

; PAUSE-2
L_1110:
    LD (IY+$35),$FF                     ; COORDS - Last point plotted?
    JR SUB_1140                         ; Routine DEBOUNCE

; PAUSE-3
L_1116:
    LD A,B                              ; A = bit 7 of B
    AND $80
    LD D,A                              ; D = old bit 7 of B
    SET 7,B                             ; Set bit 7, indicatin PAUSE mode
    LD ($4034),BC                       ; Alternate value in frame counter

; PAUSE-4
L_1120:
    LD BC,($4034)                       ; Get frame counter
    RES 7,B                             ; Ignore bit 7
    LD A,B                              ; Check if MSB
    OR C                                ; LSB
    OR D                                ; And old bit 7 are all zero (i.e. we have waited long enough)
    JR Z,L_1110                         ; Finished, back to PAUSE-2
    LD A,(HL)                           ; Get CDFLAG
    RRA                                 ; Test bit 7 for fast mode
    JR C,L_1110                         ; Finished, back to PAUSE-2
    JR L_1120                           ; Loop back to PAUSE-4

; ---------------------------------
; THE 'BEEP' AND 'NOBEEP' FUNCTIONS
; ---------------------------------

; These functions use bit 5 of the CDFLAG to control the keyboard sounds
; 0 to make sounds, 1 for silence

; BEEP
SUB_1131:
    RES 5,(IY+$3B)                      ; Clear bit 5 of CDFLAG
    RET

; NOBEEP
SUB_1136:
    SET 5,(IY+$3B)                      ; Set bit 5 of CDFLAG
    RET

; ----------------------
; THE 'BREAK' SUBROUTINE
; ----------------------

; BREAK-1
SUB_113B:
    LD A,$7F
    IN A,($FE)
    RRA

; -------------------------
; THE 'DEBOUNCE' SUBROUTINE
; -------------------------

; DEBOUNCE
SUB_1140:
    RES 0,(IY+$3B)
    LD A,$FF
    LD ($4027),A
    RET

; -------------------------
; THE 'SCANNING' SUBROUTINE
; -------------------------

; SCANNING
SUB_114A:
    RST 18H
    LD B,$00
    PUSH BC

; S-LOOP-1
L_114E:
    CP $43
    JR NZ,L_1181

; ------------------
; THE 'RND' FUNCTION
; ------------------
    CALL SUB_0F23
    JR Z,L_117F
    LD BC,($4032)
    CALL SUB_1718
    RST 28H                             ; FP-CALC
    .BYTE $A1                           ; Stk-one
    .BYTE $0F                           ; Addition
    .BYTE $30                           ; Stk-data
    .BYTE $37                           ; Exponent: $87, Bytes: 1
    .BYTE $16                           ; (+00,+00,+00)
    .BYTE $04                           ; Multiply
    .BYTE $30                           ; Stk-data
    .BYTE $80                           ; Bytes: 3
    .BYTE $41                           ; Exponent $91
    .BYTE $00,$00,$80                   ; (+00)
    .BYTE $2E                           ; N-mod-m
    .BYTE $02                           ; Delete
    .BYTE $A1                           ; Stk-one
    .BYTE $03                           ; Subtract
    .BYTE $2D                           ; Duplicate
    .BYTE $34                           ; End-calc
    CALL SUB_1782
    LD ($4032),BC
    LD A,(HL)
    AND A
    JR Z,L_117F
    SUB $10
    LD (HL),A
L_117F:
    JR L_118E

; S-TEST-PI
L_1181:
    CP $45
    JR NZ,L_1192

; -------------------
; THE 'PI' EVALUATION
; -------------------

    CALL SUB_0F23
    JR Z,L_118E
    RST 28H                             ; FP-CALC
    .BYTE $A3                           ; Stk-pi/2
    .BYTE $34                           ;end-calc
    INC (HL)

; S-PI-END
L_118E:
    RST 20H
    JP L_1278


; not S-TST-INK
L_1192:
    CP $44
    JR NZ,L_11A7
    CALL SUB_033D
    LD B,H
L_119A:
    LD C,L
    LD D,C
    INC D
    CALL NZ,SUB_095E                    ; Routine DECODE
    LD A,D
    ADC A,D
    LD B,D
    LD C,A
    EX DE,HL
    JR L_11E2

; S-ALPHANUM
L_11A7:
    CALL SUB_16CA
    JR C,L_121A
    CP $1B
    JP Z,L_123C
    LD BC,$09D8
    CP $16
    JR Z,L_1215
    CP $10
    JR NZ,L_11CB
    CALL SUB_004A
    CALL SUB_114A                       ; Routine SCANNING
    CP $11
    JR NZ,L_11F4
    CALL SUB_004A
    JR L_11ED

; S-QUOTE
L_11CB:
    CP $0B
    JR NZ,L_11F7
    CALL SUB_004A
    PUSH HL
    JR L_11D8

; S-Q-AGAIN
L_11D5:
    CALL SUB_004A

; S-QUOTE-S
L_11D8:
    CP $0B
    JR NZ,L_11F0
    POP DE
    AND A
    SBC HL,DE
    LD B,H
    LD C,L

; S-STRING
L_11E2:
    LD HL,$4001
    RES 6,(HL)
    BIT 7,(HL)
    CALL NZ,SUB_14B8
    RST 20H

; S-J-CONT-3
L_11ED:
    JP L_127D

; S-Q-NL
L_11F0:
    CP $76
    JR NZ,L_11D5

; S-RPT-C
L_11F4:
    JP L_0F17                           ; To REPORT-C - Invalid Expression

; S-FUNCTION
L_11F7:
    SUB $C0
    JR C,L_11F4
    LD BC,$04EC
    CP $13
    JR Z,L_1215
    JR NC,L_11F4
    LD B,$10
    ADD A,$D9
    LD C,A
    CP $DC
    JR NC,L_120F
    RES 6,C

; S-NO-TO-$
L_120F:
    CP $EA
    JR C,L_1215
    RES 7,C

; S-PUSH-PO
L_1215:
    PUSH BC
    RST 20H
    JP L_114E

; S-LTR-DGT
L_121A:
    CP $26
    JR C,L_123C
    CALL $1311
    JP C,L_0EC8
    CALL Z,SUB_139C
    LD A,($4001)
    CP $C0
    JR C,L_127C
    INC HL
    LD DE,($401C)
    CALL SUB_1BED
    EX DE,HL
    LD ($401C),HL
    JR L_127C

; S-DECIMAL
L_123C:
    CALL SUB_0F23
    JR NZ,L_1264
    CALL SUB_16D1
    RST 18H
    LD BC,$0006
    CALL SUB_0B30                       ; MAKE-ROOM
    INC HL
    LD (HL),$7E
    INC HL
    EX DE,HL
    LD HL,($401C)
    LD C,$05
    AND A
    SBC HL,BC
    LD ($401C),HL
    LDIR
    EX DE,HL
    DEC HL
    CALL L_004D
    JR L_1278

; S-STK-DEC
L_1264:
    RST 20H
    CP $7E
    JR NZ,L_1264
    INC HL
    LD DE,($401C)
    CALL SUB_1BED
    LD ($401C),DE
    LD ($4016),HL                       ; CH.ADD - Address of next character to interpret

; S-NUMERIC
L_1278:
    SET 6,(IY+$01)                      ; Set FLAGS  - 1 = Numeric result

; S-CONT-2
L_127C:
    RST 18H

; S-CONT-3
L_127D:
    CP $10
    JR NZ,L_128D
    BIT 6,(IY+$01)                      ; Check FLAGS - 0 = string or 1 = numeric result
    JR NZ,L_12B1
    CALL SUB_1458
    RST 20H
    JR L_127D

; S-OPERTR
L_128D:
    LD BC,$00C3
    CP $12
    JR C,L_12B1
    SUB $16
    JR NC,L_129C
    ADD A,$0D
    JR L_12AA

; SUBMLTDIV
L_129C:
    CP $03
    JR C,L_12AA
    SUB $C0
    JR C,L_12B1
    CP $06
    JR NC,L_12B1
    ADD A,$03

; GET-PRIO
L_12AA:
    ADD A,C
    LD C,A
    LD HL, L_1304 - $C3                 ; Offset to base of the priorities table (=$1241)
    ADD HL,BC
    LD B,(HL)

; S-LOOP
L_12B1:
    POP DE
    LD A,D
    CP B
    JR C,L_12E2
    AND A
    JP Z,L_0018
    PUSH BC
    PUSH DE
    CALL SUB_0F23
    JR Z,L_12CA
    LD A,E
    AND $3F
    LD B,A
    RST 28H
    SCF
    INC (HL)
    JR L_12D3

; S-SYNTEST
L_12CA:
    LD A,E
    XOR (IY+$01)
    AND $40

; S-RPORT-C
L_12D0:
    JP NZ,L_0F17                        ; To REPORT-C - Invalid Expression

; S-RUNTEST
L_12D3:
    POP DE
    LD HL,$4001
    SET 6,(HL)
    BIT 7,E
    JR NZ,L_12DF
    RES 6,(HL)

; S-LOOPEND
L_12DF:
    POP BC
    JR L_12B1

; S-TIGHTER
L_12E2:
    PUSH DE
    LD A,C
    BIT 6,(IY+$01)                      ; Check FLAGS - 0 = string or 1 = numeric result
    JR NZ,L_12FF
    AND $3F
    ADD A,$08
    LD C,A
    CP $10
    JR NZ,L_12F7
    SET 6,C
    JR L_12FF

; S-NOT-AND
L_12F7:
    JR C,L_12D0
    CP $17
    JR Z,L_12FF
    SET 7,C

; S-NEXT
L_12FF:
    PUSH BC
    RST 20H
    JP L_114E

; -------------------------
; THE 'TABLE OF PRIORITIES'
; -------------------------

; tbl-pri
L_1304:
    .BYTE $06                           ;       '-'
    .BYTE $08                           ;       '*'
    .BYTE $08                           ;       '/'
    .BYTE $0A                           ;       '**'
    .BYTE $02                           ;       'OR'
    .BYTE $03                           ;       'AND'
    .BYTE $05                           ;       '<='
    .BYTE $05                           ;       '>='
    .BYTE $05                           ;       '<>'
    .BYTE $05                           ;       '>'
    .BYTE $05                           ;       '<'
    .BYTE $05                           ;       '='
    .BYTE $06                           ;       '+'


; --------------------------
; THE 'LOOK-VARS' SUBROUTINE
; --------------------------

; LOOK-VARS
SUB_1311:
    SET 6,(IY+$01)                      ; Set FLAGS - 1 = numeric result
    RST 18H
    CALL SUB_16C6
    JP NC,L_0F17                        ; To REPORT-C - Invalid Expression
    PUSH HL
    LD C,A
    RST 20H
    PUSH HL
    RES 5,C
    CP $10
    JR Z,L_133D
    SET 6,C
    CP $0D
    JR Z,L_1338
    SET 5,C

; V-CHAR
L_132E:
    CALL SUB_16CA
    JR NC,L_133D
    RES 6,C
    RST 20H
    JR L_132E

; V-STR-VAR
L_1338:
    RST 20H
    RES 6,(IY+$01)                      ; Set FLAGS - 0 = string result

; V-RUN/SYN
L_133D:
    LD B,C
    CALL SUB_0F23
    JR NZ,L_134B
    LD A,C
    AND $E0
    SET 7,A
    LD C,A
    JR L_137F

; V-RUN
L_134B:
    LD HL,($4010)

; V-EACH
L_134E:
    LD A,(HL)
    AND $7F
    JR Z,L_137D
    CP C
    JR NZ,L_1375
    RLA
    ADD A,A
    JP P,L_138A
    JR C,L_138A
    POP DE
    PUSH DE
    PUSH HL

; V-MATCHES
L_1360:
    INC HL

; V-SPACES
L_1361:
    LD A,(DE)
    INC DE
    AND A
    JR Z,L_1361
    CP (HL)
    JR Z,L_1360
    OR $80
    CP (HL)
    JR NZ,L_1374
    LD A,(DE)
    CALL SUB_16CA
    JR NC,L_1389

; V-GET-PTR
L_1374:
    POP HL

; V-NEXT
L_1375:
    PUSH BC
    CALL SUB_0B84
    EX DE,HL
    POP BC
    JR L_134E

; V-80-BYTE
L_137D:
    SET 7,B

; V-SYNTAX
L_137F:
    POP DE
    RST 18H
    CP $10
    JR Z,L_138E
    SET 5,B
    JR L_1396

; V-FOUND-1
L_1389:
    POP DE

; V-FOUND-2
L_138A:
    POP DE
    POP DE
    PUSH HL
    RST 18H

; V-PASS
L_138E:
    CALL SUB_16CA
    JR NC,L_1396
    RST 20H
    JR L_138E

; V-END
L_1396:
    POP HL
    RL B
    BIT 6,B
    RET

; ------------------------
; THE 'STK-VAR' SUBROUTINE
; ------------------------

; STK-VAR
SUB_139C:
    XOR A
    LD B,A
    BIT 7,C
    JR NZ,L_13ED
    BIT 7,(HL)
    JR NZ,L_13B4
    INC A

; SV-SIMPLE$
L_13A7:
    INC HL
    LD C,(HL)
    INC HL
    LD B,(HL)
    INC HL
    EX DE,HL
    CALL SUB_14B8
    RST 18H
    JP L_144F

; SV-ARRAYS
L_13B4:
    INC HL
    INC HL
    INC HL
    LD B,(HL)
    BIT 6,C
    JR Z,L_13C6
    DEC B
    JR Z,L_13A7
    EX DE,HL
    RST 18H
    CP $10
    JR NZ,L_1426
    EX DE,HL

; SV-PTR
L_13C6:
    EX DE,HL
    JR L_13ED

; SV-COMMA
L_13C9:
    PUSH HL
    RST 18H
    POP HL
    CP $1A
    JR Z,L_13F0
    BIT 7,C
    JR Z,L_1426
    BIT 6,C
    JR NZ,L_13DE
    CP $11
    JR NZ,L_1418
    RST 20H
    RET

; SV-CLOSE
L_13DE:
    CP $11
    JR Z,L_144E
    CP $41
    JR NZ,L_1418

; SV-CH-ADD
L_13E6:
    RST 18H
    DEC HL
    LD ($4016),HL                       ; CH.ADD - Address of next character to interpret
    JR L_144B

; SV-COUNT
L_13ED:
    LD HL,$0000

; SV-LOOP
L_13F0:
    PUSH HL
    RST 20H
    POP HL
    LD A,C
    CP $C0
    JR NZ,L_1401
    RST 18H
    CP $11
    JR Z,L_144E
    CP $41
    JR Z,L_13E6

; SV-MULT
L_1401:
    PUSH BC
    PUSH HL
    CALL SUB_14F4
    EX (SP),HL
    EX DE,HL
    CALL SUB_14D2
    JR C,L_1426
    DEC BC
    CALL SUB_14FA
    ADD HL,BC
    POP DE
    POP BC
    DJNZ L_13C9
    BIT 7,C

; SV-RPT-C
L_1418:
    JR NZ,L_1480
    PUSH HL
    BIT 6,C
    JR NZ,L_1432
    LD B,D
    LD C,E
    RST 18H
    CP $11
    JR Z,L_1428

; REPORT-3
L_1426:
    RST 08H                             ; ERROR-1
    .BYTE $02                           ; BS - Bad Subscript

; SV-NUMBER
L_1428:
    RST 20H
    POP HL
    LD DE,$0005
    CALL SUB_14FA
    ADD HL,BC
    RET

; SV-ELEM$
L_1432:
    CALL SUB_14F4
    EX (SP),HL
    CALL SUB_14FA
    POP BC
    ADD HL,BC
    INC HL
    LD B,D
    LD C,E
    EX DE,HL
    CALL SUB_14B7
    RST 18H
    CP $11
    JR Z,L_144E
    CP $1A
    JR NZ,L_1426

; SV-SLICE
L_144B:
    CALL SUB_1458

; SV-DIM
L_144E:
    RST 20H

; SV-SLICE?
L_144F:
    CP $10
    JR Z,L_144B
    RES 6,(IY+$01)                      ; Set FLAGS - 0 = string result
    RET

; ------------------------
; THE 'SLICING' SUBROUTINE
; ------------------------

; SLICING
SUB_1458:
    CALL SUB_0F23
    CALL NZ,SUB_15ED                    ; Routine STK-FETCH
    RST 20H
    CP $11
    JR Z,L_14B3
    PUSH DE
    XOR A
    PUSH AF
    PUSH BC
    LD DE,$0001
    RST 18H
    POP HL
    CP $41
    JR Z,L_1487
    POP AF
    CALL SUB_14D3
    PUSH AF
    LD D,B
    LD E,C
    PUSH HL
    RST 18H
    POP HL
    CP $41
    JR Z,L_1487
    CP $11

; SL-RPT-C
L_1480:
    JP NZ,L_0F17                        ; To REPORT-C - Invalid Expression
    LD H,D
    LD L,E
    JR L_149A

; SL-SECOND
L_1487:
    PUSH HL
    RST 20H
    POP HL
    CP $11
    JR Z,L_149A
    POP AF
    CALL SUB_14D3
    PUSH AF
    RST 18H
    LD H,B
    LD L,C
    CP $11
    JR NZ,L_1480

; SL-DEFINE
L_149A:
    POP AF
    EX (SP),HL
    ADD HL,DE
    DEC HL
    EX (SP),HL
    AND A
    SBC HL,DE
    LD BC,$0000
    JR C,L_14AE
    INC HL
    AND A
    JP M,L_1426
    LD B,H
    LD C,L

; SL-OVER
L_14AE:
    POP DE
    RES 6,(IY+$01)                      ; Set FLAGS - 0 = string result

; SL-STORE
L_14B3:
    CALL SUB_0F23
    RET Z

; --------------------------
; THE 'STK-STORE' SUBROUTINE
; --------------------------

; STK-ST-0
SUB_14B7:
    XOR A

; STK-STO-$
SUB_14B8:
    PUSH BC
    CALL SUB_1BE2
    POP BC
    LD HL,($401C)
    LD (HL),A
    INC HL
    LD (HL),E
    INC HL
    LD (HL),D
    INC HL
    LD (HL),C
    INC HL
    LD (HL),B
    INC HL
    LD ($401C),HL
    RES 6,(IY+$01)                      ; Set FLAGS - 0 = string result
    RET

; -------------------------
; THE 'INT EXP' SUBROUTINES
; -------------------------

; INT-EXP1
SUB_14D2:
    XOR A

; INT-EXP2
SUB_14D3:
    PUSH DE
    PUSH HL
    PUSH AF
    CALL SUB_0F0F
    POP AF
    CALL SUB_0F23
    JR Z,L_14F1
    PUSH AF
    CALL SUB_1088
    POP DE
    LD A,B
    OR C
    SCF
    JR Z,L_14EE
    POP HL
    PUSH HL
    AND A
    SBC HL,BC

; I-CARRY
L_14EE:
    LD A,D
    SBC A,$00

; I-RESTORE
L_14F1:
    POP HL
    POP DE
    RET

; --------------------------
; THE 'DE,(DE+1)' SUBROUTINE
; --------------------------

; DE,(DE+1)
SUB_14F4:
    EX DE,HL
    INC HL
    LD E,(HL)
    INC HL
    LD D,(HL)
    RET

; --------------------------
; THE 'GET-HL*DE' SUBROUTINE
; --------------------------

; GET-HL*DE
SUB_14FA:
    CALL SUB_0F23
    RET Z
    PUSH BC
    LD B,$10
    LD A,H
    LD C,L
    LD HL,$0000

; HL-LOOP
L_1506:
    ADD HL,HL
    JR C,L_150F
    RL C
    RLA
    JR NC,L_1512
    ADD HL,DE

; HL-END
L_150F:
    JP C,L_10AE

; HL-AGAIN
L_1512:
    DJNZ L_1506
    POP BC
    RET

; --------------------
; THE 'LET' SUBROUTINE
; --------------------

; LET
L_1516:
    LD HL,($4012)
    BIT 1,(IY+$2D)
    JR Z,L_1563
    LD BC,$0005

; L-EACH-CH
L_1522:
    INC BC

; L-NO-SP
L_1523:
    INC HL
    LD A,(HL)
    AND A
    JR Z,L_1523
    CALL SUB_16CA
    JR C,L_1522
    CP $0D
    JP Z,L_15BD
    RST 30H
    PUSH DE
    LD HL,($4012)
    DEC DE
    LD A,C
    SUB $06
    LD B,A
    LD A,$40
    JR Z,L_154E

; L-CHAR
L_1540:
    INC HL
    LD A,(HL)
    AND A
    JR Z,L_1540
    INC DE
    LD (DE),A
    DJNZ L_1540
    OR $80
    LD (DE),A
    LD A,$80

; L-SINGLE
L_154E:
    LD HL,($4012)
    XOR (HL)
    POP HL
    CALL SUB_15DC

; L-NUMERIC
L_1556:
    PUSH HL
    RST 28H
    LD (BC),A
    INC (HL)
    POP HL
    LD BC,$0005
    AND A
    SBC HL,BC
    JR L_15A3

; L-EXISTS
L_1563:
    BIT 6,(IY+$01)                      ; Check FLAGS - 0 = string or 1 = numeric result
    JR Z,L_156F
    LD DE,$0006
    ADD HL,DE
    JR L_1556

; L-DELETE$
L_156F:
    LD HL,($4012)
    LD BC,($402E)
    BIT 0,(IY+$2D)
    JR NZ,L_15AC
    LD A,B
    OR C
    RET Z
    PUSH HL
    RST 30H
    PUSH DE
    PUSH BC
    LD D,H
    LD E,L
    INC HL
    LD (HL),$00
    LDDR
    PUSH HL
    CALL SUB_15ED                       ; Routine STK-FETCH
    POP HL
    EX (SP),HL
    AND A
    SBC HL,BC
    ADD HL,BC
    JR NC,L_1598
    LD B,H
    LD C,L

; L-LENGTH
L_1598:
    EX (SP),HL
    EX DE,HL
    LD A,B
    OR C
    JR Z,L_15A0
    LDIR

; L-IN-W/S
L_15A0:
    POP BC
    POP DE
    POP HL

; L-ENTER
L_15A3:
    EX DE,HL
    LD A,B
    OR C
    RET Z
    PUSH DE
    LDIR
    POP HL
    RET

; L-ADD$
L_15AC:
    DEC HL
    DEC HL
    DEC HL
    LD A,(HL)
    PUSH HL
    PUSH BC
    CALL SUB_15C3
    POP BC
    POP HL
    INC BC
    INC BC
    INC BC
    JP SUB_0BF5                         ; Routine RECLAIM-2

; L-NEWS
L_15BD:
    LD A,$60
    LD HL,($4012)
    XOR (HL)

; L-STRING
SUB_15C3:
    PUSH AF
    CALL SUB_15ED                       ; Routine STK-FETCH
    EX DE,HL
    ADD HL,BC
    PUSH HL
    INC BC
    INC BC
    INC BC
    RST 30H
    EX DE,HL
    POP HL
    DEC BC
    DEC BC
    PUSH BC
    LDDR
    EX DE,HL
    POP BC
    DEC BC
    LD (HL),B
    DEC HL
    LD (HL),C
    POP AF

; L-FIRST
SUB_15DC:
    PUSH AF
    CALL SUB_16BF
    POP AF
    DEC HL
    LD (HL),A
    LD HL,($401A)
    LD ($4014),HL
    DEC HL
    LD (HL),$80
    RET

; --------------------------
; THE 'STK-FETCH' SUBROUTINE
; --------------------------
; For a floating-point number the exponent is in A and the mantissa
; is the thirty-two bits EDCB.
; For strings, the start of the string is in DE and the length in BC.
; A is unused.

; STK-FETCH
SUB_15ED:
    LD HL,($401C)
    DEC HL
    LD B,(HL)
    DEC HL
    LD C,(HL)
    DEC HL
    LD D,(HL)
    DEC HL
    LD E,(HL)
    DEC HL
    LD A,(HL)
    LD ($401C),HL
    RET

; -------------------------
; THE 'DIM' COMMAND ROUTINE
; -------------------------

; DIM
SUB_15FE
    CALL SUB_1311                       ; LOOK-VARS

; D-RPORT-C
L_1601:
    JP NZ,L_0F17                        ; To REPORT-C - Invalid Expression
    CALL SUB_0F23
    JR NZ,L_1611
    RES 6,C
    CALL SUB_139C
    CALL SUB_0E9A                       ; Routine CHECK-END

; D-RUN
L_1611:
    JR C,L_161B
    PUSH BC
    CALL SUB_0B84
    CALL SUB_0BF5                       ; Routine RECLAIM-2
    POP BC

; D-LETTER
L_161B:
    SET 7,C
    LD B,$00
    PUSH BC
    LD HL,$0001
    BIT 6,C
    JR NZ,L_1629
    LD L,$05

; D-SIZE
L_1629:
    EX DE,HL

; D-NO-LOOP
L_162A:
    RST 20H
    LD H,$40
    CALL SUB_14D2
    JP C,L_1426
    POP HL
    PUSH BC
    INC H
    PUSH HL
    LD H,B
    LD L,C
    CALL SUB_14FA
    EX DE,HL
    RST 18H
    CP $1A
    JR Z,L_162A
    CP $11
    JR NZ,L_1601
    RST 20H
    POP BC
    LD A,C
    LD L,B
    LD H,$00
    INC HL
    INC HL
    ADD HL,HL
    ADD HL,DE
    JP C,L_10AE
    PUSH DE
    PUSH BC
    PUSH HL
    LD B,H
    LD C,L
    LD HL,($4014)
    DEC HL
    CALL SUB_0B30
    INC HL
    LD (HL),A
    POP BC
    DEC BC
    DEC BC
    DEC BC
    INC HL
    LD (HL),C
    INC HL
    LD (HL),B
    POP AF
    INC HL
    LD (HL),A
    LD H,D
    LD L,E
    DEC DE
    LD (HL),$00
    POP BC
    LDDR

; DIM-SIZES
L_1674:
    POP BC
    LD (HL),B
    DEC HL
    LD (HL),C
    DEC HL
    DEC A
    JR NZ,L_1674
    RET

; RESERVE
L_167D:
    LD HL,($401A)                       ; Address STKBOT
    DEC HL
    CALL SUB_0B30                       ; Routine MAKE-ROOM
    INC HL
    INC HL
    POP BC
    LD ($4014),BC
    POP BC
    EX DE,HL
    INC HL
    RET


; -------------------------
; THE 'RUN' COMMAND ROUTINE
; -------------------------

; RUN
SUB_168F:
    CALL SUB_1068                       ; GOTO with implied 0

; ---------------------------
; THE 'CLEAR' COMMAND ROUTINE
; ---------------------------

; CLEAR
SUB_1692:
    LD HL,($4010)
    LD (HL),$80
    INC HL
    LD ($4014),HL

; X-TEMP
SUB_169B:
    LD HL,($4014)                       ; Save E_LINE_lo

; set STK-B
SUB_169E:
    LD ($401A),HL                       ; Save STKBOT

; set STK-E
L_16A1:
    LD ($401C),HL                       ; Save STKEND
    RET

; -----------------------
; THE 'CURSOR-IN' ROUTINE
; -----------------------

; CURSOR-IN
SUB_16A5:
    LD HL,($4014)
    LD (HL),$7F
    INC HL
    LD (HL),$76
    INC HL
    LD (IY+$22),$02
    JR SUB_169E

; ------------------------
; THE 'SET-MIN' SUBROUTINE
; ------------------------

; SET-MIN
L_16B4:
    LD HL,$405D
    LD ($401F),HL
    LD HL,($401A)
    JR L_16A1

; ------------------------------------
; THE 'RECLAIM THE END-MARKER' ROUTINE
; ------------------------------------

; REC-V80
SUB_16BF:
    LD DE,($4014)
    JP SUB_0BF2

; ----------------------
; THE 'ALPHA' SUBROUTINE
; ----------------------

; ALPHA
SUB_16C6:
    CP $26
    JR L_16CC

; -------------------------
; THE 'ALPHANUM' SUBROUTINE
; -------------------------

; ALPHANUM
SUB_16CA:
    CP $1C

; ALPHA-2
L_16CC:
    CCF
    RET NC
    CP $40
    RET

; ------------------------------------------
; THE 'DECIMAL TO FLOATING POINT' SUBROUTINE
; ------------------------------------------

; DEC-TO-FP
SUB_16D1:
    CALL SUB_1740
    CP $1B
    JR NZ,L_16ED
    RST 28H                             ; FP-CALC
    .BYTE $A1                           ; Stk-one
    .BYTE $C0                           ; St-mem-0
    .BYTE $02                           ; Delete
    .BYTE $34                           ; End-calc

; NXT-DGT-1
L_16DD:
    RST 20H
    CALL SUB_170C
    JR C,L_16ED
    RST 28H                             ; FP-CALC
    .BYTE $E0                           ; Get-mem-0
    .BYTE $A4                           ; Stk-ten
    .BYTE $05                           ; Division
    .BYTE $C0                           ; St-mem-0
    .BYTE $04                           ; Multiply
    .BYTE $0F                           ; Addition
    .BYTE $34                           ; End-calc
    JR L_16DD

; E-FORMAT
L_16ED:
    CP $2A
    RET NZ
    LD (IY+$5D),$FF
    RST 20H
    CP $15
    JR Z,L_1700
    CP $16
    JR NZ,L_1701
    INC (IY+$5D)

; SIGN-DONE
L_1700:
    RST 20H

; ST-E-PART
L_1701:
    CALL SUB_1740
    RST 28H                             ; FP-CALC              m, e.
    .BYTE $E0                           ; Get-mem-0             m, e, (1/0) TRUE/FALSE
    .BYTE $00                           ; Jump-true
    .BYTE $02                           ; To L1511, E-POSTVE
    .BYTE $18                           ; Neg                   m, -e
;; E-POSTVE
    .BYTE $38                           ; E-to-fp               x.
    .BYTE $34                           ; End-calc              x.
    RET

; --------------------------
; THE 'STK-DIGIT' SUBROUTINE
; --------------------------

; STK-DIGIT
SUB_170C:
    CP $1C
    RET C
    CP $26
    CCF
    RET C
    SUB $1C

; ------------------------
; THE 'STACK-A' SUBROUTINE
; ------------------------

; STACK-A
SUB_1715:
    LD C,A
    LD B,$00

; -------------------------
; THE 'STACK-BC' SUBROUTINE
; -------------------------

; STACK-BC
SUB_1718:
    LD IY,$4000
    PUSH BC
    RST 28H                             ; FP-CALC
    .BYTE $A0                           ; Stk-zero                      0.
    .BYTE $34                           ; End-calc
    POP BC
    LD (HL),$91
    LD A,B
    AND A
    JR NZ,L_172E
    LD (HL),A
    OR C
    RET Z
    LD B,C
    LD C,(HL)
    LD (HL),$89

; STK-BC-2
L_172E:
    DEC (HL)
    SLA C
    RL B
    JR NC,L_172E
    SRL B
    RR C
    INC HL
    LD (HL),B
    INC HL
    LD (HL),C
    DEC HL
    DEC HL
    RET

; ------------------------------------------
; THE 'INTEGER TO FLOATING POINT' SUBROUTINE
; ------------------------------------------

; INT-TO-FP
SUB_1740:
    PUSH AF
    RST 28H                             ; FP-CALC
    .BYTE $A0                           ; Stk-zero
    .BYTE $34                           ; End-calc
    POP AF

; NXT-DGT-2
L_1745:
    CALL SUB_170C
    RET C
    RST 28H                             ; FP-CALC
    .BYTE $01                           ; Exchange
    .BYTE $A4                           ; Stk-ten
    .BYTE $04                           ; Multiply
    .BYTE $0F                           ; Addition
    .BYTE $34                           ; End-calc
    RST 20H
    JR L_1745

; ------------------------------------------------
; THE 'E-FORMAT TO FLOATING POINT' SUBROUTINE (38)
; ------------------------------------------------
SUB_1752:
    RST 28H                             ; FP-CALC              x, m.
    .BYTE $2D                           ; Duplicate             x, m, m.
    .BYTE $32                           ; Less-0                x, m, (1/0).
    .BYTE $C0                           ; St-mem-0              x, m, (1/0).
    .BYTE $02                           ; Delete                x, m.
    .BYTE $27                           ; Abs                   x, +m.

;; E-LOOP
    .BYTE $A1                           ; Stk-one               x, m,1.
    .BYTE $03                           ; Subtract              x, m-1.
    .BYTE $2D                           ; Duplicate             x, m-1,m-1.
    .BYTE $32                           ; Less-0                x, m-1, (1/0).
    .BYTE $00                           ; Jump-true             x, m-1.
    .BYTE $22                           ; To L1587, E-END       x, m-1.

    .BYTE $2D                           ; Duplicate             x, m-1, m-1.
    .BYTE $30                           ; Stk-data
    .BYTE $33                           ; Exponent: $83, Bytes: 1

    .BYTE $40                           ; (+00,+00,+00)         x, m-1, m-1, 6.
    .BYTE $03                           ; Subtract              x, m-1, m-7.
    .BYTE $2D                           ; Duplicate             x, m-1, m-7, m-7.
    .BYTE $32                           ; Less-0                x, m-1, m-7, (1/0).
    .BYTE $00                           ; Jump-true             x, m-1, m-7.
    .BYTE $0C                           ; To L157A, E-LOW

; but if exponent m is higher than 7 do a bigger chunk.
; multiplying (or dividing if negative) by 10 million - 1e7.

    .BYTE $01                           ; Exchange              x, m-7, m-1.
    .BYTE $02                           ; Delete                x, m-7.
    .BYTE $01                           ; Exchange              m-7, x.
    .BYTE $30                           ; Stk-data
    .BYTE $80                           ; Bytes: 3
    .BYTE $48                           ; Exponent $98
    .BYTE $18,$96,$80                   ; (+00)                 m-7, x, 10,000,000 (=f)
    .BYTE $2F                           ; Jump
    .BYTE $04                           ; To L157D, E-CHUNK

; ---

;; E-LOW
    .BYTE $02                           ; Delete                x, m-1.
    .BYTE $01                           ; Exchange              m-1, x.
    .BYTE $A4                           ; Stk-ten               m-1, x, 10 (=f).

;; E-CHUNK
    .BYTE $E0                           ; Get-mem-0             m-1, x, f, (1/0)
    .BYTE $00                           ; Jump-true             m-1, x, f
    .BYTE $04                           ; To L1583, E-DIVSN

    .BYTE $04                           ; Multiply              m-1, x*f.
    .BYTE $2F                           ; Jump
    .BYTE $02                           ; To L1584, E-SWAP

; ---

;; E-DIVSN
    .BYTE $05                           ; Division              m-1, x/f (= new x).

;; E-SWAP
    .BYTE $01                           ; Exchange              x, m-1 (= new m).
    .BYTE $2F                           ; Jump                  x, m.
    .BYTE $DA                           ; To L1560, E-LOOP

; ---

;; E-END
    .BYTE $02                           ; Delete                x. (-1)
    .BYTE $34                           ; End-calc              x.

    RET

; -------------------------------------
; THE 'FLOATING-POINT TO BC' SUBROUTINE
; -------------------------------------

; FP-TO-BC
SUB_1782:
    CALL SUB_15ED                       ; Routine STK-FETCH
    AND A
    JR NZ,L_178D
    LD B,A
    LD C,A
    PUSH AF
    JR L_17BE

; FPBC-NZRO
L_178D:
    LD B,E
    LD E,C
    LD C,D
    SUB $91
    CCF
    BIT 7,B
    PUSH AF
    SET 7,B
    JR C,L_17BE
    INC A
    NEG
    CP $08
    JR C,L_17A7
    LD E,C
    LD C,B
    LD B,$00
    SUB $08

; BIG-INT
L_17A7:
    AND A
    LD D,A
    LD A,E
    RLCA
    JR Z,L_17B4

; FPBC-NORM
L_17AD:
    SRL B
    RR C
    DEC D
    JR NZ,L_17AD

; EXP-ZERO
L_17B4:
    JR NC,L_17BE
    INC BC
    LD A,B
    OR C
    JR NZ,L_17BE
    POP AF
    SCF
    PUSH AF

; FPBC-END
L_17BE:
    PUSH BC
    RST 28H                             ; FP-CALC
    .BYTE $34                           ; End-calc
    POP BC
    POP AF
    LD A,C
    RET

; ------------------------------------
; THE 'FLOATING-POINT TO A' SUBROUTINE
; ------------------------------------

; FP-TO-A
SUB_17C5:
    CALL SUB_1782
    RET C
    PUSH AF
    DEC B
    INC B
    JR Z,L_17D1
    POP AF
    SCF
    RET

; FP-A-END
L_17D1:
    POP AF
    RET

; ----------------------------------------------
; THE 'PRINT A FLOATING-POINT NUMBER' SUBROUTINE
; ----------------------------------------------

; PRINT-FP
L_17D3:
    RST 28H                             ; FP-CALC              x.
    .BYTE $2D                           ; Duplicate             x, x.
    .BYTE $32                           ; Less-0                x, (1/0).
    .BYTE $00                           ; Jump-true
    .BYTE $0B                           ; To L15EA, PF-NGTVE    x.

    .BYTE $2D                           ; Duplicate             x, x
    .BYTE $33                           ; Greater-0             x, (1/0).
    .BYTE $00                           ; Jump-true
    .BYTE $0D                           ; To L15F0, PF-POSTVE   x.

    .BYTE $02                           ; Delete                .
    .BYTE $34                           ; End-calc              .
    LD A,$1C
    RST 10H
    RET

; PF-NEGTVE
    .BYTE $27                           ; Abs                   +x.
    .BYTE $34                           ; End-calc              x.
    LD A,$16
    RST 10H
    RST 28H                             ; FP-CALC              x.

; PF-POSTVE
    .BYTE $34                           ; End-calc              x.
    LD A,(HL)
    CALL SUB_1715
    RST 28H                             ; FP-CALC              x, e.
    .BYTE $30                           ; Stk-data
    .BYTE $78                           ; Exponent: $88, Bytes: 2
    .BYTE $00,$80                       ; (+00,+00)             x, e, 128.5.
    .BYTE $03                           ; Subtract              x, e -.5.
    .BYTE $30                           ; Stk-data
    .BYTE $EF                           ; Exponent: $7F, Bytes: 4
    .BYTE $1A,$20,$9A,$85               ; .30103 (log10 2)
    .BYTE $04                           ; Multiply              x,
    .BYTE $24                           ; Int
    .BYTE $C1                           ; St-mem-1              x, n.


    .BYTE $30                           ; Stk-data
    .BYTE $34                           ; Exponent: $84, Bytes: 1
    .BYTE $00                           ; (+00,+00,+00)         x, n, 8.

    .BYTE $03                           ; Subtract              x, n-8.
    .BYTE $18                           ; Neg                   x, 8-n.
    .BYTE $38                           ; E-to-fp               x * (10^n)

    .BYTE $A2                           ; Stk-half
    .BYTE $0F                           ; Addition
    .BYTE $24                           ; Int                   i.
    .BYTE $34                           ; End-calc
    LD HL,$406B
    LD (HL),$90
    LD B,$0A

; PF-LOOP
L_180D:
    INC HL
    PUSH HL
    PUSH BC
    RST 28H                             ; FP-CALC              i.
    .BYTE $A4                           ; Stk-ten               i, 10.
    .BYTE $2E                           ; N-mod-m               i mod 10, i/10
    .BYTE $01                           ; Exchange              i/10, remainder.
    .BYTE $34                           ; End-calc
    CALL SUB_17C5
    OR $90
    POP BC
    POP HL
    LD (HL),A
    DJNZ L_180D
    INC HL
    LD BC,$0008
    PUSH HL

; PF-NULL
L_1824:
    DEC HL
    LD A,(HL)
    CP $90
    JR Z,L_1824
    SBC HL,BC
    PUSH HL
    LD A,(HL)
    ADD A,$6B
    PUSH AF

; PF-RND-LP
L_1831:
    POP AF
    INC HL
    LD A,(HL)
    ADC A,$00
    DAA
    PUSH AF
    AND $0F
    LD (HL),A
    SET 7,(HL)
    JR Z,L_1831
    POP AF
    POP HL
    LD B,$06

; PF-ZERO-6
L_1843:
    LD (HL),$80
    DEC HL
    DJNZ L_1843
    RST 28H
    LD (BC),A
    POP HL
    INC (HL)
    CALL SUB_17C5
    JR Z,L_1853
    NEG

; PF-POS
L_1853:
    LD E,A
    INC E
    INC E
    POP HL

; GET-FIRST
L_1857:
    DEC HL
    DEC E
    LD A,(HL)
    AND $0F
    JR Z,L_1857
    LD A,E
    SUB $05
    CP $08
    JP P,L_187A
    CP $F6
    JP M,L_187A
    ADD A,$06
    JR Z,L_18B6
    JP M,L_18A9
    LD B,A

; PF-NIB-LP
L_1873:
    CALL SUB_18C7
    DJNZ L_1873
    JR L_18B9

; PF-E-FMT
L_187A:
    LD B,E
    CALL SUB_18C7
    CALL L_18B9
    LD A,$2A
    RST 10H
    LD A,B
    AND A
    JP P,L_1890
    NEG
    LD B,A
    LD A,$16
    JR L_1892

; PF-E-POS
L_1890:
    LD A,$15

; PF-E-SIGN
L_1892:
    RST 10H
    LD A,B
    LD B,$FF

; PF-E-TENS
L_1896:
    INC B
    SUB $0A
    JR NC,L_1896
    ADD A,$0A
    LD C,A
    LD A,B
    AND A
    JR Z,L_18A5
    CALL SUB_098C

; PF-E-LOW
L_18A5:
    LD A,C
    JP SUB_098C

; PF-ZEROS
L_18A9:
    NEG
    LD B,A
    LD A,$1B
    RST 10H
L_18AF:
    LD A,$1C

; PF-ZRO-LP  - ZX81 jumped to line above?
    RST 10H
    DJNZ L_18AF
    JR L_18BF

; PF-ZERO-1
L_18B6:
    LD A,$1C
    RST 10H

; PF-DC-OUT
L_18B9:
    DEC (HL)
    INC (HL)
    RET PE
    LD A,$1B
    RST 10H

; PF-FRAC-LP
L_18BF:
    DEC (HL)
    INC (HL)
    RET PE
    CALL SUB_18C7
    JR L_18BF

; PF-NIBBLE
SUB_18C7:
    LD A,(HL)
    AND $0F
    CALL SUB_098C
    DEC HL
    RET

; -------------------------------
; THE 'PREPARE TO ADD' SUBROUTINE
; -------------------------------

; PREP-ADD
SUB_18CF:
    LD A,(HL)
    LD (HL),$00
    AND A
    RET Z
    INC HL
    BIT 7,(HL)
    SET 7,(HL)
    DEC HL
    RET Z
    PUSH BC
    LD BC,$0005
    ADD HL,BC
    LD B,C
    LD C,A
    SCF

; NEG-BYTE
L_18E3:
    DEC HL
    LD A,(HL)
    CPL
    ADC A,$00
    LD (HL),A
    DJNZ L_18E3
    LD A,C
    POP BC
    RET

; ----------------------------------
; THE 'FETCH TWO NUMBERS' SUBROUTINE
; ----------------------------------

; FETCH-TWO
SUB_18EE:
    PUSH HL
    PUSH AF
    LD C,(HL)
    INC HL
    LD B,(HL)
    LD (HL),A
    INC HL
    LD A,C
    LD C,(HL)
    PUSH BC
    INC HL
    LD C,(HL)
    INC HL
    LD B,(HL)
    EX DE,HL
    LD D,A
    LD E,(HL)
    PUSH DE
    INC HL
    LD D,(HL)
    INC HL
    LD E,(HL)
    PUSH DE
    EXX
    POP DE
    POP HL
    POP BC
    EXX
    INC HL
    LD D,(HL)
    INC HL
    LD E,(HL)
    POP AF
    POP HL
    RET

; -----------------------------
; THE 'SHIFT ADDEND' SUBROUTINE
; -----------------------------

; SHIFT-FP
SUB_1911:
    AND A
    RET Z
    CP $21
    JR NC,L_192D
    PUSH BC
    LD B,A

; ONE-SHIFT
L_1919:
    EXX
    SRA L
    RR D
    RR E
    EXX
    RR D
    RR E
    DJNZ L_1919
    POP BC
    RET NC
    CALL SUB_1938
    RET NZ

; ADDEND-0
L_192D:
    EXX
    XOR A

; ZEROS-4/5
SUB_192F:
    LD L,$00
    LD D,A
    LD E,L
    EXX
    LD DE,$0000
    RET

; -------------------------
; THE 'ADD-BACK' SUBROUTINE
; -------------------------

; ADD-BACK
SUB_1938:
    INC E
    RET NZ
    INC D
    RET NZ
    EXX
    INC E
    JR NZ,L_1941
    INC D

; ALL-ADDED
L_1941:
    EXX
    RET

; --------------------------------
; THE 'SUBTRACTION' OPERATION (03)
; --------------------------------

; subtract
SUB_1943:
    LD A,(DE)
    AND A
    RET Z
    INC DE
    LD A,(DE)
    XOR $80
    LD (DE),A
    DEC DE

; -----------------------------
; THE 'ADDITION' OPERATION (0F)
; -----------------------------

; addition
SUB_194C:
    EXX
    PUSH HL
    EXX
    PUSH DE
    PUSH HL
    CALL SUB_18CF
    LD B,A
    EX DE,HL
    CALL SUB_18CF
    LD C,A
    CP B
    JR NC,L_1960
    LD A,B
    LD B,C
    EX DE,HL

; SHIFT-LEN
L_1960:
    PUSH AF
    SUB B
    CALL SUB_18EE
    CALL SUB_1911
    POP AF
    POP HL
    LD (HL),A
    PUSH HL
    LD L,B
    LD H,C
    ADD HL,DE
    EXX
    EX DE,HL
    ADC HL,BC
    EX DE,HL
    LD A,H
    ADC A,L
    LD L,A
    RRA
    XOR L
    EXX
    EX DE,HL
    POP HL
    RRA
    JR NC,L_1987
    LD A,$01
    CALL SUB_1911
    INC (HL)
    JR Z,L_19AA

; TEST-NEG
L_1987:
    EXX
    LD A,L
    AND $80
    EXX
    INC HL
    LD (HL),A
    DEC HL
    JR Z,L_19B0
    LD A,E
    NEG
    CCF
    LD E,A
    LD A,D
    CPL
    ADC A,$00
    LD D,A
    EXX
    LD A,E
    CPL
    ADC A,$00
    LD E,A
    LD A,D
    CPL
    ADC A,$00
    JR NC,L_19AE
    RRA
    EXX
    INC (HL)

; ADD-REP-6
L_19AA:
    JP Z,L_1A77
    EXX

; END-COMPL
L_19AE:
    LD D,A
    EXX

; GO-NC-MLT
L_19B0:
    XOR A
    JR L_1A1F

; ----------------------------------------------
; THE 'PREPARE TO MULTIPLY OR DIVIDE' SUBROUTINE
; ----------------------------------------------

; PREP-M/D
SUB_19B3:
    SCF
    DEC (HL)
    INC (HL)
    RET Z
    INC HL
    XOR (HL)
    SET 7,(HL)
    DEC HL
    RET

; -----------------------------------
; THE 'MULTIPLICATION' OPERATION (04)
; -----------------------------------

; multiply
SUB_19BD:
    XOR A
    CALL SUB_19B3
    RET C
    EXX
    PUSH HL
    EXX
    PUSH DE
    EX DE,HL
    CALL SUB_19B3
    EX DE,HL
    JR C,L_1A27
    PUSH HL
    CALL SUB_18EE
    LD A,B
    AND A
    SBC HL,HL
    EXX
    PUSH HL
    SBC HL,HL
    EXX
    LD B,$21
    JR L_19EF

; MLT-LOOP
L_19DE:
    JR NC,L_19E5
    ADD HL,DE
    EXX
    ADC HL,DE
    EXX

; NO-ADD
L_19E5:
    EXX
    RR H
    RR L
    EXX
    RR H
    RR L

; STRT-MLT
L_19EF:
    EXX
    RR B
    RR C
    EXX
    RR C
    RRA
    DJNZ L_19DE
    EX DE,HL
    EXX
    EX DE,HL
    EXX
    POP BC
    POP HL
    LD A,B
    ADD A,C
    JR NZ,L_1A05
    AND A

; MAKE-EXPT
L_1A05:
    DEC A
    CCF

; DIVN-EXPT
L_1A07:
    RLA
    CCF
    RRA
    JP P,L_1A10
    JR NC,L_1A77
    AND A

; OFLW1-CLR
L_1A10:
    INC A
    JR NZ,L_1A1B
    JR C,L_1A1B
    EXX
    BIT 7,D
    EXX
    JR NZ,L_1A77

; OFLW2-CLR
L_1A1B:
    LD (HL),A
    EXX
    LD A,B
    EXX

; TEST-NORM
L_1A1F:
    JR NC,L_1A36
    LD A,(HL)
    AND A

; NEAR-ZERO
L_1A23:
    LD A,$80
    JR Z,L_1A28

; ZERO-RSLT
L_1A27:
    XOR A

; SKIP-ZERO
L_1A28:
    EXX
    AND D
    CALL SUB_192F
    RLCA
    LD (HL),A
    JR C,L_1A5F
    INC HL
    LD (HL),A
    DEC HL
    JR L_1A5F

; NORMALIZE
L_1A36:
    LD B,$20

; SHIFT-ONE
L_1A38:
    EXX
    BIT 7,D
    EXX
    JR NZ,L_1A50
    RLCA
    RL E
    RL D
    EXX
    RL E
    RL D
    EXX
    DEC (HL)
    JR Z,L_1A23
    DJNZ L_1A38
    JR L_1A27

; NORML-NOW
L_1A50:
    RLA
    JR NC,L_1A5F
    CALL SUB_1938
    JR NZ,L_1A5F
    EXX
    LD D,$80
    EXX
    INC (HL)
    JR Z,L_1A77

; OFLOW-CLR
L_1A5F:
    PUSH HL
    INC HL
    EXX
    PUSH DE
    EXX
    POP BC
    LD A,B
    RLA
    RL (HL)
    RRA
    LD (HL),A
    INC HL
    LD (HL),C
    INC HL
    LD (HL),D
    INC HL
    LD (HL),E
    POP HL
    POP DE
    EXX
    POP HL
    EXX
    RET

; REPORT-6
L_1A77:
    RST 08H                             ; ERROR-1
    .BYTE $05                           ; OV arithmetic OVerflow.

; -----------------------------
; THE 'DIVISION' OPERATION (05)
; -----------------------------

; division
SUB_1A79:
    EX DE,HL
    XOR A
    CALL SUB_19B3
    JR C,L_1A77
    EX DE,HL
    CALL SUB_19B3
    RET C
    EXX
    PUSH HL
    EXX
    PUSH DE
    PUSH HL
    CALL SUB_18EE
    EXX
    PUSH HL
    LD H,B
    LD L,C
    EXX
    LD H,C
    LD L,B
    XOR A
    LD B,$DF
    JR L_1AA9

; DIV-LOOP
L_1A99:
    RLA
    RL C
    EXX
    RL C
    RL B
    EXX

; div-34th
L_1AA2:
    ADD HL,HL
    EXX
    ADC HL,HL
    EXX
    JR C,L_1AB9

; DIV-START
L_1AA9:
    SBC HL,DE
    EXX
    SBC HL,DE
    EXX
    JR NC,L_1AC0
    ADD HL,DE
    EXX
    ADC HL,DE
    EXX
    AND A
    JR L_1AC1

; SUBN-ONLY
L_1AB9:
    AND A
    SBC HL,DE
    EXX
    SBC HL,DE
    EXX

; NO-RSTORE
L_1AC0:
    SCF

; COUNT-ONE
L_1AC1:
    INC B
    JP M,L_1A99
    PUSH AF
    JR Z,L_1AA2                         ; Fix to ZX81 jumps to div-34th not DIV-START
    LD E,A
    LD D,C
    EXX
    LD E,C
    LD D,B
    POP AF
    RR B
    POP AF
    RR B
    EXX
    POP BC
    POP HL
    LD A,B
    SUB C
    JP L_1A07

; -----------------------------------------------------
; THE 'INTEGER TRUNCATION TOWARDS ZERO' SUBROUTINE (36)
; -----------------------------------------------------

; truncate
SUB_1ADB:
    LD A,(HL)
    CP $81
    JR NC,L_1AE6
    LD (HL),$00
    LD A,$20
    JR L_1AEB

; T-GR-ZERO
L_1AE6:
    SUB $A0
    RET P
    NEG

; NIL-BYTES
L_1AEB:
    PUSH DE
    EX DE,HL
    DEC HL
    LD B,A
    SRL B
    SRL B
    SRL B
    JR Z,L_1AFC

; BYTE-ZERO
L_1AF7:
    LD (HL),$00
    DEC HL
    DJNZ L_1AF7

; BITS-ZERO
L_1AFC:
    AND $07
    JR Z,L_1B09
    LD B,A
    LD A,$FF

; LESS-MASK
L_1B03:
    SLA A
    DJNZ L_1B03
    AND (HL)
    LD (HL),A

; IX-END
L_1B09:
    EX DE,HL
    POP DE
    RET

;********************************
;**  FLOATING-POINT CALCULATOR **
;********************************

; ------------------------
; THE 'TABLE OF CONSTANTS'
; ------------------------
L_1B0C:
; stk-zero                                                 00 00 00 00 00
    .BYTE $00                           ; Bytes: 1
    .BYTE $B0                           ; Exponent $00
    .BYTE $00                           ; (+00,+00,+00)

; stk-one                                                  81 00 00 00 00
    .BYTE $31                           ; Exponent $81, Bytes: 1
    .BYTE $00                           ; (+00,+00,+00)


; stk-half                                                 80 00 00 00 00
    .BYTE $30                           ; Exponent: $80, Bytes: 1
    .BYTE $00                           ; (+00,+00,+00)


; stk-pi/2                                                 81 49 0F DA A2
    .BYTE $F1                           ; Exponent: $81, Bytes: 4
    .BYTE $49,$0F,$DA,$A2

; stk-ten                                                  84 20 00 00 00
    .BYTE $34                           ; Exponent: $84, Bytes: 1
    .BYTE $20                           ; (+00,+00,+00)

; ------------------------
; THE 'TABLE OF ADDRESSES'
; ------------------------
L_1B1A:
    .WORD SUB_1E1E                      ; $00 - jump-true
    .WORD SUB_1C67                      ; $01 - exchange
    .WORD SUB_1BDA                      ; $02 - delete
    .WORD SUB_1943                      ; $03 - subtract
    .WORD SUB_19BD                      ; $04 - multiply
    .WORD SUB_1A79                      ; $05 - division
    .WORD SUB_1FD1                      ; $06 - to-power
    .WORD SUB_1CE2                      ; $07 - or
    .WORD SUB_1CE8                      ; $08 - no-&-no
    .WORD SUB_1CF8                      ; $09 - no-l-eql
    .WORD SUB_1CF8                      ; $0A - no-gr-eql
    .WORD SUB_1CF8                      ; $0B - nos-neql
    .WORD SUB_1CF8                      ; $0C - no-grtr
    .WORD SUB_1CF8                      ; $0D - no-less
    .WORD SUB_1CF8                      ; $0E - nos-eql
    .WORD SUB_194C                      ; $0F - addition
    .WORD SUB_1CED                      ; $10 - str-&-no
    .WORD SUB_1CF8                      ; $11 - str-l-eql
    .WORD SUB_1CF8                      ; $12 - str-gr-eql
    .WORD SUB_1CF8                      ; $13 - strs-neql
    .WORD SUB_1CF8                      ; $14 - str-grtr
    .WORD SUB_1CF8                      ; $15 - str-less
    .WORD SUB_1CF8                      ; $16 - strs-eql
    .WORD SUB_1D57                      ; $17 - strs-add
    .WORD SUB_1C95                      ; $18 - neg
    .WORD SUB_1DF5                      ; $19 - code
    .WORD SUB_1D93                      ; $1A - val
    .WORD SUB_1E00                      ; $1B - len
    .WORD SUB_1F38                      ; $1C - sin
    .WORD SUB_1F2D                      ; $1D - cos
    .WORD SUB_1F5D                      ; $1E - tan
    .WORD SUB_1FB3                      ; $1F - asn
    .WORD SUB_1FC3                      ; $20 - acs
    .WORD SUB_1F65                      ; $21 - atn
    .WORD SUB_1E98                      ; $22 - ln
    .WORD SUB_1E4A                      ; $23 - exp
    .WORD SUB_1E35                      ; $24 - int
    .WORD SUB_1FCA                      ; $25 - sqr
    .WORD SUB_1CA4                      ; $26 - sgn
    .WORD SUB_1C9F                      ; $27 - abs
    .WORD SUB_1CB3                      ; $28 - peek
    .WORD SUB_1CBA                      ; $29 - usr-no
    .WORD SUB_1DC4                      ; $2A - str$
    .WORD SUB_1D84                      ; $2B - chrs
    .WORD SUB_1CCA                      ; $2C - not
    .WORD SUB_1BED                      ; $2D - duplicate
    .WORD SUB_1E26                      ; $2E - n-mod-m
    .WORD SUB_1E12                      ; $2F - jump
    .WORD SUB_1BF3                      ; $30 - stk-data
    .WORD SUB_1E06                      ; $31 - dec-jr-nz
    .WORD SUB_1CD0                      ; $32 - less-0
    .WORD SUB_1CC3                      ; $33 - greater-0
    .WORD SUB_002B                      ; $34 - end-calc
    .WORD SUB_1F07                      ; $35 - get-argt
    .WORD SUB_1ADB                      ; $36 - truncate
    .WORD SUB_1BDB                      ; $37 - fp-calc-2
    .WORD SUB_1752                      ; $38 - e-to-fp
    .WORD SUB_1C74                      ; $39 - series-xx    $80 - $9F.
    .WORD SUB_1C39                      ; $3A - stk-const-xx $A0 - $BF.
    .WORD SUB_1C58                      ; $3B - st-mem-xx    $C0 - $DF.
    .WORD SUB_1C2D                      ; $3C - get-mem-xx   $E0 - $FF.

; -------------------------------
; THE 'FLOATING POINT CALCULATOR'
; -------------------------------

; CALCULATE
L_1B94:
    CALL SUB_1D7A

; GEN-ENT-1
SUB_1B97:
    LD A,B
    LD ($401E),A

; GEN-ENT-2
SUB_1B9B:
    EXX
    EX (SP),HL
    EXX

; RE-ENTRY
L_1B9E:
    LD ($401C),DE
    EXX
    LD A,(HL)
    INC HL

; SCAN-ENT
L_1BA5:
    PUSH HL
    AND A
    JP P,L_1BB9
    LD D,A
    AND $60
    RRCA
    RRCA
    RRCA
    RRCA
    ADD A,$72
    LD L,A
    LD A,D
    AND $1F
    JR L_1BC7

; FIRST-3D
L_1BB9:
    CP $18
    JR NC,L_1BC5
    EXX
    LD BC,$FFFB
    LD D,H
    LD E,L
    ADD HL,BC
    EXX

; DOUBLE-A
L_1BC5:
    RLCA
    LD L,A

; ENT-TABLE
L_1BC7:
    LD DE,L_1B1A
    LD H,$00
    ADD HL,DE
    LD E,(HL)
    INC HL
    LD D,(HL)
    LD HL,L_1B9E
    EX (SP),HL
    PUSH DE
    EXX
    LD BC,($401D)

; -----------------------
; THE 'DELETE' SUBROUTINE
; -----------------------

; delete
SUB_1BDA:
    RET

; ---------------------------------
; THE 'SINGLE OPERATION' SUBROUTINE
; ---------------------------------

; fp-calc-2
SUB_1BDB:
    POP AF
    LD A,($401E)
    EXX
    JR L_1BA5

; ------------------------------
; THE 'TEST 5 SPACES' SUBROUTINE
; ------------------------------

; TEST-5-SP
SUB_1BE2:
    PUSH DE
    PUSH HL
    LD BC,$0005
    CALL SUB_10A0
SUB_1BEA:
    POP HL
    POP DE
    RET

; ---------------------------------------------
; THE 'MOVE A FLOATING POINT NUMBER' SUBROUTINE
; ---------------------------------------------

; MOVE-FP
SUB_1BED:
    CALL SUB_1BE2
    LDIR
    RET

; -------------------------------
; THE 'STACK LITERALS' SUBROUTINE
; -------------------------------

; stk-data
SUB_1BF3:
    LD H,D
    LD L,E

; STK-CONST
SUB_1BF5:
    CALL SUB_1BE2
    EXX
    PUSH HL
    EXX
    EX (SP),HL
    PUSH BC
    LD A,(HL)
    AND $C0
    RLCA
    RLCA
    LD C,A
    INC C
    LD A,(HL)
    AND $3F
    JR NZ,L_1C0B
    INC HL
    LD A,(HL)

; FORM-EXP
L_1C0B:
    ADD A,$50
    LD (DE),A
    LD A,$05
    SUB C
    INC HL
    INC DE
    LD B,$00
    LDIR
    POP BC
    EX (SP),HL
    EXX
    POP HL
    EXX
    LD B,A
    XOR A

; STK-ZEROS
L_1C1E:
    DEC B
    RET Z
    LD (DE),A
    INC DE
    JR L_1C1E

; --------------------------------
; THE 'MEMORY LOCATION' SUBROUTINE
; --------------------------------

; LOC-MEM (which came after SKIP-NEXT on the ZX81?)
SUB_1C24:
    LD C,A
    RLCA
    RLCA
    ADD A,C
    LD C,A
    LD B,$00
    ADD HL,BC
    RET

; -------------------------------------
; THE 'GET FROM MEMORY AREA' SUBROUTINE
; -------------------------------------

; get-mem-xx
SUB_1C2D:
    PUSH DE
    LD HL,($401F)
    CALL SUB_1C24
    CALL SUB_1BED
    POP HL
    RET

; ---------------------------------
; THE 'STACK A CONSTANT' SUBROUTINE
; ---------------------------------

; stk-const-xx
SUB_1C39:
    LD H,D
    LD L,E
    EXX
    PUSH HL
    LD HL,L_1B0C
    EXX

; SKIP-CONS (ZX81 was a call rather than drop through)
    AND A

; SKIP-NEXT (ZX81 version is RET Z)
    JR Z,L_1C51

L_1C44:
    PUSH AF
    PUSH DE
    LD DE,$0000
    CALL SUB_1BF5
    POP DE
    POP AF
    DEC A
    JR NZ,L_1C44
L_1C51:
    CALL SUB_1BF5
    EXX
    POP HL
    EXX
    RET

; ---------------------------------------
; THE 'STORE IN A MEMORY AREA' SUBROUTINE
; ---------------------------------------

; st-mem-xx
SUB_1C58:
    PUSH HL
    EX DE,HL
    LD HL,($401F)
    CALL SUB_1C24
    EX DE,HL
    CALL SUB_1BED
    EX DE,HL
    POP HL
    RET

; -------------------------
; THE 'EXCHANGE' SUBROUTINE
; -------------------------

; exchange
SUB_1C67:
    LD B,$05

; SWAP-BYTE
L_1C69:
    LD A,(DE)
    LD C,(HL)
    EX DE,HL
    LD (DE),A
    LD (HL),C
    INC HL
    INC DE
    DJNZ L_1C69
    EX DE,HL
    RET

; ---------------------------------
; THE 'SERIES GENERATOR' SUBROUTINE
; ---------------------------------

; series-xx
SUB_1C74:
    LD B,A
    CALL SUB_1B97
    .BYTE $2D                           ; Duplicate       x,x
    .BYTE $0F                           ; Addition        x+x
    .BYTE $C0                           ; St-mem-0        x+x
    .BYTE $02                           ; Delete          .
    .BYTE $A0                           ; Stk-zero        0
    .BYTE $C2                           ; St-mem-2        0
;; G-LOOP
    .BYTE $2D                           ; Duplicate       v,v.
    .BYTE $E0                           ; Get-mem-0       v,v,x+2
    .BYTE $04                           ; Multiply        v,v*x+2
    .BYTE $E2                           ; Get-mem-2       v,v*x+2,v
    .BYTE $C1                           ; St-mem-1
    .BYTE $03                           ; Subtract
    .BYTE $34                           ; End-calc

    CALL SUB_1BF3
    CALL SUB_1B9B

    .BYTE $0F                           ; Addition
    .BYTE $01                           ; Exchange
    .BYTE $C2                           ; St-mem-2
    .BYTE $02                           ; Delete
    .BYTE $31                           ; Dec-jr-nz
    .BYTE $EE                           ; Back to L1A89, G-LOOP
    .BYTE $E1                           ; Get-mem-1
    .BYTE $03                           ; Subtract
    .BYTE $34                           ; End-calc
    RET

; -----------------------
; Handle unary minus (18)
; -----------------------

; negate
SUB_1C95:
    LD A,(HL)
    AND A
    RET Z
    INC HL
    LD A,(HL)
    XOR $80
    LD (HL),A
    DEC HL
    RET

; -----------------------
; Absolute magnitude (27)
; -----------------------

; abs
SUB_1C9F:
    INC HL
    RES 7,(HL)
    DEC HL
    RET

; -----------
; Signum (26)
; -----------

; sgn
SUB_1CA4:
    INC HL
    LD A,(HL)
    DEC HL
    DEC (HL)
    INC (HL)
    SCF
    CALL NZ,SUB_1CD5
    INC HL
    RLCA
    RR (HL)
    DEC HL
    RET

; -------------------------
; Handle PEEK function (28)
; -------------------------

; peek
SUB_1CB3:
    CALL SUB_1088
    LD A,(BC)
    JP SUB_1715

; ---------------
; USR number (29)
; ---------------

; usr-no
SUB_1CBA:
    CALL SUB_1088
    LD HL,SUB_1718
    PUSH HL
    PUSH BC
    RET

; -----------------------
; Greater than zero ($33)
; -----------------------

; greater-0
SUB_1CC3:
    LD A,(HL)
    AND A
    RET Z
    LD A,$FF
    JR L_1CD1


; -------------------------
; Handle NOT operator ($2C)
; -------------------------

; not
SUB_1CCA:
    LD A,(HL)
    NEG
    CCF
    JR SUB_1CD5


; -------------------
; Less than zero (32)
; -------------------

; less-0
SUB_1CD0:
    XOR A

; SIGN-TO-C
L_1CD1:
    INC HL
    XOR (HL)
    DEC HL
    RLCA

; -----------
; Zero or one
; -----------

; FP-0/1
SUB_1CD5:
    PUSH HL
    LD B,$05

; FP-loop
L_1CD8:
    LD (HL),$00
    INC HL
    DJNZ L_1CD8
    POP HL
    RET NC
    LD (HL),$81
    RET


; -----------------------
; Handle OR operator (07)
; -----------------------

; or
SUB_1CE2:
    LD A,(DE)
    AND A
    RET Z
    SCF
    JR SUB_1CD5


; -----------------------------
; Handle number AND number (08)
; -----------------------------

; no-&-no
SUB_1CE8:
    LD A,(DE)
    AND A
    RET NZ
    JR SUB_1CD5

; -----------------------------
; Handle string AND number (10)
; -----------------------------

; str-&-no
SUB_1CED:
    LD A,(DE)
    AND A
    RET NZ
    PUSH DE
    DEC DE
    XOR A
    LD (DE),A
    DEC DE
    LD (DE),A
    POP DE
    RET

; -------------------------------------
; Perform comparison ($09-$0E, $11-$16)
; -------------------------------------

; no-l-eql,etc.
SUB_1CF8:
    LD A,B
    SUB $08
    BIT 2,A
    JR NZ,L_1D00
    DEC A

; EX-OR-NOT
L_1D00:
    RRCA
    JR NC,L_1D0B
    PUSH AF
    PUSH HL
    CALL SUB_1C67
    POP DE
    EX DE,HL
    POP AF

; NU-OR-STR
L_1D0B:
    BIT 2,A
    JR NZ,L_1D16
    RRCA
    PUSH AF
    CALL SUB_1943
    JR L_1D49

; STRINGS
L_1D16:
    RRCA
    PUSH AF
    CALL SUB_15ED                       ; Routine STK-FETCH
    PUSH DE
    PUSH BC
    CALL SUB_15ED                       ; Routine STK-FETCH
    POP HL

; BYTE-COMP
L_1D21:
    LD A,H
    OR L
    EX (SP),HL
    LD A,B
    JR NZ,L_1D32
    OR C

; SECND-LOW
L_1D28:
    POP BC
    JR Z,L_1D2F
    POP AF
    CCF
    JR L_1D45

; BOTH-NULL
L_1D2F:
    POP AF
    JR L_1D45

; SEC-PLUS
L_1D32:
    OR C
    JR Z,L_1D42
    LD A,(DE)
    SUB (HL)
    JR C,L_1D42
    JR NZ,L_1D28
    DEC BC
    INC DE
    INC HL
    EX (SP),HL
    DEC HL
    JR L_1D21

; FRST-LESS
L_1D42:
    POP BC
    POP AF
    AND A

; STR-TEST
L_1D45:
    PUSH AF
    RST 28H                             ; FP-CALC
    .BYTE $A0                           ; Stk-zero      an initial false value.
    .BYTE $34                           ; End-calc

; END-TESTS
L_1D49:
    POP AF
    PUSH AF
    CALL C,SUB_1CCA
    CALL SUB_1CC3
    POP AF
    RRCA
    CALL NC,SUB_1CCA
    RET

; -------------------------
; String concatenation ($17)
; -------------------------

; strs-add
SUB_1D57:
    CALL SUB_15ED                       ; Routine STK-FETCH
    PUSH DE
    PUSH BC
    CALL SUB_15ED                       ; Routine STK-FETCH
    POP HL
    PUSH HL
    PUSH DE
    PUSH BC
    ADD HL,BC
    LD B,H
    LD C,L
    RST 30H
    CALL SUB_14B8
    POP BC
    POP HL
    LD A,B
    OR C
    JR Z,L_1D72
    LDIR

; OTHER-STR
L_1D72:
    POP BC
    POP HL
    LD A,B
    OR C
    JR Z,SUB_1D7A
    LDIR

; --------------------
; Check stack pointers
; --------------------

; STK-PNTRS
SUB_1D7A:
    LD HL,($401C)
    LD DE,$FFFB
    PUSH HL
    ADD HL,DE
    POP DE
    RET

; ----------------
; Handle CHR$ (2B)
; ----------------

; chrs
SUB_1D84:
    CALL SUB_1083                       ; Modified from ZX81 to inline REPORT-Bd
    PUSH AF
    LD BC,$0001
    RST 30H
    POP AF
    LD (DE),A
    CALL SUB_14B8
    EX DE,HL
    RET

; ----------------
; Handle VAL ($1A)
; ----------------

; val
SUB_1D93:
    LD HL,($4016)                       ; CH.ADD - Address of next character to interpret
    PUSH HL
    CALL SUB_15ED                       ; Routine STK-FETCH
    PUSH DE
    INC BC
    RST 30H
    POP HL
    LD ($4016),DE                       ; CH.ADD
    PUSH DE
    LDIR
    EX DE,HL
    DEC HL
    LD (HL),$76
    RES 7,(IY+$01)
    CALL SUB_0F0F
    CALL L_0E9F
    POP HL
    LD ($4016),HL                       ; CH.ADD
    SET 7,(IY+$01)
    CALL SUB_114A                       ; Routine SCANNING
    POP HL
    LD ($4016),HL                       ; CH.ADD
    JR SUB_1D7A

; ----------------
; Handle STR$ (2A)
; ----------------

; str$
SUB_1DC4:
    LD BC,$0001
    RST 30H
    LD (HL),$76
    LD HL,($4039)
    PUSH HL
    LD L,$FF
    LD ($4039),HL
    LD HL,($400E)
    PUSH HL
    LD ($400E),DE
    PUSH DE
    CALL L_17D3
    POP DE
    LD HL,($400E)
    AND A
    SBC HL,DE
    LD B,H
    LD C,L
    POP HL
    LD ($400E),HL
    POP HL
    LD ($4039),HL
    CALL SUB_14B8
    EX DE,HL
    RET

; ------------------------
; THE 'CODE' FUNCTION (19)
; ------------------------

; code
SUB_1DF5:
    CALL SUB_15ED                       ; Routine STK-FETCH
    LD A,B
    OR C
    JR Z,L_1DFD
    LD A,(DE)

; STK-CODE
L_1DFD:
    JP SUB_1715

; -------------------------
; THE 'LEN' SUBROUTINE (1B)
; -------------------------

; len
SUB_1E00:
    CALL SUB_15ED                       ; Routine STK-FETCH
    JP SUB_1718

; ------------------------------------------
; THE 'DECREASE THE COUNTER' SUBROUTINE (31)
; ------------------------------------------

; dec-jr-nz
SUB_1E06:
    EXX
    PUSH HL
    LD HL,$401E
    DEC (HL)
    POP HL
    JR NZ,L_1E13
    INC HL
    EXX
    RET

; --------------------------
; THE 'JUMP' SUBROUTINE (2F)
; --------------------------

; jump
SUB_1E12:
L_1E12:
    EXX

; JUMP-2
L_1E13:
    LD E,(HL)
    XOR A
    BIT 7,E
    JR Z,L_1E1A
    CPL

; JUMP-3
L_1E1A:
    LD D,A
    ADD HL,DE
    EXX
    RET

; ----------------------------------
; THE 'JUMP ON TRUE' SUBROUTINE (00)
; ----------------------------------

; jump-true
SUB_1E1E:
    LD A,(DE)
    AND A
    JR NZ,L_1E12
    EXX
    INC HL
    EXX
    RET

; -----------------------------
; THE 'MODULUS' SUBROUTINE (2E)
; -----------------------------

; n-mod-m
SUB_1E26:
    RST 28H                             ; FP_CALC
    .BYTE $C0                           ; St-mem-0          17, 3.
    .BYTE $02                           ; Delete            17.
    .BYTE $2D                           ; Duplicate         17, 17.
    .BYTE $E0                           ; Get-mem-0         17, 17, 3.
    .BYTE $05                           ; Division          17, 17/3.
    .BYTE $24                           ; Int               17, 5.
    .BYTE $E0                           ; Get-mem-0         17, 5, 3.
    .BYTE $01                           ; Exchange          17, 3, 5.
    .BYTE $C0                           ; St-mem-0          17, 3, 5.
    .BYTE $04                           ; Multiply          17, 15.
    .BYTE $03                           ; Subtract          2.
    .BYTE $E0                           ; Get-mem-0         2, 5.
    .BYTE $34                           ; End-calc          2, 5.
    RET

; ---------------------------
; THE 'INTEGER' FUNCTION (24)
; ---------------------------

; int
SUB_1E35:
    RST 28H                             ; FP-CALC              x.    (= 3.4 or -3.4).
    .BYTE $2D                           ; Duplicate             x, x.
    .BYTE $32                           ; Less-0                x, (1/0)
    .BYTE $00                           ; Jump-true             x, (1/0)
    .BYTE $04                           ; To L1C46, X-NEG

    .BYTE $36                           ; Truncate              trunc 3.4 = 3.
    .BYTE $34                           ; End-calc              3.
    RET

; X-NEG
    .BYTE $2D                           ; Duplicate             -3.4, -3.4.
    .BYTE $36                           ; Truncate              -3.4, -3.
    .BYTE $C0                           ; St-mem-0              -3.4, -3.
    .BYTE $03                           ; Subtract              -.4
    .BYTE $E0                           ; Get-mem-0             -.4, -3.
    .BYTE $01                           ; Exchange              -3, -.4.
    .BYTE $2C                           ; Not                   -3, (0).
    .BYTE $00                           ; Jump-true             -3.
    .BYTE $03                           ; To L1C59, EXIT        -3.

    .BYTE $A1                           ; Stk-one               -3, 1.
    .BYTE $03                           ; Subtract              -4.

;; EXIT
    .BYTE $34                           ; End-calc              -4.
    RET

; ----------------
; Exponential (23)
; ----------------
; EXP
SUB_1E4A:
L_1E4A:
    RST 28H
    .BYTE $30                           ; Stk-data
    .BYTE $F1                           ; Exponent: $81, Bytes: 4
    .BYTE $38,$AA,$3B,$29
    .BYTE $04                           ; Multiply
    .BYTE $2D                           ; Duplicate
    .BYTE $24                           ; Int
    .BYTE $C3                           ; St-mem-3
    .BYTE $03                           ; Subtract
    .BYTE $2D                           ; Duplicate
    .BYTE $0F                           ; Addition
    .BYTE $A1                           ; Stk-one
    .BYTE $03                           ; Subtract
    .BYTE $88                           ; Series-08
    .BYTE $13                           ; Exponent: $63, Bytes: 1
    .BYTE $36                           ; (+00,+00,+00)
    .BYTE $58                           ; Exponent: $68, Bytes: 2
    .BYTE $65,$66                       ; (+00,+00)
    .BYTE $9D                           ; Exponent: $6D, Bytes: 3
    .BYTE $78,$65,$40                   ; (+00)
    .BYTE $A2                           ; Exponent: $72, Bytes: 3
    .BYTE $60,$32,$C9                   ; (+00)
    .BYTE $E7                           ; Exponent: $77, Bytes: 4
    .BYTE $21,$F7,$AF,$24
    .BYTE $EB                           ; Exponent: $7B, Bytes: 4
    .BYTE $2F,$B0,$B0,$14
    .BYTE $EE                           ; Exponent: $7E, Bytes: 4
    .BYTE $7E,$BB,$94,$58
    .BYTE $F1                           ; Exponent: $81, Bytes: 4
    .BYTE $3A,$7E,$F8,$CF
    .BYTE $E3                           ; Get-mem-3
    .BYTE $34                           ; End-calc

    CALL SUB_17C5
    JR NZ,L_1E8A
    JR C,L_1E88
    ADD A,(HL)
    JR NC,L_1E91

; REPORT-6b
L_1E88:
    RST 08H                             ; ERROR-1
    .BYTE $05                           ; OV arithmetic OVerflow

; N-NEGTV
L_1E8A:
    JR C,L_1E93
    SUB (HL)
    JR NC,L_1E93
    NEG

; RESULT-OK
L_1E91:
    LD (HL),A
    RET

; RSLT-ZERO
L_1E93:
    RST 28H                             ; FP-CALC
    .BYTE $02                           ; Delete
    .BYTE $A0                           ; Stk-zero
    .BYTE $34                           ; End-calc
    RET


; -------------------------------------
; THE 'NATURAL LOGARITHM' FUNCTION (22)
; -------------------------------------

; ln
SUB_1E98:
    RST 28H                             ; FP-CALC
    .BYTE $2D                           ; Duplicate
    .BYTE $33                           ; Greater-0
    .BYTE $00                           ; Jump-true
    .BYTE $04                           ; To L1CB1, VALID
    .BYTE $34                           ; End-calc

; REPORT-Ab
    RST 08H                             ; ERROR-1
    .BYTE $09                           ; AG invalid ArGument

; VALID
    .BYTE $A0                           ; Stk-zero              Note. not
    .BYTE $02                           ; Delete                necessary.
    .BYTE $34                           ; End-calc
    LD A,(HL)
    LD (HL),$80
    CALL SUB_1715
    RST 28H                             ; FP-CALC
    .BYTE $30                           ; Stk-data
    .BYTE $38                           ; Exponent: $88, Bytes: 1
    .BYTE $00                           ; (+00,+00,+00)
    .BYTE $03                           ; Subtract
    .BYTE $01                           ; Exchange
    .BYTE $2D                           ; Duplicate
    .BYTE $30                           ; Stk-data
    .BYTE $F0                           ; Exponent: $80, Bytes: 4
    .BYTE $4C,$CC,$CC,$CD
    .BYTE $03                           ; Subtract
    .BYTE $33                           ; Greater-0
    .BYTE $00                           ; Jump-true
    .BYTE $08                           ; To L1CD2, GRE.8

    .BYTE $01                           ; Exchange
    .BYTE $A1                           ; Stk-one
    .BYTE $03                           ; Subtract
    .BYTE $01                           ; Exchange
    .BYTE $34                           ; End-calc
    INC (HL)

    RST 28H                             ; FP-CALC

;; GRE.8
    .BYTE $01                           ; Exchange
    .BYTE $30                           ; Stk-data
    .BYTE $F0                           ; Exponent: $80, Bytes: 4
    .BYTE $31,$72,$17,$F8
    .BYTE $04                           ; Multiply
    .BYTE $01                           ; Exchange
    .BYTE $A2                           ; Stk-half
    .BYTE $03                           ; Subtract
    .BYTE $A2                           ; Stk-half
    .BYTE $03                           ; Subtract
    .BYTE $2D                           ; Duplicate
    .BYTE $30                           ; Stk-data
    .BYTE $32                           ; Exponent: $82, Bytes: 1
    .BYTE $20                           ; (+00,+00,+00)
    .BYTE $04                           ; Multiply
    .BYTE $A2                           ; Stk-half
    .BYTE $03                           ; Subtract
    .BYTE $8C                           ; Series-0C
    .BYTE $11                           ; Exponent: $61, Bytes: 1
    .BYTE $AC                           ; (+00,+00,+00)
    .BYTE $14                           ; Exponent: $64, Bytes: 1
    .BYTE $09                           ; (+00,+00,+00)
    .BYTE $56                           ; Exponent: $66, Bytes: 2
    .BYTE $DA,$A5                       ; (+00,+00)
    .BYTE $59                           ; Exponent: $69, Bytes: 2
    .BYTE $30,$C5                       ; (+00,+00)
    .BYTE $5C                           ; Exponent: $6C, Bytes: 2
    .BYTE $90,$AA                       ; (+00,+00)
    .BYTE $9E                           ; Exponent: $6E, Bytes: 3
    .BYTE $70,$6F,$61                   ; (+00)
    .BYTE $A1                           ; Exponent: $71, Bytes: 3
    .BYTE $CB,$DA,$96                   ; (+00)
    .BYTE $A4                           ; Exponent: $74, Bytes: 3
    .BYTE $31,$9F,$B4                   ; (+00)
    .BYTE $E7                           ; Exponent: $77, Bytes: 4
    .BYTE $A0,$FE,$5C,$FC
    .BYTE $EA                           ; Exponent: $7A, Bytes: 4
    .BYTE $1B,$43,$CA,$36
    .BYTE $ED                           ; Exponent: $7D, Bytes: 4
    .BYTE $A7,$9C,$7E,$5E
    .BYTE $F0                           ; Exponent: $80, Bytes: 4
    .BYTE $6E,$23,$80,$93
    .BYTE $04                           ; Multiply
    .BYTE $0F                           ; Addition
    .BYTE $34                           ; End-calc
    RET


; -----------------------------
; THE 'TRIGONOMETRIC' FUNCTIONS
; -----------------------------

;----- --------------------------------
; THE 'REDUCE ARGUMENT' SUBROUTINE (35)
; -------------------------------------

; get-argt
SUB_1F07:
    RST 28H                             ; FP-CALC         X.
    .BYTE $30                           ; Stk-data
    .BYTE $EE                           ; Exponent: $7E,
                                        ; Bytes: 4
    .BYTE $22,$F9,$83,$6E               ;  X, 1/(2*PI)
    .BYTE $04                           ; Multiply         X/(2*PI) = fraction

    .BYTE $2D                           ; Duplicate
    .BYTE $A2                           ; Stk-half
    .BYTE $0F                           ; Addition
    .BYTE $24                           ; Int

    .BYTE $03                           ; Subtract         now range -.5 to .5

    .BYTE $2D                           ; Duplicate
    .BYTE $0F                           ; Addition         now range -1 to 1.
    .BYTE $2D                           ; Duplicate
    .BYTE $0F                           ; Addition         now range -2 to 2.

    .BYTE $2D                           ; Duplicate        Y, Y.
    .BYTE $27                           ; Abs              Y, abs(Y).    range 1 to 2
    .BYTE $A1                           ; Stk-one          Y, abs(Y), 1.
    .BYTE $03                           ; Subtract         Y, abs(Y)-1.  range 0 to 1
    .BYTE $2D                           ; Duplicate        Y, Z, Z.
    .BYTE $33                           ; Greater-0        Y, Z, (1/0).

    .BYTE $C0                           ; St-mem-0         store as possible sign for cosine function.

    .BYTE $00                           ; Jump-true
    .BYTE $04                           ; To L1D35, ZPLUS  with quadrants II and III

    .BYTE $02                           ; Delete          Y    delete test value.
    .BYTE $34                           ; End-calc        Y.

    RET

; ZPLUS
    .BYTE $A1                           ; Stk-one         Y, Z, 1
    .BYTE $03                           ; Subtract        Y, Z-1.       Q3 = 0 to -1
    .BYTE $01                           ; Exchange        Z-1, Y.
    .BYTE $32                           ; Less-0          Z-1, (1/0).
    .BYTE $00                           ; Jump-true       Z-1.
    .BYTE $02                           ; To L1D3C, YNEG
    .BYTE $18                           ; Negate          range +1 to 0
;; YNEG
    .BYTE $34                           ; End-calc        quadrants II and III correct.
    RET


; --------------------------
; THE 'COSINE' FUNCTION (1D)
; --------------------------

; cos
SUB_1F2D:
    RST 28H                             ; FP-CALC              angle in radians.
    .BYTE $35                           ; Get-argt              X       reduce -1 to +1
    .BYTE $27                           ; Abs                   ABS X   0 to 1
    .BYTE $A1                           ; Stk-one               ABS X, 1.
    .BYTE $03                           ; Subtract              now opposite angle
                                        ;                       though negative sign.
    .BYTE $E0                           ; Get-mem-0             fetch sign indicator.
    .BYTE $00                           ; Jump-true
    .BYTE $06                           ; Fwd to L1D4B, C-ENT
                                        ; Forward to common code if in QII or QIII
    .BYTE $18                           ; Negate                else make positive.
    .BYTE $2F                           ; Jump
    .BYTE $03                           ; Fwd to L1D4B, C-ENT
                                        ; With quadrants QI and QIV

; ------------------------
; THE 'SINE' FUNCTION (1C)
; ------------------------

; sin
SUB_1F38:
    RST 28H                             ; FP-CALC      angle in radians
    .BYTE $35                           ; Get-argt      reduce - sign now correct.

;; C-ENT
    .BYTE $2D                           ; Duplicate
    .BYTE $2D                           ; Duplicate
    .BYTE $04                           ; Multiply
    .BYTE $2D                           ; Duplicate
    .BYTE $0F                           ; Addition
    .BYTE $A1                           ; Stk-one
    .BYTE $03                           ; Subtract

    .BYTE $86                           ; Series-06
    .BYTE $14                           ; Exponent: $64, Bytes: 1
    .BYTE $E6                           ; (+00,+00,+00)
    .BYTE $5C                           ; Exponent: $6C, Bytes: 2
    .BYTE $1F,$0B                       ; (+00,+00)
    .BYTE $A3                           ; Exponent: $73, Bytes: 3
    .BYTE $8F,$38,$EE                   ; (+00)
    .BYTE $E9                           ; Exponent: $79, Bytes: 4
    .BYTE $15,$63,$BB,$23
    .BYTE $EE                           ; Exponent: $7E, Bytes: 4
    .BYTE $92,$0D,$CD,$ED
    .BYTE $F1                           ; Exponent: $81, Bytes: 4
    .BYTE $23,$5D,$1B,$EA

    .BYTE $04                           ; Multiply
    .BYTE $34                           ; End-calc
    RET

; ---------------------------
; THE 'TANGENT' FUNCTION (1E)
; ---------------------------

;; tan
SUB_1F5D:
    RST 28H                             ; FP-CALC          x.
    .BYTE $2D                           ; Duplicate         x, x.
    .BYTE $1C                           ; Sin               x, sin x.
    .BYTE $01                           ; Exchange          sin x, x.
    .BYTE $1D                           ; Cos               sin x, cos x.
    .BYTE $05                           ; Division          sin x/cos x (= tan x).
    .BYTE $34                           ; End-calc          tan x.
    RET

; --------------------------
; THE 'ARCTAN' FUNCTION (21)
; --------------------------

; atn
SUB_1F65:
    LD A,(HL)
    CP $81
    JR C,L_1F78
    RST 28H                             ; FP-CALC      X.
    .BYTE $A1                           ; Stk-one
    .BYTE $18                           ; Negate
    .BYTE $01                           ; Exchange
    .BYTE $05                           ; Division
    .BYTE $2D                           ; Duplicate
    .BYTE $32                           ; Less-0
    .BYTE $A3                           ; Stk-pi/2
    .BYTE $01                           ; Exchange
    .BYTE $00                           ; Jump-true
    .BYTE $06                           ; To L1D8B, CASES

    .BYTE $18                           ; Negate
    .BYTE $2F                           ; Jump
    .BYTE $03                           ; To L1D8B, CASES

L_1F78:
; SMALL
    RST 28H                             ; FP-CALC
    .BYTE $A0                           ; Stk-zero

;; CASES
    .BYTE $01                           ; Exchange
    .BYTE $2D                           ; Duplicate
    .BYTE $2D                           ; Duplicate
    .BYTE $04                           ; Multiply
    .BYTE $2D                           ; Duplicate
    .BYTE $0F                           ; Addition
    .BYTE $A1                           ; Stk-one
    .BYTE $03                           ; Subtract

    .BYTE $8C                           ; Series-0C
    .BYTE $10                           ; Exponent: $60, Bytes: 1
    .BYTE $B2                           ; (+00,+00,+00)
    .BYTE $13                           ; Exponent: $63, Bytes: 1
    .BYTE $0E                           ; (+00,+00,+00)
    .BYTE $55                           ; Exponent: $65, Bytes: 2
    .BYTE $E4,$8D                       ; (+00,+00)
    .BYTE $58                           ; Exponent: $68, Bytes: 2
    .BYTE $39,$BC                       ; (+00,+00)
    .BYTE $5B                           ; Exponent: $6B, Bytes: 2
    .BYTE $98,$FD                       ; (+00,+00)
    .BYTE $9E                           ; Exponent: $6E, Bytes: 3
    .BYTE $00,$36,$75                   ; (+00)
    .BYTE $A0                           ; Exponent: $70, Bytes: 3
    .BYTE $DB,$E8,$B4                   ; (+00)
    .BYTE $63                           ; Exponent: $73, Bytes: 2
    .BYTE $42,$C4                       ; (+00,+00)
    .BYTE $E6                           ; Exponent: $76, Bytes: 4
    .BYTE $B5,$09,$36,$BE
    .BYTE $E9                           ; Exponent: $79, Bytes: 4
    .BYTE $36,$73,$1B,$5D
    .BYTE $EC                           ; Exponent: $7C, Bytes: 4
    .BYTE $D8,$DE,$63,$BE
    .BYTE $F0                           ; Exponent: $80, Bytes: 4
    .BYTE $61,$A1,$B3,$0C

    .BYTE $04                           ; Multiply
    .BYTE $0F                           ; Addition
    .BYTE $34                           ; End-calc
    RET

; --------------------------
; THE 'ARCSIN' FUNCTION (1F)
; --------------------------
;; asn
SUB_1FB3:
    RST 28H                             ; FP-CALC      x.
    .BYTE $2D                           ; Duplicate     x, x.
    .BYTE $2D                           ; Duplicate     x, x, x.
    .BYTE $04                           ; Multiply      x, x*x.
    .BYTE $A1                           ; Stk-one       x, x*x, 1.
    .BYTE $03                           ; Subtract      x, x*x-1.
    .BYTE $18                           ; Negate        x, 1-x*x.
    .BYTE $25                           ; Sqr           x, sqr(1-x*x) = y.
    .BYTE $A1                           ; Stk-one       x, y, 1.
    .BYTE $0F                           ; Addition      x, y+1.
    .BYTE $05                           ; Division      x/y+1.
    .BYTE $21                           ; Atn           a/2     (half the angle)
    .BYTE $2D                           ; Duplicate     a/2, a/2.
    .BYTE $0F                           ; Addition      a.
    .BYTE $34                           ; End-calc      a.
    RET

; --------------------------
; THE 'ARCCOS' FUNCTION (20)
; --------------------------

;; acs
SUB_1FC3:
    RST 28H                             ; FP-CALC      x.
    .BYTE $1F                           ; Asn           asn(x).
    .BYTE $A3                           ; Stk-pi/2      asn(x), pi/2.
    .BYTE $03                           ; Subtract      asn(x) - pi/2.
    .BYTE $18                           ; Negate        pi/2 - asn(x) = acs(x).
    .BYTE $34                           ; End-calc      acs(x)
    RET

; -------------------------------
; THE 'SQUARE ROOT' FUNCTION (25)
; -------------------------------

; sqr
SUB_1FCA:
    RST 28H                             ; FP-CALC              x.
    .BYTE $2D                           ; Duplicate             x, x.
    .BYTE $2C                           ; Not                   x, 1/0
    .BYTE $00                           ; Jump-true             x, (1/0).
    .BYTE $1E                           ; To L1DFD, LAST        exit if argument zero
    .BYTE $A2                           ; Stk-half              x, .5.
    .BYTE $34                           ; End-calc              x, .5.

; -----------------------------------
; THE 'EXPONENTIATION' OPERATION (06)
; -----------------------------------

; to-power
SUB_1FD1:
    RST 28H                             ; FP-CALC              X,Y.
    .BYTE $01                           ; Exchange              Y,X.
    .BYTE $2D                           ; Duplicate             Y,X,X.
    .BYTE $2C                           ; Not                   Y,X,(1/0).
    .BYTE $00                           ; Jump-true
    .BYTE $07                           ; Forward to L1DEE, XISO if X is zero.

;   else X is non-zero. function 'ln' will catch a negative value of X.

    .BYTE $22                           ; Ln                    Y, LN X.
    .BYTE $04                           ; Multiply              Y * LN X
    .BYTE $34                           ; End-calc
    JP L_1E4A

; XISO
    .BYTE $02                           ; Delete                Y.
    .BYTE $2D                           ; Duplicate             Y, Y.
    .BYTE $2C                           ; Not                   Y, (1/0).
    .BYTE $00                           ; Jump-true
    .BYTE $09                           ; Forward to L1DFB, ONE if Y is zero.
    .BYTE $A0                           ; Stk-zero              Y, 0.
    .BYTE $01                           ; Exchange              0, Y.
    .BYTE $33                           ; Greater-0             0, (1/0).
    .BYTE $00                           ; Jump-true             0
    .BYTE $06                           ; To L1DFD, LAST        if Y was any positive number.
    .BYTE $A1                           ; Stk-one               0, 1.
    .BYTE $01                           ; Exchange              1, 0.
    .BYTE $05                           ; Division              1/0    >> error
; ONE
    .BYTE $02                           ; Delete                .
    .BYTE $A1                           ; Stk-one               1.

; LAST
    .BYTE $34                           ; End-calc              last value 1 or 0.
    RET

; ---------------------
; THE 'SPARE LOCATIONS'
; ---------------------

; SPARE
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP

.END
