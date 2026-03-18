/// Board-level abstraction for Raspberry Pi Pico.
struct Board {
  let led = LED()

  init() {
    Clocks.initialize()
    SysTick.initialize()
    Resets.unreset(.ioBank0)
    Resets.unreset(.padsBank0)
    led.initialize()
  }

  /// Delays for the specified number of milliseconds.
  func sleep(milliseconds ms: UInt32) {
    SysTick.delay(milliseconds: ms)
  }
}

/// On-board LED connected to GPIO25.
struct LED {
  private let pin: UInt32 = 25

  func initialize() {
    SIO.disableOutput(pin)
    SIO.clearOutput(pin)

    // Configure pad: enable output drive, disable input
    let padValue = PadsBank.read(pin)
    PadsBank.xor(pin, (padValue ^ 0x40) & 0xC0)

    IOBank.setFunction(pin, .sio)
    SIO.enableOutput(pin)
  }

  func on() { SIO.setOutput(pin) }
  func off() { SIO.clearOutput(pin) }
  func toggle() { SIO.toggleOutput(pin) }
}
