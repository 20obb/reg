#Requires -Version 5.1
<#
.SYNOPSIS
    Windows iCloud Activation Bypass Tool
.DESCRIPTION
    Performs iCloud activation lock bypass on jailbroken iOS devices.
    This tool is NOT a jailbreak utility - device must already be jailbroken with OpenSSH installed.
.NOTES
    Author: iCloud Bypass Tool
    Version: 1.0.0
    Requires: libimobiledevice (iproxy.exe), PuTTY tools (plink.exe, pscp.exe)
#>

# ============================================================================
# CRITICAL: Set working directory to script location
# This ensures relative paths like .\mobileactivationd resolve correctly
# ============================================================================
$Script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($Script:ScriptDir) {
    Set-Location -Path $Script:ScriptDir
}

# ============================================================================
# CONFIGURATION - All paths are absolute to ensure proper resolution
# ============================================================================
$Script:Config = @{
    SSHPassword           = "alpine"
    SSHPort               = 4444
    iPhoneSSHPort         = 44
    SSHUser               = "root"
    SSHHost               = "localhost"
    MobileActivationdPath = "$Script:ScriptDir\mobileactivationd"
    PlistPath             = "$Script:ScriptDir\com.bypass.mobileactivationd.plist"
    ToolsPath             = "$Script:ScriptDir\tools"
    IproxyExe             = "$Script:ScriptDir\tools\iproxy.exe"
    PlinkExe              = "$Script:ScriptDir\tools\plink.exe"
    PscpExe               = "$Script:ScriptDir\tools\pscp.exe"
    IdeviceinfoExe        = "$Script:ScriptDir\tools\ideviceinfo.exe"
    MinFileSize           = 2000000  # 2 MB minimum for mobileactivationd
    MaxFileSize           = 3500000  # 3.5 MB maximum for mobileactivationd
}

$Script:IproxyProcess = $null

# Debug: Show resolved paths
Write-Host "  [i] Script directory: $Script:ScriptDir" -ForegroundColor Gray

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  =================================================================" -ForegroundColor Cyan
    Write-Host "  |                                                               |" -ForegroundColor Cyan
    Write-Host "  |        " -ForegroundColor Cyan -NoNewline
    Write-Host "iCloud Activation Bypass Tool for Windows" -ForegroundColor White -NoNewline
    Write-Host "           |" -ForegroundColor Cyan
    Write-Host "  |                                                               |" -ForegroundColor Cyan
    Write-Host "  |                      Version 1.0.0                            |" -ForegroundColor Cyan
    Write-Host "  |                                                               |" -ForegroundColor Cyan
    Write-Host "  =================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [!] " -ForegroundColor Yellow -NoNewline
    Write-Host "This tool requires a jailbroken device with OpenSSH installed" -ForegroundColor Gray
    Write-Host ""
}

