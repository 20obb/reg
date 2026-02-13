using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading.Tasks;
using BroqueClone.Core.Interfaces;
using BroqueClone.Core.Models;
using System.IO;
using System.Linq;

namespace BroqueClone.Services.Device
{
    public class DeviceManager : IDeviceManager
    {
        private const string ToolsPath = "Tools";

        public async Task<List<DeviceInfo>> DetectDevicesAsync()
        {
            var devices = new List<DeviceInfo>();
            try
            {
                // Run idevice_id -l to get list of UDIDs
                var output = await RunToolAsync("idevice_id.exe", "-l");
                if (string.IsNullOrWhiteSpace(output)) return devices;

                var udids = output.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
                foreach (var udid in udids)
                {
                    if (udid.Length > 20) // Simple validation
                    {
                        var info = await GetDeviceInfoAsync(udid);
                        if (info != null) devices.Add(info);
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error detecting devices: {ex.Message}");
            }
            return devices;
        }

        public async Task<DeviceInfo> GetDeviceInfoAsync(string udid)
        {
            var info = new DeviceInfo { UDID = udid };
            try
            {
                // Parse ideviceinfo output
                var output = await RunToolAsync("ideviceinfo.exe", $"-u {udid}");
                var lines = output.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
                
                foreach (var line in lines)
                {
                    var parts = line.Split(new[] { ": " }, 2, StringSplitOptions.None);
                    if (parts.Length != 2) continue;
                    
                    var key = parts[0];
                    var val = parts[1];

                    switch (key)
                    {
                        case "ProductType": info.ProductType = val; break;
                        case "ProductVersion": info.ProductVersion = val; break;
                        case "BuildVersion": info.BuildVersion = val; break;
                        case "SerialNumber": info.SerialNumber = val; break;
                        case "UniqueChipID": info.ECID = val; break;
                        case "HardwareModel": info.HardwareModel = val; break;
                        case "DeviceClass": info.DeviceClass = val; break;
                    }
                }

                info.CurrentMode = await DetermineModeAsync(udid);
            }
            catch
            {
                // Log error
            }
            return info;
        }

        public async Task<bool> IsDeviceInModeAsync(string udid, DeviceMode mode)
        {
            // Simple check using current determination logic
            // In reality, this would query specific tools depending on the mode expectd
            var current = await DetermineModeAsync(udid);
            return current == mode;
        }

        public async Task<bool> EnterDFUModeAsync(DeviceInfo deviceInfo, IProgress<string> progress = null)
        {
            // This usually requires user interaction, or specific triggers if already in Recovery
            progress?.Report("Please put device into DFU mode manually.");
            
            // Wait for DFU detection
            for (int i = 0; i < 60; i++) 
            {
                // Pseudo-check: in real impl run 'irecovery -q' to check mode
                // match "MODE: DFU"
                var mode = await Get_recoveryMode(); 
                if (mode == "DFU") return true; 
                await Task.Delay(1000);
            }
            return false;
        }
        
        private async Task<DeviceMode> DetermineModeAsync(string udid)
        {
             // Check normal mode via ideviceinfo (already done if GetDeviceInfo succeeded)
             // Check recovery/DFU via irecovery
             var output = await RunToolAsync("irecovery.exe", "-q");
             if (output.Contains("MODE: DFU")) return DeviceMode.DFU;
             if (output.Contains("MODE: Recovery")) return DeviceMode.Recovery;
             
             return DeviceMode.Normal;
        }

        private async Task<string> RunToolAsync(string toolName, string args)
        {
            var startInfo = new ProcessStartInfo
            {
                FileName = Path.Combine(ToolsPath, toolName),
                Arguments = args,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                CreateNoWindow = true
            };
            
            using (var process = Process.Start(startInfo))
            {
                if (process == null) return string.Empty;
                var result = await process.StandardOutput.ReadToEndAsync();
                await process.WaitForExitAsync();
                return result;
            }
        }
        
        // Mock method for syntax correctness in this draft
        private async Task<string> Get_recoveryMode() 
        {
             var output = await RunToolAsync("irecovery.exe", "-q");
             if (output.Contains("MODE: DFU")) return "DFU";
             return "";
        }
    }
}
