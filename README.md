# pico-bare-swift

Bare-metal Raspberry Pi Pico examples in Embedded Swift — no Pico SDK required.

Each example is a standalone SwiftPM project that builds a `.elf` firmware for the RP2040, written entirely in Swift (including the vector table, boot2, and startup code).

## Examples

| Example | Description |
|---------|-------------|
| [01-blink-minimal](01-blink-minimal) | LED blink with busy-wait delay. The absolute minimum bare-metal setup. |
| [02-blink-clock](02-blink-clock) | LED blink with XOSC, PLL (125MHz), and SysTick timer for precise timing. |
| [03-uart-print](03-uart-print) | UART debug output via Debug Probe. Prints messages to a serial console. |
| [04-pwm-fade](04-pwm-fade) | Smooth LED fade in/out using PWM for brightness control. |
| [05-oled-text](05-oled-text) | SSD1306 OLED display over I2C. Shows text and a live uptime counter. |
| [06-oled-pattern](06-oled-pattern) | Display test patterns: stripes, checkerboard, gradient, and font sample. |
| [07-oled-bounce](07-oled-bounce) | Bouncing ball animation on the OLED display. |
| [08-button-input](08-button-input) | GPIO button input with a Famicom-style controller displayed on the OLED. |

> **Note**: These examples are designed for the **Raspberry Pi Pico** (not Pico W). On the Pico W, the on-board LED is connected to the CYW43439 WiFi chip (WL_GPIO0), not to RP2040 GPIO25. Controlling it requires SPI communication with the WiFi chip and loading its firmware — a much more complex setup that these examples do not cover.

## Requirements

- **Swift toolchain**: A recent `main` development snapshot from [swift.org](https://www.swift.org/install/)
- **[swiftly](https://github.com/swiftlang/swiftly)** (recommended): The `.swift-version` file in each project selects the correct toolchain automatically

Install with swiftly:

```
swiftly install main-snapshot
```

## Build

```
cd 01-blink-minimal
make release
```

Or directly with `swift build`:

```
swift build --triple armv6m-none-none-eabi -c release --toolset toolset.json
```

The output ELF is at `.build/armv6m-none-none-eabi/release/Application`. Running `make` or `make release` also generates `.build/firmware.uf2`.

## Flash

### Option 1: UF2 (no debug probe needed)

Hold the **BOOTSEL** button on the Pico while plugging it into USB. It appears as a USB drive. Copy the UF2 file:

```
cp .build/firmware.uf2 /Volumes/RPI-RP2/
```

To generate the UF2 manually:

```
swift ../Tools/elf2uf2.swift .build/armv6m-none-none-eabi/release/Application .build/firmware.uf2
```

The `Tools/elf2uf2.swift` script is included in this repository — no external tools required.

### Option 2: Debug probe (flash + debug)

See the [Debug with VS Code](#debug-with-vs-code) section below.

## Hardware Setup

### 01-blink-minimal, 02-blink-clock

No extra wiring needed. Uses the on-board LED (GPIO25).

### 03-uart-print

Requires a [Debug Probe](#debug-with-vs-code) connected to the target Pico's UART pins (GP0/GP1). See the wiring details in the [debug section](#debug-with-vs-code) below.

> **Tip**: The UART pins can be changed in `Board.swift`. For example, to use the other side of the board: `UART.initialize(tx: 16, rx: 17)`.

## Debug with VS Code

### Hardware

The [Raspberry Pi Debug Probe](https://www.raspberrypi.com/products/debug-probe/) is a small USB device that connects to a Pico's debug and serial pins. It lets you flash firmware, set breakpoints, and view UART output from your computer — without unplugging cables each time.

![Debug Probe connected to Pico](https://github.com/user-attachments/assets/295dbefb-3eb5-4a79-9275-e6b3bd2a419b)

> Images from [Raspberry Pi Debug Probe documentation](https://www.raspberrypi.com/documentation/microcontrollers/debug-probe.html) (CC BY-SA 4.0)

Alternatively, a second Raspberry Pi Pico running [Picoprobe](https://github.com/raspberrypi/picoprobe) firmware can serve the same purpose.

**SWD** (debug and flash) — connect to the 3-pin debug header on the bottom of the Pico, next to the USB connector:

| Debug Probe | Target Pico | Description |
|-------------|-------------|-------------|
| SWCLK       | SWCLK       | Serial Wire Clock |
| SWDIO       | SWDIO       | Serial Wire Data |
| GND         | GND         | Common ground |

**UART** (serial output for 03-uart-print) — connect to the GPIO header:

| Debug Probe | Target Pico | Description |
|-------------|-------------|-------------|
| UART TX     | GP1 (pin 2) | Debug Probe transmits to Pico RX |
| UART RX     | GP0 (pin 1) | Pico TX to Debug Probe receive |
| UART GND    | GND (pin 3) | Common ground |

![Debug Probe wiring diagram](https://github.com/user-attachments/assets/df016347-3410-4b1e-b370-dbba05b4fd70)

> Images from [Raspberry Pi Debug Probe documentation](https://www.raspberrypi.com/documentation/microcontrollers/debug-probe.html) (CC BY-SA 4.0)

To view UART output, open a serial console at **115200 baud**:

```
screen /dev/tty.usbmodem* 115200
```

(Press `Ctrl-A` then `K` to exit `screen`.)

### Software

1. Install [OpenOCD](https://openocd.org/):

   ```
   brew install openocd
   ```

2. Install [ARM GNU Toolchain](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads) (for `arm-none-eabi-gdb`).

3. Install the [Cortex-Debug](https://marketplace.visualstudio.com/items?itemName=marus25.cortex-debug) extension in VS Code.

4. Set `armToolchainPath` in `.vscode/launch.json` to your ARM GNU Toolchain `bin` directory:

   ```json
   "armToolchainPath": "/path/to/arm-gnu-toolchain/bin"
   ```

   If installed via `brew install --cask gcc-arm-embedded`, leave it empty (the tools are already in PATH).

### Launch

Each example includes `.vscode/launch.json` and `.vscode/tasks.json` pre-configured for debugging. Open an example folder in VS Code and press **F5** to:

1. Build the debug ELF
2. Flash it to the Pico via OpenOCD
3. Start a debug session with breakpoints, stepping, and register inspection

The `rp2040.svd` file provides peripheral register names in the debug view.

## Project Structure

Each example follows the same layout:

```
Sources/Application/
  Main.swift              # Application entry point
  Board/
    Board.swift           # Board and LED abstraction
  Hardware/
    MMIO.swift            # Register type for volatile hardware access
    GPIO.swift            # SIO, IOBank, PadsBank
    Resets.swift          # Peripheral reset controller
    ...                   # Additional peripherals per example
  Support/
    Boot2.swift           # RP2040 second stage bootloader binary (from Pico SDK)
    VectorTable.swift     # ARM Cortex-M0+ vector table and handlers
    Startup.swift         # Memory section initialization (.data, .bss)
    RuntimeStubs.swift    # Heap allocator, atomics, memcpy/memset
```

## Support

If you find this project useful, consider [sponsoring](https://github.com/sponsors/kishikawakatsumi) to support continued development.

## License

This project is licensed under the [MIT License](LICENSE).

The boot2 binary and rp2040.svd file are derived from the [Raspberry Pi Pico SDK](https://github.com/raspberrypi/pico-sdk) and are licensed under the BSD 3-Clause License. See [THIRD-PARTY-NOTICES](THIRD-PARTY-NOTICES) for details.
