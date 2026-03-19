# 07-oled-bounce

A ball bounces around the OLED display, reflecting off all four edges. Demonstrates real-time animation with framebuffer clearing, circle drawing, and periodic display updates.

![Demo](https://github.com/user-attachments/assets/5aa86396-2dec-4c89-ad94-0c6f133e6c53)

## What you'll learn

- Animation loop: clear → draw → flush → sleep
- Filled circle rendering
- Edge collision detection and velocity reflection
- Maintaining smooth frame rate with SysTick delays

## Wiring

| Pico | SSD1306 |
| ---- | ------- |
| GP16 | SDA     |
| GP17 | SCL     |
| 3V3  | VCC     |
| GND  | GND     |
