; Datasette Shell
; Copyright (c) 2025 Arvid Juskaitis

; Read file, load into memory

; read regular file or Integer-BASIC in ProDOS format
read:
    lda #0                      ; reset file type
    sta type

    lda #CMD_READ               ; send read cmd
    jsr tx_byte_no_fc

    jsr checksum_init
    
    SET_PTR msg_press           ; start play
    jsr print_msg

read_start:
    jsr read_wait_for_input     ; serial or keyboard event
    bcs read_receive_header
    cmp #KEY_CANCEL
    beq read_canceled
    cmp #KEY_READ
    bne read_start
    lda #CMD_READ               ; send read cmd
    jsr tx_byte_no_fc
    jmp read_start

read_receive_header:
    jsr read_header
    bcs read_err
    ; save file type
    lda buffer+3
    sta type

    jsr read_payload
    bcs read_err
    bne read_canceled

    lda type
    cmp #FILE_TYPE_BASIC
    bne read_receive_checksum
    jsr read_basic_header
    bcs read_err
    bne read_canceled

read_receive_checksum:
    jsr read_checksum
    bcs read_err
    bne read_canceled

; done
    SET_PTR msg_done
    jsr print_msg
read_done:
    lda #CR
    jsr ECHO
    clc                         ; success
    rts
read_canceled:
    lda #CMD_CANCEL             ; cancel transfer if any
    jsr tx_byte_no_fc
    
    SET_PTR msg_canceled
    jsr print_msg

    jmp read_done
read_err:
    lda #'!'
    jsr ECHO
    sec                         ; failure
    rts

; wait for pressed key or received char
; Cary flag - serial byte available, otherwise pressed key in A
; -------------------------------------------------------------
read_wait_for_input:
    ; check serial
    lda ACIA_STATUS
    and #%00000001              ; Bit 0 = RDRF (data received)
    bne read_wait_for_input_serial

    ; check keyboard
    jsr KBDIN_NOWAIT            ; A = key or 0
    beq read_wait_for_input
    
    clc
    rts
read_wait_for_input_serial:
    sec
    rts

; Header chunk format: 0,1-length lo, hi, 2-chunk_type=1, 3-file_type=1|2|3
; -------------------------------------------------------------
read_header:
    ldx #0
    ldy #4
    jsr rx_y_bytes_checksum
    bcs read_header_err
    lda buffer+2                ; chunk type
    cmp #CHUNK_TYPE_HEADER
    bne read_header_err
    ldy buffer                  ; chuck length
    dey                         ; skip chunk type
    dey                         ; skip file type
    jsr rx_y_bytes_checksum     ; read rest of the header
    bcs read_header_err
    lda #0
    sta buffer, x               ; null terminate 

    ; print file name, type
    SET_PTR buffer+4            ; file name
    jsr print_msg
    lda #' '
    jsr ECHO
    lda #'('
    jsr ECHO
    ldx buffer+3                ; file type
    lda file_type, x
    jsr ECHO
    lda #')'
    jsr ECHO
    lda #' '
    jsr ECHO

    ; done
    clc                         ; success
    rts
read_header_err:
    sec                         ; failure
    rts

; Payread chunk format: 0,1-length lo, hi, 2-chunk_type=2, 3,4-start address lo, hi
; returns non zero in A if canceled
; -------------------------------------------------------------
read_payload:
    ldx #0
    ldy #5
    jsr rx_y_bytes_checksum
    bcs read_payload_err
    lda buffer+2                ; chunk type
    cmp #CHUNK_TYPE_PAYLOAD
    bne read_payload_err

    ; initialize ptr with start address, save address to prg_start
    lda buffer+3
    sta prg_start
    sta ptr
    lda buffer+4
    sta prg_start+1
    sta ptr+1

    ; calculate prg_stop = start + size
    clc
    lda prg_start               ; start low
    adc buffer                  ; size low
    sta prg_stop                ; stop low
    lda prg_start+1             ; start high
    adc buffer+1                ; size high
    sta prg_stop+1              ; stop high

    ; subtract 3 bytes from stop- skip chunk-type, start addr
    sec
    lda prg_stop                ; stop low
    sbc #$03
    sta prg_stop                ; stop low
    lda prg_stop+1              ; stop high
    sbc #$00
    sta prg_stop+1              ; stop high

    jsr print_start_stop

read_payload_rx_byte_input:
    jsr read_wait_for_input     ; serial or keyboard event
    bcs read_payload_rx_byte
    cmp #KEY_CANCEL
    beq read_payload_cancel
    jmp read_payload_rx_byte_input
read_payload_rx_byte:
    jsr rx_byte_checksum
    bcs read_payload_err
    ldy #$00
    sta (ptr),y

    ; increment ptr
    inc ptr
    bne read_payload_skip_high  ; if ptr low byte did not wrap, skip high byte increment
    inc ptr+1
