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
func __aeabi_memcpy4(_ dest: UnsafeMutableRawPointer, _ src: UnsafeRawPointer, _ count: UInt) {
  memcpy(dest, src, count)
}
