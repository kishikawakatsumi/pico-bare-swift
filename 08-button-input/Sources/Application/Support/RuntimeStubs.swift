// Runtime stubs for Embedded Swift on bare-metal ARM (armv6m).
//
// Embedded Swift still requires a few symbols normally provided by libc
// or libgcc. Since we link with -nostdlib, we provide them here.

// MARK: - Heap Allocator

// Swift's runtime allocates memory for class instances and existential
// containers via posix_memalign. This bump allocator starts right after
// the .bss section and grows upward. It never frees — sufficient for
// simple programs that don't dynamically create/destroy many objects.

nonisolated(unsafe) var heapPointer: UInt = 0

@c
func posix_memalign(
  _ memptr: UnsafeMutablePointer<UnsafeMutableRawPointer?>,
  _ alignment: UInt, _ size: UInt
) -> Int32 {
  if heapPointer == 0 {
    heapPointer = linkerSymbolAddress(&__bss_end)
  }
  var address = heapPointer
  address = (address &+ alignment &- 1) & ~(alignment &- 1)
  memptr.pointee = UnsafeMutableRawPointer(bitPattern: address)
  heapPointer = address &+ size
  return 0
}

@c
func free(_ ptr: UnsafeMutableRawPointer?) {}

// MARK: - Atomic Operations

// Swift uses __atomic_* builtins for reference counting (retain/release).
// Cortex-M0+ has no hardware atomics (LDREX/STREX), but on a single-core
// processor without preemptive interrupts, plain load/store is sufficient.

@c
func __atomic_load_4(_ ptr: UnsafePointer<UInt32>, _ memorder: Int32) -> UInt32 {
  ptr.pointee
}

@c
func __atomic_store_4(_ ptr: UnsafeMutablePointer<UInt32>, _ value: UInt32, _ memorder: Int32) {
  ptr.pointee = value
}

@c
func __atomic_fetch_add_4(
  _ ptr: UnsafeMutablePointer<UInt32>, _ value: UInt32, _ memorder: Int32
) -> UInt32 {
  let oldValue = ptr.pointee
  ptr.pointee = oldValue &+ value
  return oldValue
}

@c
func __atomic_fetch_sub_4(
  _ ptr: UnsafeMutablePointer<UInt32>, _ value: UInt32, _ memorder: Int32
) -> UInt32 {
  let oldValue = ptr.pointee
  ptr.pointee = oldValue &- value
  return oldValue
}

@c
func __atomic_compare_exchange_4(
  _ ptr: UnsafeMutablePointer<UInt32>,
  _ expected: UnsafeMutablePointer<UInt32>,
  _ desired: UInt32,
  _ successOrder: Int32,
  _ failureOrder: Int32
) -> Int32 {
  let current = ptr.pointee
  if current == expected.pointee {
    ptr.pointee = desired
    return 1
  }
  expected.pointee = current
  return 0
}

// MARK: - Memory Operations

// The compiler emits __aeabi_mem* calls for bulk memory operations.
// @inline(never) prevents the compiler from recognizing the byte loop
// and re-emitting the same call (infinite recursion).

@inline(never)
private func memclr(_ dest: UnsafeMutableRawPointer, _ count: UInt) {
  var i: UInt = 0
  while i < count {
    dest.advanced(by: Int(i)).storeBytes(of: UInt8(0), as: UInt8.self)
    i &+= 1
  }
}

@inline(never)
private func memset(_ dest: UnsafeMutableRawPointer, _ value: UInt8, _ count: UInt) {
  var i: UInt = 0
  while i < count {
    dest.advanced(by: Int(i)).storeBytes(of: value, as: UInt8.self)
    i &+= 1
  }
}

@inline(never)
private func memcpy(_ dest: UnsafeMutableRawPointer, _ src: UnsafeRawPointer, _ count: UInt) {
  var i: UInt = 0
  while i < count {
    let byte = src.advanced(by: Int(i)).load(as: UInt8.self)
    dest.advanced(by: Int(i)).storeBytes(of: byte, as: UInt8.self)
    i &+= 1
  }
}

@c
func __aeabi_memclr(_ dest: UnsafeMutableRawPointer, _ count: UInt) {
  memclr(dest, count)
}

@c
func __aeabi_memclr4(_ dest: UnsafeMutableRawPointer, _ count: UInt) {
  memclr(dest, count)
}

