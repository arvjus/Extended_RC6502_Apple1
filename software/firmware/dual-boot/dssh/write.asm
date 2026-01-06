; Datasette Shell
; Copyright (c) 2025 Arvid Juskaitis

; Save memory, write to file

; save Integer-BASIC in ProDOS format
save:
    ; store type of file
    lda #FILE_TYPE_BASIC
    sta type

    jsr write_copy_basic_addresses
    jsr write_print_messages

    jsr checksum_init

    ; begin transfer
    jsr write_sync

    ; header chunk
    jsr write_header_chunk
    bcs write_err
    jsr delay_500ms

    ; payload chunk
    jsr write_payload_chunk
    bcs write_err
    jsr delay_125ms

    ; basic chunk
    jsr write_basic_chunk
    bcs write_err
    jsr delay_125ms

    ; checksum chunk
    jsr write_checksum
    bcs write_err

    ; end transfer
    jsr write_end

    jmp write_done

; write regular file
write:
    ; store type of file
    lda #FILE_TYPE_RUNNABLE
    sta type

    jsr write_parse_cmd_args
    bcs write_err           ; invalid command line
    jsr write_print_messages

    jsr checksum_init

    ; begin transfer
    jsr write_sync

    ; header chunk
    jsr write_header_chunk
    bcs write_err
    jsr delay_500ms

    ; payload chunk
    jsr write_payload_chunk
    bcs write_err
    jsr delay_125ms

    ; checksum chunk
    jsr write_checksum
    bcs write_err
    jsr delay_125ms

    ; end transfer
    jsr write_end

write_done:
    SET_PTR write_msg3
    jsr print_msg
    rts
write_err:
    lda #'!'
    jsr ECHO
    rts

; Header's format:
; 1nd - the length of following data
; 2rd - always 0
; 3st byte is always 1
; 4th - type (runnable=1, basic=2, data=3)
; the rest is name of the file
; Max payload size = 32 bytes
;
; type contains file type (runnable, basic) 
; the name of file is stored in buffer+3, terminated by 0 or '#'
; thus length of chunk = position of 0|'#' - 1
; -------------------------------------------------------------
write_header_chunk:
    ldy #$03                ; start position, eg 'SV TEST'
write_header_chunk_search:
    lda buffer, y
    beq write_header_chunk_found    
    cmp #$23                ; '#'
    beq write_header_chunk_found   
    iny
    cpy #$20                ; file name cannot be longer than 32 chars
    beq write_header_chunk_err
    jmp write_header_chunk_search
write_header_chunk_found:
    dey
    dey
    dey                     ; Y contains now filename's length

    ; send command w####
    lda #CMD_WRITE
    jsr tx_byte             ; write cmd
    ; calculate and send lengh of chunk in hex
    lda #'0'                ; lengh hex hi
    jsr tx_byte             ; hi nibble 
    jsr tx_byte             ; lo nibble 
    tya                     ; lengh hex lo
    clc
    adc #$04                ; increase to length of chunk
    jsr tx_byte_hex

    ; send chunk-header
    tya                     ; filename's length
    clc 
    adc #$02                ; length of chunk 
    jsr tx_byte_checksum    ; length lo
    lda #0
    jsr tx_byte_checksum    ; length hi
    lda #CHUNK_TYPE_HEADER
    jsr tx_byte_checksum    ; chunk type
    lda type
    jsr tx_byte_checksum    ; program type

    ; send file name, Y contains the length of filename
    ldx #$03                ; start position, eg 'SV TEST'
    jsr tx_y_bytes_checksum
    bcs write_header_chunk_err

write_header_chunk_done:
    clc
    rts
write_header_chunk_err:
    sec
    rts


