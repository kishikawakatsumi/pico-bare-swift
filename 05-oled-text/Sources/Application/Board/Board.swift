/// Board-level abstraction for Raspberry Pi Pico.
struct Board {
  let led = LED()
  var display = Display()

  init() {
    Clocks.initialize()
    SysTick.initialize()
    Resets.reset(.i2c0)
    Resets.reset(.uart0)
    Resets.reset(.pwm)
    Resets.unreset(.ioBank0)
    Resets.unreset(.padsBank0)
    UART.initialize(tx: 0, rx: 1)
    led.initialize()
    display.initialize()
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
  ///
  /// - Parameters:
  ///   - text: The string to display.
  ///   - column: Character column (0-20).
  ///   - row: Character row / page (0-7).
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
      // 1-pixel spacing between characters
      if x + Font5x7.glyphWidth < SSD1306.width {
        framebuffer[pageOffset + x + Font5x7.glyphWidth] = 0
      }
      x += Font5x7.charWidth
    }
  }

  /// Draws a UInt32 value as decimal text at the given position.
  mutating func drawNumber(_ value: UInt32, column: Int, row: Int, digits: Int = 0) {
    // Convert to decimal digits (reversed)
    var buf: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0)  // max 10 digits for UInt32
    var n = value
    var count = 0
    repeat {
      buf.0 = UInt8(n % 10) + 0x30  // ASCII '0'
      // Shift digits manually (no array)
      buf.9 = buf.8
      buf.8 = buf.7
      buf.7 = buf.6
      buf.6 = buf.5
      buf.5 = buf.4
      buf.4 = buf.3
      buf.3 = buf.2
      buf.2 = buf.1
      buf.1 = buf.0
      n /= 10
      count += 1
    } while n > 0

    // Zero-pad if requested
    while count < digits {
      buf.0 = 0x30
      buf.9 = buf.8
      buf.8 = buf.7
      buf.7 = buf.6
      buf.6 = buf.5
      buf.5 = buf.4
      buf.4 = buf.3
      buf.3 = buf.2
      buf.2 = buf.1
      buf.1 = buf.0
      count += 1
    }

    // Draw digits from buf (stored in positions 1..count, reversed order)
    var x = column * Font5x7.charWidth
    let pageOffset = row * SSD1306.width
    // buf is arranged: buf.1 = most significant, buf[count] = least significant
    // Access via withUnsafePointer to index the tuple
    withUnsafePointer(to: &buf) { ptr in
      let bytes = UnsafeRawPointer(ptr).assumingMemoryBound(to: UInt8.self)
      for i in 1...count {
        let ch = bytes[i]
        if ch >= 0x20 && ch <= 0x7E {
          let fontIndex = Int(ch - 0x20) * Font5x7.glyphWidth
          for col in 0..<Font5x7.glyphWidth {
            if x + col < SSD1306.width {
              framebuffer[pageOffset + x + col] = Font5x7.data[fontIndex + col]
            }
          }
          if x + Font5x7.glyphWidth < SSD1306.width {
            framebuffer[pageOffset + x + Font5x7.glyphWidth] = 0
          }
        }
        x += Font5x7.charWidth
      }
    }
  }

  /// Sends the framebuffer to the display.
  func flush() {
    framebuffer.withUnsafeBufferPointer { SSD1306.draw($0) }
  }
}
