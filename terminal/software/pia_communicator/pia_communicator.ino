#include <Arduino.h>
#include "MCP23S17.h"
#include <SPI.h>

#define DEBUG false
#define KBD_INTERRUPT_ENABLE true
#define KBD_SEND_TIMEOUT 23

#define IO_SS 10

#define IO_VIDEO 0
#define IO_VIDEO_D0 0
#define IO_VIDEO_D6 6
#define VIDEO_RDA 5
#define VIDEO_DA 3

#define IO_KBD 1
#define IO_KBD_D0 8
#define IO_KBD_D6 14
#define IO_KBD_DA 15
#define KBD_READY 2
#define KBD_STROBE 4

MCP23S17 bridge(&SPI, IO_SS, 0);
unsigned long previousMillis = 0; 

void setup() {
  configure_pins();
  configure_bridge();

  Serial.begin(250000);
  Serial.println("RC6502 Apple 1 Replica");
}

void configure_pins() {
  pinMode(KBD_READY, INPUT);
  pinMode(VIDEO_DA, INPUT);
  pinMode(KBD_STROBE, OUTPUT);
  pinMode(VIDEO_RDA, OUTPUT);
}

void configure_bridge() {
  bridge.begin();

  /* Configure video section */
  for (int i = IO_VIDEO_D0; i <= IO_VIDEO_D6; i++) {
    bridge.pinMode(i, INPUT);
  }
  bridge.pinMode(7, INPUT_PULLUP);

  /* Configure keyboard section */
  for (int i = 8; i <= 15; i++) {
    bridge.pinMode(i, OUTPUT);
  }
}

void serial_receive() {
  if (Serial.available() > 0) {
    int c = Serial.read();
#if DEBUG
    char buff[20];
    snprintf(buff, sizeof(buff), "%c{{%02X}} ", c, c);
    Serial.print(buff);
#endif    
    pia_send(c);
  }
}

void pia_send(int c) {
  /* Make sure STROBE signal is off */
  digitalWrite(KBD_STROBE, LOW);
  c = map_to_ascii(c);

  /* Output the actual keys as long as it's supported */
  if (c <= 127) {
    bridge.writePort(IO_KBD, c | 128);

    digitalWrite(KBD_STROBE, HIGH);
#if KBD_INTERRUPT_ENABLE
      byte timeout;

      /* Wait for KBD_READY (CA2) to go HIGH */
      timeout = KBD_SEND_TIMEOUT;
      while(timeout -- > 0 && digitalRead(KBD_READY) != HIGH)
        delay(1);
      digitalWrite(KBD_STROBE, LOW);

      /* Wait for KBD_READY (CA2) to go LOW */
      timeout = KBD_SEND_TIMEOUT;
      while(timeout -- > 0 && digitalRead(KBD_READY) != LOW)
        delay(1);
#else
      delay(KBD_SEND_TIMEOUT);
      digitalWrite(KBD_STROBE, LOW);
#endif
  }
}

char map_to_ascii(int c) {
  /* Convert DEL to BS */
  if (c == 0x7F) {
    c = 8;
  }

  /* Convert lowercase keys to UPPERCASE 
  if (c > 96 && c < 123) {
    c -= 32;
  }*/
  
  return c;
}

void serial_transmit() {
  digitalWrite(VIDEO_RDA, HIGH);

  if (digitalRead(VIDEO_DA)) {
    delay(2);
    char c = bridge.readPort(IO_VIDEO) & 127;
    delay(2);
    digitalWrite(VIDEO_RDA, LOW);

    if (c == 0x7f)
      reset_spi();
    else
      Serial.print(c);
  }
}

void reset_spi() {
    SPI.end();
    configure_bridge();
    previousMillis = millis(); 
}

void loop() {
  if (millis() - previousMillis >= 180000) {  // reset every 3 min
    reset_spi();
  }

  serial_receive();
  serial_transmit();
}
