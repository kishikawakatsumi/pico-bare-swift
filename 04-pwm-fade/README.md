# 04-pwm-fade

Smooth LED fade in and out using PWM. The on-board LED gradually brightens and dims instead of blinking on/off.

![Demo](https://github.com/user-attachments/assets/1d9450eb-4f60-47e5-8414-baa49492ba19)

## What you'll learn

- PWM slice and channel configuration
- GPIO-to-PWM-slice mapping (pin / 2 = slice, pin % 2 = channel)
- 16-bit duty cycle control for variable brightness