@c
func __aeabi_memset(_ dest: UnsafeMutableRawPointer, _ count: UInt, _ value: Int32) {
  memset(dest, UInt8(value & 0xFF), count)
}

@c
func __aeabi_memset4(_ dest: UnsafeMutableRawPointer, _ count: UInt, _ value: Int32) {
  memset(dest, UInt8(value & 0xFF), count)
}

@c
func __aeabi_memcpy(_ dest: UnsafeMutableRawPointer, _ src: UnsafeRawPointer, _ count: UInt) {
  memcpy(dest, src, count)
}

@c
func __aeabi_memcpy4(_ dest: UnsafeMutableRawPointer, _ src: UnsafeRawPointer, _ count: UInt) {
  memcpy(dest, src, count)
}

// MARK: - Integer Arithmetic

// Cortex-M0+ has no 64-bit multiply instruction. The implementation
// must use only 32-bit operations to avoid recursion — UInt64 &* UInt64
// would itself emit a call to __aeabi_lmul.

@c @inline(never)
func __aeabi_lmul(_ a: UInt64, _ b: UInt64) -> UInt64 {
  let aLo = UInt32(truncatingIfNeeded: a)
  let aHi = UInt32(truncatingIfNeeded: a >> 32)
  let bLo = UInt32(truncatingIfNeeded: b)
  let bHi = UInt32(truncatingIfNeeded: b >> 32)

  // 32x32 → 64 using 16-bit halves to avoid overflow
  let aLoL: UInt32 = aLo & 0xFFFF
  let aLoH: UInt32 = aLo >> 16
  let bLoL: UInt32 = bLo & 0xFFFF
  let bLoH: UInt32 = bLo >> 16

  let p0 = aLoL &* bLoL
  let p1 = aLoH &* bLoL
  let p2 = aLoL &* bLoH
  let p3 = aLoH &* bLoH

  let mid = (p0 >> 16) &+ (p1 & 0xFFFF) &+ (p2 & 0xFFFF)
  let resultLo = (p0 & 0xFFFF) | (mid << 16)
  let resultHi =
    p3 &+ (p1 >> 16) &+ (p2 >> 16) &+ (mid >> 16)
    &+ aHi &* bLo &+ aLo &* bHi

  return (UInt64(resultHi) << 32) | UInt64(resultLo)
}

// Cortex-M0+ has no hardware divider. Binary long division.

@c
func __aeabi_uidiv(_ numerator: UInt32, _ denominator: UInt32) -> UInt32 {
  if denominator == 0 { return 0 }
  var quotient: UInt32 = 0
  var remainder: UInt32 = 0
  var bit: Int32 = 31
  while bit >= 0 {
    remainder = (remainder << 1) | ((numerator >> UInt32(bit)) & 1)
    if remainder >= denominator {
      remainder &-= denominator
      quotient |= (1 << UInt32(bit))
    }
    bit &-= 1
  }
  return quotient
}

// __aeabi_uidivmod returns quotient in r0 and remainder in r1.
// The C ABI packs this as a 64-bit return: (remainder << 32) | quotient.

@c
func __aeabi_uidivmod(_ numerator: UInt32, _ denominator: UInt32) -> UInt64 {
  let q = __aeabi_uidiv(numerator, denominator)
  let r = numerator &- q &* denominator
  return (UInt64(r) << 32) | UInt64(q)
}

// Signed 32-bit division, implemented via unsigned division.

@c
func __aeabi_idiv(_ numerator: Int32, _ denominator: Int32) -> Int32 {
  if denominator == 0 { return 0 }
  let negative = (numerator < 0) != (denominator < 0)
  let n = numerator < 0 ? UInt32(0 &- numerator) : UInt32(numerator)
  let d = denominator < 0 ? UInt32(0 &- denominator) : UInt32(denominator)
  let q = __aeabi_uidiv(n, d)
  return negative ? Int32(bitPattern: 0 &- q) : Int32(bitPattern: q)
}

@c
func __aeabi_idivmod(_ numerator: Int32, _ denominator: Int32) -> UInt64 {
  let q = __aeabi_idiv(numerator, denominator)
  let r = numerator &- q &* denominator
  return (UInt64(UInt32(bitPattern: r)) << 32) | UInt64(UInt32(bitPattern: q))
}
