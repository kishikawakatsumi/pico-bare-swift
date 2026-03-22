/// Default exception handler that halts the processor.
@c
func defaultHandler() {
  while true {}  // Infinite loop prevents returning to corrupted state
}

/// Entry point called by the hardware on reset (via the vector table).
@c
func resetHandler() {
  initializeMemorySections()
  Application.main()
}

/// ARM Cortex-M0+ vector table.
///
/// The hardware reads this table on reset:
/// - `[0]` Initial stack pointer
/// - `[1]` Reset handler (entry point)
/// - `[2]` NMI handler
/// - `[3]` Hard fault handler
@used  // Prevent dead-stripping by the linker
@section(".vector")  // Place in .vector section (beginning of .text in ROM)
let vectorTable:
  (
    UInt32,  // 0: Initial Stack Pointer
    @convention(c) () -> Void,  // 1: Reset Handler
    @convention(c) () -> Void,  // 2: NMI Handler
    @convention(c) () -> Void  // 3: Hard Fault Handler
  ) = (
    0x2004_0000,  // Top of SRAM: 0x20000000 + 256K
    resetHandler,  // Called by hardware on power-on/reset
    defaultHandler,
    defaultHandler
  )
