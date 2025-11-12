// ESP8266 based HTTP/HTTPS - serial proxy
// Copyright (c) 2025 Arvid Juskaitis

#include <WiFiClientSecure.h>
#include <ArduinoJson.h>
#include "writer.h"
#include "slowio.h"

#define NO_LIMIT 2147483647

// Write all available data from client to Serial (no filter)
void noFilter(WiFiClientSecure& client) {
    while (client.available()) {
        slowWrite(client.read());
    }
}

void filterSilent(WiFiClientSecure& client) {
    while (client.available()) {
        client.read(); // Discard all data
    }
}

void filterHeader(WiFiClientSecure& client) {
    String header;
    while (client.available()) {
        char c = client.read();
        header += c;
        if (header.endsWith("\r\n\r\n")) { // End of HTTP headers
            break;
        }
    }
    slowPrint(header, true);
}

void filterBody(WiFiClientSecure& client) {
    String body;
    bool headerSkipped = false;
    while (client.available()) {
        char c = client.read();
        if (!headerSkipped) {
            static String headerBuffer;
            headerBuffer += c;
            if (headerBuffer.endsWith("\r\n\r\n")) { // End of HTTP headers
                headerSkipped = true;
            }
        } else {
            body += c;
        }
    }
    slowPrint(body, true);
}

String getJsonBody(WiFiClientSecure& client, int limit) {
    String json;
    int count = 0;
    bool headerSkipped = false;
    while (client.available() && count < limit) {
        char c = client.read();
        if (!headerSkipped) {
            if (c == '{') {
                headerSkipped = true;
                json += c;
            }
        } else {
            json += c;
        }
        count++;
    }
    return json;
}

void filterJson(WiFiClientSecure& client) {
    String json = getJsonBody(client, NO_LIMIT);
    slowPrint(json, true);
}

void filterJsonOpenAI(WiFiClientSecure& client) {
    StaticJsonDocument<200> doc;
    String json = getJsonBody(client, 2400);
    DeserializationError error = deserializeJson(doc, json);
    if (error) {
        slowPrint("Error parsing JSON", true);
        return;
    }
    if (!doc["choices"] || !doc["choices"][0]["message"] || !doc["choices"][0]["message"]["content"]) {
        slowPrint("No matching data found", true);
        return;
    }
    String content = doc["choices"][0]["message"]["content"].as<String>();
    slowPrint(content, true);
}

void filterJsonMatrix(WiFiClientSecure& client) {
    StaticJsonDocument<200> doc;
    String json = getJsonBody(client, NO_LIMIT);
    DeserializationError error = deserializeJson(doc, json);
    if (error) {
        slowPrint("Error parsing JSON", true);
        return;
    }
    if (doc["end"]) {
        String end = doc["end"].as<String>();
        slowPrintln(end, true);
    }
    if (doc["chunk"] && doc["chunk"].is<JsonArray>()) {
        for (JsonObject chunk : doc["chunk"].as<JsonArray>()) {
            String item;
            if (chunk["sender"]) {
                String sender = chunk["sender"].as<String>();
                int colonIndex = sender.indexOf(':');
                if (colonIndex != -1) {
                    item = sender.substring(0, colonIndex);
                } else {
                    item = sender; // Fallback if no colon is found
                }
            }
            item += ": ";
            if (chunk["content"] && chunk["content"]["body"]) {
                item += chunk["content"]["body"].as<String>();
            } else {
                item += "[no body]";
            }
            slowPrintln(item, true);
        }
    } else {
        // Debugging: Log missing or invalid "chunk" field
        slowPrintln("Missing or invalid 'chunk' field", true);
    }
}

void write(const String& filter, WiFiClientSecure& client) {
    if (filter == "NONE") {
        noFilter(client);
    } else if (filter == "SILENT-FILTER") {
        filterSilent(client);
    } else if (filter == "HEADER-FILTER") {
        filterHeader(client);
    } else if (filter == "BODY-FILTER") {
        filterBody(client);
    } else if (filter == "JSON-FILTER") {
        filterJson(client);
    } else if (filter == "OPENAI-FILTER") {
        filterJsonOpenAI(client);
    } else if (filter == "MATRIX-FILTER") {
        filterJsonMatrix(client);
    } else {
        slowPrintln(">ERROR:UNKNOWN-FILTER");
    }
}
