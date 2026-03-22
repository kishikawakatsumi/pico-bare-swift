# 06-oled-pattern

Displays test patterns on the SSD1306 OLED: solid fill, vertical/horizontal stripes, checkerboard, gradient, border, and a font sample.

![Demo](https://github.com/user-attachments/assets/ef81467c-cd8d-425e-a7de-9f9d5339668c)

## What you'll learn

- Pixel-level framebuffer manipulation
- Drawing geometric patterns with setPixel
- Full ASCII font rendering

## Wiring

![Wiring diagram](https://github.com/user-attachments/assets/3f4e80be-114b-4254-8dcf-7ebfb7c030d1)

| Pico | SSD1306 |
| ---- | ------- |
| GP16 | SDA     |
| GP17 | SCL     |
| 3V3  | VCC     |
| GND  | GND     |
