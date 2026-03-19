# 01-blink-minimal

The absolute minimum bare-metal setup. Blinks the on-board LED using a busy-wait loop — no clock configuration, no timer, no external hardware.

![Demo](https://github.com/user-attachments/assets/f299776c-f6b8-4e04-bf2a-f4d470662fcb)

## What you'll learn

- Vector table and Reset_Handler in Swift
- Boot2 bootloader as a Swift data literal
- GPIO output control via the SIO block
- Memory section initialization (.data / .bss)
- Runtime stubs required by Embedded Swift
