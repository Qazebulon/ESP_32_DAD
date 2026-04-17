# echo_asm — UART Echo in Xtensa Assembly

Bare-metal UART echo for the ESP32-2432S028 "Cheap Yellow Display."
Receives a character over USB-serial and echoes it back — about 20
instructions total, no C runtime, no RTOS task loop.

## Build & Flash

```bash
source ~/esp/esp-idf/export.sh
cd echo_asm
idf.py build
idf.py -p /dev/ttyUSB0 flash       # Linux
idf.py -p COM5 flash                # Windows
```

## Test

```bash
screen /dev/ttyUSB0 115200          # Linux
```

Type characters — each one should appear once as the board echoes it back.
Press `Ctrl-a k` to quit screen.

## How It Works

UART0 is already initialized to 115200 8N1 by the ESP32 ROM bootloader, so
the assembly code inherits that and goes straight to polling:

1. Spin on `UART_STATUS_REG` until `RXFIFO_CNT > 0`
2. Read the byte from `UART_FIFO_REG`
3. Spin on `UART_STATUS_REG` until `TXFIFO_CNT < 128`
4. Write the byte to `UART_FIFO_REG`
5. Repeat
