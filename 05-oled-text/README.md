# 05-oled-text

Displays text and a live uptime counter on a 128x64 SSD1306 OLED display over I2C.

![Demo](https://github.com/user-attachments/assets/e2c5009f-71c1-4cae-9731-34b1f6aad5a8)

## What you'll learn

- I2C controller initialization (400kHz fast mode)
- SSD1306 OLED display initialization command sequence
- Framebuffer-based rendering with a 5x7 bitmap font
- Zero-allocation I2C communication (byte-by-byte TX)

## Wiring

![Wiring diagram](https://github.com/user-attachments/assets/5252f982-5d72-4040-af94-adfe39f45a1d)

| Pico | SSD1306 |
| ---- | ------- |
| GP16 | SDA     |
| GP17 | SCL     |
| 3V3  | VCC     |
| GND  | GND     |
