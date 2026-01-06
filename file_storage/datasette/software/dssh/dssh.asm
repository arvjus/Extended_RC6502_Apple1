; Datasette Shell
; Copyright (c) 2025 Arvid Juskaitis

VERSION = "1.0"

.if FIRMWARE
*   = $F000
RESET:
; reset vector init
    ldy #$7F        ; Mask for DSP data direction register.
    sty DSP         ; Set it up.
    lda #$A7        ; KBD and DSP control register mask.
    sta KBDCR       ; Enable interrupts, set CA1, CB1, for
    sta DSPCR       ; positive edge sense/output mode.
    jmp dssh_init

    .include "defs.asm"
    .include "delay.asm" 
    .include "common.asm" 
    .include "read.asm" 
    .include "write.asm" 
.else
    .include "bss.asm"
*   = $7000
    jmp dssh_init

    .include "defs.asm"
    .include "system.asm" 
    .include "delay.asm" 
    .include "common.asm" 
    .include "read.asm" 
    .include "write.asm" 
.endif

dssh_init:
; do cpu init
    sei             ; Disable interrupts
    cld             ; Clear decimal mode
    ldx #$ff        ; Initialize stack pointer
    txs

; Init ACIA
    lda #%00000011  ; $02 master reset
    sta ACIA_CTRL
    ;lda #%00010101 ; $15 115200 baud 8-n-1
    lda #%00010110  ; $16 28800 baud 8-n-1
    sta ACIA_CTRL

; init ZP variables
    lda #0
    sta prefix      ; clear prefix buffer
    lda #$00        ; Default to WozMon
    sta prg_start
    lda #$ff
    sta prg_start+1
    lda #CR
    jsr ECHO

    SET_PTR welcome
    jsr print_msg

menu:
; print prompt
    lda #'$'
    jsr ECHO
; read command dline
    ldx #0
menu_input:
    jsr KBDIN
    jsr ECHO
    sta buffer, x
    cmp #BS
    beq menu_input_back
    cmp #ESC
    beq exit
    cmp #CR
    beq menu_process
    inx
    jmp menu_input
menu_input_back:
    cpx #0
    beq menu_input
    dex 
    jmp menu_input
; process command
menu_process:
    lda #0          ; replaece CR with #0
    sta buffer, x
    sta buffer+1, x ; arg for e.g. 'LS' must be #0 or valid string
    lda buffer+2    ; SP or 0 is expected
    beq menu_process_cont
    cmp #' '
    bne unknown_cmd
menu_process_cont:
    lda buffer      ; 1st cmd byte
    ldx buffer+1    ; 2nd cmd byte
    ldy #0          ; index in cmd_table

search_command:
    lda cmd_table,y
    beq unknown_cmd ; end of cmd_table
    cmp buffer      ; cmp first character
    bne next_cmd
    lda cmd_table+1,y
    cmp buffer+1    ; cmp second character
    bne next_cmd

    ; jump to address
    lda cmd_table+2, y
    sta ptr
    lda cmd_table+3, y
    sta ptr+1
    jmp (ptr)

next_cmd:
    iny
    iny
    iny
    iny
    bne search_command

unknown_cmd:
    SET_PTR help
    jsr print_msg
    jmp menu

; Exit to WozMon
exit:   
    jmp do_jmp_loader
    jmp $ff00           ; WozMon entry

do_write:
    jsr write
    jmp menu
do_save:
    jsr save
    jmp menu
do_load:
    jsr read
    jmp menu
do_run:
    lda type
    bne jmp_prog
    jmp menu
jmp_prog:    
    cmp #2              ; basic
    beq do_jmp_basic
    jmp (prg_start)     ; address must be set by loading or saving file
do_jmp_basic:
    jmp $e2b3           ; BASIC warm entry
do_jmp_loader:
    jmp $f800           ; loader's entry
     
; Command table format:
; 2 bytes: command prefix
; 2 bytes: jump address (low/high)
cmd_table:
    .byte 'W', 'R', <do_write,      >do_write
    .byte 'S', 'V', <do_save,       >do_save
    .byte 'L', 'D', <do_load,       >do_load
    .byte 'R', 'N', <do_run,        >do_run
    .byte 'J', 'B', <do_jmp_basic,  >do_jmp_basic
    .byte 'J', 'L', <do_jmp_loader, >do_jmp_loader
    .byte 0          ; End of table marker

welcome:
.if REAL_HW
    .text "Datasette Shell v", VERSION, " by Arvid Juskaitis", 13
.endif
    .text 0
help:
.if REAL_HW
    .text "WR <filename>#start#stop", 13
    .text "SV <filename>", 13
    .text "LD", 13
    .text "RN", 13
.endif
    .text 0
