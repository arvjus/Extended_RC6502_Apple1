
# ESP8266 based HTTP/HTTPS - serial proxy
# Copyright (c) 2025 Arvid Juskaitis

## General
Project built/managed with VSCode+PlatrofmIo
Board: Espressif Generic ESP8266 ESP-01 1M (esp01_1m)

## Serial communication
Baud rate 28800, 8n1. It jputs 5ms delay before sending each character to the wire.

## Wifi connection
Two variables WIFI-SSID, WIFI-PASS has to be set. Device tries to connect to WiFi during the first 5 sec. 

## Available commands (case sensitive):

All commands begins with '!'

### WIFI
Check wifi status

### RESET
Reset the device

### SET
List all key-values

### SET <VAR> [value]
Set or remove key values. Variables could be used as a template name or refered by $(KEY) syntax in GET, POST, HEAD, BODY, TEMPL commands.

### MARKERS ON|OFF
Show/hide markers (>DATA, >END, >STATUS)

### GET <url>
Set method and url -https:// and http:// are supported.

### POST <url>
Set method and url -https:// and http:// are supported.

### HEAD <header>
Set header values

### BODY <body>
Set body or template. Before sending, every "@CNT@" is replaced by content variable and "@CTX@" by context.

### FILTER <filter-name>
There are two values supported- NONE, JSON-CONTENT

### SEND
Invoke GET or POST method. 

### CLEAR
Reset all variables.

## Send free text

### <context>*
Set context, used in template.

### <content>
Set content, used in template. This command invokes SEND command.