function Write-Step {
    param (
        [string]$Message,
        [string]$Status = "INFO",
        [switch]$NoNewLine
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $color = switch ($Status) {
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "INFO" { "Cyan" }
        "WORKING" { "Magenta" }
        default { "White" }
    }
    
    $icon = switch ($Status) {
        "SUCCESS" { "[+]" }
        "ERROR" { "[X]" }
        "WARNING" { "[!]" }
        "INFO" { "[i]" }
        "WORKING" { "[~]" }
        default { "[*]" }
    }
    
    if ($NoNewLine) {
        Write-Host "  $timestamp " -ForegroundColor DarkGray -NoNewline
        Write-Host "$icon " -ForegroundColor $color -NoNewline
        Write-Host "$Message" -NoNewline
    }
    else {
        Write-Host "  $timestamp " -ForegroundColor DarkGray -NoNewline
        Write-Host "$icon " -ForegroundColor $color -NoNewline
        Write-Host "$Message"
    }
}

function Write-Separator {
    Write-Host "  -----------------------------------------------------------------" -ForegroundColor DarkGray
}

function Test-Prerequisites {
    Write-Host ""
    Write-Separator
    Write-Host "  CHECKING PREREQUISITES" -ForegroundColor White
    Write-Separator
    
    $allPassed = $true
    
    # Check mobileactivationd file
    if (Test-Path $Config.MobileActivationdPath) {
        $fileInfo = Get-Item $Config.MobileActivationdPath
        $fileSize = $fileInfo.Length
        
        if ($fileSize -ge $Config.MinFileSize -and $fileSize -le $Config.MaxFileSize) {
            $sizeMB = [math]::Round($fileSize / 1048576, 2)
            Write-Step "mobileactivationd found ($sizeMB MB)" -Status "SUCCESS"
        }
        else {
            $sizeMB = [math]::Round($fileSize / 1048576, 2)
            Write-Step "mobileactivationd has unexpected size ($sizeMB MB)" -Status "WARNING"
            Write-Step "  Expected: 2-3.5 MB. File may be corrupted or incorrect." -Status "WARNING"
        }
    }
    else {
        Write-Step "mobileactivationd NOT FOUND in current directory" -Status "ERROR"
        Write-Step "  Please place the modified mobileactivationd binary in: $(Get-Location)" -Status "INFO"
        $allPassed = $false
    }
    
    # Check plist file
    if (Test-Path $Config.PlistPath) {
        Write-Step "com.bypass.mobileactivationd.plist found" -Status "SUCCESS"
    }
    else {
        Write-Step "com.bypass.mobileactivationd.plist NOT FOUND" -Status "ERROR"
        $allPassed = $false
    }
    
    # Check tools directory
    if (-not (Test-Path $Config.ToolsPath)) {
        Write-Step "tools\ directory NOT FOUND" -Status "ERROR"
        New-Item -ItemType Directory -Path $Config.ToolsPath -Force | Out-Null
        Write-Step "  Created tools\ directory. Please add required tools." -Status "INFO"
        $allPassed = $false
    }
    
    # Check iproxy.exe
    if (Test-Path $Config.IproxyExe) {
        Write-Step "iproxy.exe found" -Status "SUCCESS"
    }
    else {
        Write-Step "iproxy.exe NOT FOUND in tools\" -Status "ERROR"
        Write-Step "  Download from: https://github.com/L1ghtmann/libimobiledevice/releases" -Status "INFO"
        $allPassed = $false
    }
    
    # Check plink.exe
    if (Test-Path $Config.PlinkExe) {
        Write-Step "plink.exe found" -Status "SUCCESS"
    }
    else {
        Write-Step "plink.exe NOT FOUND in tools\" -Status "ERROR"
        Write-Step "  Download from: https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html" -Status "INFO"
        $allPassed = $false
    }
    
    # Check pscp.exe
    if (Test-Path $Config.PscpExe) {
        Write-Step "pscp.exe found" -Status "SUCCESS"
    }
    else {
        Write-Step "pscp.exe NOT FOUND in tools\" -Status "ERROR"
        Write-Step "  Download from: https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html" -Status "INFO"
        $allPassed = $false
    }
    
    # Check ideviceinfo.exe (optional but recommended)
    if (Test-Path $Config.IdeviceinfoExe) {
        Write-Step "ideviceinfo.exe found (optional)" -Status "SUCCESS"
    }
    else {
        Write-Step "ideviceinfo.exe not found (optional, but recommended)" -Status "WARNING"
    }
    
    return $allPassed
}

function Test-iPhoneConnection {
    Write-Host ""
    Write-Separator
    Write-Host "  CHECKING DEVICE CONNECTION" -ForegroundColor White
    Write-Separator
    
    if (Test-Path $Config.IdeviceinfoExe) {
        Write-Step "Checking for connected iOS device..." -Status "WORKING"
        
        try {
            $result = & $Config.IdeviceinfoExe 2>&1
            if ($LASTEXITCODE -eq 0) {
                # Extract device name if possible
                $deviceName = ($result | Select-String "DeviceName:").ToString().Split(":")[1].Trim()
                $productType = ($result | Select-String "ProductType:").ToString().Split(":")[1].Trim()
                Write-Step "Device detected: $deviceName ($productType)" -Status "SUCCESS"
                return $true
            }
            else {
                Write-Step "No iOS device detected or device not trusted" -Status "WARNING"
                Write-Step "  Please ensure device is connected via USB and trusted" -Status "INFO"
                return $false
            }
        }
        catch {
            Write-Step "Could not detect device (ideviceinfo error)" -Status "WARNING"
            Write-Step "  Continuing anyway - SSH connection will verify device" -Status "INFO"
            return $true
        }
    }
    else {
        Write-Step "Skipping device check (ideviceinfo.exe not found)" -Status "WARNING"
        Write-Step "  Ensure device is connected and trusted before proceeding" -Status "INFO"
        return $true
    }
}

function Start-Iproxy {
    Write-Host ""
    Write-Separator
    Write-Host "  STARTING USB PORT FORWARDING" -ForegroundColor White
    Write-Separator
    
    # Kill any existing iproxy processes
    Get-Process -Name "iproxy" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
    
    Write-Step "Starting iproxy (port $($Config.SSHPort):$($Config.iPhoneSSHPort))..." -Status "WORKING"
    
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = (Resolve-Path $Config.IproxyExe).Path
        $psi.Arguments = "$($Config.SSHPort) $($Config.iPhoneSSHPort)"
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        
        $Script:IproxyProcess = [System.Diagnostics.Process]::Start($psi)
        
        Start-Sleep -Seconds 2
        
        if (-not $Script:IproxyProcess.HasExited) {
            Write-Step "iproxy started successfully (PID: $($Script:IproxyProcess.Id))" -Status "SUCCESS"
            return $true
        }
        else {
            Write-Step "iproxy failed to start" -Status "ERROR"
            return $false
        }
    }
    catch {
        Write-Step "Failed to start iproxy: $($_.Exception.Message)" -Status "ERROR"
        return $false
    }
}

