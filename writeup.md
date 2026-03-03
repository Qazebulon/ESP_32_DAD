# ESP32 CYD Getting Started — Session Writeup

A record of everything done in this session to get MicroPython running on a CYD board, display text on the screen, and blink the onboard LED.

---

## 1. Choosing a Language: MicroPython vs Rust

For a first project on ESP32, **MicroPython** was chosen over Rust for its dramatically faster setup time (~10 min vs ~1-2 hours on Windows) and minimal toolchain requirements. The recommendation is to use MicroPython for early projects and migrate to Rust later if performance or memory constraints require it.

---

## 2. Identifying the Board

A photo of the board was examined. The silkscreen reads **ESP32-2432S028**, manufactured by Sunton. This is commonly known as the **"Cheap Yellow Display" (CYD)**.

**Key specs:**
- SoC: ESP32-D0WD-V3 revision 3.1
- Dual core, 240 MHz, Wi-Fi + Bluetooth
- Display: ILI9341 2.8" TFT, 320×240
- USB-to-serial: CH340 (not CP2102 as some board variants use)
- MAC address: `ec:e3:34:65:ce:08`

**References:**
- [ESP32-Cheap-Yellow-Display PINS.md (witnessmenow/GitHub)](https://github.com/witnessmenow/ESP32-Cheap-Yellow-Display/blob/main/PINS.md)
- [CYD Pinout — Random Nerd Tutorials](https://randomnerdtutorials.com/esp32-cheap-yellow-display-cyd-pinout-esp32-2432s028r/)
- [ESP32-2432S028 specs — espboards.dev](https://www.espboards.dev/esp32/cyd-esp32-2432s028/)

---

## 3. Detecting the Board on Windows

The CH340 driver was already installed. The board was confirmed on **COM5** using PowerShell:

```powershell
Get-PnpDevice -Class Ports
# → USB-SERIAL CH340 (COM5)  Status: OK
```

Connection was verified with esptool:

```bash
python -m esptool --chip esp32 --port COM5 chip-id
# → ESP32-D0WD-V3 (revision v3.1), confirmed connected
```

**Tool:** [esptool](https://github.com/espressif/esptool) — installed via `pip install esptool`

---

## 4. Flashing MicroPython

The latest stable MicroPython firmware for ESP32 Generic was downloaded and flashed:

```bash
# Erase
python -m esptool --chip esp32 --port COM5 --baud 460800 erase-flash

# Flash
python -m esptool --chip esp32 --port COM5 --baud 460800 write-flash 0x1000 ESP32_GENERIC-20251209-v1.27.0.bin
```

**Firmware:** [MicroPython v1.27.0 for ESP32_GENERIC](https://micropython.org/download/ESP32_GENERIC/)

File transfer to the board was done with **ampy**:

```bash
pip install adafruit-ampy
python -m ampy.cli --port COM5 --delay 2 put main.py
python -m ampy.cli --port COM5 --delay 2 reset
```

---

## 5. Displaying Text on the Screen

A minimal ILI9341 driver was written from scratch in MicroPython (`ili9341.py`), supporting:
- Screen fill with a 16-bit RGB565 colour
- Scaled text rendering using MicroPython's built-in `framebuf` 8×8 font

### CYD Display Pin Mapping

| Signal | GPIO |
|--------|------|
| SPI SCK | 14 |
| SPI MOSI | 13 |
| SPI MISO | 12 |
| CS | 15 |
| DC | 2 |
| Backlight | **21** (active HIGH) |

### Orientation Fix

The ILI9341 MADCTL register controls display orientation. Several values were tested:

| MADCTL | Effect |
|--------|--------|
| `0x48` | Portrait-like (wrong for CYD) |
| `0x28` | **Correct landscape for CYD** |

The correct value is **`0x28`** (MV + BGR bits set).

### Lessons Learned

- `main.py` must contain a `while True` loop at the end — without it, MicroPython exits to REPL and a soft reset can clear GPIO state (including the backlight).
- Hold the backlight `Pin` object in a named variable to prevent it being garbage collected.
- A 500 ms boot delay (`time.sleep_ms(500)`) improves display init stability.

### Result

`main.py` displays **"Hello from Jonathan"** on a navy blue background in large scaled text (scale=4), white on line 1 and orange on line 2.

---

## 6. Blinking the LED

The CYD has one user-controllable RGB LED on the back of the board. **LED1** refers to its **red channel**.

| Colour | GPIO | Polarity |
|--------|------|----------|
| Red (LED1) | **4** | Active LOW (0 = on) |
| Green | 16 | Active LOW |
| Blue | 17 | Active LOW |

500 ms blink program:

```python
from machine import Pin
import time

led = Pin(4, Pin.OUT, value=1)  # start OFF

while True:
    led.value(0)        # ON
    time.sleep_ms(500)
    led.value(1)        # OFF
    time.sleep_ms(500)
```

---

## 7. Packaging for Dad (Linux)

A self-contained zip (`cyd_blink.zip`, ~1.9 KB) was created containing:

- `main.py` — the blink program
- `flash.sh` — automated shell script that downloads MicroPython, flashes the board, and uploads the program
- `README.md` — step-by-step instructions for a Linux user

The flash script auto-detects the serial port, downloads firmware from micropython.org, and handles the full flash + upload sequence with a single command:

```bash
bash flash.sh
```

On Linux, no driver installation is needed for CH340 (kernel module is built in). The only one-time setup is adding the user to the `dialout` group:

```bash
sudo usermod -a -G dialout $USER
# then log out and back in
```

---

## File Summary

| File | Description |
|------|-------------|
| `main.py` | LED blink program (current) |
| `ili9341.py` | Reusable MicroPython ILI9341 display driver |
| `archive/main_hello_display.py` | "Hello from Jonathan" display program |
| `flash.sh` | Linux automated flash script |
| `README.md` | Linux setup instructions for end users |
| `cyd_blink.zip` | Email-ready package (main.py + flash.sh + README.md) |
| `esp_target.jpeg` | Photo of the board used to identify it |

---

## Web Resources

- [MicroPython ESP32 firmware download](https://micropython.org/download/ESP32_GENERIC/)
- [esptool on GitHub](https://github.com/espressif/esptool)
- [adafruit-ampy on PyPI](https://pypi.org/project/adafruit-ampy/)
- [ESP32-Cheap-Yellow-Display pinout reference (witnessmenow)](https://github.com/witnessmenow/ESP32-Cheap-Yellow-Display/blob/main/PINS.md)
- [CYD Pinout — Random Nerd Tutorials](https://randomnerdtutorials.com/esp32-cheap-yellow-display-cyd-pinout-esp32-2432s028r/)
- [ESP32-2432S028 specs — espboards.dev](https://www.espboards.dev/esp32/cyd-esp32-2432s028/)
- [Silicon Labs CP210x driver](https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers) *(not needed for this board — uses CH340)*
- [ILI9341 datasheet](https://cdn-shop.adafruit.com/datasheets/ILI9341.pdf)
