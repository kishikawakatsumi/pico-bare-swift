/// Board-level abstraction for Raspberry Pi Pico.
struct Board {
  let led = LED()
  var display = Display()
  let controller = Controller()

  init() {
    Clocks.initialize()
    SysTick.initialize()
    Resets.unreset(.ioBank0)
    Resets.unreset(.padsBank0)
    UART.initialize(tx: 0, rx: 1)
    led.initialize()
    display.initialize()
    controller.initialize()
  }

  /// Delays for the specified number of milliseconds.
  func sleep(milliseconds ms: UInt32) {
    SysTick.delay(milliseconds: ms)
  }

  /// Sends a string to UART0 (visible on Debug Probe's serial port).
  func print(_ message: StaticString) {
    UART.write(message)
  }
}

/// On-board LED connected to GPIO25, driven by PWM for brightness control.
struct LED {
  private let pin: UInt32 = 25

  func initialize() {
    let padValue = PadsBank.read(pin)
    PadsBank.xor(pin, (padValue ^ 0x40) & 0xC0)
    PWM.initialize(pin: pin)
  }

  /// Sets LED brightness (0 = off, 65535 = full brightness).
  func setBrightness(_ value: UInt32) {
    PWM.setDuty(pin: pin, duty: value)
  }
}

/// Famicom-style controller with 6 buttons (D-pad + A + B).
///
/// Buttons are active-low: connect each button between the GPIO pin and GND.
/// Internal pull-ups keep the pin high when the button is not pressed.
struct Controller {
  // GPIO pin assignments
  let pinUp: UInt32 = 2
  let pinDown: UInt32 = 3
  let pinLeft: UInt32 = 4
  let pinRight: UInt32 = 5
  let pinA: UInt32 = 6
  let pinB: UInt32 = 7

  func initialize() {
    // Configure all button pins as inputs with pull-ups
    let pins = [pinUp, pinDown, pinLeft, pinRight, pinA, pinB]
    for pin in pins {
      IOBank.setFunction(pin, .sio)
      SIO.disableOutput(pin)  // Input mode (don't drive the pin)
      PadsBank.enablePullUp(pin)
    }
  }

  var isUpPressed: Bool { SIO.isLow(pinUp) }
  var isDownPressed: Bool { SIO.isLow(pinDown) }
  var isLeftPressed: Bool { SIO.isLow(pinLeft) }
  var isRightPressed: Bool { SIO.isLow(pinRight) }
  var isAPressed: Bool { SIO.isLow(pinA) }
  var isBPressed: Bool { SIO.isLow(pinB) }
}

/// SSD1306 128x64 OLED display connected via I2C0 (GP16=SDA, GP17=SCL).
struct Display {
  private var framebuffer = [UInt8](repeating: 0, count: SSD1306.bufferSize)

  func initialize() {
    I2C.initialize(sda: 16, scl: 17)
    SSD1306.initialize()
    SSD1306.clear()
  }

  /// Clears the framebuffer.
  mutating func clear() {
    for i in 0..<framebuffer.count {
      framebuffer[i] = 0
    }
  }

  /// Sets a pixel at (x, y). Origin is top-left.
  mutating func setPixel(x: Int, y: Int) {
    guard x >= 0, x < SSD1306.width, y >= 0, y < SSD1306.height else { return }
    let page = y / 8
    let bit = y % 8
    framebuffer[page * SSD1306.width + x] |= UInt8(1 << bit)
  }

  /// Draws a filled rectangle.
  mutating func fillRect(x: Int, y: Int, width w: Int, height h: Int) {
    for dy in 0..<h {
      for dx in 0..<w {
        setPixel(x: x + dx, y: y + dy)
      }
    }
  }

  /// Draws a rectangle outline.
  mutating func drawRect(x: Int, y: Int, width w: Int, height h: Int) {
    for dx in 0..<w {
      setPixel(x: x + dx, y: y)
      setPixel(x: x + dx, y: y + h - 1)
    }
    for dy in 0..<h {
      setPixel(x: x, y: y + dy)
      setPixel(x: x + w - 1, y: y + dy)
    }
  }

  /// Draws a circle outline at (cx, cy) with the given radius.
  mutating func drawCircle(cx: Int, cy: Int, radius: Int) {
    // Midpoint circle algorithm
    var x = radius
    var y = 0
    var err = 1 - radius
    while x >= y {
      setPixel(x: cx + x, y: cy + y)
      setPixel(x: cx - x, y: cy + y)
      setPixel(x: cx + x, y: cy - y)
      setPixel(x: cx - x, y: cy - y)
      setPixel(x: cx + y, y: cy + x)
      setPixel(x: cx - y, y: cy + x)
      setPixel(x: cx + y, y: cy - x)
      setPixel(x: cx - y, y: cy - x)
      y += 1
      if err < 0 {
        err += 2 * y + 1
      } else {
        x -= 1
        err += 2 * (y - x) + 1
      }
    }
  }

  /// Draws a filled circle at (cx, cy) with the given radius.
  mutating func fillCircle(cx: Int, cy: Int, radius: Int) {
    for dy in -radius...radius {
      for dx in -radius...radius {
        if dx * dx + dy * dy <= radius * radius {
          setPixel(x: cx + dx, y: cy + dy)
        }
      }
    }
  }

  /// Draws a string at the given character position (column, row).
  mutating func drawText(_ text: StaticString, column: Int, row: Int) {
    var x = column * Font5x7.charWidth
    let pageOffset = row * SSD1306.width

    for i in 0..<text.utf8CodeUnitCount {
      let ch = text.utf8Start[i]
      if ch < 0x20 || ch > 0x7E { continue }
      let fontIndex = Int(ch - 0x20) * Font5x7.glyphWidth

      for col in 0..<Font5x7.glyphWidth {
        if x + col < SSD1306.width {
          framebuffer[pageOffset + x + col] = Font5x7.data[fontIndex + col]
        }
      }
      if x + Font5x7.glyphWidth < SSD1306.width {
        framebuffer[pageOffset + x + Font5x7.glyphWidth] = 0
      }
      x += Font5x7.charWidth
    }
  }

  /// Sends the framebuffer to the display.
  func flush() {
    framebuffer.withUnsafeBufferPointer { SSD1306.draw($0) }
  }
}
