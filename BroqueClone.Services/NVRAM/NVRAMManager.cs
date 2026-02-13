using System;
using System.Threading.Tasks;
using BroqueClone.Core.Interfaces;
using BroqueClone.Core.Models;
using BroqueClone.Services.Communication;

namespace BroqueClone.Services.NVRAM
{
    public class NVRAMManager : INVRAMManager
    {
        private readonly SSHService _sshService;
        private readonly SerialGenerator _generator;

        public NVRAMManager(SSHService sshService)
        {
            _sshService = sshService;
            _generator = new SerialGenerator();
        }

        public string GenerateSerial(string productType)
        {
            return _generator.GenerateSerial(productType);
        }

        public bool ValidateSerial(string serial)
        {
            return _generator.ValidateSerial(serial);
        }

        public async Task<bool> ChangeSerialAsync(DeviceInfo device, string newSerial, IProgress<string> progress)
        {
            if (!_sshService.IsConnected)
            {
                progress?.Report("SSH not connected. Attempting to connect...");
                if (!await _sshService.ConnectAsync())
                {
                    progress?.Report("Failed to connect via SSH.");
                    return false;
                }
            }

            // Sequence based on RE analysis
            progress?.Report("Mounting filesystem as R/W...");
            await _sshService.ExecuteCommandAsync("mount -o rw,union,update /");

            progress?.Report("Backing up NVRAM...");
            await _sshService.ExecuteCommandAsync("nvram -p > /mnt1/nvram_backup.txt"); // Backup to mnt1 or somewhere safe

            progress?.Report($"Writing new serial: {newSerial}...");
            
            // Set primary serial
            await _sshService.ExecuteCommandAsync($"nvram serial-number={newSerial}");
            // Set secondary serial if it exists (some devices check SSN)
            await _sshService.ExecuteCommandAsync($"nvram SSN={newSerial}");
            
            // Commit changes
            progress?.Report("Committing NVRAM changes...");
            await _sshService.ExecuteCommandAsync("nvram -c");
            
            // Verify
            var verifyOutput = await _sshService.ExecuteCommandAsync("nvram serial-number");
            if (verifyOutput.Contains(newSerial))
            {
                progress?.Report($"Success! Serial changed to {newSerial}");
                return true;
            }
            else
            {
                progress?.Report("Verification failed. Serial mismatch.");
                return false;
            }
        }
    }
}
