# 02-blink-clock

LED blink with precise timing. Configures the RP2040 clock system (XOSC → PLL → 125MHz) and uses the ARM SysTick timer for accurate delays.

![Demo](https://github.com/user-attachments/assets/2bbdff4d-3135-4e06-943e-0e4fcb91bf77)

## What you'll learn

- Crystal oscillator (XOSC) initialization
- PLL configuration for 125MHz system clock
- Clock generator switching (glitch-free mux)
- SysTick timer for millisecond-accurate delays
