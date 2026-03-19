@main
struct Application {
  static func main() {
    let board = Board()

    board.print("Hello from Embedded Swift!\r\n")
    board.print("LED fade start\r\n")

    // Fade LED in and out using PWM
    var brightness: UInt32 = 0
    let step: UInt32 = 256
    var increasing = true

    while true {
      board.led.setBrightness(brightness)
      board.sleep(milliseconds: 2)

      if increasing {
        brightness &+= step
        if brightness >= 65535 {
          brightness = 65535
          increasing = false
        }
      } else {
        if brightness <= step {
          brightness = 0
          increasing = true
        } else {
          brightness &-= step
        }
      }
    }
  }
}
