# chatgpt program, uses M6850B ACIA + ESP8266

Connect from host (linux):
picocom --echo --omap crcrlf -b 28800 /dev/ttyUSB1

## Example session:
```
!CLEAR
!POST https://api.openai.com/v1/chat/completions
!HEAD Authorization: Bearer $(OPENAI-KEY)
!HEAD Content-Type: application/json
!BODY $(OPENAI-BODY)
!FILTER JSON-CONTENT
6502*
is it good?
```

## Screenshots

### ChatGpt client:
![chatgpt](https://github.com/arvjus/Extended_RC6502_Apple1/blob/main/gallery/chatgpt.jpeg?raw=1)
