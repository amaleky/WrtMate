# WrtMate

**WrtMate** is a utility designed to streamline the setup and management of OpenWrt-based routers. This project provides an installation script to automate the configuration process, ensuring a consistent and efficient deployment.

## Features

- Automated installation of necessary packages.
- Configuration of system settings for optimal performance.
- Simplified management of OpenWrt environments.

## Minimum System Requirements

To ensure optimal performance, your device should meet the following minimum specifications:

- **RAM:** 512 MB
- **Storage:** 100 MB available space
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

2. **Install Bash shell:**

   ```bash
   opkg update
   opkg install bash

3. **Download and Run the installation script:**

   ```bash
   bash -c "$(wget -cO- https://raw.githubusercontent.com/amaleky/WrtMate/main/install.sh)"

## Usage

After installation, WrtMate will be configured on your device. You can manage your OpenWrt settings as usual. For advanced configurations and features, refer to the project's documentation.

## Contributing

Contributions are welcome! If you have suggestions, bug reports, or improvements, please open an issue or submit a pull request on the [GitHub repository](https://github.com/amaleky/WrtMate).

## License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/amaleky/WrtMate/blob/main/LICENSE) file for details.

