; C (cc65) support for RC6502 Apple1 Replica
; Copyright (c) 2025 Arvid Juskaitis
; 
; Stubs to support calling ExtLib functions from C

    .export _print_char, _print_hex, _print_str, _print_int, _get_char, _get_char_nowait, _get_str, _get_int
    .export _clear_screen, _set_cursor_pos, _set_color
    .importzp sp
    .import incsp2, incsp3, pusha, pushax, ldax0sp, ldaxysp

CLEAR_SCREEN = $f900
SET_CURSOR_POS = $f903
SET_COLOR = $f906
PRINT_STR = $f909
PRINT_INT = $f90c
GET_CHAR = $f90f
GET_CHAR_NOWAIT = $f912
GET_STR = $f915
GET_INT = $f918
UINT2STR = $f91b
STR2UINT = $f922

    .segment "CODE"

; void __fastcall__ print_char(char c) - Prints a character using WozMon's ECHO ($FFEF)
; ---------------------------------------------------------------
_print_char:
    jmp $FFEF       ; Call ECHO
    
; void __fastcall__ print_hex(uint8_t value) - Prints a byte in hex using WozMon's PRBYTE ($FFDC)
; ---------------------------------------------------------------
_print_hex:
    jmp $FFDC       ; Call PRBYTE

; void __fastcall__ print_str(unsigned char* str);
_print_str_ptr=$1B   ; store pointer after first 26 bytes, used by compiler
; ---------------------------------------------------------------
_print_str:
    jsr pushax
    jsr PRINT_STR
    jmp incsp2

; void __fastcall__ print_int(uint16_t value);
; ---------------------------------------------------------------
_print_int:
	jsr pushax
	jsr PRINT_INT
	jmp incsp2
    
; char __fastcall__ get_char(void) - Waits for a key press, returns the character
; ---------------------------------------------------------------
_get_char:
    jmp GET_CHAR

; char __fastcall__ get_char_nowait(void) - Non-blocking key check, returns 0 if no key available
; ---------------------------------------------------------------
_get_char_nowait:
    jmp GET_CHAR_NOWAIT

; unsigned char __fastcall__ get_str (unsigned char* ptr, uint8_t maxlen)
; ---------------------------------------------------------------
_get_str:
    jsr pusha
    ldy #$00
    lda (sp),y
    sta $46         ; the end of tmp_buffer, where tmp_value is stored
    ldy #$02
    jsr ldaxysp
    ldy $46
    jsr GET_STR
    jmp incsp3

; unsigned int __fastcall__ get_int (void)
; ---------------------------------------------------------------
_get_int:
	jmp GET_INT
	
; void __fastcall__ clear_screen();
; ---------------------------------------------------------------
_clear_screen:
    jmp CLEAR_SCREEN

; void __fastcall__ set_cursor_pos(uint8_t row, uint8_t col);
; ---------------------------------------------------------------
_set_cursor_pos:
	jsr pusha
	; col
	ldy     #$00
	lda     (sp),y
	tax
    ; row
	ldy     #$01
	lda     (sp),y
	jsr SET_CURSOR_POS
	jmp incsp2  ; this does rts

; void __fastcall__ set_color(uint8_t color);
; ---------------------------------------------------------------
_set_color:
    jmp SET_COLOR

.ifdef DRIVER_IO_IMPL        
    .export _read, _write
; int __cdeclr__ read(int fd, unsigned char* buf, int size);
; ---------------------------------------------------------------
_read:  rts

; int __cdeclr__ write(int fd, unsigned char* buf, int size);
; ---------------------------------------------------------------
_write: rts        
.endif
