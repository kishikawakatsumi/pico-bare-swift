/// I2C0 controller (datasheet 4.3).
///
/// Uses the DesignWare I2C IP block. Operates in master mode only.
enum I2C {
  private static let base: UInt32 = 0x4004_4000

  private static let control = Register(address: base + 0x00)
  private static let targetAddress = Register(address: base + 0x04)
  private static let dataCommand = Register(address: base + 0x10)
  private static let fastSCLHighCount = Register(address: base + 0x1C)
  private static let fastSCLLowCount = Register(address: base + 0x20)
  private static let clearTxAbort = Register(address: base + 0x54)
  private static let enable = Register(address: base + 0x6C)
  private static let status = Register(address: base + 0x70)
  private static let sdaHold = Register(address: base + 0x7C)
  private static let abortSource = Register(address: base + 0x80)
  private static let enableStatus = Register(address: base + 0x9C)
  private static let spikeSuppress = Register(address: base + 0xA0)

  // Status register bits
  private static let txFifoNotFull: UInt32 = 1 << 1
  private static let txFifoEmpty: UInt32 = 1 << 2
  private static let masterActivity: UInt32 = 1 << 5

  // Data command bits
  private static let stopBit: UInt32 = 1 << 9

  // Cached target address to avoid redundant disable/enable cycles
  nonisolated(unsafe) private static var currentTarget: UInt8 = 0xFF

  /// Initializes I2C0 in master mode at 400kHz (assuming 125MHz clk_sys).
  ///
  /// - Parameters:
  ///   - sda: GPIO pin number for data (e.g., 16)
  ///   - scl: GPIO pin number for clock (e.g., 17)
  static func initialize(sda: UInt32, scl: UInt32) {
    Resets.unreset(.i2c0)

    // Configure GPIO pins for I2C with pull-ups
    IOBank.setFunction(sda, .i2c)
    IOBank.setFunction(scl, .i2c)
    PadsBank.store(sda, 0x4A)
    PadsBank.store(scl, 0x4A)

    // Disable I2C before configuration
    enable.store(0)
    while enableStatus.load() & 1 != 0 {}

    // Master mode, fast speed (400kHz), restart enable, slave disable
    control.store(0x0165)

    // SCL timing for 400kHz at 125MHz
    fastSCLHighCount.store(125)
    fastSCLLowCount.store(187)

    // Spike suppression
    spikeSuppress.store(11)

    // SDA hold time (~300ns at 125MHz)
    sdaHold.store(38)

    // Leave disabled. The first call to setTarget() will enable the controller
    // after writing IC_TAR. IC_TAR must only be written while IC_ENABLE=0.
    currentTarget = 0xFF
  }

  /// Sets the target address. IC_TAR can only be written while disabled,
  /// so this disables the controller, writes IC_TAR, then re-enables.
  /// Skips if the address hasn't changed.
  private static func setTarget(_ address: UInt8) {
    if address == currentTarget { return }

    enable.store(0)
    while enableStatus.load() & 1 != 0 {}

    targetAddress.store(UInt32(address))
    currentTarget = address

    enable.store(1)
  }

  /// Clears any pending TX abort condition.
  private static func clearAbort() {
    if abortSource.load() != 0 {
      _ = clearTxAbort.load()
    }
  }

  /// Waits for TX FIFO space. Returns false on timeout.
  private static func waitTxReady() -> Bool {
    var waited: UInt32 = 0
    while status.load() & txFifoNotFull == 0 {
      waited &+= 1
      if waited > 100_000 {
        clearAbort()
        return false
      }
    }
    return true
  }

  /// Waits for the current transaction to complete.
  private static func waitIdle() {
    while status.load() & txFifoEmpty == 0 {}
    while status.load() & masterActivity != 0 {}
  }

  /// Begins a new transaction to the specified address.
  /// Sends a single byte without STOP.
  static func writeByte(address: UInt8, _ byte: UInt8) {
    setTarget(address)
    clearAbort()
    if !waitTxReady() { return }
    dataCommand.store(UInt32(byte))
  }

  /// Begins a new transaction and sends a single byte with STOP.
  static func writeByteWithStop(address: UInt8, _ byte: UInt8) {
    setTarget(address)
    clearAbort()
    if !waitTxReady() { return }
    dataCommand.store(UInt32(byte) | stopBit)
    waitIdle()
  }

  /// Sends a byte without STOP, within an ongoing transaction.
  static func continueByte(_ byte: UInt8) {
    if !waitTxReady() { return }
    dataCommand.store(UInt32(byte))
  }

  /// Sends a byte with STOP, ending the transaction.
  static func continueByteWithStop(_ byte: UInt8) {
    if !waitTxReady() { return }
    dataCommand.store(UInt32(byte) | stopBit)
    waitIdle()
  }
}
