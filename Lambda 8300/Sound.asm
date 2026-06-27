;###########################################################
; Sound functions for Lambda 8300 BASIC for the Minstrel 4th
; Dave Curran 2026-06-20
;###########################################################

;##############################################################################
; Play Note
; E = note, defined as 32500Hz/E, so (0=256=>127Hz) to (1=>32.5KHz)
; BC = duration, defined as BC/65ms, so (1=>15ms) to (0=65536=>1 second)
; Two entry points, key beep, error and SOUND use PLAY_NOTE, MUSIC uses PLAY_NOTE_2

PLAY_NOTE:
; speaker on
    XOR A                               ; Clear A so save output (bit 5) stays low
    OUT ($FE),A                         ; Speaker on    
    LD D,E                              ; Load note period into D

; first loop, after speaker is on
PLAY_NOTE_2:
    DEC BC                              ; Count down duration
    LD A,B                              ; Check if BC=0    
    OR C                                ; 
    RET Z                               ; If BC=0 exit here
    DEC D                               ; Count down note    
    JR Z,_PLAY_NOTE_3                   ; Note countdown complete, speaker off
    NOP                                 ; Loop timing
    NOP                                 ;
    JR PLAY_NOTE_2                      ; Loop until note or duration complete

; speaker off
_PLAY_NOTE_3:
    IN A,($FE)                          ; Speaker off
    LD D,E                              ; Load note period into D

; second loop, with speaker off
_PLAY_NOTE_4:
    DEC BC                              ; Count down duration
    LD A,B                              ; Check if BC=0    
    OR C                                ; 
    RET Z                               ; If BC=0 exit here
    DEC D                               ; Count down note    
    JR Z,PLAY_NOTE                      ; Note countdown complete, speaker on
    NOP                                 ; Loop timing
    NOP                                 ;
    JR _PLAY_NOTE_4                     ; Loop until note or duration complete

