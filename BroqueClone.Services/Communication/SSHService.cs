using System;
using System.IO;
using System.Threading.Tasks;
using Renci.SshNet;

namespace BroqueClone.Services.Communication
{
    public class SSHService : IDisposable
    {
        private SshClient _sshClient;
        private ScpClient _scpClient;
        
        // Standard ramdisk credentials
        private const string Host = "127.0.0.1";
        private const int Port = 2222;
        private const string User = "root";
        private const string Pass = "alpine";

        public bool IsConnected => _sshClient?.IsConnected ?? false;

        public async Task<bool> ConnectAsync()
        {
            try
            {
                _sshClient = new SshClient(Host, Port, User, Pass);
                _sshClient.Connect();
                
                _scpClient = new ScpClient(Host, Port, User, Pass);
                _scpClient.Connect();
                
                return _sshClient.IsConnected;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"SSH Connection failed: {ex.Message}");
                return false;
            }
        }

        public async Task<string> ExecuteCommandAsync(string command)
        {
            if (!IsConnected) return string.Empty;
            
            try
            {
                // Should run in Task.Run for async
                return await Task.Run(() => 
                {
                    var cmd = _sshClient.CreateCommand(command);
                    var result = cmd.Execute();
                    return result;
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Command failed: {ex.Message}");
                return string.Empty;
            }
        }

        public async Task<bool> UploadFileAsync(string localPath, string remotePath)
        {
            if (!IsConnected) return false;
            
            try
            {
                await Task.Run(() => 
                {
                    _scpClient.Upload(new FileInfo(localPath), remotePath);
                });
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Upload failed: {ex.Message}");
                return false;
            }
        }

        public void Dispose()
        {
            _sshClient?.Disconnect();
            _sshClient?.Dispose();
            _scpClient?.Disconnect();
            _scpClient?.Dispose();
        }
    }
}
