/// 12MHz external crystal oscillator (datasheet 2.16).
enum XOSC {
  private static let control = Register(address: 0x4002_4000)
  private static let status = Register(address: 0x4002_4004)
  private static let startup = Register(address: 0x4002_400C)

  /// Enables the crystal oscillator and waits for it to stabilize.
  static func initialize() {
    control.store(0xAA0)  // FREQ_RANGE = 1-15MHz
    startup.store(47)  // ~1ms startup delay for 12MHz crystal
    control.set(0xFAB << 12)  // ENABLE
    while status.load() & (1 << 31) == 0 {}  // Wait for STABLE
  }
}
