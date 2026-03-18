@main
struct Application {
  static func main() {
    let board = Board()

    while true {
      board.led.toggle()
      board.sleep(milliseconds: 500)
    }
  }
}
