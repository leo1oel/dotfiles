# How to enable Kanata and my custom keyboard layout?

## 1. Install and Enable Karabiner-DriverKit-VirtualHIDDevice
Download and install the latest version of [Karabiner-DriverKit-VirtualHIDDevice](https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/tree/main/dist). 
See [Full installation instructions](https://github.com/jtroo/kanata/discussions/1537) for creating Karabiner `plist` files and `launchctl`.

## 2. Enable Kanata:
```bash 
sudo cp ~/.config/kanata/docs/com.example.kanata.plist /Library/LaunchDaemons/
sudo launchctl bootstrap system /Library/LaunchDaemons/com.example.kanata.plist
sudo launchctl enable system/com.example.kanata.plist
sudo launchctl start com.example.kanata
```
