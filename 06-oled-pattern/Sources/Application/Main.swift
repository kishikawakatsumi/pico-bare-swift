@main
struct Application {
  static func main() {
    var board = Board()

    board.print("Hello from Embedded Swift!\r\n")
    board.print("Display test pattern\r\n")

    // Row 0: All pixels on (white bar)
    for x in 0..<SSD1306.width {
      for y in 0..<8 { board.display.setPixel(x: x, y: y) }
    }

    // Row 1: Vertical stripes (1px on, 1px off)
    for x in stride(from: 0, to: SSD1306.width, by: 2) {
      for y in 8..<16 { board.display.setPixel(x: x, y: y) }
    }

    // Row 2: Horizontal stripes (1px on, 1px off)
    for x in 0..<SSD1306.width {
      for y in stride(from: 16, to: 24, by: 2) { board.display.setPixel(x: x, y: y) }
    }

    // Row 3: Checkerboard (2x2)
    for x in 0..<SSD1306.width {
      for y in 24..<32 {
        if (x / 2 + y / 2) % 2 == 0 { board.display.setPixel(x: x, y: y) }
      }
    }

    // Row 4: Gradient (increasing density left to right)
    for x in 0..<SSD1306.width {
      for y in 32..<40 {
        if x % (1 + (SSD1306.width - x) / 16) == 0 { board.display.setPixel(x: x, y: y) }
      }
    }

    // Row 5: Border rectangle
    for x in 0..<SSD1306.width {
      board.display.setPixel(x: x, y: 40)
      board.display.setPixel(x: x, y: 47)
    }
    for y in 40..<48 {
      board.display.setPixel(x: 0, y: y)
      board.display.setPixel(x: SSD1306.width - 1, y: y)
    }

    // Row 6-7: Font sample
    board.display.drawText("ABCDEFGHIJKLMNOPQRSTU", column: 0, row: 6)
    board.display.drawText("0123456789 !@#$%&*().", column: 0, row: 7)

    board.display.flush()

    while true {
      board.sleep(milliseconds: 1000)
    }
  }
}
