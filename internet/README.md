Internet support for RC6502 Apple1 Replica 

TCP/IP support is done by http_proxy, implemented on ESP8266 MCU

http_proxy has templates for building requests, key-value database to store configuration, simple http/https engine, accepting commands from the client application, usint UART. This module helps to parse complex responses, like JSON documents.

Currently there are 3 applicaitons, using http_proxy - telnet, chatgpt client and chat program based on matrix.org api.
So, adding a new program is a matter of adding new configuration set with help of terminal program and writing a client to manage this configuration, send requests, receive response.