; Payload's format:
; 1nd and 2rd - the length of following payload data, 16 bit value
; 3st byte is always 2
; 4th and 5th - start address
; the rest is the payload data
;
; prg_start, prg_stop, prg_size already contains values
; -------------------------------------------------------------
write_payload_chunk:
; create chunck's header in the buffer
    ; copy, increase size
    clc
    lda prg_size
    adc #$03  
    sta buffer
    lda prg_size+1
    adc #$00    
    sta buffer+1
    
    ; copy rest of header values
    lda #CHUNK_TYPE_PAYLOAD
    sta buffer+2
    lda prg_start
    sta buffer+3
    lda prg_start+1
    sta buffer+4

    ; send command w0005
    lda #CMD_WRITE
    jsr tx_byte             ; write cmd
    lda #'0'
    jsr tx_byte
    jsr tx_byte
    jsr tx_byte
    lda #'5'
    jsr tx_byte

    ; send header and wait
    ldx #$00                ; index of 1st byte
    ldy #$05                ; length 
    jsr tx_y_bytes_checksum
    bcs write_payload_chunk_err
    jsr delay_125ms

; start sending data
    ; init ptr
    lda prg_start
    sta ptr
    lda prg_start+1
    sta ptr+1

    ; send command wxxxx
    lda #CMD_WRITE
    jsr tx_byte             ; write cmd
    lda prg_size+1
    jsr tx_byte_hex
    lda prg_size
    jsr tx_byte_hex

write_payload_chunk_loop:
    ; check if ptr reached prg_stop
    lda ptr+1
    cmp prg_stop+1
    bne write_payload_chunk_store
    lda ptr
    cmp prg_stop
    beq write_payload_chunk_done

write_payload_chunk_store:
    ldy #$00
    lda (ptr),y
    jsr tx_byte_checksum
    bcs write_payload_chunk_done  ; timeout

    ; increment ptr
    inc ptr
    bne write_payload_chunk_loop
    inc ptr+1
    jmp write_payload_chunk_loop

write_payload_chunk_done:
    clc
    rts
write_payload_chunk_err:
    sec
    rts


; Basic Header's format:
; 1nd - always 1
; 2rd - always 2, 
; 3st byte is always 3
; the rest is the payload data 512 bytes
; Fixed payload size = 515 bytes
;
; write first 2 pages, prg_start, prg_stop, prg_size already contains values
; -------------------------------------------------------------
write_basic_chunk:
; create chunck's header in the buffer
    lda #$01
    sta buffer
    lda #$02
    sta buffer+1
    lda #CHUNK_TYPE_BASIC
    sta buffer+2

    ; send command w0203    ; 515 length
    lda #CMD_WRITE
    jsr tx_byte             ; write cmd
    lda #'0'
    jsr tx_byte
    lda #'2'
    jsr tx_byte
    lda #'0'
    jsr tx_byte
    lda #'3'
    jsr tx_byte

    ; send header
    ldx #$00                ; index of 1st byte
    ldy #$03                ; length 
    jsr tx_y_bytes_checksum
    bcs write_basic_chunk_err

; start sending data

    ; store signature
    lda #'A'
    sta $00
    lda #'1'
    sta $01

    ; init ptr
    lda #$00
    sta ptr
    sta ptr+1

write_basic_chunk_loop:
    ; check if ptr reached prg_stop
    lda ptr+1
    cmp #$02
    bne write_basic_chunk_store
    lda ptr
    cmp #$00
    beq write_basic_chunk_done

write_basic_chunk_store:
    ldy #$00
    lda (ptr),y
    jsr tx_byte_checksum
    bcs write_basic_chunk_err    ; timeout

    ; increment ptr
    inc ptr
    bne write_basic_chunk_loop
    inc ptr+1
    jmp write_basic_chunk_loop

write_basic_chunk_done:
    jsr write_print_messages
    clc
    rts
write_basic_chunk_err:
    sec
    rts


; Checksum's format:
; 1nd - always 2 (the length of checksum)
; 2rd - always 0
; 3st byte is always 4
; 4th and 5th - checksum (16-bit modulo 65536 addition)
;
; write checksum chunk
; -------------------------------------------------------------
write_checksum:
    ; create chunck's header in the buffer
    lda #$02
    sta buffer
    lda #$00
    sta buffer+1
    lda #CHUNK_TYPE_CHECKSUM
    sta buffer+2
    lda checksum
    sta buffer+3
    lda checksum+1
    sta buffer+4

    ; send command w0005
    lda #CMD_WRITE
    jsr tx_byte             ; write cmd
    lda #'0'
    jsr tx_byte
    jsr tx_byte
    jsr tx_byte
    lda #'5'
    jsr tx_byte

    ; send header
    ldx #$00                ; index of 1st byte
    ldy #$05                ; length 
    jsr tx_y_bytes_checksum
    rts

