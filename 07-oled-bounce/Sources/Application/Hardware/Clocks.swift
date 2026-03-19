/// Clock generators — routes clock sources to peripherals (datasheet 2.15).
enum Clocks {
  private static let refControl = Register(address: 0x4000_8030)
  private static let refSelected = Register(address: 0x4000_8038)
  private static let sysControl = Register(address: 0x4000_803C)
  private static let sysSelected = Register(address: 0x4000_8044)
  private static let periControl = Register(address: 0x4000_8048)
  private static let resusControl = Register(address: 0x4000_8078)

  /// Configures the clock system for 125MHz operation.
  ///
  /// After this function returns:
  /// - clk_ref = XOSC (12MHz)
  /// - clk_sys = PLL_SYS (125MHz)
  /// - clk_peri = clk_sys (125MHz)
  static func initialize() {
    // Disable automatic fallback to ROSC
    resusControl.store(0)

    // Enable 12MHz crystal oscillator
    XOSC.initialize()

    // Move clocks to safe sources before reconfiguring PLL
    sysControl.clear(1 << 0)  // clk_sys → clk_ref
    while sysSelected.load() != 0x1 {}
    refControl.clear(0x3)  // clk_ref → ROSC
    while refSelected.load() != 0x1 {}

    // Configure PLL for 125MHz
    PLL.initialize()

    // Switch to final clock sources
    refControl.store(0x2)  // clk_ref → XOSC
    while refSelected.load() & (1 << 2) == 0 {}

    sysControl.store(0 << 5)  // AUXSRC = PLL_SYS
    sysControl.set(1 << 0)  // SRC = aux mux
    while sysSelected.load() & (1 << 1) == 0 {}

    periControl.store((1 << 11) | (0 << 5))  // clk_peri = clk_sys, enable
  }
}
