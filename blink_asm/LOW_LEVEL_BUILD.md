# Low-Level Build Pipeline — What `idf.py` Does Under the Hood

This document breaks down the exact toolchain commands that ESP-IDF runs when
you type `idf.py build` and `idf.py flash`. Useful for understanding the
assembler, linker, and flash stages without the abstraction layer.

To see every command yourself, run `idf.py build -v` (verbose mode).

---

## The Pipeline

```
blink.S  ──▶  Assemble  ──▶  Link  ──▶  Convert  ──▶  Flash
  (source)    (.obj)        (.elf)      (.bin)       (on chip)
```

---

## 1. Assemble

The Xtensa cross-compiler translates `blink.S` into a relocatable object file:

```bash
xtensa-esp32-elf-gcc -mlongcalls -ffunction-sections -fdata-sections \
  -c main/blink.S -o blink.S.obj
```

| Flag | Purpose |
|------|---------|
| `-mlongcalls` | Required for Xtensa; allows calls beyond the default 512 KB reach by inserting indirect jumps |
| `-ffunction-sections` | Place each function in its own ELF section so unused code can be stripped later |
| `-fdata-sections` | Same as above, but for data symbols |
| `-c` | Compile/assemble only, do not link |

Output: `blink.S.obj` (ELF relocatable object, not yet runnable).

---

## 2. Link

Even though the assembly source is 59 lines, the linker pulls in ESP-IDF's
bootloader startup code, FreeRTOS stubs, and windowed-register ABI support.
Linker scripts from the ESP-IDF install directory define the ESP32 memory map:

```bash
xtensa-esp32-elf-gcc -nostdlib \
  -Wl,--gc-sections \
  -Wl,-Map=blink_asm.map \
  -T esp32.project.ld \
  -T esp32.rom.ld \
  -T esp32.rom.api.ld \
  -T esp32.rom.libgcc.ld \
  -T memory.ld \
  blink.S.obj \
  -lesp_system -lesp_rom -lfreertos -lnewlib -lgcc \
  -o blink_asm.elf
```

| Flag / File | Purpose |
|-------------|---------|
| `-nostdlib` | Don't link the standard C library automatically; ESP-IDF provides its own newlib |
| `-Wl,--gc-sections` | Garbage-collect unused sections (critical since ESP-IDF links many libraries but this code only touches GPIO registers) |
| `-T *.ld` | Linker scripts defining the memory map: IRAM at `0x40080000`, DRAM at `0x3FFB0000`, flash at `0x400D0000`, etc. These place `app_main` at the correct address |
| `-lesp_system` | Startup code that initializes hardware and calls `app_main` |
| `-lesp_rom` | ROM function stubs baked into the ESP32 silicon |
| `-lfreertos` | FreeRTOS idle task (required by the startup sequence) |
| `-lnewlib` | Minimal C library used by ESP-IDF internals |
| `-lgcc` | Compiler support routines (soft-float, division, etc.) |

Output: `blink_asm.elf` (fully linked ELF with absolute addresses).

---

## 3. Convert ELF to Flashable Binary

The ESP32 bootloader doesn't understand ELF. `esptool.py` strips metadata and
packs loadable segments into the ESP32 image format with checksums and headers:

```bash
esptool.py --chip esp32 elf2image \
  --flash_mode dio --flash_freq 40m --flash_size 4MB \
  -o blink_asm.bin blink_asm.elf
```

Output: `blink_asm.bin` (raw flashable image).

---

## 4. Flash to the Board

Three separate binaries are written to specific addresses in SPI flash:

```bash
esptool.py --chip esp32 --port /dev/ttyUSB0 --baud 460800 \
  write_flash --flash_mode dio --flash_freq 40m --flash_size detect \
  0x1000  build/bootloader/bootloader.bin \
  0x8000  build/partition_table/partition-table.bin \
  0x10000 build/blink_asm.bin
```

| Address | Binary | Purpose |
|---------|--------|---------|
| `0x1000` | `bootloader.bin` | 2nd-stage bootloader: initializes clocks, reads partition table, loads the app |
| `0x8000` | `partition-table.bin` | Tells the bootloader where to find app partitions in flash |
| `0x10000` | `blink_asm.bin` | The actual application (the linked + converted assembly) |

On Windows (CYD on COM5), replace `--port /dev/ttyUSB0` with `--port COM5`.

---

## Boot Sequence

```
ROM bootloader (0x0, burned into silicon)
  └──▶ 2nd-stage bootloader (0x1000, bootloader.bin)
         └──▶ reads partition table (0x8000)
                └──▶ loads app from 0x10000 into IRAM/DRAM
                       └──▶ call_start_cpu0 → ... → app_main (your code)
```

The ROM bootloader is permanently etched into the ESP32 die at the factory.
Everything from `0x1000` onward is what you flash.

---

## Summary Table

| Step | Tool | Input | Output |
|------|------|-------|--------|
| Assemble | `xtensa-esp32-elf-gcc -c` | `blink.S` | `blink.S.obj` |
| Link | `xtensa-esp32-elf-gcc` + linker scripts | `.obj` + ESP-IDF libs | `blink_asm.elf` |
| Convert | `esptool.py elf2image` | `.elf` | `.bin` |
| Flash | `esptool.py write_flash` | 3 `.bin` files | Written to SPI flash via serial |

The 59 lines of assembly end up as a tiny fraction of the final binary. Most of
the weight comes from ESP-IDF's startup code, the FreeRTOS idle task, and the
bootloader. The linker scripts are the glue that maps everything onto the
ESP32's physical memory layout.
