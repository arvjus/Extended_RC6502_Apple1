// ESP8266 based HTTP/HTTPS - serial proxy
// Copyright (c) 2025 Arvid Juskaitis

#include <ArduinoJson.h>
#include <LittleFS.h>
#include "slowio.h"
#include "config.h"

// Holds configuration data in memory
StaticJsonDocument<512> configDoc;
const char *CONFIG_FILE = "/config.json";

// Initialize configuration: mount FS and load config
void initConfig() {
    if (!LittleFS.begin()) {
        slowPrintln("Formatting file system..");
        LittleFS.format();
        if (!LittleFS.begin()) {
            slowPrintln("Failed to mount file system");
            return;
        }
    }
    loadConfig();
}

// Load configuration from file
bool loadConfig() {
    File file = LittleFS.open(CONFIG_FILE, "r");
    if (!file) return false;
    DeserializationError error = deserializeJson(configDoc, file);
    file.close();
    return !error;
}

// Save configuration to file
bool saveConfig() {
    File file = LittleFS.open(CONFIG_FILE, "w");
    if (!file) return false;
    serializeJson(configDoc, file);
    file.close();
    return true;
}

// Handle SET command: set, remove, or print config
void handleSetConfig(const String &line) {
    int firstSpace = line.indexOf(' ');
    int secondSpace = line.indexOf(' ', firstSpace + 1);

    if (firstSpace == -1) {
        slowPrintln("");
        for (JsonPair kv : configDoc.as<JsonObject>()) {
            slowPrint(kv.key().c_str());
            slowPrint(": ");
            slowPrintln(kv.value().as<String>());
        }
        return;
    }

    String key, value;
    if (secondSpace == -1) {
        key = line.substring(firstSpace + 1);
        value = "";
    } else {
        key = line.substring(firstSpace + 1, secondSpace);
        value = line.substring(secondSpace + 1);
    }

    if (value.length() > 0) {
        DynamicJsonDocument tempDoc(256);
        DeserializationError err = deserializeJson(tempDoc, value);
        configDoc[key] = err ? value : tempDoc.as<JsonVariant>();
    } else if (configDoc.containsKey(key)) {
        configDoc.remove(key);
    }

    saveConfig();
}

// Get a config value by key, print error if not found
String getConfigValue(const String& key) {
    if (configDoc.containsKey(key)) {
        return configDoc[key].as<String>();
    }
    slowPrint(">ERROR:KEY NOT FOUND: ");
    slowPrintln(key);
    return "";
}
