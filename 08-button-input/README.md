# 08-button-input

A Famicom-style controller is drawn on the OLED display. Press physical buttons connected to GPIO pins and see them react on screen in real time.

![Demo](https://github.com/user-attachments/assets/975a5b12-6a11-4641-9264-3447be5e5f6b)

## What you'll learn

- GPIO input with internal pull-ups (active-low buttons)
- Reading pin state via the SIO input register
- Combining input and display output in a real-time loop

## Wiring

![Wiring diagram](https://github.com/user-attachments/assets/35197fcf-4fa3-4771-a2d7-0c75354cb555)

### OLED Display (SSD1306)

| Pico | SSD1306 |
| ---- | ------- |
| GP16 | SDA     |
| GP17 | SCL     |
| 3V3  | VCC     |
| GND  | GND     |

### Buttons

Connect each button between the GPIO pin and GND. No external resistors needed (internal pull-ups are enabled).

| Pico | Button |
| ---- | ------ |
| GP2  | Up     |
| GP3  | Down   |
| GP4  | Left   |
| GP5  | Right  |
| GP6  | A      |
| GP7  | B      |
