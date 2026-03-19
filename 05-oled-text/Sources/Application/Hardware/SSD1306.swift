/// SSD1306 128x64 OLED display driver over I2C.
///
/// The display is organized as 8 pages of 128 columns.
/// Each byte represents 8 vertical pixels (LSB = top).
enum SSD1306 {
  static let width = 128
  static let height = 64
  static let bufferSize = width * height / 8  // 1024 bytes

  private static let address: UInt8 = 0x3C

  /// Sends commands to the display (no heap allocation).
  private static func sendCommand(_ cmd: UInt8) {
    I2C.writeByte(address: address, 0x00)  // Control byte: command
    I2C.continueByteWithStop(cmd)
  }

  /// Sends a two-byte command.
  private static func sendCommand(_ cmd: UInt8, _ arg: UInt8) {
    I2C.writeByte(address: address, 0x00)
    I2C.continueByte(cmd)
    I2C.continueByteWithStop(arg)
  }

  /// Sends a three-byte command.
  private static func sendCommand(_ cmd: UInt8, _ arg1: UInt8, _ arg2: UInt8) {
    I2C.writeByte(address: address, 0x00)
    I2C.continueByte(cmd)
    I2C.continueByte(arg1)
    I2C.continueByteWithStop(arg2)
  }

  /// Initializes the SSD1306 for 128x64 display.
  static func initialize() {
    sendCommand(0xAE)  // Display OFF
    sendCommand(0xD5, 0x80)  // Clock divide ratio / oscillator frequency
    sendCommand(0xA8, 0x3F)  // Multiplex ratio = 63 (64 lines)
    sendCommand(0xD3, 0x00)  // Display offset = 0
    sendCommand(0x40)  // Start line = 0
    sendCommand(0x8D, 0x14)  // Enable charge pump
    sendCommand(0x20, 0x00)  // Horizontal addressing mode
    sendCommand(0xA1)  // Segment remap (column 127 = SEG0)
    sendCommand(0xC8)  // COM scan direction (remapped)
    sendCommand(0xDA, 0x12)  // COM pins config (128x64)
    sendCommand(0x81, 0x7F)  // Contrast = 127
    sendCommand(0xD9, 0xF1)  // Pre-charge period
    sendCommand(0xDB, 0x40)  // VCOMH deselect level
    sendCommand(0xA4)  // Display follows RAM
    sendCommand(0xA6)  // Normal display (not inverted)
    sendCommand(0xAF)  // Display ON
  }

  /// Writes a full framebuffer (1024 bytes) to the display.
  ///
  /// Sends bytes directly via I2C without heap allocation.
  static func draw(_ framebuffer: UnsafeBufferPointer<UInt8>) {
    // Set addressing window to full screen
    sendCommand(0x21, 0x00, 0x7F)  // Column range 0-127
    sendCommand(0x22, 0x00, 0x07)  // Page range 0-7

    // Send framebuffer as data stream
    I2C.writeByte(address: address, 0x40)  // Control byte: data
    for i in 0..<framebuffer.count {
      if i == framebuffer.count - 1 {
        I2C.continueByteWithStop(framebuffer[i])
      } else {
        I2C.continueByte(framebuffer[i])
      }
    }
  }

  /// Clears the display (all pixels off, no heap allocation).
  static func clear() {
    sendCommand(0x21, 0x00, 0x7F)
    sendCommand(0x22, 0x00, 0x07)

    I2C.writeByte(address: address, 0x40)
    for i in 0..<bufferSize {
      if i == bufferSize - 1 {
        I2C.continueByteWithStop(0x00)
      } else {
        I2C.continueByte(0x00)
      }
    }
  }
}
