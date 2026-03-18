/// Board-level abstraction for Raspberry Pi Pico.
struct Board {
  let led = LED()

  init() {
    Resets.unreset(.ioBank0)
    Resets.unreset(.padsBank0)
    led.initialize()
  }

  /// Busy-wait delay. Duration is approximate since no clock is configured.
  func sleep(iterations: UInt32) {
    let dummy = Register(address: 0xD000_0000)  // SIO base
    for _ in 0..<iterations {
      _ = dummy.load()  // Volatile read prevents loop elimination
    }
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
