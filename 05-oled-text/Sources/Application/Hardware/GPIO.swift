/// Single-cycle I/O block — controls GPIO output and direction.
enum SIO {
  private static let base: UInt32 = 0xD000_0000

  private static let outputSet = Register(address: base + 0x14)
  private static let outputClear = Register(address: base + 0x18)
  private static let outputXor = Register(address: base + 0x1C)
  private static let outputEnableSet = Register(address: base + 0x24)
  private static let outputEnableClear = Register(address: base + 0x28)

  static func setOutput(_ pin: UInt32) { outputSet.store(1 << pin) }
  static func clearOutput(_ pin: UInt32) { outputClear.store(1 << pin) }
  static func toggleOutput(_ pin: UInt32) { outputXor.store(1 << pin) }
  static func enableOutput(_ pin: UInt32) { outputEnableSet.store(1 << pin) }
  static func disableOutput(_ pin: UInt32) { outputEnableClear.store(1 << pin) }
}

/// GPIO function multiplexer — selects which peripheral drives each pin.
enum IOBank {
  private static let base: UInt32 = 0x4001_4000

  /// Available pin functions (datasheet 2.19.2).
  enum Function: UInt32 {
    case uart = 2
    case i2c = 3
    case pwm = 4
    case sio = 5
  }

  /// Assigns a function to a GPIO pin.
  static func setFunction(_ pin: UInt32, _ function: Function) {
    Register(address: base + 0x04 + pin &* 8).store(function.rawValue)
  }
}

/// Pad electrical configuration — drive strength, pull-ups, slew rate.
enum PadsBank {
  private static let base: UInt32 = 0x4001_C000

  private static func pad(_ pin: UInt32) -> Register {
    Register(address: base + 0x04 + pin &* 4)
  }

  static func store(_ pin: UInt32, _ value: UInt32) {
    pad(pin).store(value)
  }

  static func read(_ pin: UInt32) -> UInt32 {
    pad(pin).load()
  }

  static func xor(_ pin: UInt32, _ bits: UInt32) {
    pad(pin).xor(bits)
  }

  /// Enables pull-up and input for I2C pins.
  static func enablePullUp(_ pin: UInt32) {
    // Set PUE (pull-up enable, bit 3), clear PDE (pull-down, bit 2),
    // ensure IE (input enable, bit 6) and SCHMITT (bit 1) are set
    let reg = pad(pin)
    var value = reg.load()
    value |= (1 << 3) | (1 << 6) | (1 << 1)  // PUE, IE, SCHMITT
    value &= ~UInt32(1 << 2)  // Clear PDE
    reg.store(value)
  }
}
