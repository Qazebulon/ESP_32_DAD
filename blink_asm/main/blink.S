@ blink.S — Xtensa LX6 assembly blink for ESP32 / CYD
@
@ Hardware: ESP32-2432S028 "Cheap Yellow Display"
@   Red LED on GPIO 4, active LOW (LED on = pin LOW, LED off = pin HIGH)
@   CPU runs at 240 MHz
@
@ Timing: 500 ms on, 500 ms off, looping forever
@   At 240 MHz, each loop iteration (addi + bnez) ≈ 3 cycles
@   500 ms = 120,000,000 cycles → 40,000,000 iterations
@
@ GPIO registers (memory-mapped, ESP32 Technical Reference Manual §4):
@   0x3FF44024  GPIO_ENABLE_W1TS_REG  — write 1s to enable GPIO output
@   0x3FF44008  GPIO_OUT_W1TS_REG     — write 1s to drive pin HIGH
@   0x3FF4400C  GPIO_OUT_W1TC_REG     — write 1s to drive pin LOW
@
@ Register usage:
@   a2 — GPIO register address (changes each step)
@   a3 — GPIO4 bit mask = 0x10 (constant throughout)
@   a4 — delay counter (scratch)

    .text
    .align  4
    .global app_main
    .type   app_main, @function

app_main:
    entry   sp, 32                  @ Xtensa function prologue, 32-byte frame

    @ ── Enable GPIO4 as output ──────────────────────────────────────────
    movi    a2, 0x3FF44024          @ GPIO_ENABLE_W1TS_REG
    movi    a3, 0x10                @ bit 4 = GPIO4
    s32i    a3, a2, 0               @ enable GPIO4 output direction

blink_loop:

    @ ── LED ON: pull GPIO4 LOW (active-low LED turns on) ────────────────
    movi    a2, 0x3FF4400C          @ GPIO_OUT_W1TC_REG  (clear = drive LOW)
    s32i    a3, a2, 0

    @ ── Delay ~500 ms ────────────────────────────────────────────────────
    movi    a4, 40000000
delay_on:
    addi    a4, a4, -1
    bnez    a4, delay_on

    @ ── LED OFF: push GPIO4 HIGH (active-low LED turns off) ─────────────
    movi    a2, 0x3FF44008          @ GPIO_OUT_W1TS_REG  (set = drive HIGH)
    s32i    a3, a2, 0

    @ ── Delay ~500 ms ────────────────────────────────────────────────────
    movi    a4, 40000000
delay_off:
    addi    a4, a4, -1
    bnez    a4, delay_off

    j       blink_loop              @ loop forever

    .size   app_main, .-app_main
