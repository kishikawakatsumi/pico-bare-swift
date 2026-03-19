@main
struct Application {
  static func main() {
    var board = Board()

    board.print("Hello from Embedded Swift!\r\n")
    board.print("Bouncing ball demo\r\n")

    let radius = 7
    var x = 30
    var y = 30
    var dx = 3
    var dy = 2

    while true {
      board.display.clear()
      board.display.fillCircle(cx: x, cy: y, radius: radius)
      board.display.flush()

      // Move ball
      x += dx
      y += dy

      // Bounce off edges (clamp to prevent sticking)
      if x - radius < 0 {
        x = radius
        dx = dx < 0 ? -dx : dx
      }
      if x + radius >= SSD1306.width {
        x = SSD1306.width - 1 - radius
        dx = dx > 0 ? -dx : dx
      }
      if y - radius < 0 {
        y = radius
        dy = dy < 0 ? -dy : dy
      }
      if y + radius >= SSD1306.height {
        y = SSD1306.height - 1 - radius
        dy = dy > 0 ? -dy : dy
      }

      board.sleep(milliseconds: 20)
    }
  }
}
