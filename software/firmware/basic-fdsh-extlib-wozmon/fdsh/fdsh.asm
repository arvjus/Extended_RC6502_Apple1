; Flash Disk Shell
; Copyright (c) 2025 Arvid Juskaitis

REAL_HW = 1
MOCK_HW = 0
DEBUG = 0       ; 1=Show traces in data exchange
VERSION = "1.0"
    
*   = $F000
    
FDSH:    
    cld             ; Clear decimal arithmetic mode.
    cli
    ldy #$7F        ; Mask for DSP data direction register.
    sty DSP         ; Set it up.
    lda #$A7        ; KBD and DSP control register mask.
    sta KBDCR       ; Enable interrupts, set CA1, CB1, for
    sta DSPCR       ; positive edge sense/output mode.
    ldx #$ff        ; Initialize stack pointer
    txs
    jmp fdsh_init

    .include "defs.asm"
    .include "delay.asm" 
    .include "common.asm" 
    .include "list.asm" 
    .include "read.asm" 
    .include "write.asm" 
    .include "delete.asm" 

fdsh_init:
; init ZP variables
    lda #DAT        
    sta dat_mask    ; A bit to test to distinguish between data and ctrl byte
    lda #0
    sta prefix      ; clear prefix buffer
    lda #$00        ; Default to WozMon
    sta prg_start
    lda #$ff
    sta prg_start+1
.if MOCK_HW
    lda #$97        ; RDY, not BSY and two nibbles == 'w' 
    sta DEVICE_IN
.endif    
    lda #CR
    jsr ECHO

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
    jmp $ff00           ; WozMon entry

do_list:
    jsr list
    jmp menu
do_read:
    jsr read
    jmp menu
do_load:
    jsr load
    jmp menu
do_write:
    jsr write
    jmp menu
do_save:
    jsr save
    jmp menu
do_run:
    ldx #2
    lda buffer,x
    beq do_jmp          ; no arg, just jmp
    jsr read
    bcc do_jmp          ; read succeeded
    jmp menu
do_jmp:
    jmp (prg_start)     ; address must be set by loading or saving file
do_basic:
    jmp $e2b3           ; BASIC warm entry
do_remove:
    jsr delete
    jmp menu

; Copies up to 10 bytes from buffer+3 to prefix, appends '/' if buffer+2 is not null
cd_prefix:
    ldx #2
    ldy #0
    lda buffer,x
    beq prefix_null_terminate
    inx                 ; skip SP
cd_prefix_loop:
    lda buffer,x
    beq prefix_append_slash
    sta prefix,y
    inx
    iny
    cpy #10
    bne cd_prefix_loop
prefix_append_slash:
    cpy #0
    beq prefix_null_terminate
    lda #$2F            ; '/'
    sta prefix,y
    iny
prefix_null_terminate:
    lda #$00
    sta prefix,y
    jmp menu

; Command table format:
; 2 bytes: command prefix
; 2 bytes: jump address (low/high)
cmd_table:
    .byte 'C', 'D', <cd_prefix, >cd_prefix
    .byte 'L', 'S', <do_list,   >do_list
    .byte 'W', 'R', <do_write,  >do_write
    .byte 'R', 'D', <do_read,   >do_read
    .byte 'R', 'N', <do_run,    >do_run
    .byte 'S', 'V', <do_save,   >do_save
    .byte 'L', 'D', <do_load,   >do_load
    .byte 'B', 'S', <do_basic,  >do_basic
    .byte 'R', 'M', <do_remove, >do_remove
    .byte 0          ; End of table marker

help:
.if REAL_HW
    .text "FlashDisk Shell v", VERSION, " by Arvid Juskaitis", 13
    .text "CD [directory]", 13
    .text "LS [prefix]", 13
    .text "WR <filename>#start#stop", 13
    .text "RD <filename|#block>", 13
    .text "RN [filename|#block]", 13
    .text "SV <filename>", 13
    .text "LD <filename|#block>", 13
    .text "BS", 13
    .text "RM <filename|#block>", 13
.endif
    .text 0

