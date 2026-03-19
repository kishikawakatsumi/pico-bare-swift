# 07-oled-bounce

A ball bounces around the OLED display, reflecting off all four edges. Demonstrates real-time animation with framebuffer clearing, circle drawing, and periodic display updates.

![Demo](https://github.com/user-attachments/assets/91a9d76b-af2c-4332-8009-acacf2d1ef6f)

## What you'll learn

- Animation loop: clear → draw → flush → sleep
- Filled circle rendering
- Edge collision detection and velocity reflection
- Maintaining smooth frame rate with SysTick delays

## Wiring

![Wiring diagram](https://github.com/user-attachments/assets/322da340-24b0-4728-b386-96d940168c1b)

| Pico | SSD1306 |
| ---- | ------- |
| GP16 | SDA     |
| GP17 | SCL     |
| 3V3  | VCC     |
| GND  | GND     |
