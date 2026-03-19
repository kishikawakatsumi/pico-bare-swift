# 05-oled-text

Displays text and a live uptime counter on a 128x64 SSD1306 OLED display over I2C.

![Demo](https://github.com/user-attachments/assets/2f13f2a3-4786-41ae-b269-9ca041b0cd57)

## What you'll learn

- I2C controller initialization (400kHz fast mode)
- SSD1306 OLED display initialization command sequence
- Framebuffer-based rendering with a 5x7 bitmap font
- Zero-allocation I2C communication (byte-by-byte TX)

## Wiring

![Wiring diagram](https://github.com/user-attachments/assets/322da340-24b0-4728-b386-96d940168c1b)

| Pico | SSD1306 |
| ---- | ------- |
| GP16 | SDA     |
| GP17 | SCL     |
| 3V3  | VCC     |
| GND  | GND     |
