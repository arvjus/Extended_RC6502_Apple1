// ESP8266 based HTTP/HTTPS - serial proxy
// Copyright (c) 2025 Arvid Juskaitis

#include <ESP8266WiFi.h>
#include <WiFiClientSecure.h>
#include "slowio.h"
#include "writer.h"
#include "config.h"


WiFiClientSecure client;
bool connected = false;
bool showMarkers = false;
String method = "";
String url = "";
String body = "";
String context = "";
String content = "";
String filter = "NONE";
struct Header {
    String key;
    String value;
};
Header headers[8];
int headerCount = 0;

String parseValue(const String& value);
void printRequest();
void sendRequest();
void printHelp();

void setup() {
    Serial.begin(28800);
    Serial.setTimeout(10000);
    initConfig();

    String delayStr = getConfigValue("DELAY");
    if (delayStr.length() > 0) {
        slowioDelay = delayStr.toInt();
    }

    WiFi.begin(getConfigValue("WIFI-SSID"), getConfigValue("WIFI-PASS"));
    client.setInsecure();

    int count = 50;
    while (WiFi.status() != WL_CONNECTED && --count) delay(100);
    connected = (WiFi.status() == WL_CONNECTED);
}

// Command handlers
void handleWifi() {
    if (connected) {
        slowPrintln(">WIFI CONNECTED, IP: " + WiFi.localIP().toString());
    } else {
        slowPrintln(">WIFI NOT CONNECTED");
    }
}
void handleHead(const String& line) {
    int sep = line.indexOf(':', 5);
    if (sep > 5 && headerCount < 8) {
        headers[headerCount].key = line.substring(5, sep);
        headers[headerCount].value = parseValue(line.substring(sep + 1));
        headers[headerCount].key.trim();
        headers[headerCount].value.trim();
        headerCount++;
    }
}
void handleMarkers(const String& line) { 
    String value = line.substring(8);
    value.trim();
    showMarkers = (value == "ON");
}
void handleClear() {
    method = "";
    url = "";
    body = "";
    context = "";
    content = "";
    filter = "NONE";
    headerCount = 0;
}

void loop() {
    if (Serial.available()) {
        String line = Serial.readStringUntil('\r');
        line.trim();
        if (line.length() == 0) return;
        if (line.charAt(0) == '!') {
            line = line.substring(1);
            if (line == "HELP") {
                printHelp();
            } else if (line.startsWith("SET")) {
                handleSetConfig(line);
            } else if (line.startsWith("MARKERS ")) {
                handleMarkers(line);
            } else if (line == "WIFI") {
                handleWifi();
            } else if (line == "RESET") {
                ESP.restart();
            } else if (line.startsWith("GET ")) {
                method = "GET";
                url = parseValue(line.substring(4));
            } else if (line.startsWith("PUT ")) {
                method = "PUT";
                url = parseValue(line.substring(4));
            } else if (line.startsWith("POST ")) {
                method = "POST";
                url = parseValue(line.substring(5));
            } else if (line.startsWith("HEAD ")) {
                handleHead(line);
            } else if (line.startsWith("BODY ")) {
                body = parseValue(line.substring(5));
            } else if (line.startsWith("FILTER ")) {
                filter = line.substring(7);
            } else if (line == "SEND") {
                sendRequest();
            } else if (line == "REQUEST") {
                printRequest();
            } else if (line == "CLEAR") {
                handleClear();
            }
        } else if (line.length() > 1 && line.charAt(line.length() - 1) == '*') {
            context = parseValue(line.substring(0, line.length() - 1));
        } else {
            content = parseValue(line);
            sendRequest();
        }
    }
}

