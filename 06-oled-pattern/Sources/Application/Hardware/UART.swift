/// UART0 serial interface (datasheet 4.2).
///
/// 115200 baud, 8N1. TX/RX pins are specified at initialization.
enum UART {
  private static let base: UInt32 = 0x4003_4000

  private static let dataRegister = Register(address: base + 0x000)
  private static let flags = Register(address: base + 0x018)
  private static let integerBaudRate = Register(address: base + 0x024)
  private static let fractionalBaudRate = Register(address: base + 0x028)
  private static let lineControl = Register(address: base + 0x02C)
  private static let control = Register(address: base + 0x030)

  // Flag register bits
  private static let txFifoFull: UInt32 = 1 << 5

  // Control register bits
  private static let enable: UInt32 = 1 << 0
  private static let txEnable: UInt32 = 1 << 8
  private static let rxEnable: UInt32 = 1 << 9

  /// Initializes UART0 at 115200 baud (assuming 125MHz peripheral clock).
  ///
  /// - Parameters:
  ///   - tx: GPIO pin number for transmit (e.g., 0 or 16)
  ///   - rx: GPIO pin number for receive (e.g., 1 or 17)
  static func initialize(tx: UInt32, rx: UInt32) {
    Resets.unreset(.uart0)

    IOBank.setFunction(tx, .uart)
    IOBank.setFunction(rx, .uart)

    // Baud rate 115200 at 125MHz:
    // Divisor = 125_000_000 / (16 * 115200) = 67.8168...
    // IBRD = 67, FBRD = round(0.8168 * 64) = 52
    integerBaudRate.store(67)
    fractionalBaudRate.store(52)

    // 8 data bits, no parity, 1 stop bit, FIFO enabled
    lineControl.store(0x70)

    // Enable UART, TX, and RX
    control.store(enable | txEnable | rxEnable)
  }

  /// Writes a single byte, blocking until the TX FIFO has space.
  static func write(_ byte: UInt8) {
    while flags.load() & txFifoFull != 0 {}
    dataRegister.store(UInt32(byte))
  }

  /// Writes a string.
  static func write(_ string: StaticString) {
    for i in 0..<string.utf8CodeUnitCount {
      write(string.utf8Start[i])
    }
  }
}