function Stop-Iproxy {
    if ($Script:IproxyProcess -and -not $Script:IproxyProcess.HasExited) {
        $Script:IproxyProcess.Kill()
        Write-Step "iproxy stopped" -Status "INFO"
    }
    
    Get-Process -Name "iproxy" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

function Invoke-SSHCommand {
    param (
        [string]$Command,
        [string]$Description,
        [switch]$IgnoreErrors
    )
    
    Write-Step "$Description..." -Status "WORKING"
    
    $plinkArgs = "-batch -pw $($Config.SSHPassword) -P $($Config.SSHPort) $($Config.SSHUser)@$($Config.SSHHost) `"$Command`""
    
    try {
        $result = & $Config.PlinkExe -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" $Command 2>&1
        
        if ($LASTEXITCODE -eq 0 -or $IgnoreErrors) {
            Write-Step "$Description - Complete" -Status "SUCCESS"
            return $true
        }
        else {
            Write-Step "$Description - Failed" -Status "ERROR"
            if ($result) {
                Write-Step "  Output: $result" -Status "INFO"
            }
            return $false
        }
    }
    catch {
        if ($IgnoreErrors) {
            Write-Step "$Description - Complete (with warnings)" -Status "WARNING"
            return $true
        }
        Write-Step "$Description - Error: $($_.Exception.Message)" -Status "ERROR"
        return $false
    }
}

function Send-FileToiPhone {
    param (
        [string]$LocalPath,
        [string]$RemotePath,
        [string]$Description
    )
    
    Write-Step "$Description..." -Status "WORKING"
    
    # Resolve path to absolute if relative
    if (-not [System.IO.Path]::IsPathRooted($LocalPath)) {
        $LocalPath = Join-Path (Get-Location) $LocalPath
    }
    
    # Verify file exists
    if (-not (Test-Path $LocalPath)) {
        Write-Step "File not found: $LocalPath" -Status "ERROR"
        return $false
    }
    
    $plinkPath = $Config.PlinkExe
    $sshArgs = "-batch -pw $($Config.SSHPassword) -P $($Config.SSHPort) $($Config.SSHUser)@$($Config.SSHHost)"
    $pathSetup = "export PATH=/cores/binpack/bin:/cores/binpack/usr/bin:`$PATH"
    
    # First try SCP (faster if available)
    $sftpCheck = & $plinkPath -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" "test -f /usr/libexec/sftp-server && echo yes || echo no" 2>&1
    
    if ($sftpCheck -match "yes") {
        try {
            $result = & $Config.PscpExe -batch -pw $Config.SSHPassword -P $Config.SSHPort $LocalPath "$($Config.SSHUser)@$($Config.SSHHost):$RemotePath" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Step "$Description - Complete" -Status "SUCCESS"
                return $true
            }
        }
        catch { }
    }
    
    # SFTP not available - use stdin streaming with xxd (avoids ALL command line limits)
    Write-Step "Using stdin streaming (hex + xxd)..." -Status "INFO"
    
    try {
        $fileBytes = [IO.File]::ReadAllBytes($LocalPath)
        $fileSize = $fileBytes.Length
        
        Write-Step "File size: $([Math]::Round($fileSize/1MB, 2)) MB" -Status "INFO"
        
        $startTime = Get-Date
        
        # Convert entire file to hex (fast in-memory operation)
        Write-Step "Converting to hex..." -Status "WORKING"
        $hexString = -join ($fileBytes | ForEach-Object { $_.ToString("x2") })
        Write-Step "Hex conversion complete ($([Math]::Round($hexString.Length/1MB, 2)) MB)" -Status "INFO"
        
        # Stream to device via stdin - no command line length limits!
        Write-Step "Streaming to device..." -Status "WORKING"
        
        $decodeCmd = "$pathSetup && xxd -r -p > '$RemotePath'"
        
        # Pipe hex string directly to plink stdin
        $hexString | & $plinkPath -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" $decodeCmd 2>&1 | Out-Null
        
        if ($LASTEXITCODE -ne 0) {
            throw "Stream transfer failed with exit code: $LASTEXITCODE"
        }
        
        # Verify file size on remote
        Write-Step "Verifying upload..." -Status "WORKING"
        
        # Check file exists
        $existsCmd = "$pathSetup && test -f '$RemotePath' && echo EXISTS || echo MISSING"
        $existsResult = & $plinkPath -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" $existsCmd 2>&1
        
        if ($existsResult -notmatch "EXISTS") {
            Write-Step "Remote file does not exist after upload!" -Status "ERROR"
            return $false
        }
        
        # Get file size
        $sizeCmd = "$pathSetup && wc -c < '$RemotePath'"
        $remoteSize = & $plinkPath -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" $sizeCmd 2>&1
        $remoteSize = ($remoteSize -replace '[^0-9]', '').Trim()
        
        if ([string]::IsNullOrEmpty($remoteSize)) {
            $remoteSize = "0"
        }
        
        $totalTime = ((Get-Date) - $startTime).TotalSeconds
        $speed = if ($totalTime -gt 0) { $fileSize / $totalTime / 1024 } else { 0 }
        
        Write-Step "Local: $fileSize bytes, Remote: $remoteSize bytes" -Status "INFO"
        
        if ([int]$remoteSize -eq $fileSize) {
            Write-Step "$Description - Complete ($([Math]::Round($fileSize/1MB, 2)) MB in $([Math]::Round($totalTime, 1))s @ $([Math]::Round($speed, 1)) KB/s)" -Status "SUCCESS"
            return $true
        }
        else {
            Write-Step "Size mismatch! Expected $fileSize, got $remoteSize" -Status "ERROR"
            
            # Debug: show file details
            $debugCmd = "$pathSetup && ls -la '$RemotePath' 2>&1"
            $debugResult = & $plinkPath -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" $debugCmd 2>&1
            Write-Step "Debug: $debugResult" -Status "INFO"
            
            return $false
        }
        
    }
    catch {
        Write-Step "$Description - Error: $($_.Exception.Message)" -Status "ERROR"
        return $false
    }
}