void printHelp() {
    slowPrintln(">HELP");
    slowPrintln("!SET <key>=<value> - Set configuration value");
    slowPrintln("!MARKERS <on/off> - Enable/disable markers");
    slowPrintln("!WIFI - Check WiFi connection status");
    slowPrintln("!RESET - Restart the device");
    slowPrintln("!GET <url> - Set method and URL");
    slowPrintln("!PUT <url> - Set method and URL");
    slowPrintln("!POST <url> - Set method and URL");
    slowPrintln("!HEAD <key>:<value> - Add HTTP header");
    slowPrintln("!BODY <body> - Set request body (for POST)");
    slowPrintln("!FILTER <filter> - Set output filter (NONE, HEADER-FILTER, BODY-FILTER, STATUS-FILTER, SILENT-FILTER, JSON-FILTER, OPENAI-FILTER, MATRIX-FILTER)"); 
    slowPrintln("!SEND - Send the HTTP request");
    slowPrintln("!REQUEST - Print current request configuration");
    slowPrintln("!CLEAR - Clear current request configuration");
}   

void printRequest() {
    slowPrintln(">REQUEST");
    slowPrintln("METHOD: " + method);
    slowPrintln("URL: " + url);
    for (int i = 0; i < headerCount; i++) {
        slowPrintln("HEADER: " + headers[i].key + ": " + headers[i].value);
    }
    slowPrintln("BODY: " + body);
    slowPrintln("CONTEXT: " + context);
    slowPrintln("CONTENT: " + content);
    slowPrintln("FILTER: " + filter);
}

String getRandomNumberString(int length) {
    String result = "";
    for (int i = 0; i < length; i++) {
        result += String(random(0, 10));
    }
    return result;
}

void sendRequest() {
    if (method.length() == 0 || url.length() == 0) {
        slowPrintln(">ERROR:METHOD/URL MISSING");
        return;
    }

    String host;
    String path = "/";
    int port, schemeLength;

    if (url.startsWith("https://")) {
        port = 443;
        schemeLength = 8;
    } else if (url.startsWith("http://")) {
        port = 80;
        schemeLength = 7;
    } else {
        slowPrintln(">ERROR:URL MUST START WITH https:// or http://");
        return;
    }

    int pathIndex = url.indexOf('/', schemeLength);
    int hostPortEnd = pathIndex > 0 ? pathIndex : url.length();

    String hostPort = url.substring(schemeLength, hostPortEnd);

    int colonIndex = hostPort.indexOf(':');
    if (colonIndex >= 0) {
        host = hostPort.substring(0, colonIndex);
        port = hostPort.substring(colonIndex + 1).toInt();
    } else {
        host = hostPort;
    }

    if (pathIndex > 0) {
        path = url.substring(pathIndex);
    }

    if (!client.connect(host.c_str(), port)) {
        slowPrintln(">ERROR:CONNECT");
        return;
    }

    String bodyContent = body;
    if (bodyContent.length() > 0) {
        bodyContent.replace("@CTX@", context);
        bodyContent.replace("@CNT@", content);
    }

    client.println(method + " " + path + " HTTP/1.1");
    client.println("Host: " + host);
    for (int i = 0; i < headerCount; i++) {
        client.println(headers[i].key + ": " + headers[i].value);
    }
    if (method == "POST" || method == "PUT") {
        client.println("Content-Length: " + String(bodyContent.length()));
    }
    client.println("Connection: close");
    client.println("");
    if (method == "POST" || method == "PUT") {
        client.println(bodyContent);
    }

    // Parse response
    String status = client.readStringUntil('\n');
    status.trim();
    if (showMarkers)
        slowPrintln(">STATUS " + status);

    // Skip headers
    while (client.connected()) {
        String h = client.readStringUntil('\n');
        if (h == "\r" || h == "") break;
    }

    if (showMarkers)
        slowPrintln(">DATA");
    write(filter, client);
    slowPrintln("");
    slowWrite((char)0, true);
    if (showMarkers)
        slowPrintln(">END");

    client.stop();
}

String parseValue(const String& value) {
    String result;
    unsigned int pos = 0;
  
    while (pos < value.length()) {
      int start = value.indexOf("$(", pos);
      if (start == -1) {
        result += value.substring(pos);
        break;
      }
  
      result += value.substring(pos, start);
      int end = value.indexOf(')', start + 2);
  
      if (end == -1) {
        // No closing ), treat as literal
        result += value.substring(start);
        break;
      }
  
      String varName = value.substring(start + 2, end);
      String varValue = (varName == "RANDOM") ? getRandomNumberString(10) : getConfigValue(varName);
      result += varValue;
  
      pos = end + 1;
    }
  
    return result;
  }
