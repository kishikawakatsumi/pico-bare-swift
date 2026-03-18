# pico-bare-swift

Bare-metal Raspberry Pi Pico examples in Embedded Swift — no Pico SDK required.

Each example is a standalone SwiftPM project that builds a `.elf` firmware for the RP2040, written entirely in Swift (including the vector table, boot2, and startup code).

## Examples

| Example | Description |
|---------|-------------|
| [01-blink-minimal](01-blink-minimal) | LED blink with busy-wait delay. The absolute minimum bare-metal setup. |
| [02-blink-clock](02-blink-clock) | LED blink with XOSC, PLL (125MHz), and SysTick timer for precise timing. |

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

The output ELF is at `.build/armv6m-none-none-eabi/release/Application`.

## Flash

Convert to UF2 and copy to the Pico (in BOOTSEL mode):

```
swift ../Tools/elf2uf2.swift .build/armv6m-none-none-eabi/release/Application .build/firmware.uf2
cp .build/firmware.uf2 /Volumes/RPI-RP2/
```

The `Tools/elf2uf2.swift` script is included in this repository — no external tools required.

## Debug with VS Code

### Hardware

Connect a debug probe to the target Pico's SWD pins (SWCLK, SWDIO, GND). Either of these works:

- [Raspberry Pi Debug Probe](https://www.raspberrypi.com/products/debug-probe/)
- A second Raspberry Pi Pico running [Picoprobe](https://github.com/raspberrypi/picoprobe) firmware

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
    Boot2.swift           # RP2040 second stage bootloader (from Pico SDK)
    VectorTable.swift     # ARM Cortex-M0+ vector table and handlers
    Startup.swift         # Memory section initialization (.data, .bss)
    RuntimeStubs.swift    # Heap allocator, atomics, memcpy/memset
```

## License

This project is licensed under the [MIT License](LICENSE).

The boot2 binary and rp2040.svd file are derived from the [Raspberry Pi Pico SDK](https://github.com/raspberrypi/pico-sdk) and are licensed under the BSD 3-Clause License. See [THIRD-PARTY-NOTICES](THIRD-PARTY-NOTICES) for details.