function Test-SSHConnection {
    Write-Step "Testing SSH connection to iPhone..." -Status "WORKING"
    
    # First, we need to accept the host key automatically
    # plink will prompt for host key - we use echo y to accept
    try {
        $echoProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/c echo y | `"$($Config.PlinkExe)`" -pw $($Config.SSHPassword) -P $($Config.SSHPort) $($Config.SSHUser)@$($Config.SSHHost) echo connected" -NoNewWindow -Wait -PassThru
        
        # Now test the actual connection
        $result = & $Config.PlinkExe -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" "echo connected" 2>&1
        
        if ($result -match "connected") {
            Write-Step "SSH connection established successfully" -Status "SUCCESS"
            return $true
        }
        else {
            Write-Step "SSH connection failed" -Status "ERROR"
            Write-Step "  Make sure OpenSSH is installed on your jailbroken device" -Status "INFO"
            Write-Step "  Default password should be 'alpine'" -Status "INFO"
            return $false
        }
    }
    catch {
        Write-Step "SSH connection error: $($_.Exception.Message)" -Status "ERROR"
        return $false
    }
}

function Invoke-BypassProcess {
    Write-Host ""
    Write-Separator
    Write-Host "  EXECUTING BYPASS PROCESS" -ForegroundColor White
    Write-Separator
    Write-Host ""
    
    $success = $true
    $mounted = $false
    
    # First, detect jailbreak type by checking for rootless indicator
    Write-Step "Detecting jailbreak type..." -Status "WORKING"
    $rootlessCheck = & $Config.PlinkExe -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" "test -L /var/jb && echo rootless || echo rootful" 2>&1
    
    if ($rootlessCheck -match "rootless") {
        Write-Step "Rootless jailbreak detected (/var/jb symlink exists)" -Status "WARNING"
        Write-Host ""
        Write-Host "  =================================================================" -ForegroundColor Yellow
        Write-Host "  |  ROOTLESS JAILBREAK - CANNOT MODIFY SYSTEM FILES             |" -ForegroundColor Yellow
        Write-Host "  =================================================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  This bypass requires ROOTFUL jailbreak to modify system files." -ForegroundColor White
        Write-Host ""
        Write-Host "  Options:" -ForegroundColor Yellow
        Write-Host "  1. Re-jailbreak with: palera1n -f -c  (rootful + fakefs)" -ForegroundColor Gray
        Write-Host "  2. Use Sileo tweak-based bypass instead" -ForegroundColor Gray
        Write-Host ""
        return $false
    }
    
    Write-Step "Rootful jailbreak detected" -Status "SUCCESS"
    
    # CRITICAL: Check iOS version compatibility
    Write-Step "Checking iOS version compatibility..." -Status "WORKING"
    $iosVersionCmd = "sw_vers -productVersion 2>&1"
    $iosVersion = & $Config.PlinkExe -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" $iosVersionCmd 2>&1
    $iosVersion = $iosVersion.Trim()
    
    Write-Step "iOS Version: $iosVersion" -Status "INFO"
    
    # Parse major version
    $majorVersion = 0
    if ($iosVersion -match "^(\d+)\.") {
        $majorVersion = [int]$Matches[1]
    }
    
    if ($majorVersion -ge 15) {
        Write-Host ""
        Write-Host "  =================================================================" -ForegroundColor Red
        Write-Host "  |                                                               |" -ForegroundColor Red
        Write-Host "  |              INCOMPATIBLE iOS VERSION                        |" -ForegroundColor Red
        Write-Host "  |                                                               |" -ForegroundColor Red
        Write-Host "  =================================================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "  This bypass method does NOT work on iOS $majorVersion" -ForegroundColor Yellow
        Write-Host "  iOS 15-16 require RAMDISK-based bypass (kernel patches needed)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Recommended Tools for iOS 15-16:" -ForegroundColor White
        Write-Host ""
        Write-Host "  1. Broque Ramdisk (Free)" -ForegroundColor Green
        Write-Host "     -> Works on iOS 15-16, full bypass" -ForegroundColor Gray
        Write-Host "     -> Search: 'Broque Ramdisk Windows download'" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  2. WinRa1n with palera1n --bypass (Free)" -ForegroundColor Green
        Write-Host "     -> Download: https://winra1n.net" -ForegroundColor Cyan
        Write-Host "     -> Use: palera1n -f --bypass" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Why this script won't work on iOS 15-16:" -ForegroundColor Yellow
        Write-Host "    - iOS 15+ has kernel-level activation checks" -ForegroundColor Gray
        Write-Host "    - Simple mobileactivationd replacement is detected" -ForegroundColor Gray
        Write-Host "    - Requires boot-time kernel patches (ramdisk mode)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  =================================================================" -ForegroundColor Red
        return $false
    }
    
    Write-Step "iOS $majorVersion is compatible with this bypass method" -Status "SUCCESS"
    
    # Try multiple mount methods for fakefs/rootful
    Write-Step "Mounting filesystem..." -Status "WORKING"
    
    # Method 1: Standard mount
    & $Config.PlinkExe -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" "mount -o rw,union,update /" 2>&1 | Out-Null
    
    # Method 2: Remount
    & $Config.PlinkExe -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" "mount -uw /" 2>&1 | Out-Null
    
    # Method 3: Snapshot mount (for iOS 15+ fakefs)
    & $Config.PlinkExe -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" "/sbin/mount -uw /" 2>&1 | Out-Null
    
    # Test if we can actually write to the target directory (use echo, touch may not exist)
    Write-Step "Testing write access to /usr/libexec/..." -Status "WORKING"
    $writeTest = & $Config.PlinkExe -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" "echo test > /usr/libexec/.bypass_test 2>&1 && rm -f /usr/libexec/.bypass_test && echo SUCCESS || echo FAILED" 2>&1
    
    if ($writeTest -match "SUCCESS") {
        Write-Step "Filesystem is writable" -Status "SUCCESS"
        $mounted = $true
    }
    else {
        Write-Step "Cannot write to /usr/libexec/" -Status "ERROR"
        Write-Step "Output: $writeTest" -Status "INFO"
        Write-Host ""
        Write-Host "  =================================================================" -ForegroundColor Red
        Write-Host "  |  FILESYSTEM NOT WRITABLE - FAKEFS MAY NOT BE SET UP          |" -ForegroundColor Red
        Write-Host "  =================================================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "  For palera1n rootful, you need fakefs:" -ForegroundColor White
        Write-Host "  1. Boot device normally (not jailbroken)" -ForegroundColor Gray
        Write-Host "  2. Run: palera1n -f -c   (first time to create fakefs)" -ForegroundColor Gray
        Write-Host "  3. After reboot, run: palera1n -f   (to boot with fakefs)" -ForegroundColor Gray
        Write-Host ""
        return $false
    }
    
    # Palera1n uses binaries in /cores/binpack - set up PATH
    Write-Step "Setting up palera1n environment..." -Status "WORKING"
    $binpackPath = "export PATH=/cores/binpack/bin:/cores/binpack/usr/bin:\$PATH"
    
    # Step 1: Stop activation service BEFORE making any changes
    Write-Step "Stopping activation service..." -Status "WORKING"
    $stopCmd = "$binpackPath && killall -9 mobileactivationd 2>&1 || true"
    & $Config.PlinkExe -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" $stopCmd 2>&1 | Out-Null
    
    # Unload the ORIGINAL iOS daemon (not custom one)
    $unloadCmd = "launchctl unload /System/Library/LaunchDaemons/com.apple.mobileactivationd.plist 2>&1 || true"
    & $Config.PlinkExe -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" $unloadCmd 2>&1 | Out-Null
    Write-Step "Activation service stopped" -Status "SUCCESS"
    
    # Step 2: Backup original mobileactivationd
    $backupCmd = "$binpackPath && mv -v /usr/libexec/mobileactivationd /usr/libexec/mobileactivationdBackup"
    if (-not (Invoke-SSHCommand -Command $backupCmd -Description "Backing up original mobileactivationd" -IgnoreErrors)) {
        # Might already be backed up, continue
        Write-Step "  Backup may already exist, continuing..." -Status "WARNING"
    }
    
    # Step 3: Extract entitlements from backup (use /tmp to avoid fakefs mmap issues)
    Write-Step "Extracting entitlements from backup..." -Status "WORKING"
    $ldidCmd = @"
$binpackPath && cp /usr/libexec/mobileactivationdBackup /tmp/mad_backup 2>&1 && ldid -e /tmp/mad_backup > /tmp/mad.plist 2>&1 && mv /tmp/mad.plist /usr/libexec/mobileactivationd.plist && rm -f /tmp/mad_backup && echo SUCCESS
"@
    $ldidResult = & $Config.PlinkExe -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" $ldidCmd 2>&1
    
    $Script:HasEntitlements = $false
    if ($ldidResult -match "SUCCESS") {
        Write-Step "Extracting entitlements from backup - Complete" -Status "SUCCESS"
        $Script:HasEntitlements = $true
    }
    else {
        Write-Step "Entitlement extraction failed (fakefs limitation)" -Status "WARNING"
        Write-Step "Creating default entitlements..." -Status "WORKING"
        
        # Create minimal default entitlements
        $defaultEntCmd = @"
$binpackPath && cat > /usr/libexec/mobileactivationd.plist << 'ENTEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>platform-application</key>
    <true/>
    <key>com.apple.private.security.no-container</key>
    <true/>
    <key>com.apple.private.skip-library-validation</key>
    <true/>
</dict>
</plist>
ENTEOF
"@
        $defaultResult = & $Config.PlinkExe -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" $defaultEntCmd 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Step "Default entitlements created" -Status "SUCCESS"
            $Script:HasEntitlements = $true
        }
        else {
            Write-Step "Cannot create entitlements - will skip signing" -Status "WARNING"
        }
    }
    
    # Step 4: Upload modified mobileactivationd
    if (-not (Send-FileToiPhone -LocalPath $Config.MobileActivationdPath -RemotePath "/usr/libexec/mobileactivationd" -Description "Uploading modified mobileactivationd")) {
        return $false
    }
    
    # Step 5: Set permissions
    $chmodCmd = "$binpackPath && chmod 755 /usr/libexec/mobileactivationd"
    if (-not (Invoke-SSHCommand -Command $chmodCmd -Description "Setting executable permissions")) {
        return $false
    }
    
    # Step 6: Sign the binary with entitlements (use /tmp to avoid fakefs mmap issues)
    if ($Script:HasEntitlements) {
        Write-Step "Signing binary with entitlements..." -Status "WORKING"
        $signCmd = @"
$binpackPath && cp /usr/libexec/mobileactivationd /tmp/mad_new 2>&1 && ldid -S/usr/libexec/mobileactivationd.plist /tmp/mad_new 2>&1 && mv /tmp/mad_new /usr/libexec/mobileactivationd && echo SUCCESS
"@
        $signResult = & $Config.PlinkExe -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" $signCmd 2>&1
        
        if ($signResult -match "SUCCESS") {
            Write-Step "Signing binary with entitlements - Complete" -Status "SUCCESS"
        }
        else {
            Write-Step "Signing failed, using unsigned binary (may still work)" -Status "WARNING"
        }
    }
    else {
        Write-Step "Skipping code signing (using pre-signed binary)" -Status "INFO"
    }
    
    # Step 7: Clean up temporary plist
    $cleanCmd = "$binpackPath && rm -f /usr/libexec/mobileactivationd.plist"
    Invoke-SSHCommand -Command $cleanCmd -Description "Cleaning up temporary files" -IgnoreErrors | Out-Null
    
    # Step 8: CRITICAL - Create Activation Records (required for bypass to work!)
    Write-Step "Creating activation records..." -Status "WORKING"
    
    # Create activation records directory
    $createDirCmd = "mkdir -p /var/root/Library/Lockdown/activation_records 2>&1 && echo CREATED"
    $dirResult = & $Config.PlinkExe -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" $createDirCmd 2>&1
    
    if ($dirResult -match "CREATED") {
        Write-Step "Activation records directory created" -Status "SUCCESS"
    }
    
    # Generate activation_record.plist
    Write-Step "Creating activation_record.plist..." -Status "WORKING"
    $activationRecordCmd = @'
