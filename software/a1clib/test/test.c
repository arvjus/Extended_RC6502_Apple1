// C (cc65) support for RC6502 Apple1 Replica
// Copyright (c) 2025 Arvid Juskaitis
// 
// Test ExtLib routines

#ifdef __LINUX__
#define __fastcall__ /**/
#endif
#include "../include/extlib.h"

char buff[20];

void main() {
    uint16_t n;
    char ch, i;

    clear_screen();
    for (i = 1; i <= 7; i ++) {
        set_cursor_pos(i + 3, 5);
        set_color(i + 30);
        print_str("this is a sample text");
    }
    
    print_str("\n\nPress any key, I will display the value in HEX: ");
    ch = get_char();
    print_hex(ch);
    print_char(' ');
    
    print_str("\nInput string (max 20 char): ");
    get_str(buff, 20);
    print_str("\nYour string is: ");
    print_str(buff);
    print_char('\n');
    
    print_str("\nInput number (0-65535): ");
    n = get_int();
    print_str("\nYour number is: ");
    print_int(n);
    print_char('\n');
}
