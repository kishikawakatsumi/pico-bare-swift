#!/usr/bin/env swift

/// Converts an ARM ELF binary to UF2 format for RP2040.
///
/// Usage: swift elf2uf2.swift <input.elf> <output.uf2>

import Foundation

// MARK: - UF2 Constants

let UF2_MAGIC_START0: UInt32 = 0x0A32_4655  // "UF2\n"
let UF2_MAGIC_START1: UInt32 = 0x9E5D_5157
let UF2_MAGIC_END: UInt32 = 0x0AB1_6F30
let UF2_FLAG_FAMILY_ID: UInt32 = 0x0000_2000
let RP2040_FAMILY_ID: UInt32 = 0xE48B_FF56
let UF2_PAGE_SIZE = 256
let UF2_BLOCK_SIZE = 512

// MARK: - RP2040 Flash Address Range

let FLASH_START: UInt32 = 0x1000_0000
let FLASH_END: UInt32 = 0x10FF_FFFF

// MARK: - Binary Helpers

func readUInt16LE(_ data: Data, at offset: Int) -> UInt16 {
  UInt16(data[offset]) | UInt16(data[offset + 1]) << 8
}

func readUInt32LE(_ data: Data, at offset: Int) -> UInt32 {
  UInt32(data[offset])
    | UInt32(data[offset + 1]) << 8
    | UInt32(data[offset + 2]) << 16
    | UInt32(data[offset + 3]) << 24
}

func appendUInt32LE(_ value: UInt32, to data: inout Data) {
  data.append(UInt8(value & 0xFF))
  data.append(UInt8((value >> 8) & 0xFF))
  data.append(UInt8((value >> 16) & 0xFF))
  data.append(UInt8((value >> 24) & 0xFF))
}

// MARK: - ELF Parsing

struct ProgramHeader {
  let offset: UInt32  // Offset in ELF file
  let paddr: UInt32  // Physical address (flash address)
  let filesz: UInt32  // Size in file
}

func parseLoadableSegments(_ elf: Data) -> [ProgramHeader] {
  // Validate ELF magic, 32-bit, little-endian
  guard elf.count >= 52,
    elf[0] == 0x7F, elf[1] == 0x45, elf[2] == 0x4C, elf[3] == 0x46,
    elf[4] == 1, elf[5] == 1
  else {
    fputs("Error: not a valid 32-bit little-endian ELF file\n", stderr)
    return []
  }

  let phoff = readUInt32LE(elf, at: 0x1C)
  let phentsize = Int(readUInt16LE(elf, at: 0x2A))
  let phnum = Int(readUInt16LE(elf, at: 0x2C))

  var segments: [ProgramHeader] = []
  for i in 0..<phnum {
    let base = Int(phoff) + i * phentsize
    let type = readUInt32LE(elf, at: base)
    let ph = ProgramHeader(
      offset: readUInt32LE(elf, at: base + 0x04),
      paddr: readUInt32LE(elf, at: base + 0x0C),
      filesz: readUInt32LE(elf, at: base + 0x10)
    )
    // PT_LOAD segments with data in flash range
    if type == 1, ph.filesz > 0, ph.paddr >= FLASH_START, ph.paddr <= FLASH_END {
      segments.append(ph)
    }
  }
  return segments
}

// MARK: - Page Extraction

struct Page {
  let address: UInt32
  var data: [UInt8]
}

func extractPages(from elf: Data, segments: [ProgramHeader]) -> [Page] {
  var pages: [Page] = []

  for segment in segments {
    var addr = segment.paddr
    var srcOffset = Int(segment.offset)
    var remaining = Int(segment.filesz)

    while remaining > 0 {
      let pageBase = addr & ~UInt32(UF2_PAGE_SIZE - 1)
      let offsetInPage = Int(addr - pageBase)
      let count = min(remaining, UF2_PAGE_SIZE - offsetInPage)

      if let index = pages.firstIndex(where: { $0.address == pageBase }) {
        for i in 0..<count {
          pages[index].data[offsetInPage + i] = elf[srcOffset + i]
        }
      } else {
        var page = Page(address: pageBase, data: [UInt8](repeating: 0, count: UF2_PAGE_SIZE))
        for i in 0..<count {
          page.data[offsetInPage + i] = elf[srcOffset + i]
        }
        pages.append(page)
      }

      addr += UInt32(count)
      srcOffset += count
      remaining -= count
    }
  }

  return pages.sorted { $0.address < $1.address }
}

// MARK: - UF2 Generation

func generateUF2(pages: [Page]) -> Data {
  var output = Data(capacity: pages.count * UF2_BLOCK_SIZE)

  for (blockNo, page) in pages.enumerated() {
    var block = Data(capacity: UF2_BLOCK_SIZE)

    // Header (32 bytes)
    appendUInt32LE(UF2_MAGIC_START0, to: &block)
    appendUInt32LE(UF2_MAGIC_START1, to: &block)
    appendUInt32LE(UF2_FLAG_FAMILY_ID, to: &block)
    appendUInt32LE(page.address, to: &block)
    appendUInt32LE(UInt32(UF2_PAGE_SIZE), to: &block)
    appendUInt32LE(UInt32(blockNo), to: &block)
    appendUInt32LE(UInt32(pages.count), to: &block)
    appendUInt32LE(RP2040_FAMILY_ID, to: &block)

    // Data (476 bytes: 256 payload + 220 padding)
    block.append(contentsOf: page.data)
    block.append(contentsOf: [UInt8](repeating: 0, count: 476 - UF2_PAGE_SIZE))

    // Footer (4 bytes)
    appendUInt32LE(UF2_MAGIC_END, to: &block)

    output.append(block)
  }

  return output
}

// MARK: - Main

guard CommandLine.arguments.count == 3 else {
  fputs("Usage: swift \(CommandLine.arguments[0]) <input.elf> <output.uf2>\n", stderr)
  exit(1)
}

let inputPath = CommandLine.arguments[1]
let outputPath = CommandLine.arguments[2]

guard let elfData = try? Data(contentsOf: URL(fileURLWithPath: inputPath)) else {
  fputs("Error: cannot read \(inputPath)\n", stderr)
  exit(1)
}

let segments = parseLoadableSegments(elfData)
guard !segments.isEmpty else {
  fputs("Error: no loadable segments in flash range\n", stderr)
  exit(1)
}

let pages = extractPages(from: elfData, segments: segments)
let uf2 = generateUF2(pages: pages)

do {
  try uf2.write(to: URL(fileURLWithPath: outputPath))
  print("\(inputPath) -> \(outputPath) (\(pages.count) pages, \(uf2.count / 1024)KB)")
} catch {
  fputs("Error: cannot write \(outputPath): \(error)\n", stderr)
  exit(1)
}
