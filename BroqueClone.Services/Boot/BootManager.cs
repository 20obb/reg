using System;
using System.IO;
using System.Threading.Tasks;
using System.Collections.Generic;
using BroqueClone.Core.Models;
using System.Diagnostics;
using BroqueClone.Core.Interfaces;

namespace BroqueClone.Services.Boot
{
    public class BootManager : IBootManager
    {
        private const string BootFilesPath = "Resources/Boot";
        private const string ToolsPath = "Tools";

        public async Task<bool> BootRamdiskAsync(DeviceInfo device, IProgress<string> progress)
        {
            progress?.Report($"Preparing to boot ramdisk for {device.ProductType}...");

            // 1. Locate Boot Files
            var deviceBootPath = Path.Combine(BootFilesPath, device.ProductType, device.ProductVersion);
            if (!Directory.Exists(deviceBootPath))
            {
                progress?.Report($"Boot files not found for {device.ProductType}");
                return false;
            }

            try
            {
                // 2. Load iBSS
                progress?.Report("Sending iBSS...");
                await SendFileAsync("iBSS", deviceBootPath);
                await Task.Delay(2000); // Wait for device to accept

                // 3. Load iBEC
                progress?.Report("Sending iBEC...");
                await SendFileAsync("iBEC", deviceBootPath);
                await Task.Delay(2000);

                // 4. Load DeviceTree
                progress?.Report("Sending DeviceTree...");
                await SendFileAsync("DeviceTree", deviceBootPath);

                // 5. Load Ramdisk
                progress?.Report("Sending Ramdisk (this may take a while)...");
                await SendFileAsync("ramdisk", deviceBootPath);

                // 6. Load Kernel
                progress?.Report("Sending Kernelcache...");
                await SendFileAsync("kernelcache", deviceBootPath);

                // 7. Boot
                progress?.Report("Executing boot command...");
                await RunIrecoveryCommandAsync("-c bootx");

                progress?.Report("Boot command sent. Waiting for SSH...");
                return true;
            }
            catch (Exception ex)
            {
                progress?.Report($"Boot failed: {ex.Message}");
                return false;
            }
        }

        private async Task SendFileAsync(string fileType, string searchPath)
        {
            // Find file matching type (simple checks for now)
            var files = Directory.GetFiles(searchPath, $"*{fileType}*");
            if (files.Length == 0) throw new FileNotFoundException($"No {fileType} found in {searchPath}");

            var file = files[0];
            await RunIrecoveryCommandAsync($"-f \"{file}\"");
        }

        private async Task RunIrecoveryCommandAsync(string arguments)
        {
            var startInfo = new ProcessStartInfo
            {
                FileName = Path.Combine(ToolsPath, "irecovery.exe"),
                Arguments = arguments,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                CreateNoWindow = true
            };

            using (var process = Process.Start(startInfo))
            {
                if (process == null) throw new Exception("Failed to start irecovery");
                await process.WaitForExitAsync();
                
                if (process.ExitCode != 0)
                {
                    throw new Exception($"irecovery failed with exit code {process.ExitCode}");
                }
            }
        }
    }
}
