/*
 * Arduino Atmega328 (non-P), 16Mhz, no bootloader
 *
 * HW setup:
 * 
 * MUX1, MUX2 address lines - Pin 2, 3, 4 (2-4 bits Port D)
 * MUX1 strobe - Pin 5 (5 bit Port D)
 * MUX2 strobe - Pin 6 (6 bit Port D)
 * MUX1, MUX2 output - Pin 7 (7 bit Port D)
 * Ouput address lines - Pin 8, 9, 10 (0-2 bits Port B)
 */

#include <Arduino.h>
#include <Wire.h>

// I2C Slave address
#define SLAVE_ADDRESS 0x42

#define DEBOUNCE_TIME_MS    30
#define REPRESS_IGNORE_MS   200

#define KEY_SHIFT       (100 * 7 + 0)
#define KEY_CAPS_LOCK   (100 * 0 + 1)
#define KEY_DEL         (100 * 7 + 1)
#define KEY_CODE        (100 * 7 + 3)
#define KEY_UP          (100 * 3 + 8)
#define KEY_DOWN        (100 * 2 + 8)
#define KEY_F1          (100 * 4 + 1)
#define KEY_F2          (100 * 2 + 2)
#define KEY_F3          (100 * 1 + 1)
#define KEY_F4          (100 * 5 + 1)
#define KEY_F5          (100 * 6 + 2)
#define KEY_F6          (100 * 3 + 8)
#define KEY_F7          (100 * 2 + 8)
#define KEY_F8          (100 * 5 + 8)
#define KEY_F9          (100 * 0 + 2)
#define KEY_F10         (100 * 7 + 8)

// @formatter:off
static const uint8_t normal_keys[8][13] {
    //  0       1       2       3       4       5       6       7       8       9       10      11      12
        0,      0,      0,      0,      'z',    'x',    'c',    'v',    13,     '\'',   '.',    ',',    'm',
        0,      0,      0,      0,      0,      0,      0,      't',    0,      'a',    0,      '~',    'y',
        0,      '\t',   0,      0,      'q',    'w',    'e',    'r',    0,      'p',    'o',    'i',    'u',
        0,      0,      0,      0,      '1',    '2',    '3',    '4',    0,      '0',    '9',    '8',    '7',
        0,      0,      0,      0,      '#',    0,      0,      '5',    '\b',   '+',    0,      0,      '6',
        0,      0,      0,      0,      'a',    's',    'd',    'f',    0,      'o',    'l',    'k',    'j',
        0,      0,      0,      0,      0,      0,      0,      'g',    0,      'a',    0,      0,      'h',
        0,      0,      ' ',    0,      '>',    0,      0,      'b',    0,      '-',    0,      0,      'n'
};
static const uint8_t shifted_keys[8][13] {
    //  0       1       2       3       4       5       6       7       8       9       10      11      12
        0,      0,      0,      0,      'Z',    'X',    'C',    'V',    13,     '*',    ':',    ';',    'M',
        0,      0,      0,      0,      0,      0,      0,      'T',    0,      'A',    0,      '^',    'Y',
        0,      '\t',   0,      0,      'Q',    'W',    'E',    'R',    0,      'P',    'O',    'I',    'U',
        0,      0,      0,      0,      '!',    '"',    '@',    '$',    0,      '=',    ')',    '(',    '/',
        0,      0,      0,      0,      0,      0,      0,      '%',    '\b',   '?',    0,      '`',    '&',
        0,      0,      0,      0,      'A',    'S',    'D',    'F',    0,      'O',    'L',    'K',    'J',
        0,      0,      0,      0,      0,      0,      0,      'G',    0,      'A',    0,      0,      'H',
        0,      0,      ' ',    0,      '<',    0,      0,      'B',    0,      '_',    0,      0,      'N'
};
// @formatter:on

unsigned long last_key_press_time[8][13] = {0};

uint8_t caps_flag = 0;
uint8_t shift_flag = 0;
uint8_t code_flag = 0;
uint8_t uppercase_flag = 1;
uint8_t color_idx = 0;
bool trace = false;
char buff[20];

const char *color_sequences[]{"\033[37m", "\033[33m", "\033[92m", "\033[32m"};

// called up on an active key
// returns non-zero if character has handled
uint8_t handle_control_key(short row, short col) {
    switch (100 * row + col) {
        case KEY_CAPS_LOCK:
            caps_flag = !caps_flag;
            delay(100);
            return 1;
    }
    return 0;
}

