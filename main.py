from machine import Pin
import time

led = Pin(4, Pin.OUT, value=1)  # GPIO 4 = red LED, start OFF (active low)

while True:
    led.value(0)        # ON
    time.sleep_ms(500)
    led.value(1)        # OFF
    time.sleep_ms(500)
