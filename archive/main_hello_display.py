from machine import Pin, SPI
from ili9341 import ILI9341
import time

# Small boot delay for stability
time.sleep_ms(500)

# Keep a reference to backlight pin so it isn't garbage collected
bl = Pin(21, Pin.OUT)
bl.value(1)

# CYD (ESP32-2432S028) display SPI pins
spi = SPI(1, baudrate=40_000_000, sck=Pin(14), mosi=Pin(13), miso=Pin(12))
display = ILI9341(spi, cs=15, dc=2, rst=None, bl=None, width=320, height=240)

# Navy blue background
display.fill(0x000F)

# "Hello from" — 10 chars * 8 * scale=4 = 320px wide (exact fit)
display.text("Hello from", 0, 80, 0xFFFF, 0x000F, scale=4)

# "Jonathan" — 8 chars * 32 = 256px wide => x=(320-256)//2=32
display.text("Jonathan", 32, 136, 0xFD20, 0x000F, scale=4)

# Keep running so GPIO and display stay active
while True:
    time.sleep(1)
