# echo_asm — UART Echo in Xtensa Assembly

Bare-metal UART echo for the ESP32-2432S028 "Cheap Yellow Display."
Receives a character over USB-serial, uppercases it if it's an ASCII
lowercase letter (`a`–`z` → `A`–`Z`), and echoes the result. Other
bytes pass through unchanged. About 25 instructions total, no C
runtime, no RTOS task loop.

## Build & Flash

### Linux

```bash
source ~/esp/esp-idf/export.sh
cd echo_asm
idf.py build
idf.py -p /dev/ttyUSB0 flash
```

### Windows

Easiest: launch **"ESP-IDF 5.4 CMD"** from the Start menu — the environment
is already sourced. Otherwise, source it manually:

```cmd
C:\Users\Jonat\Proj\ESP32\v5.4.1\esp-idf\export.bat
```

Then:

```cmd
cd echo_asm
idf.py build
idf.py -p COM5 flash
```

Find the COM port in Device Manager → *Ports (COM & LPT)* → "USB-SERIAL CH340".

## Test

Type characters — lowercase letters come back uppercased (`a` → `A`,
`z` → `Z`); everything else echoes through unchanged.

### Linux

```bash
screen /dev/ttyUSB0 115200
```

Press `Ctrl-a k` to quit screen.

### Windows

```cmd
idf.py -p COM5 monitor
```

Exit with `Ctrl-]`. Alternatively, use PuTTY (Connection type: Serial,
Serial line: `COM5`, Speed: `115200`).

## How It Works

UART0 is already initialized to 115200 8N1 by the ESP32 ROM bootloader, so
the assembly code inherits that and goes straight to polling:

1. Spin on `UART_STATUS_REG` until `RXFIFO_CNT > 0`
2. Read the byte from `UART_FIFO_REG`
3. If the byte is in `'a'..'z'`, subtract `0x20` to uppercase it
4. Spin on `UART_STATUS_REG` until `TXFIFO_CNT < 128`
5. Write the byte to `UART_FIFO_REG`
6. Repeat
