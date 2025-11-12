// ESP8266 based HTTP/HTTPS - serial proxy
// Copyright (c) 2025 Arvid Juskaitis

#include "slowio.h"

#define DEFAULT_SLOWIO_DELAY 5
unsigned long slowioDelay = DEFAULT_SLOWIO_DELAY;

// Write a single character to Serial with delay
void slowWrite(char ch, bool flush) {
    delay(slowioDelay);
    Serial.write(ch);
    if (flush) Serial.flush();
}

// Write a string to Serial with delay between each character
void slowPrint(const String& msg, bool flush) {
    for (size_t i = 0; i < msg.length(); ++i) {
        delay(slowioDelay);
        Serial.write(msg[i]);
        if (flush) Serial.flush();
    }
}

// Write a string followed by CRLF to Serial with delay
void slowPrintln(const String& msg, bool flush) {
    slowPrint(msg, flush);
    slowPrint("\r\n", flush);
}
