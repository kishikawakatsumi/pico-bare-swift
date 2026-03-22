# 02-blink-clock

LED blink with precise timing. Configures the RP2040 clock system (XOSC → PLL → 125MHz) and uses the ARM SysTick timer for accurate delays.

![Demo](https://github.com/user-attachments/assets/ab796d58-1f49-4950-b715-d3eaf771fe99)

## What you'll learn

- Crystal oscillator (XOSC) initialization
- PLL configuration for 125MHz system clock
- Clock generator switching (glitch-free mux)
- SysTick timer for millisecond-accurate delays
