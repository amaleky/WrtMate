# WrtMate

![License](https://img.shields.io/github/license/amaleky/WrtMate)

**WrtMate** is a utility designed to streamline the setup and management of OpenWrt-based routers. This project provides an script to automate the configuration process, ensuring a consistent and efficient deployment.

## Features

- Automated installation of necessary packages.
- Configuration of system settings for optimal performance.
- Simplified management of OpenWrt environments.

## Minimum System Requirements

To ensure optimal performance, your device should meet the following minimum specifications:

- **RAM:** 200 MB
- **Storage:** 500 MB available space
- **CPU:** Dual-core processor

## Prerequisites

Before running the installation script, ensure the following:

- You have a compatible OpenWrt device.
- SSH access is enabled on your router.
- You have administrative privileges.

## Installation

To install WrtMate on your OpenWrt device, follow these steps:

1. **Connect to your router via SSH:**

   ```bash
   ssh root@<your-router-ip>
   ```

2. **Install Bash shell:**

   ```bash
   opkg update
   opkg install bash
   ```

3. **Run the installation script:**

   ```bash
   bash -c "$(wget -qO- https://github.com/amaleky/WrtMate/raw/main/install.sh)"
   ```

## Usage

After installation, WrtMate will be configured on your device. You can manage your OpenWrt settings as usual. For advanced configurations and features, refer to the project's documentation.

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Code of Conduct

This project adheres to a [Code of Conduct](CODE_OF_CONDUCT.md) to foster an open and welcoming environment.

## License

This project is licensed under the [MIT License](LICENSE).
