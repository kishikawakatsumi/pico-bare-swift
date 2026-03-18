/// Peripheral reset controller.
///
/// RP2040 peripherals start in a reset state. To use a peripheral,
/// clear its reset bit and wait for the done flag.
enum Resets {
  private static let reset = Register(address: 0x4000_C000)
  private static let resetDone = Register(address: 0x4000_C008)

  /// Peripherals that can be reset.
  enum Peripheral: UInt32 {
    case ioBank0 = 5
    case padsBank0 = 8
    case pllSys = 12
    case uart0 = 22
  }

  /// Takes a peripheral out of reset and waits until it is ready.
  static func unreset(_ peripheral: Peripheral) {
    let mask: UInt32 = 1 << peripheral.rawValue
    reset.clear(mask)
    while resetDone.load() & mask == 0 {}
  }

  /// Puts a peripheral into reset.
  static func reset(_ peripheral: Peripheral) {
    reset.set(1 << peripheral.rawValue)
  }
}