; write end transfer
; -------------------------------------------------------------
write_sync
    lda #CMD_SYNC
    jsr tx_byte
    rts

; write end transfer
; -------------------------------------------------------------
write_end:
    lda #CMD_END
    jsr tx_byte
    rts

; copy addresses, calculate prg_size
; -------------------------------------------------------------
write_copy_basic_addresses:
    ; store lomem, himem variables into prg_start, prg_stop.
    lda lomem
    sta prg_start
    lda lomem+1
    sta prg_start+1
    lda himem
    sta prg_stop
    lda himem+1
    sta prg_stop+1
    
    ; calculate size, put into prg_size
    sec                     ; clear borrow
    lda prg_stop
    sbc prg_start
    sta prg_size
    lda prg_stop+1
    sbc prg_start+1         ; Subtract with borrow
    sta prg_size+1    

    rts

; Parse string in format 'wr name#xxxx#xxxx' and extract xxxx values
; -------------------------------------------------------------
write_parse_cmd_args:
    ldx #$03                ; index in string

    ; Find first '#'
find_first_hash:
    lda buffer, x
    inx
    beq write_parse_cmd_args_err ; no '#' within buffer
    cmp #$23                ; '#'
    bne find_first_hash
    cpy #$02
    beq write_parse_cmd_args_err ; name is empy

    ; Parse first xxxx into prg_start
    jsr parse_addr          ; Parse 4-digit hex value into ptr
    lda ptr
    sta prg_start
    lda ptr+1
    sta prg_start+1

    lda buffer, x         
    cmp #$23                ; second '#' is expected
    bne write_parse_cmd_args_err
    inx                     ; point to next value

    ; Parse second xxxx into prg_stop
    jsr parse_addr          ; Parse 4-digit hex value into ptr
    lda ptr
    sta prg_stop
    lda ptr+1
    sta prg_stop+1
    
    ; Calculate size = prg_stop - prg_start, store into prg_size
    sec                     ; clear borrow
    lda prg_stop
    sbc prg_start
    sta prg_size
    lda prg_stop+1
    sbc prg_start+1         ; Subtract with borrow
    sta prg_size+1    
    
    clc
    rts
write_parse_cmd_args_err:
    sec
    rts

; Parse 4-digit hex value into (ptr, ptr+1). x points to the first digit in buffer
; -------------------------------------------------------------
parse_addr:
    lda #$00
    sta ptr
    sta ptr+1
    ldy #$00                ; Digit counter (4 per value)

parse_addr_loop:
    lda buffer, x         
    beq parse_addr_done     ; null terminator
    cmp #$23                ; next '#'
    beq parse_addr_done   
    jsr hex_to_bin          ; ASCII hex to binary nibble

    ; Shift destination left by 4 (equivalent to multiplying by 16)
    asl ptr
    rol ptr+1
    asl ptr
    rol ptr+1
    asl ptr
    rol ptr+1
    asl ptr
    rol ptr+1

    ora ptr                 ; Add nibble to lower byte
    sta ptr

    inx
    iny
    cpy #$04                ; Process exactly 4 digits
    bne parse_addr_loop

parse_addr_done:
    rts


; print messages start, stop values
; -------------------------------------------------------------
write_print_messages:
    SET_PTR write_msg1
    jsr print_msg

    lda prg_start+1         ; start high
    jsr PRBYTE
    lda prg_start           ; start low
    jsr PRBYTE
    lda #' '
    jsr ECHO
    lda #'-'
    jsr ECHO
    lda #' '
    jsr ECHO
    lda prg_stop+1          ; stop high
    jsr PRBYTE          
    lda prg_stop            ; stop low
    jsr PRBYTE

    SET_PTR write_msg2
    jsr print_msg
    rts

write_msg1:  .text "Writing memory ", 0
write_msg2:  .text " to file", 0
write_msg3:  .text " .. done.", 13, 0

