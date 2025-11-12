// C (cc65) support for RC6502 Apple1 Replica
// Copyright (c) 2025 Arvid Juskaitis
// 
// Dummy implementation of ExtLib for cross-development

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

void print_char(char c) {
    putchar(c);
}

void print_hex(uint8_t value) {
    printf("%02X", value);
}

void print_str(unsigned char* ptr) {
    while (*ptr) {
        print_char(*ptr++);
    }
}

void print_int(uint16_t value) {
    printf("%u", value);
}

uint8_t get_char(void) {
    return getchar();
}

uint8_t get_char_nowait(void) {
    return 0; // Stub implementation, requires platform-specific code for non-blocking input
}

uint8_t get_str(unsigned char* ptr, uint8_t maxlen) {
    fgets((char*)ptr, maxlen, stdin);
    return (uint8_t)strlen((char*)ptr);
}

uint16_t get_int(void) {
    char buffer[10];
    fgets(buffer, sizeof(buffer), stdin);
    return (uint16_t)atoi(buffer);
}

void clear_screen() {
    printf("\033[2J\033[H"); // ANSI escape sequence for clearing screen and moving cursor to home
}

void set_cursor_pos(uint8_t row, uint8_t col) {
    printf("\033[%d;%dH", row, col); // ANSI escape sequence for setting cursor position
}

void set_color(uint8_t color) {
    printf("\033[3%dm", color % 8); // Basic ANSI color (0-7)
}