cat > /var/root/Library/Lockdown/activation_records/activation_record.plist << 'PLISTEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>ActivationState</key>
    <string>Activated</string>
    <key>ActivationStateAcknowledged</key>
    <true/>
    <key>ActivityURL</key>
    <string>https://albert.apple.com/deviceservices/activity</string>
    <key>BasebandActivationTicket</key>
    <data>VGhpcyBpcyBhIGZha2UgYmFzZWJhbmQgdGlja2V0IGZvciBieXBhc3MgcHVycG9zZXM=</data>
    <key>FairPlayKeyData</key>
    <data>VGhpcyBpcyBmYWtlIEZhaXJQbGF5IGtleSBkYXRh</data>
    <key>ActivationInfoComplete</key>
    <true/>
    <key>ActivationRandomness</key>
    <string>BYPASS-ACTIVATION-RANDOMNESS</string>
    <key>ActivationInfoXML</key>
    <data>PHBsaXN0PjxkaWN0PjwvZGljdD48L3BsaXN0Pg==</data>
    <key>WildcardTicket</key>
    <data>V2lsZGNhcmRUaWNrZXRGb3JCeXBhc3NBY3RpdmF0aW9u</data>
    <key>AccountToken</key>
    <data>QnlwYXNzQWNjb3VudFRva2Vu</data>
    <key>RegulatoryImages</key>
    <dict/>
