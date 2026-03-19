import _Volatile

/// A 32-bit memory-mapped hardware register.
///
/// All reads and writes are volatile — the compiler will not optimize
/// them away or reorder them.
///
/// RP2040 provides atomic bit manipulation via address aliases:
///   - `set(_:)`   writes to base + 0x2000 (sets bits to 1)
///   - `clear(_:)` writes to base + 0x3000 (clears bits to 0)
///   - `xor(_:)`   writes to base + 0x1000 (toggles bits)
///
/// These avoid read-modify-write races without disabling interrupts.
struct Register {
  let address: UInt32

  /// Reads the register value.
  @inline(__always)
  func load() -> UInt32 {
    VolatileMappedRegister<UInt32>(unsafeBitPattern: UInt(address)).load()
  }

  /// Writes a value to the register.
  @inline(__always)
  func store(_ value: UInt32) {
    VolatileMappedRegister<UInt32>(unsafeBitPattern: UInt(address)).store(value)
  }

  /// Atomically sets bits (via +0x2000 alias).
  @inline(__always)
  func set(_ bits: UInt32) {
    VolatileMappedRegister<UInt32>(unsafeBitPattern: UInt(address &+ 0x2000)).store(bits)
  }

  /// Atomically clears bits (via +0x3000 alias).
  @inline(__always)
  func clear(_ bits: UInt32) {
    VolatileMappedRegister<UInt32>(unsafeBitPattern: UInt(address &+ 0x3000)).store(bits)
  }

  /// Atomically XORs (toggles) bits (via +0x1000 alias).
  @inline(__always)
  func xor(_ bits: UInt32) {
    VolatileMappedRegister<UInt32>(unsafeBitPattern: UInt(address &+ 0x1000)).store(bits)
  }
}
