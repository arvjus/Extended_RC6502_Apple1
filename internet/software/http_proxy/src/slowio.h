// ESP8266 based HTTP/HTTPS - serial proxy
// Copyright (c) 2025 Arvid Juskaitis

#pragma once

#include <Arduino.h>

extern unsigned long slowioDelay;

void slowWrite(char ch, bool flush = true);
void slowPrint(const String& msg, bool flush = true);
void slowPrintln(const String& msg, bool flush = true);