read_payload_skip_high:
    ; check if ptr reached prg_stop
    lda ptr+1
    cmp prg_stop+1                  ; compare high byte first
    bcc read_payload_rx_byte_input  ; if ptr+1 < prg_stop+1, continue
    bne read_payload_done           ; if ptr+1 > prg_stop+1, exit
    lda ptr
    cmp prg_stop
    bcc read_payload_rx_byte_input  ; if ptr < prg_stop, continue

read_payload_done:    
    lda #0
    clc                         ; success
    rts
read_payload_err:
    sec                         ; failure
    rts
read_payload_cancel:    
    lda #1
    clc                         ; success
    rts

; handle first 512 bytes of data      
; Basic Header chunk format: 0,1-length lo, hi, 2-chunk_type=3
; -------------------------------------------------------------
read_basic_header:
    ldx #0
    ldy #3
    jsr rx_y_bytes_checksum
    bcs read_basic_err
    lda buffer+2                ; chunk type
    cmp #CHUNK_TYPE_BASIC
    bne read_basic_err

    ; check header
    jsr rx_byte_checksum
    bcs read_basic_err          ; byte is expected
    cmp #'A'
    bne read_basic_err          ; file signature is expected
    jsr rx_byte_checksum
    bcs read_basic_err          ; byte is expected
    cmp #'1'
    bne read_basic_err          ; file signature is expected
    
    ; skip another $48 bytes
    lda #2
    sta ptr                     ; we've already received 2 bytes 
read_skip_zp_loop_input:    
    jsr read_wait_for_input     ; serial or keyboard event
    bcs read_skip_zp_loop
    cmp #KEY_CANCEL
    beq read_basic_cancel
    jmp read_skip_zp_loop_input
read_skip_zp_loop:    
    jsr rx_byte_checksum
    bcs read_basic_err          ; byte is expected
    inc ptr
    lda ptr
    cmp #$4a
    bne read_skip_zp_loop_input

    ; read $4a - $ff data
    lda #0                      ; ZP                      
    sta ptr+1                   ; while LSB points to $4a
read_receive_zp_data_byte_input:    
    jsr read_wait_for_input     ; serial or keyboard event
    bcs read_receive_zp_data_byte
    cmp #KEY_CANCEL
    beq read_basic_cancel
    jmp read_receive_zp_data_byte_input
read_receive_zp_data_byte:
    jsr rx_byte_checksum
    bcs read_basic_err          ; byte is expected
    ldy #$00
    sta (ptr),y
    inc ptr
    bne read_receive_zp_data_byte_input ; loop until value wrapps

    ; skip $100 - $1ff
    lda #1                      ; stack, first page        
    sta ptr+1                   ; ZP, while LSB is 0
read_skip_stack_loop_input:    
    jsr read_wait_for_input     ; serial or keyboard event
    bcs read_skip_stack_loop
    cmp #KEY_CANCEL
    beq read_basic_cancel
    jmp read_skip_stack_loop_input
read_skip_stack_loop:    
    jsr rx_byte_checksum
    bcs read_basic_err          ; byte is expected
    inc ptr
    bne read_skip_stack_loop_input

    ; done
    lda #0
    clc                         ; success
    rts
read_basic_cancel:
    lda #1
    clc                         ; success
    rts
read_basic_err:
    sec                         ; failure
    rts

; Checksum chunk format: 0,1-length lo, hi, 2-chunk_type=4, 3,4-checksum lo, hi
; returns non zero in A if canceled
; -------------------------------------------------------------
read_checksum:
    ldx #0
    ldy #5
read_checksum_rx_byte_input:
    jsr read_wait_for_input     ; serial or keyboard event
    bcs read_checksum_rx_byte
    cmp #KEY_CANCEL
    beq read_checksum_cancel
    jmp read_checksum_rx_byte_input
read_checksum_rx_byte:
    jsr rx_byte
    bcs read_checksum_err
    sta buffer, x
    inx
    dey
    bne read_checksum_rx_byte_input ; not done yet? 
    
    lda buffer+2                ; chunk type
    cmp #CHUNK_TYPE_CHECKSUM
    bne read_checksum_err

    ; compare checksum
    lda checksum
    cmp buffer+3
    bne read_checksum_mismatch
    lda checksum+1
    cmp buffer+4
    bne read_checksum_mismatch

    ; done
    lda #0
    clc                         ; success
    rts
read_checksum_cancel:
    lda #1
    clc
    rts
read_checksum_mismatch:
    SET_PTR msg_checksum
    jsr print_msg
read_checksum_err:
    sec                         ; failure
    rts

msg_press:     .text   "Press Datasette Play or (C)ancel.. ", 0
msg_checksum:  .text   "checksum ", 0
msg_done:      .text   "done.", 0
msg_canceled:  .text   "canceled.", 0
file_type:     .byte   '?', 'R', 'B', 'D'

