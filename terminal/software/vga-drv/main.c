// VGA driver
// Copyright (c) 2025 Arvid Juskaitis

#include <stdio.h>
#include <stdlib.h>
#include <pico/stdlib.h>
#include <hardware/i2c.h>
#include <pico/i2c_slave.h>
#include <hardware/pio.h>
#include <hardware/dma.h>
#include "vga.h"

// Define I2C pins and slave address
#define I2C_SLAVE_ADDRESS 0x42
#define I2C_PORT i2c0
#define SDA_PIN 0
#define SCL_PIN 1

// Buffer to store received data
#define BUFFER_SIZE 12
uint8_t rx_buffer[BUFFER_SIZE];
volatile uint8_t rx_index = 0;

static void i2c_slave_handler(i2c_inst_t *i2c, i2c_slave_event_t event) {
    switch (event) {
        case I2C_SLAVE_RECEIVE: // master has written some data
            uint8_t data = i2c_read_byte_raw(i2c);
            if (rx_index < BUFFER_SIZE) {
                rx_buffer[rx_index++] = data;
            }
        case I2C_SLAVE_FINISH: // master has signalled Stop / Restart
            break;
    }
}

int main() {
    // Initialize VGA
    initVGA();
    clearScreen();

    stdio_init_all();

    // Initialize I2C with selected pins
    gpio_init(SDA_PIN);
    gpio_set_function(SDA_PIN, GPIO_FUNC_I2C);
    gpio_init(SCL_PIN);
    gpio_set_function(SCL_PIN, GPIO_FUNC_I2C);

    i2c_init(I2C_PORT, 400 * 1000); // 400 kHz
    i2c_slave_init(I2C_PORT, I2C_SLAVE_ADDRESS, &i2c_slave_handler);

    // Main loop
    while (1) {
        if (rx_index > 0) {
            uint8_t local_index;

            irq_set_enabled(I2C0_IRQ, false);
            local_index = rx_index;
            rx_index = 0;
            irq_set_enabled(I2C0_IRQ, true);

            // Process the received data
            for (uint8_t i = 0; i < local_index; i++) {
                writeChar(rx_buffer[i]);
            }
        }
        sleep_ms(10);
    }
}