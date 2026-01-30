#include "vga.h"

// Unified ANSI-to-color mapping structure
typedef struct {
    const char *ansi_code; // ANSI escape sequence
    Color color;           // Color code
    char is_foreground;    // 1 if foreground, 0 if background
} AnsiToColorMap;

// Unified mapping array
const AnsiToColorMap ansi_map[] = {
        {"[30m",  BLACK,       1},    // Black foreground
        {"[32m",  DARK_GREEN,  1},    // Dark Green foreground
        {"[92m",  MED_GREEN,   1},    // Medium Green foreground
        {"[34m",  DARK_BLUE,   1},    // Dark Blue foreground
        {"[94m",  BLUE,        1},    // Bright Blue foreground
        {"[96m",  LIGHT_BLUE,  1},    // Bright Cyan foreground
        {"[36m",  CYAN,        1},    // Cyan foreground
        {"[31m",  RED,         1},    // Red foreground
        {"[33m",  DARK_ORANGE, 1},    // Dark Orange foreground
        {"[93m",  ORANGE,      1},    // Bright Orange foreground
        {"[35m",  MAGENTA,     1},    // Magenta foreground
        {"[95m",  PINK,        1},    // Bright Magenta foreground
        {"[37m",  WHITE,       1},    // White foreground
        {"[40m",  BLACK,       0},    // Black background
        {"[42m",  DARK_GREEN,  0},    // Dark Green background
        {"[102m", MED_GREEN,   0},    // Medium Green background
        {"[44m",  DARK_BLUE,   0},    // Dark Blue background
        {"[104m", BLUE,        0},    // Bright Blue background
        {"[106m", LIGHT_BLUE,  0},    // Bright Cyan background
        {"[46m",  CYAN,        0},    // Cyan background
        {"[41m",  RED,         0},    // Red background
        {"[43m",  DARK_ORANGE, 0},    // Dark Orange background
        {"[103m", ORANGE,      0},    // Bright Orange background
        {"[45m",  MAGENTA,     0},    // Magenta background
        {"[105m", PINK,        0},    // Bright Magenta background
        {"[47m",  WHITE,       0},    // White background
        {NULL,        BLACK,       0}     // Sentinel
};
