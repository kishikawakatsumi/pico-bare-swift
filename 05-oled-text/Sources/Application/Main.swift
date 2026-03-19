@main
struct Application {
  static func main() {
    var board = Board()

    board.print("Hello from Embedded Swift!\r\n")

    var seconds: UInt32 = 0

    while true {
      let minutes = seconds / 60
      let secs = seconds % 60

      board.display.clear()
      board.display.drawText("Hello, Swift!", column: 0, row: 0)
      board.display.drawText("Embedded Swift", column: 0, row: 2)
      board.display.drawText("on RP2040", column: 0, row: 3)
      board.display.drawText("Uptime:", column: 0, row: 5)
      board.display.drawNumber(minutes, column: 0, row: 7, digits: 2)
      board.display.drawText(":", column: 2, row: 7)
      board.display.drawNumber(secs, column: 3, row: 7, digits: 2)
      board.display.flush()

      board.sleep(milliseconds: 1000)
      seconds &+= 1
    }
  }
}
