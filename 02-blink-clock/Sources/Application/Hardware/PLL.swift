/// System PLL — generates 125MHz from the 12MHz XOSC (datasheet 2.18).
///
/// PLL formula: `f_out = (f_ref / REFDIV) x FBDIV / (POSTDIV1 x POSTDIV2)`
///
/// Default configuration: `(12MHz / 1) x 125 / (6 x 2) = 125MHz`
enum PLL {
  private static let controlStatus = Register(address: 0x4002_8000)
  private static let power = Register(address: 0x4002_8004)
  private static let feedbackDivider = Register(address: 0x4002_8008)
  private static let postDivider = Register(address: 0x4002_800C)

  /// Configures PLL_SYS for 125MHz output.
  static func initialize() {
    Resets.reset(.pllSys)
    Resets.unreset(.pllSys)
    controlStatus.store(1)  // REFDIV = 1
    feedbackDivider.store(125)  // VCO = 12MHz x 125 = 1500MHz
    power.store(0x2C)  // Power on VCO (clear PD + VCOPD)
    while controlStatus.load() & (1 << 31) == 0 {}  // Wait for lock
    postDivider.store((6 << 16) | (2 << 12))  // POSTDIV1=6, POSTDIV2=2
    power.clear(1 << 3)  // Enable post dividers → 125MHz
  }
}
