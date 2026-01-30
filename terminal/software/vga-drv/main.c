#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <pico/stdlib.h>
#include <hardware/i2c.h>
#include <pico/i2c_slave.h>
#include <hardware/pio.h>
#include <hardware/dma.h>
#include "ansi.h"

// Define I2C pins and slave address
#define I2C_SLAVE_ADDRESS 0x42
#define I2C_PORT i2c0
#define SDA_PIN 0
#define SCL_PIN 1

// Buffer definitions
#define BUFFER_SIZE 128
uint8_t ring_buffer[BUFFER_SIZE];
volatile uint8_t head = 0, tail = 0;

// Escape sequence buffer
#define ESC_BUFFER_SIZE 32
char esc_buffer[ESC_BUFFER_SIZE];
volatile uint8_t esc_index = 0;

int ring_buffer_read(uint8_t *data)
{
  if (head == tail) {
    return 0; // Buffer empty
  }
  *data = ring_buffer[tail];
  tail = (tail + 1) % BUFFER_SIZE;
  return 1;
}

static void i2c_slave_handler(i2c_inst_t *i2c, i2c_slave_event_t event)
{
  switch (event) {
  case I2C_SLAVE_RECEIVE:
    if (i2c_get_read_available(i2c)) {
      uint8_t data = i2c_read_byte_raw(i2c);
      uint8_t next = (head + 1) % BUFFER_SIZE;

      if (next == tail) {
        // Buffer overflow: Return NACK
        i2c_write_byte_raw(i2c, 0xFF); // Signal NACK
      } else {
        // Buffer has space: Store the received byte
        ring_buffer[head] = data;
        head = next;
      }
    }
    break;

  case I2C_SLAVE_FINISH:
    break;
  }
}

void handle_escape_code()
{
  int param1 = 0, param2 = 0;

  if (esc_buffer[0] == '[') {
    if (strcmp(esc_buffer, "[2J") == 0) {
      clearScreen();
      drawCharDefaults(' ');
    } else if (esc_buffer[3] == 'm' && esc_buffer[4] == '\0' || esc_buffer[4] == 'm' && esc_buffer[5] == '\0') {
      for (int i = 0; ansi_map[i].ansi_code != NULL; i++) {
        if (strcmp(esc_buffer, ansi_map[i].ansi_code) == 0) {
          if (ansi_map[i].is_foreground) {
            setColor(ansi_map[i].color);
          } else {
            setBgColor(ansi_map[i].color);
          }
          drawCharDefaults(' ');
          break;
        }
      }
    } else if (sscanf(esc_buffer, "[%d;%dH", &param1, &param2) == 2) {
      setCursorOff();
      setCursor((param2 - 1) * CHAR_WIDTH, (param1 - 1) * CHAR_HEIGHT);
    }
  }
}

int main()
{
  // Initialize VGA
  initVGA();
  clearScreen();
  setCursor(1, 1);

  stdio_init_all();

  // Initialize I2C with selected pins
  gpio_init(SDA_PIN);
  gpio_set_function(SDA_PIN, GPIO_FUNC_I2C);
  gpio_init(SCL_PIN);
  gpio_set_function(SCL_PIN, GPIO_FUNC_I2C);

  i2c_init(I2C_PORT, 400 * 1000); // 400 kHz
  i2c_slave_init(I2C_PORT, I2C_SLAVE_ADDRESS, &i2c_slave_handler);

  char in_escape = 0;

  // Main loop
  while (1) {
    uint8_t data;
    while (ring_buffer_read(&data)) { // Read data from ring buffer
      if (in_escape) {
        if ((data >= 'A' && data <= 'Z') || (data >= 'a' && data <= 'z')) {
          // End of ESC sequence
          if (esc_index < ESC_BUFFER_SIZE - 1) {
            esc_buffer[esc_index++] = data;
            esc_buffer[esc_index] = '\0';
            handle_escape_code();
          }
          in_escape = 0;
        } else if (esc_index < ESC_BUFFER_SIZE - 1) {
          esc_buffer[esc_index++] = data;
        }
      } else {
        if (data == '\033') { // ESC character
          in_escape = 1;
          esc_index = 0;
        } else if (data <= 127) {
          writeChar(data);
        }
      }
    }
    sleep_ms(10);
  }
}
