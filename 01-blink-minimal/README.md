# 01-blink-minimal

The absolute minimum bare-metal setup. Blinks the on-board LED using a busy-wait loop — no clock configuration, no timer, no external hardware.

![Demo](https://github.com/user-attachments/assets/f31747b0-8f59-4a07-9b5d-78130d22834b)

## What you'll learn

- Vector table and Reset_Handler in Swift
- Boot2 bootloader as a Swift data literal
- GPIO output control via the SIO block
- Memory section initialization (.data / .bss)
- Runtime stubs required by Embedded Swift
