# CYD Blink — Setup Instructions

Blinks the red LED on the back of your ESP32 board (500ms on / 500ms off).

---

## What you need

- Your CYD board (ESP32-2432S028)
- A USB cable (the **smaller** of the two USB ports on the board)
- A Linux computer with internet access

---

## Steps

### 1. One-time setup (first time only)

Open a terminal and run:

```bash
sudo usermod -a -G dialout $USER
```

Then **log out and log back in** (or reboot). This lets your user talk to USB devices.

### 2. Plug in the board

Use the **micro-USB port** (the smaller one). Your computer should detect it automatically — no driver installation needed on Linux.

### 3. Run the installer

In the terminal, navigate to this folder and run:

```bash
bash flash.sh
```

The script will:
- Download MicroPython firmware (~1.7 MB)
- Erase and flash the board
- Upload the blink program
- Reset the board

### 4. Done

The **red LED on the back** of the board should start blinking.

---

## Troubleshooting

**"Board not found"** — Make sure the USB cable supports data (not charge-only). Try the other USB port on the board if there are two.

**"Permission denied"** — You haven't logged out after step 1. Log out and back in, then try again.

**LED not blinking after install** — Press the small **RST** button on the board to restart it.
