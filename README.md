# iCloud Activation Bypass Tool for Windows

A Windows-native tool to bypass iCloud Activation Lock on jailbroken iOS devices.

> [!CAUTION]
> This tool is **NOT** a jailbreak utility. Your device **MUST** already be jailbroken with OpenSSH installed before using this tool.

---

## 📋 What This Tool Does

This tool bypasses the iCloud Activation Lock screen by:
1. Replacing the system's `mobileactivationd` daemon with a patched version
2. Installing a launch daemon to keep the patched daemon running
3. Rebooting the userspace to apply changes

### What This Tool Does NOT Do
- ❌ Jailbreak your device (use checkra1n or palera1n first)
- ❌ Remove Find My iPhone
- ❌ Restore cellular functionality
- ❌ Unlock carrier-locked devices

---

## ⚠️ Prerequisites

Before using this tool, you **MUST** complete these steps:

| Step | Requirement | How to Verify |
|------|-------------|---------------|
| 1 | **Device is jailbroken** | Cydia or Sileo app is visible on device |
| 2 | **OpenSSH is installed** | Installed via Cydia/Sileo package manager |
| 3 | **USB cable connected** | Device recognized by Windows |
| 4 | **Device on activation screen** | Shows "iPhone is locked to owner" |
| 5 | **You have the patched binary** | `mobileactivationd` file (~2.3 MB) |

---

## 🔧 Required Tools & Downloads

### 1. libimobiledevice for Windows
Download from: https://github.com/L1ghtmann/libimobiledevice/releases

**Required files** (place in `tools\` folder):
- `iproxy.exe`
- `ideviceinfo.exe` (optional but recommended)
- All `.dll` files from the release

### 2. PuTTY Tools
Download from: https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html

**Required files** (place in `tools\` folder):
- `plink.exe`
- `pscp.exe`

### 3. Modified mobileactivationd Binary
- Source: Extract from a jailbroken device that already has bypass applied
- Size: ~2-3 MB
- Location: Place in project root folder

---

## 📁 Folder Structure

```
.\ (current folder)
├── mobileactivationd              ← You provide this
├── com.bypass.mobileactivationd.plist
├── bypass.ps1                     ← Main script
├── tools\
│   ├── iproxy.exe                 ← Download this
│   ├── ideviceinfo.exe            ← Download this (optional)
│   ├── plink.exe                  ← Download this
│   ├── pscp.exe                   ← Download this
│   └── *.dll                      ← Download all DLLs
├── README.md
└── PREREQUISITES.txt
```

---

## 🚀 Installation Steps

### Step 1: Enable PowerShell Script Execution
Open PowerShell as Administrator and run:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Step 2: Download libimobiledevice
1. Go to https://github.com/L1ghtmann/libimobiledevice/releases
2. Download the latest Windows release (`.zip` file)
3. Extract all files to `.\tools\`

### Step 3: Download PuTTY Tools
1. Go to https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html
2. Download `plink.exe` and `pscp.exe` (64-bit recommended)
3. Place both in `.\tools\`

### Step 4: Place mobileactivationd Binary
1. Copy your patched `mobileactivationd` binary
2. Place it in the project root folder (same location as `bypass.ps1`)
3. Verify file size is approximately 2-3 MB

### Step 5: Verify Installation
```powershell
cd <project-folder>
Get-ChildItem -Recurse | Select-Object Name
```

---

## 📱 Usage Instructions

### 1. Prepare Your Device
- Ensure device is jailbroken (run palera1n/checkra1n if needed)
- Install OpenSSH via Cydia or Sileo
- Connect device to PC via USB cable
- Trust the computer if prompted on device

### 2. Run the Bypass
```powershell
cd <project-folder>
.\bypass.ps1
```

### 3. Follow On-Screen Prompts
The script will:
1. ✓ Check prerequisites
2. ✓ Detect connected device
3. ✓ Establish USB port forwarding
4. ✓ Connect via SSH
5. ✓ Upload and install bypass files
6. ✓ Reboot userspace

### 4. After Completion
- Wait ~30 seconds for device to restart SpringBoard
- Device should bypass activation screen
- Set up device as new (skip Apple ID)

---

## 🔍 Troubleshooting

### "Device not found"
- Check USB cable connection
- Try different USB port
- Install iTunes to get Apple Mobile Device drivers
- Restart the device

### "Connection refused" or "SSH failed"
- Verify OpenSSH is installed on device
- Check if device is on activation screen (SSH works there)
- Try default password: `alpine`
- Re-jailbreak if needed

### "Permission denied"
- Password might be changed from default `alpine`
- Check SSH password in script config

### "iproxy failed to start"
- Close any other instances of iproxy
- Check if port 4444 is in use: `netstat -an | findstr 4444`
- Restart your PC if needed

### "mobileactivationd upload failed"
- Check file isn't corrupted
- Verify file size (2-3 MB)
- Re-run the script

### Windows Defender Warnings
Some tools may trigger antivirus warnings - these are false positives:
- Add the project folder to Windows Defender exclusions
- Or temporarily disable real-time protection

---

## ⚡ Known Limitations

| Limitation | Description |
|------------|-------------|
| No Cellular | SIM card will not work; WiFi only |
| No iCloud | Cannot sign into iCloud or use Apple services |
| No Passcode (A10/A11) | SEP bypass not included; no passcode on some devices |
| Semi-tethered | Bypass persists as long as jailbreak does |

---

## 🔄 How to Revert/Undo Bypass

If you need to restore original behavior:

1. Connect device and run iproxy:
```powershell
.\tools\iproxy.exe 4444 44
```

2. In another terminal, SSH to device:
```powershell
.\tools\plink.exe -pw alpine -P 4444 root@localhost
```

3. Execute revert commands:
```bash
launchctl unload /Library/LaunchDaemons/com.bypass.mobileactivationd.plist
rm -f /Library/LaunchDaemons/com.bypass.mobileactivationd.plist
mv /usr/libexec/mobileactivationdBackup /usr/libexec/mobileactivationd
reboot
```

---

## 📜 Technical Details

### SSH Commands Executed
```bash
mount -o rw,union,update /                    # Mount filesystem writable
mv mobileactivationd mobileactivationdBackup  # Backup original
ldid -e mobileactivationdBackup > *.plist     # Extract entitlements
chmod 755 mobileactivationd                   # Set permissions
ldid -S/*.plist mobileactivationd             # Sign with entitlements
launchctl load *.plist                        # Load launch daemon
launchctl reboot userspace                    # Restart SpringBoard
```

### Supported Devices
- A7-A11 devices (iPhone 5s through iPhone X)
- iOS 15.x - 16.x (as supported by palera1n/checkra1n)

---

## ⚖️ Legal Disclaimer

This tool is provided for **educational and research purposes only**. Users are responsible for ensuring they have legal rights to bypass activation on any device. Bypassing activation lock on stolen devices is illegal. The authors assume no responsibility for misuse.

---

## 🙏 Credits

- libimobiledevice project
- palera1n team
- checkm8 exploit researchers
- PuTTY development team