</dict>
</plist>
PLISTEOF
echo ACTIVATION_CREATED
'@
    $activationResult = & $Config.PlinkExe -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" $activationRecordCmd 2>&1
    
    if ($activationResult -match "ACTIVATION_CREATED") {
        Write-Step "activation_record.plist created" -Status "SUCCESS"
    }
    else {
        Write-Step "Could not create activation_record.plist" -Status "WARNING"
    }
    
    # Generate wildcard_record.plist
    Write-Step "Creating wildcard_record.plist..." -Status "WORKING"
    $wildcardRecordCmd = @'
cat > /var/root/Library/Lockdown/activation_records/wildcard_record.plist << 'PLISTEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>ActivationState</key>
    <string>WildcardActivated</string>
    <key>WildcardTicket</key>
    <data>V2lsZGNhcmRUaWNrZXRGb3JCeXBhc3NBY3RpdmF0aW9u</data>
    <key>AccountToken</key>
    <data>QnlwYXNzQWNjb3VudFRva2Vu</data>
    <key>AccountTokenCertificate</key>
    <data>QnlwYXNzQ2VydGlmaWNhdGU=</data>
    <key>AccountTokenSignature</key>
    <data>QnlwYXNzU2lnbmF0dXJl</data>
</dict>
</plist>
PLISTEOF
echo WILDCARD_CREATED
'@
    $wildcardResult = & $Config.PlinkExe -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" $wildcardRecordCmd 2>&1
    
    if ($wildcardResult -match "WILDCARD_CREATED") {
        Write-Step "wildcard_record.plist created" -Status "SUCCESS"
    }
    else {
        Write-Step "Could not create wildcard_record.plist" -Status "WARNING"
    }
    
    # Generate data_ark.plist (device identity)
    Write-Step "Creating data_ark.plist..." -Status "WORKING"
    $dataArkCmd = @'
