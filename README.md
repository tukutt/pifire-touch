# PiFire Touch

**PiFire Touch** is a modern, touch-friendly graphical user interface for [PiFire](https://github.com/nebhead/PiFire), designed to run directly on a Raspberry Pi with a touch display. It leverages Qt6 (PySide6) and QML to provide a seamless, responsive, and aesthetically pleasing experience.

## ✨ Features

-   **Material Design UI**: Sleek, dark-mode interface built with Qt Quick Controls 2 (Material style).
-   **Real-time Monitoring**: Live updates of Grill temperature, Probes, and Timer status.
-   **Full Control**:
    -   Start/Stop the grill.
    -   Change Modes (Smoke, Hold, Shutdown, etc.).
    -   Adjust Target Temperatures.
    -   Set P-Mode and Smoke Plus settings.
-   **History Graphing**: Visualizing temperature history (Grill + Probes) directly on the screen.
-   **Multi-Platform**: Runs on Linux Desktop (for development) and Raspberry Pi (EGLFS/LinuxFB for production).

## 🛠 Prerequisites

### Hardware
-   Raspberry Pi (4, or 5 recommended).
-   Touchscreen display (HDMI or DSI) compatible with Raspberry Pi.
-   [PiFire](https://github.com/nebhead/PiFire) server running (either on the same Pi or another device).

### Software
-   **Python 3.9+**
-   **Qt6** dependencies (for EGLFS support on Raspberry Pi).

## 📦 Installation

### 1. Clone the Repository
```bash
git clone https://github.com/tukutt/pifire-touch.git
cd pifire-touch
```

### 2. Install Python Dependencies
Create a virtual environment (recommended) and install the requirements:
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 3. Configuration
By default, the application attempts to connect to `http://pifire.local`.

You can configure the server address directly within the application:
1.  Navigate to **Settings** > **Server Address**.
2.  Select your connection mode:
    -   **pifire.local** (Default)
    -   **localhost** (If running on the same device)
    -   **Custom IP/URL** (Enter a specific IP address using the on-screen keypad)

## 🚀 Usage

### Running on Desktop (Development)
You can test the UI on your desktop Linux environment:
```bash
./scripts/run_desktop.sh
```

### Running on Raspberry Pi (Touchscreen)

**First-time Setup:**
Run the setup script to install system dependencies for Qt6 and configure permissions (requires sudo):
```bash
chmod +x scripts/setup_remote.sh scripts/run_remote.sh
./scripts/setup_remote.sh
```
*Note: You may need to reboot after this step.*

**Start the Application:**
To launch the interface in full-screen (framebuffer) mode:
```bash
./scripts/run_remote.sh
```
This script handles:
-   Hiding the mouse cursor.
-   Setting up the Qt platform backend (`linuxfb` or `eglfs`).
-   Cleaning up the framebuffer on exit.

## 📝 ToDo
- [ ] Pellet management
- [ ] Recipes
- [ ] PWM Fan control
- [ ] Alarm on probe
- [ ] A better History graph
- [ ] Some Settings
- [ ] Maybe your idea :)


## 📄 License
[GPLv3 License](LICENSE)
