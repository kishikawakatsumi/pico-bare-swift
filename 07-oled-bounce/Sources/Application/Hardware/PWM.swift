/// PWM (Pulse Width Modulation) controller (datasheet 4.5).
///
/// The RP2040 has 8 PWM slices, each with two channels (A and B).
/// GPIO pin n maps to slice (n / 2), channel (n % 2): A=0, B=1.
enum PWM {
  private static let base: UInt32 = 0x4005_0000

  // Per-slice registers (each slice occupies 0x14 bytes)
  private static func controlStatus(_ slice: UInt32) -> Register { Register(address: base + slice &* 0x14 + 0x00) }
  private static func clockDivider(_ slice: UInt32) -> Register { Register(address: base + slice &* 0x14 + 0x04) }
  private static func compareValue(_ slice: UInt32) -> Register { Register(address: base + slice &* 0x14 + 0x0C) }
  private static func wrapValue(_ slice: UInt32) -> Register { Register(address: base + slice &* 0x14 + 0x10) }

  /// Initializes a PWM slice for the given GPIO pin.
  ///
  /// Configures the pin's function to PWM and sets up the slice with
  /// 16-bit resolution (~1907 Hz at 125MHz).
  static func initialize(pin: UInt32) {
    Resets.unreset(.pwm)
    IOBank.setFunction(pin, .pwm)

    let slice = (pin >> 1) & 7
    clockDivider(slice).store(1 << 4)  // Divider = 1 (INT=1, FRAC=0)
    wrapValue(slice).store(65535)  // 16-bit resolution
    compareValue(slice).store(0)  // Start with 0% duty
    controlStatus(slice).store(1)  // Enable slice
  }

  /// Sets the duty cycle (0–65535) for the given GPIO pin.
  static func setDuty(pin: UInt32, duty: UInt32) {
    let slice = (pin >> 1) & 7
    let channel = pin & 1
    if channel == 0 {
      // Channel A: bits [15:0]
      compareValue(slice).store(duty & 0xFFFF)
    } else {
      // Channel B: bits [31:16]
      compareValue(slice).store((duty & 0xFFFF) << 16)
    }
  }
}
