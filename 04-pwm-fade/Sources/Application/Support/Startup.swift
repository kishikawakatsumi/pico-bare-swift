// Linker-defined section boundary symbols (see linker/memmap.ld).
// Their addresses — not values — represent the section boundaries.
// Equivalent to `extern char __data_org;` in C, where `&__data_org`
// gives the address.
@_extern(c, "__data_org") nonisolated(unsafe) var __data_org: UInt8
@_extern(c, "__data_start") nonisolated(unsafe) var __data_start: UInt8
@_extern(c, "__data_end") nonisolated(unsafe) var __data_end: UInt8
@_extern(c, "__bss_end") nonisolated(unsafe) var __bss_end: UInt8

/// Returns the address of a linker-defined symbol.
///
/// Equivalent to `(uintptr_t)&symbol` in C.
@inline(__always)
func linkerSymbolAddress(_ symbol: inout UInt8) -> UInt {
  withUnsafePointer(to: &symbol) { UInt(bitPattern: $0) }
}

/// Copies `.data` from ROM to RAM and zero-fills `.bss`.
///
/// Must run before any Swift code that uses global variables.
func initializeMemorySections() {
  var src = UnsafeMutablePointer<UInt32>(bitPattern: linkerSymbolAddress(&__data_org))!
  var dst = UnsafeMutablePointer<UInt32>(bitPattern: linkerSymbolAddress(&__data_start))!
  let dataEnd = UnsafeMutablePointer<UInt32>(bitPattern: linkerSymbolAddress(&__data_end))!
  let bssEnd = UnsafeMutablePointer<UInt32>(bitPattern: linkerSymbolAddress(&__bss_end))!

  while dst != dataEnd {
    dst.pointee = src.pointee
    dst = dst.advanced(by: 1)
    src = src.advanced(by: 1)
  }

  while dst != bssEnd {
    dst.pointee = 0
    dst = dst.advanced(by: 1)
  }
}
