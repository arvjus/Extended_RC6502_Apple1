// ESP8266 based HTTP/HTTPS - serial proxy
// Copyright (c) 2025 Arvid Juskaitis

#pragma once

void initConfig();
bool loadConfig();
bool saveConfig();
void handleSetConfig(const String& line);
String getConfigValue(const String& key);
  