bool display_char(char ch) {
    for (int i = 0; i < 3; ++i) {
        Wire.beginTransmission(SLAVE_ADDRESS);      // Begin communication with slave
        Wire.write(ch);                             // Send a byte of data
        uint8_t status = Wire.endTransmission();    // End communication
        if (status == 0)
            return true;
        delay(20);
    }
    return false;
}

bool display_string(const char *str) {
    for (int i = 0; i < 3; ++i) {
        Wire.beginTransmission(SLAVE_ADDRESS);      // Begin communication with slave
        Wire.write(str);                            // Send a byte of data
        uint8_t status = Wire.endTransmission();    // End communication
        if (status == 0)
            return true;
        delay(50);
    }
    return false;
}

void send_char(char ch) {
  if (trace) {
    snprintf(buff, sizeof(buff), " %c[%02X]", ch, ch);
    display_string(buff);
  }
  Serial.print(ch);
}

// called up on an active key
void handle_key(short row, short col) {
    unsigned long now = millis();
    if (now - last_key_press_time[row][col] < REPRESS_IGNORE_MS)
        return;

    last_key_press_time[row][col] = now;

    if (code_flag)
    switch (100 * row + col) {
        case 100 * 3 + 10:  // Code + '9'
            send_char(shift_flag ? '}' : ']');
            return;
        case 100 * 3 + 11:  // Code + '8'
            send_char(shift_flag ? '{' : '[');
            return;
        case 100 * 3 + 12:  // Code + '7'
            send_char('\\');
            return;
        case 100 * 7 + 4:  // Code + '<'
            send_char('|');
            return;
    }
    else         
    switch (100 * row + col) {
        case KEY_F1:  // <|-|>
            Serial.print((char)27);
            return;
        case KEY_F2:  // |<->|
            uppercase_flag = 1;
            return;
        case KEY_F3:  // |<->|
            uppercase_flag = 0;
            return;
        case KEY_F6:  // |<--
            trace = !trace;
            return;
        case KEY_F8:  // R
            display_string("\033[1;1H");
            display_string("\033[2J");
            return;
        case KEY_F9:  // Arrow up
            if (color_idx > 0) {
              display_string(color_sequences[--color_idx]);
            }
            return;
        case KEY_F10:  // Arrow down
            if (color_idx < 3) {
              display_string(color_sequences[++color_idx]);
            }
            return;
    }

    uint8_t ch = (shift_flag ^ caps_flag) ? shifted_keys[row][col] : normal_keys[row][col];
    if (ch != 0) {
        if (uppercase_flag && ch > 96 && ch < 123)
            ch -= 32;
        send_char((char) ch);
    }
}

void setup() {
    // Initialize I2C as master
    Wire.begin();
    Wire.setClock(400000); // Set I2C frequency to 400 kHz

    Serial.begin(250000);

    // Set pins as outputs for Port D
    DDRD |= (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5) | (1 << 6);

    // Set pin 7 as input
    DDRD &= ~(1 << 7);  // Clears bit 7 in DDRD to set as input

    // Set pins as outputs for Port C
    DDRC |= (1 << 0) | (1 << 1) | (1 << 2);
}

void loop() {
    unsigned long start = millis();
    for (int row = 0; row < 8; row++) {
        // Set output address lines on PORTC
        PORTC = (PORTC & 0b11111000) | (row & 0b00000111);
        delayMicroseconds(2);

        // Set strobe MUX1 low, MUX2 high
        PORTD = (PORTD | (1 << 6)) & ~(1 << 5);

        for (int col = 0; col < 8; col++) {
            // Set input address lines on PORTD
            PORTD = (PORTD & 0b11100011) | ((col & 0b00000111) << 2);
            delayMicroseconds(3);

            int on = (PIND & (1 << 7)) == 0;  // digitalRead(7);
            if (row == 7 && col == 0)         // hadle KEY_SHIFT
                shift_flag = on;
            else if (row == 7 && col == 3)    // hadle KEY_CODE
                code_flag = on;
            else if (on && !handle_control_key(row, col))
                handle_key(row, col);

        }

        // Set strobe MUX1 high, MUX2 low
        PORTD = (PORTD | (1 << 5)) & ~(1 << 6);

        for (int col = 0; col < 5; col++) {
            // Set input address lines (pins 2, 3, 4) on PORTD
            PORTD = (PORTD & 0b11100011) | ((col & 0b00000111) << 2);
            delayMicroseconds(3);

            int on = (PIND & (1 << 7)) == 0;  // digitalRead(7);
            if (on && !handle_control_key(row, col + 8))
                handle_key(row, col + 8);
        }
    }

    // debounce delay
    while (millis() - start < DEBOUNCE_TIME_MS) {
        if (Serial.available() > 0) {
            display_char(Serial.read());
        }
        delay(1);
    }
}