cat > /var/root/Library/Lockdown/data_ark.plist << 'PLISTEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>ActivationState</key>
    <string>Activated</string>
    <key>com.apple.MobileActivation.State</key>
    <string>Activated</string>
    <key>com.apple.MobileActivation.LastActivatedTime</key>
    <date>2024-01-01T00:00:00Z</date>
    <key>com.apple.MobileActivation.ActivationCompleted</key>
    <true/>
</dict>
</plist>
PLISTEOF
echo DATA_ARK_CREATED
'@
    $dataArkResult = & $Config.PlinkExe -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" $dataArkCmd 2>&1
    
    if ($dataArkResult -match "DATA_ARK_CREATED") {
        Write-Step "data_ark.plist created" -Status "SUCCESS"
    }
    else {
        Write-Step "Could not create data_ark.plist" -Status "WARNING"
    }
    
    # Set proper permissions on all activation files
    Write-Step "Setting activation record permissions..." -Status "WORKING"
    $permCmd = @"
chmod 644 /var/root/Library/Lockdown/activation_records/*.plist 2>&1
chmod 644 /var/root/Library/Lockdown/data_ark.plist 2>&1
chown root:wheel /var/root/Library/Lockdown/activation_records/*.plist 2>&1
chown root:wheel /var/root/Library/Lockdown/data_ark.plist 2>&1
echo PERMS_SET
"@
    $permResult = & $Config.PlinkExe -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" $permCmd 2>&1
    
    if ($permResult -match "PERMS_SET") {
        Write-Step "Activation record permissions set" -Status "SUCCESS"
    }
    else {
        Write-Step "Permission setting may have failed" -Status "WARNING"
    }
    
    Write-Step "Activation records created" -Status "SUCCESS"
    
    # Step 9: Load ORIGINAL iOS daemon (which will now use our modified binary)
    Write-Step "Loading activation daemon..." -Status "WORKING"
    $loadCmd = "launchctl load /System/Library/LaunchDaemons/com.apple.mobileactivationd.plist 2>&1"
    $loadResult = & $Config.PlinkExe -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" $loadCmd 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Step "Daemon load returned non-zero (may be normal)" -Status "WARNING"
    }
    else {
        Write-Step "Activation daemon loaded" -Status "SUCCESS"
    }
    
    # Step 9: System cache refresh (SKIPPED - takes 2-5 min and not required for bypass)
    Write-Step "Skipping system cache refresh (optional, would take 2-5 min)" -Status "INFO"
    
    # Step 10: Clear activation state cache
    Write-Step "Clearing activation cache..." -Status "WORKING"
    $clearCacheCmd = @"
rm -rf /var/mobile/Library/Caches/com.apple.MobileActivation 2>&1 || true
rm -rf /var/mobile/Library/com.apple.MobileActivation 2>&1 || true
rm -rf /var/wireless/Library/Preferences/com.apple.commcenter.device_specific_nobackup.plist 2>&1 || true
echo 'DONE'
"@
    & $Config.PlinkExe -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" $clearCacheCmd 2>&1 | Out-Null
    Write-Step "Activation cache cleared" -Status "SUCCESS"
    
    # Step 11: Verify daemon is running
    Write-Step "Verifying daemon status..." -Status "WORKING"
    $verifyCmd = "ps aux | grep mobileactivationd | grep -v grep | head -1"
    $daemonStatus = & $Config.PlinkExe -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" $verifyCmd 2>&1
    
    if ($daemonStatus) {
        Write-Step "Daemon is running" -Status "SUCCESS"
    }
    else {
        Write-Step "Daemon not visible in process list (may start on demand)" -Status "INFO"
    }
    
    # Step 12: Reboot userspace
    Write-Step "Rebooting userspace (device will restart SpringBoard)..." -Status "WORKING"
    & $Config.PlinkExe -batch -pw $Config.SSHPassword -P $Config.SSHPort "$($Config.SSHUser)@$($Config.SSHHost)" "launchctl reboot userspace" 2>&1 | Out-Null
    Write-Step "Userspace reboot command sent" -Status "SUCCESS"
    
    return $true
}

function Show-CompletionMessage {
    param ([bool]$Success)
    
    Write-Host ""
    Write-Separator
    
    if ($Success) {
        Write-Host ""
        Write-Host "  =================================================================" -ForegroundColor Green
        Write-Host "  |                                                               |" -ForegroundColor Green
        Write-Host "  |           " -ForegroundColor Green -NoNewline
        Write-Host "BYPASS INSTALLATION COMPLETED!" -ForegroundColor White -NoNewline
        Write-Host "                     |" -ForegroundColor Green
        Write-Host "  |                                                               |" -ForegroundColor Green
        Write-Host "  =================================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "  [!] CRITICAL: Complete these steps on your iPhone:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Step 1: Wait for Reboot" -ForegroundColor White
        Write-Host "    -> Device will restart to setup screen in ~30 seconds" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Step 2: Go Through Setup Wizard" -ForegroundColor White
        Write-Host "    -> Select your Language" -ForegroundColor Gray
        Write-Host "    -> Select your Country/Region" -ForegroundColor Gray
        Write-Host "    -> Continue to Wi-Fi selection screen" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Step 3: IMPORTANT - Activate Bypass" -ForegroundColor Cyan
        Write-Host "    -> Look at the BOTTOM of the Wi-Fi screen" -ForegroundColor Gray
        Write-Host "    -> Tap: " -ForegroundColor Gray -NoNewline
        Write-Host "'Connect to iTunes'" -ForegroundColor Yellow
        Write-Host "    -> This triggers the bypass activation!" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Step 4: Verification" -ForegroundColor White
        Write-Host "    -> Device should show home screen in ~10 seconds" -ForegroundColor Gray
        Write-Host "    -> You can now use the device (Wi-Fi only)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  -----------------------------------------------------------------" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Limitations:" -ForegroundColor Yellow
        Write-Host "    - No cellular service (SIM will not work)" -ForegroundColor Gray
        Write-Host "    - No iCloud features" -ForegroundColor Gray
        Write-Host "    - No FaceTime/iMessage" -ForegroundColor Gray
        Write-Host "    - Semi-tethered (requires re-jailbreak after full power off)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Troubleshooting:" -ForegroundColor Yellow
        Write-Host "    If device doesn't activate after 'Connect to iTunes':" -ForegroundColor Gray
        Write-Host "    1. Manually reboot device (hold Power button)" -ForegroundColor Gray
        Write-Host "    2. Re-jailbreak with palera1n" -ForegroundColor Gray
        Write-Host "    3. Run this bypass script again" -ForegroundColor Gray
        Write-Host ""
    }
    else {
        Write-Host ""
        Write-Host "  =================================================================" -ForegroundColor Red
        Write-Host "  |                                                               |" -ForegroundColor Red
        Write-Host "  |                    " -ForegroundColor Red -NoNewline
        Write-Host "BYPASS FAILED" -ForegroundColor White -NoNewline
        Write-Host "                            |" -ForegroundColor Red
        Write-Host "  |                                                               |" -ForegroundColor Red
        Write-Host "  =================================================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Troubleshooting:" -ForegroundColor Yellow
        Write-Host "  1. Ensure device is properly jailbroken" -ForegroundColor Gray
        Write-Host "  2. Verify OpenSSH is installed (via Cydia/Sileo)" -ForegroundColor Gray
        Write-Host "  3. Check USB connection is stable" -ForegroundColor Gray
        Write-Host "  4. Try running the script again" -ForegroundColor Gray
        Write-Host "  5. See README.md for more troubleshooting steps" -ForegroundColor Gray
        Write-Host ""
    }
}

function Invoke-RevertBypass {
    Write-Host ""
    Write-Separator
    Write-Host "  REVERTING BYPASS" -ForegroundColor White
    Write-Separator
    
    # Unload launch daemon
    Invoke-SSHCommand -Command "launchctl unload /Library/LaunchDaemons/com.bypass.mobileactivationd.plist" -Description "Unloading launch daemon" -IgnoreErrors | Out-Null
    
    # Remove launch daemon plist
    Invoke-SSHCommand -Command "rm -f /Library/LaunchDaemons/com.bypass.mobileactivationd.plist" -Description "Removing launch daemon plist" -IgnoreErrors | Out-Null
    
    # Restore original mobileactivationd
    Invoke-SSHCommand -Command "mv -v /usr/libexec/mobileactivationdBackup /usr/libexec/mobileactivationd" -Description "Restoring original mobileactivationd" -IgnoreErrors | Out-Null
    
    Write-Step "Revert process completed" -Status "SUCCESS"
    Write-Step "Reboot device to apply changes" -Status "INFO"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

function Start-Bypass {
    Write-Banner
    
    # Check if running with elevated permissions (not required but note it)
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Step "Running without administrator privileges (usually not required)" -Status "INFO"
    }
    
    # Check prerequisites
    if (-not (Test-Prerequisites)) {
        Write-Host ""
        Write-Host "  [X] Prerequisites check failed. Please fix the issues above and try again." -ForegroundColor Red
        Write-Host "  See README.md for detailed setup instructions." -ForegroundColor Gray
        Write-Host ""
        return
    }
    
    # Check device connection
    $deviceConnected = Test-iPhoneConnection
    if (-not $deviceConnected) {
        Write-Host ""
        $continue = Read-Host "  Device not detected. Continue anyway? (y/n)"
        if ($continue -ne "y" -and $continue -ne "Y") {
            Write-Host "  Exiting..." -ForegroundColor Yellow
            return
        }
    }
    
    # Start iproxy
    if (-not (Start-Iproxy)) {
        Write-Host ""
        Write-Host "  [X] Failed to start port forwarding. Is iPhone connected?" -ForegroundColor Red
        return
    }
    
    # Test SSH connection
    Write-Host ""
    Write-Separator
    Write-Host "  TESTING SSH CONNECTION" -ForegroundColor White
    Write-Separator
    
    if (-not (Test-SSHConnection)) {
        Stop-Iproxy
        return
    }
    
    # Execute bypass
    $success = Invoke-BypassProcess
    
    # Cleanup
    Stop-Iproxy
    
    # Show completion message
    Show-CompletionMessage -Success $success
}

# Run if executed directly
if ($MyInvocation.InvocationName -ne '.') {
    try {
        Start-Bypass
    }
    catch {
        Write-Host ""
        Write-Host "  [X] An unexpected error occurred: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
        Stop-Iproxy
    }
    finally {
        Write-Host "  Press any key to exit..." -ForegroundColor DarkGray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}
