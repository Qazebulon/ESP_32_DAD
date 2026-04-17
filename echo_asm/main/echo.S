# echo.S — Xtensa LX6 assembly UART echo for ESP32 / CYD
#
# Hardware: ESP32-2432S028 "Cheap Yellow Display"
#   UART0 TX/RX is routed through the CH340 USB-to-serial bridge.
#   The ROM bootloader initializes UART0 to 115200 baud, 8N1.
#   We inherit that configuration — no UART init needed.
#
# Behavior: waits for a byte on UART0 RX, echoes it back on UART0 TX.
#
# UART0 registers (ESP32 Technical Reference Manual, Chapter 13):
#   0x3FF40000  UART_FIFO_REG     — read = RX FIFO, write = TX FIFO
#   0x3FF40024  UART_STATUS_REG   — bits 7:0  = RXFIFO_CNT (bytes waiting)
#                                   bits 23:16 = TXFIFO_CNT (bytes queued)
#
# Register usage:
#   a2 — register address (scratch)
#   a3 — status / FIFO count (scratch)
#   a4 — the byte being echoed

    .text
    .align  4
    .global app_main
    .type   app_main, @function

app_main:
    entry   sp, 32                  # Xtensa windowed-register prologue

echo_loop:
    # ── Wait for a byte in the RX FIFO ──────────────────────────────────
    movi    a2, 0x3FF40024          # UART_STATUS_REG
    l32i    a3, a2, 0               # read status
    extui   a3, a3, 0, 8           # extract bits 7:0 = RXFIFO_CNT
    beqz    a3, echo_loop           # spin until at least one byte arrives

    # ── Read the byte ───────────────────────────────────────────────────
    movi    a2, 0x3FF40000          # UART_FIFO_REG
    l32i    a4, a2, 0               # read byte from RX FIFO into a4

tx_wait:
    # ── Wait for space in the TX FIFO ───────────────────────────────────
    movi    a2, 0x3FF40024          # UART_STATUS_REG
    l32i    a3, a2, 0               # read status
    extui   a3, a3, 16, 8          # extract bits 23:16 = TXFIFO_CNT
    bgeui   a3, 128, tx_wait        # spin if TX FIFO is full (128 entries)

    # ── Echo the byte back ──────────────────────────────────────────────
    movi    a2, 0x3FF40000          # UART_FIFO_REG
    s32i    a4, a2, 0               # write byte to TX FIFO

    j       echo_loop               # loop forever

    .size   app_main, .-app_main
