using System;
using System.IO;
using System.Threading.Tasks;
using BroqueClone.Core.Interfaces;
using BroqueClone.Core.Models;
using BroqueClone.Services.Communication;
using Newtonsoft.Json; 
// Note: In real impl, use a Plist library (e.g. Claunia.PropertyList)
// For this clone, we simulate Plist generation via XML templates strings

namespace BroqueClone.Services.Activation
{
    public class ActivationService : IActivationService
    {
        private readonly SSHService _sshService;
        private readonly TicketGenerator _ticketGenerator;

        public ActivationService(SSHService sshService)
        {
            _sshService = sshService;
            _ticketGenerator = new TicketGenerator();
        }

        public async Task<ActivationTicket> GenerateTicketAsync(DeviceInfo device, IProgress<string> progress)
        {
            progress?.Report("Generating activation ticket...");
            return await Task.Run(() => _ticketGenerator.GenerateTicket(device));
        }

        public async Task<bool> InjectTicketAsync(DeviceInfo device, ActivationTicket ticket, IProgress<string> progress)
        {
            if (!_sshService.IsConnected)
            {
                if (!await _sshService.ConnectAsync())
                {
                    progress?.Report("SSH Connection failed.");
                    return false;
                }
            }

            try
            {
                // 1. Mount FS
                progress?.Report("Mounting filesystem...");
                await _sshService.ExecuteCommandAsync("mount -o rw,union,update /");

                // 2. Prepare paths
                progress?.Report("Creating directory structure...");
                await _sshService.ExecuteCommandAsync("mkdir -p /var/root/Library/Lockdown/activation_records");

                // 3. Serialize Ticket to Plist (Simulated)
                var plistContent = GeneratePlistContent(ticket);
                var tempFile = Path.GetTempFileName();
                File.WriteAllText(tempFile, plistContent);

                // 4. Upload Ticket
                progress?.Report("Uploading activation record...");
                var remotePath = "/var/root/Library/Lockdown/activation_records/activation_record.plist";
                await _sshService.UploadFileAsync(tempFile, remotePath);
                
                // 5. Set Permissions
                await _sshService.ExecuteCommandAsync($"chmod 644 {remotePath}");
                await _sshService.ExecuteCommandAsync($"chown root:mobile {remotePath}");

                // 6. Modify data_ark.plist (Simulated logic)
                // In real tool: download -> modify -> upload
                progress?.Report("Patching data_ark.plist...");
                // await ModifyDataArkAsync(); // implementation omitted for brevity

                // 7. Patch MobileGestalt or other files if needed
                
                // 8. Respring/Reboot
                progress?.Report("Activation files injected.");
                
                // Cleanup
                if (File.Exists(tempFile)) File.Delete(tempFile);
                
                return true;
            }
            catch (Exception ex)
            {
                progress?.Report($"Injection failed: {ex.Message}");
                return false;
            }
        }

        private string GeneratePlistContent(ActivationTicket ticket)
        {
             // Simplified Plist XML template
             return $@"<?xml version=""1.0"" encoding=""UTF-8""?>
<!DOCTYPE plist PUBLIC ""-//Apple//DTD PLIST 1.0//EN"" ""http://www.apple.com/DTDs/PropertyList-1.0.dtd"">
<plist version=""1.0"">
<dict>
    <key>ActivationState</key>
    <string>{ticket.ActivationState}</string>
    <key>SerialNumber</key>
    <string>{ticket.SerialNumber}</string>
    <key>UniqueDeviceID</key>
    <string>{ticket.UniqueDeviceID}</string>
    <!-- Metadata from reverse engineering would go here -->
</dict>
</plist>";
        }
    }
}
