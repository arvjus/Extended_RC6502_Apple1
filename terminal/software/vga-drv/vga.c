/**
 * Hunter Adams (vha3@cornell.edu)
 * Arvid Juskaitis
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pico/stdlib.h>
#include <hardware/pio.h>
#include <hardware/dma.h>
#include "hsync.pio.h"
#include "vsync.pio.h"
#include "rgb.pio.h"
#include "font.h"
#include "vga.h"

// VGA timing constants
#define H_ACTIVE   655    // (active + frontporch - 1) - one cycle delay for mov
#define V_ACTIVE   479    // (active - 1)
#define RGB_ACTIVE 319    // (horizontal active)/2 - 1

// Length of the pixel array, and number of DMA transfers
#define TXCOUNT 153600 // Total pixels/2 (since we have 2 pixels per byte)
#define PIX_COUNT_PER_LINE 5120 //  number of bytes for 16 scan lines

// Pixel color array that is DMA's to the PIO machines and
// a pointer to the ADDRESS of this color array.
// Note that this array is automatically initialized to all 0's (black)
unsigned char vga_data_array[TXCOUNT];
char *address_pointer = &vga_data_array[0];

// Bit masks for drawPixel routine
#define TOPMASK 0b00001111
#define BOTTOMMASK 0b11110000

// For accessing the font library
#define pgm_read_byte(addr) (*(const unsigned char *)(addr))

// For drawing characters
unsigned short cursor_y, cursor_x;
char textcolor = WHITE, textbgcolor = BLACK, wrap = 1;

// Screen/char dimensions
#define SCREEN_WIDTH 640
#define SCREEN_HEIGHT 480
#define CHAR_WIDTH  8
#define CHAR_HEIGHT 16
#define TAB_SPACE    4


void initVGA() {
    // Choose which PIO instance to use (there are two instances, each with 4 state machines)
    PIO pio = pio0;

    // Our assembled program needs to be loaded into this PIO's instruction
    // memory. This SDK function will find a location (offset) in the
    // instruction memory where there is enough space for our program. We need
    // to remember these locations!
    //
    // We only have 32 instructions to spend! If the PIO programs contain more than
    // 32 instructions, then an error message will get thrown at these lines of code.
    //
    // The program name comes from the .program part of the pio file
    // and is of the form <program name_program>
    uint hsync_offset = pio_add_program(pio, &hsync_program);
    uint vsync_offset = pio_add_program(pio, &vsync_program);
    uint rgb_offset = pio_add_program(pio, &rgb_program);

    // Manually select a few state machines from pio instance pio0.
    uint hsync_sm = 0;
    uint vsync_sm = 1;
    uint rgb_sm = 2;

    // Call the initialization functions that are defined within each PIO file.
    // Why not create these programs here? By putting the initialization function in
    // the pio file, then all information about how to use/setup that state machine
    // is consolidated in one place. Here in the C, we then just import and use it.
    hsync_program_init(pio, hsync_sm, hsync_offset, HSYNC);
    vsync_program_init(pio, vsync_sm, vsync_offset, VSYNC);
    rgb_program_init(pio, rgb_sm, rgb_offset, LO_GRN);


    // ============================== PIO DMA Channels =================================================
    // DMA channels - 0 sends color data, 1 reconfigures and restarts 0
    int rgb_chan_0 = dma_claim_unused_channel(true);
    int rgb_chan_1 = dma_claim_unused_channel(true);

    // Channel Zero (sends color data to PIO VGA machine)
    dma_channel_config c0 = dma_channel_get_default_config(rgb_chan_0);  // default configs
    channel_config_set_transfer_data_size(&c0, DMA_SIZE_8);              // 8-bit txfers
    channel_config_set_read_increment(&c0, true);                        // yes read incrementing
    channel_config_set_write_increment(&c0, false);                      // no write incrementing
    channel_config_set_dreq(&c0, DREQ_PIO0_TX2);                        // DREQ_PIO0_TX2 pacing (FIFO)
    channel_config_set_chain_to(&c0, rgb_chan_1);                        // chain to other channel

    dma_channel_configure(
            rgb_chan_0,                 // Channel to be configured
            &c0,                        // The configuration we just created
            &pio->txf[rgb_sm],          // write address (RGB PIO TX FIFO)
            &vga_data_array,            // The initial read address (pixel color array)
            TXCOUNT,                    // Number of transfers; in this case each is 1 byte.
            false                       // Don't start immediately.
    );

    // Channel One (reconfigures the first channel)
    dma_channel_config c1 = dma_channel_get_default_config(rgb_chan_1);   // default configs
    channel_config_set_transfer_data_size(&c1, DMA_SIZE_32);              // 32-bit txfers
    channel_config_set_read_increment(&c1, false);                        // no read incrementing
    channel_config_set_write_increment(&c1, false);                       // no write incrementing
    channel_config_set_chain_to(&c1, rgb_chan_0);                         // chain to other channel

    dma_channel_configure(
            rgb_chan_1,                         // Channel to be configured
            &c1,                                // The configuration we just created
            &dma_hw->ch[rgb_chan_0].read_addr,  // Write address (channel 0 read address)
            &address_pointer,                   // Read address (POINTER TO AN ADDRESS)
            1,                                  // Number of transfers, in this case each is 4 byte
            false                               // Don't start immediately.
    );

    // Initialize PIO state machine counters. This passes the information to the state machines
    // that they retrieve in the first 'pull' instructions, before the .wrap_target directive
    // in the assembly. Each uses these values to initialize some counting registers.
    pio_sm_put_blocking(pio, hsync_sm, H_ACTIVE);
    pio_sm_put_blocking(pio, vsync_sm, V_ACTIVE);
    pio_sm_put_blocking(pio, rgb_sm, RGB_ACTIVE);


    // Start the two pio machine IN SYNC
    // Note that the RGB state machine is running at full speed,
    // so synchronization doesn't matter for that one. But, we'll
    // start them all simultaneously anyway.
    pio_enable_sm_mask_in_sync(pio, ((1u << hsync_sm) | (1u << vsync_sm) | (1u << rgb_sm)));

    // Start DMA channel 0. Once started, the contents of the pixel color array
    // will be continously DMA's to the PIO machines that are driving the screen.
    // To change the contents of the screen, we need only change the contents
    // of that array.
    dma_start_channel_mask((1u << rgb_chan_0));
}

inline void setCursor(short x, short y) {
    cursor_x = x;
    cursor_y = y;
    drawHLine(cursor_x, cursor_y + CHAR_HEIGHT - 1, CHAR_WIDTH, textcolor);
}

inline void setColor(char c, char b) {
    textcolor = c;
    textbgcolor = b;
}

void clearScreen() {
    memset(vga_data_array, (textbgcolor << 4 | textbgcolor), sizeof vga_data_array);
    setCursor(0, 0);
}

// A function for drawing a pixel with a specified color.
// Note that because information is passed to the PIO state machines through
// a DMA channel, we only need to modify the contents of the array and the
// pixels will be automatically updated on the screen.
void drawPixel(short x, short y, char color) {
    // Range checks (640x480 display)
    if (x > 639) x = 639;
    if (x < 0) x = 0;
    if (y < 0) y = 0;
    if (y > 479) y = 479;

    // Which pixel is it?
    int pixel = ((640 * y) + x);

    // Is this pixel stored in the first 4 bits
    // of the vga data array index, or the second
    // 4 bits? Check, then mask.
    if (pixel & 1) {
        vga_data_array[pixel >> 1] = (vga_data_array[pixel >> 1] & TOPMASK) | (color << 4);
    } else {
        vga_data_array[pixel >> 1] = (vga_data_array[pixel >> 1] & BOTTOMMASK) | (color);
    }
}

void drawChar(short x, short y, unsigned char c, char color, char bg) {
    char i, j;
    unsigned char line;
    for (i = 0; i < CHAR_HEIGHT; i++) {
        line = pgm_read_byte(font + ((int) c * CHAR_HEIGHT) + i);
        for (j = 0; j < CHAR_WIDTH; j++) {
            if (line & 0x80) {
                drawPixel(x + j, y + i, color);
            } else if (bg != color) {
                drawPixel(x + j, y + i, bg);
            }
            line <<= 1;
        }
    }
}

void drawVLine(short x, short y, short h, char color) {
    for (short i = y; i < (y + h); i++) {
        drawPixel(x, i, color);
    }
}

void drawHLine(short x, short y, short w, char color) {
    for (short i = x; i < (x + w); i++) {
        drawPixel(i, y, color);
    }
}

void writeChar(unsigned char c) {
    unsigned short old_cursor_y = cursor_y, old_cursor_x = cursor_x;
    char char_placed = 0;

    if (c == '\n') {
        if (cursor_y + CHAR_HEIGHT < SCREEN_HEIGHT)
            cursor_y += CHAR_HEIGHT;
        else {
            // clear cursor, scroll up lines
            drawChar(cursor_x, cursor_y, ' ', textcolor, textbgcolor);
            memmove(vga_data_array, vga_data_array + PIX_COUNT_PER_LINE, TXCOUNT - PIX_COUNT_PER_LINE);
            memset(vga_data_array + TXCOUNT - PIX_COUNT_PER_LINE, (textbgcolor << 4 | textbgcolor), PIX_COUNT_PER_LINE);
        }
        cursor_x = 0;
    } else if (c == '\r') {
        // skip em
    } else if (c == '\t') {
        int new_x = (cursor_x + TAB_SPACE * CHAR_WIDTH) - (cursor_x % (TAB_SPACE * CHAR_WIDTH));
        if (new_x < SCREEN_WIDTH) {
            cursor_x = new_x;
        }
    } else if (c == 127) {   // BS
        if (cursor_x - CHAR_WIDTH >= 0) {
            cursor_x -= CHAR_WIDTH;
            drawChar(cursor_x, cursor_y, ' ', textcolor, textbgcolor);
        }
    } else {
        drawChar(cursor_x, cursor_y, c, textcolor, textbgcolor);
        char_placed = 1;
        cursor_x += CHAR_WIDTH;
        if (wrap && (cursor_x > (SCREEN_WIDTH - CHAR_WIDTH))) {
            cursor_y += CHAR_HEIGHT;
            cursor_x = 0;
        }
    }

    if (!char_placed)
        drawChar(old_cursor_x, old_cursor_y, ' ', textcolor, textbgcolor);
    drawHLine(cursor_x, cursor_y + CHAR_HEIGHT - 1, CHAR_WIDTH, textcolor);
}
