@main
struct Application {
  static func main() {
    let board = Board()

    board.print("Hello from Embedded Swift!\r\n")
    board.print("LED blink start\r\n")

    while true {
      board.led.toggle()
      board.sleep(milliseconds: 500)
    }
  }
}
