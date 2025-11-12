// Extension Library to support basic I/O of RC6502 Apple1 Replica
// Copyright (c) 2025 Arvid Juskaitis

#ifndef EXTLIB_H
#define EXTLIB_H

#include <stdint.h>

void __fastcall__ print_char(char c);               // WozMon's ECHO
void __fastcall__ print_hex(uint8_t value);         // WozMon's PRBYTE
void __fastcall__ print_str(unsigned char* ptr);    // WozMon's ECHO
void __fastcall__ print_int(uint16_t value);        // uint2str, WozMon's ECHO

uint8_t __fastcall__ get_char(void);                // blocks, returns pressed key
uint8_t __fastcall__ get_char_nowait(void);         // non-blocking, returns 0 if no key available
uint8_t __fastcall__ get_str(unsigned char* ptr, uint8_t maxlen);   // get_char
uint16_t __fastcall__ get_int(void);                // get_str, str2uint

void __fastcall__ clear_screen();
void __fastcall__ set_cursor_pos(uint8_t row, uint8_t col);
void __fastcall__ set_color(uint8_t color);

// color definitions 
#define COLOR_FG_BLACK          30
#define COLOR_FG_RED            31
#define COLOR_FG_DARK_GREEN     32
#define COLOR_FG_DARK_ORANGE    33
#define COLOR_FG_DARK_BLUE      34
#define COLOR_FG_MAGENTA        35
#define COLOR_FG_CYAN           36
#define COLOR_FG_WHITE          37

#define COLOR_BG_BLACK          40
#define COLOR_BG_RED            41
#define COLOR_BG_DARK_GREEN     42
#define COLOR_BG_DARK_ORANGE    43
#define COLOR_BG_DARK_BLUE      44
#define COLOR_BG_MAGENTA        45
#define COLOR_BG_CYAN           46
#define COLOR_BG_WHITE          47

#define COLOR_FG_MEDIUM_GREEN   92
#define COLOR_FG_BRIGHT_ORANGE  93
#define COLOR_FG_BRIGHT_BLUE    94
#define COLOR_FG_BRIGHT_MAGENTA 95
#define COLOR_FG_BRIGHT_CYAN    96

#define COLOR_BG_MEDIUM_GREEN   102
#define COLOR_BG_BRIGHT_ORANGE  103
#define COLOR_BG_BRIGHT_BLUE    104
#define COLOR_BG_BRIGHT_MAGENTA 105
#define COLOR_BG_BRIGHT_CYAN    106

#endif // EXTLIB_H
