# 07-oled-bounce

A ball bounces around the OLED display, reflecting off all four edges. Demonstrates real-time animation with framebuffer clearing, circle drawing, and periodic display updates.

![Demo](https://github.com/user-attachments/assets/7e718b70-d5c7-46c4-83d8-b84b9dc0974e)

## What you'll learn

- Animation loop: clear → draw → flush → sleep
- Filled circle rendering
- Edge collision detection and velocity reflection
- Maintaining smooth frame rate with SysTick delays

## Wiring

![Wiring diagram](https://github.com/user-attachments/assets/5252f982-5d72-4040-af94-adfe39f45a1d)

| Pico | SSD1306 |
| ---- | ------- |
| GP16 | SDA     |
| GP17 | SCL     |
| 3V3  | VCC     |
| GND  | GND     |
