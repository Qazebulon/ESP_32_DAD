---
title: ESP32 CYD Assembly Blink — Linux Setup
---

# ESP32 CYD Assembly Blink — Linux Setup

How to build and flash the `blink_asm` project (Xtensa LX6 assembly) onto the
**ESP32-2432S028 "Cheap Yellow Display"** from a Linux machine.

---

## 1. Install System Dependencies

```bash
sudo apt update
sudo apt install git wget flex bison gperf python3 python3-pip python3-venv \
  cmake ninja-build ccache libffi-dev libssl-dev dfu-util libusb-1.0-0
```

| Package | Purpose |
|---|---|
| `git` | Clones ESP-IDF and its submodules |
| `wget` | Downloads files during component installs |
| `flex` / `bison` | Parser generators used to build the Xtensa compiler |
| `gperf` | Hash generator used in compiler build tools |
| `python3` + `pip` + `venv` | ESP-IDF's build tool (`idf.py`) is a Python script |
| `cmake` | Reads `CMakeLists.txt` and generates build files |
| `ninja-build` | Fast build executor that CMake delegates to |
| `ccache` | Compiler cache — speeds up rebuilds |
| `libffi-dev` | Required by Python packages that call C functions |
| `libssl-dev` | Required for HTTPS downloads during builds |
| `dfu-util` | USB firmware update tool (needed by some ESP32 variants) |
| `libusb-1.0-0` | Low-level USB access — used by `esptool` to talk to the board |

---

## 2. Install ESP-IDF (Espressif's Toolchain)

```bash
git clone --recursive https://github.com/espressif/esp-idf.git ~/esp/esp-idf
cd ~/esp/esp-idf
./install.sh esp32
```

This installs the **Xtensa cross-compiler** (`xtensa-esp32-elf-gcc`), which
translates the assembly source into an ESP32 binary your Linux machine can't
run natively.

---

## 3. Add Yourself to the `dialout` Group

Linux restricts serial port access (`/dev/ttyUSB0`) to root by default.
This command grants permanent access without needing `sudo` every time:

```bash
sudo usermod -a -G dialout $USER
```

**Log out and back in** for this to take effect.

---

## 4. Get the Project

```bash
git clone https://github.com/Qazebulon/ESP_32_DAD.git
cd ESP_32_DAD/blink_asm
```

---

## 5. Build

Run this once per terminal session to activate the ESP-IDF environment:

```bash
source ~/esp/esp-idf/export.sh
```

Then build:

```bash
idf.py build
```

---

## 6. Flash to the Board

Plug in the CYD via USB, then:

```bash
idf.py -p /dev/ttyUSB0 flash
```

If the board doesn't appear on `/dev/ttyUSB0`, check `/dev/ttyACM0`:

```bash
ls /dev/ttyUSB* /dev/ttyACM*
```

---

## What to Expect

Once flashed, the **red LED on the back of the CYD** will blink on and off
every 500 ms — driven entirely by Xtensa assembly with no OS or runtime.
