@main
struct Application {
  static func main() {
    var board = Board()

    board.print("Hello from Embedded Swift!\r\n")
    board.print("Famicom controller demo\r\n")

    while true {
      board.display.clear()

      // Controller body
      board.display.drawRect(x: 4, y: 8, width: 120, height: 48)

      // --- D-pad (left side) ---
      let dpadCx = 32
      let dpadCy = 32
      let dpadW = 10   // width (short side)
      let dpadH = 13   // height (long side, direction of press)
      let dpadGap = 1

      // Up
      if board.controller.isUpPressed {
        board.display.fillRect(x: dpadCx - dpadW / 2, y: dpadCy - dpadH - dpadGap, width: dpadW, height: dpadH)
      } else {
        board.display.drawRect(x: dpadCx - dpadW / 2, y: dpadCy - dpadH - dpadGap, width: dpadW, height: dpadH)
      }

      // Down
      if board.controller.isDownPressed {
        board.display.fillRect(x: dpadCx - dpadW / 2, y: dpadCy + dpadGap, width: dpadW, height: dpadH)
      } else {
        board.display.drawRect(x: dpadCx - dpadW / 2, y: dpadCy + dpadGap, width: dpadW, height: dpadH)
      }

      // Left
      if board.controller.isLeftPressed {
        board.display.fillRect(x: dpadCx - dpadH - dpadGap, y: dpadCy - dpadW / 2, width: dpadH, height: dpadW)
      } else {
        board.display.drawRect(x: dpadCx - dpadH - dpadGap, y: dpadCy - dpadW / 2, width: dpadH, height: dpadW)
      }

      // Right
      if board.controller.isRightPressed {
        board.display.fillRect(x: dpadCx + dpadGap, y: dpadCy - dpadW / 2, width: dpadH, height: dpadW)
      } else {
        board.display.drawRect(x: dpadCx + dpadGap, y: dpadCy - dpadW / 2, width: dpadH, height: dpadW)
      }

      // D-pad center
      board.display.fillRect(
        x: dpadCx - dpadW / 2, y: dpadCy - dpadW / 2,
        width: dpadW, height: dpadW
      )

      // --- A and B buttons (right side) ---
      let btnRadius = 9

      // B button (left)
      let bx = 82
      let by = 34
      if board.controller.isBPressed {
        board.display.fillCircle(cx: bx, cy: by, radius: btnRadius)
      } else {
        board.display.drawCircle(cx: bx, cy: by, radius: btnRadius)
      }

      // A button (right)
      let ax = 106
      let ay = 34
      if board.controller.isAPressed {
        board.display.fillCircle(cx: ax, cy: ay, radius: btnRadius)
      } else {
        board.display.drawCircle(cx: ax, cy: ay, radius: btnRadius)
      }

      board.display.flush()
      board.sleep(milliseconds: 16)
    }
  }
}
