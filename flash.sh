#!/bin/bash
set -e

FIRMWARE_URL="https://micropython.org/resources/firmware/ESP32_GENERIC-20251209-v1.27.0.bin"
FIRMWARE="micropython.bin"

echo "=== CYD Blink Flasher ==="

# Check Python
if ! command -v python3 &>/dev/null; then
    echo "ERROR: python3 not found. Install it with: sudo apt install python3 python3-pip"
    exit 1
fi

# Install tools if missing
python3 -m pip install --quiet esptool adafruit-ampy

# Find board
PORT=$(ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null | head -1)
if [ -z "$PORT" ]; then
    echo "ERROR: Board not found. Make sure it's plugged in."
    echo "If this is your first time, run: sudo usermod -a -G dialout \$USER"
    echo "Then log out and back in, and try again."
    exit 1
fi
echo "Found board on $PORT"

# Download firmware
if [ ! -f "$FIRMWARE" ]; then
    echo "Downloading MicroPython firmware..."
    curl -L --progress-bar "$FIRMWARE_URL" -o "$FIRMWARE"
fi

# Flash
echo "Erasing flash..."
python3 -m esptool --chip esp32 --port "$PORT" --baud 460800 erase-flash

echo "Flashing MicroPython..."
python3 -m esptool --chip esp32 --port "$PORT" --baud 460800 write-flash 0x1000 "$FIRMWARE"

# Upload blink program
echo "Uploading blink program..."
sleep 2
python3 -m ampy.cli --port "$PORT" --delay 2 put main.py

echo "Resetting board..."
python3 -m ampy.cli --port "$PORT" --delay 2 reset

echo ""
echo "Done! The red LED on the back should now be blinking."
