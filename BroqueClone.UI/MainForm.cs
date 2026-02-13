using System;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Forms;
using BroqueClone.Core.Models;
using BroqueClone.Services.Device;
using BroqueClone.Services.Communication;
using BroqueClone.Services.Exploit;
using BroqueClone.Services.Boot;
using BroqueClone.Services.NVRAM;
using BroqueClone.Services.Activation;
using Serilog;

namespace BroqueClone.UI
{
    public partial class MainForm : Form
    {
        private readonly DeviceManager _deviceManager;
        private readonly ExploitEngine _exploitEngine;
        private readonly BootManager _bootManager;
        private readonly SSHService _sshService;
        private readonly NVRAMManager _nvramManager;
        private readonly ActivationService _activationService;
        
        private DeviceInfo _currentDevice;

        public MainForm()
        {
            InitializeComponent();
            
            // In a real generic host app, we'd use DI. Here we verify manually.
            var logger = new LoggerConfiguration().WriteTo.File("log.txt").CreateLogger();
            
            _deviceManager = new DeviceManager(); 
            _exploitEngine = new ExploitEngine();
            _bootManager = new BootManager();
            _sshService = new SSHService();
            _nvramManager = new NVRAMManager(_sshService);
            _activationService = new ActivationService(_sshService);
        }

        private async void MainForm_Load(object sender, EventArgs e)
        {
            Log("Initialized BroqueClone...");
            await RefreshDeviceAsync();
        }

        private async Task RefreshDeviceAsync()
        {
            var devices = await _deviceManager.DetectDevicesAsync();
            if (devices.Count > 0)
            {
                _currentDevice = devices.First();
                UpdateDeviceInfoUI(_currentDevice);
            }
            else
            {
                lblStatus.Text = "Status: No Device";
                 _currentDevice = null;
            }
        }

        private void UpdateDeviceInfoUI(DeviceInfo device)
        {
            lblECID.Text = $"ECID: {device.ECID}";
            lblSerial.Text = $"Serial: {device.SerialNumber}";
            lblModel.Text = $"Model: {device.ProductType}";
            lblStatus.Text = $"Status: {device.CurrentMode}";
        }

        private void Log(string message)
        {
            if (InvokeRequired)
            {
                Invoke(new Action<string>(Log), message);
                return;
            }
            txtLog.AppendText($"[{DateTime.Now:HH:mm:ss}] {message}{Environment.NewLine}");
        }

        private async void btnCheckm8_Click(object sender, EventArgs e)
        {
            if (_currentDevice == null) { Log("No device connected."); return; }
            
            var progress = new Progress<string>(msg => Log(msg));
            await _exploitEngine.ExecuteExploitAsync(_currentDevice, progress);
        }

        private async void btnBoot_Click(object sender, EventArgs e)
        {
            if (_currentDevice == null) { Log("No device connected."); return; }

            var progress = new Progress<string>(msg => Log(msg));
            await _bootManager.BootRamdiskAsync(_currentDevice, progress);
        }

        private async void btnChangeSerial_Click(object sender, EventArgs e)
        {
            if (_currentDevice == null) { Log("No device connected."); return; }
            
            var newSerial = _nvramManager.GenerateSerial(_currentDevice.ProductType);
            if (MessageBox.Show($"Change serial to {newSerial}?", "Confirm", MessageBoxButtons.YesNo) == DialogResult.Yes)
            {
                var progress = new Progress<string>(msg => Log(msg));
                await _nvramManager.ChangeSerialAsync(_currentDevice, newSerial, progress);
                await RefreshDeviceAsync();
            }
        }

        private async void btnActivate_Click(object sender, EventArgs e)
        {
            if (_currentDevice == null) { Log("No device connected."); return; }

            var progress = new Progress<string>(msg => Log(msg));
            
            Log("Generating ticket...");
            var ticket = await _activationService.GenerateTicketAsync(_currentDevice, progress);
            
            Log("Injecting activation...");
            bool success = await _activationService.InjectTicketAsync(_currentDevice, ticket, progress);
            
            if (success)
            {
                MessageBox.Show("Bypass Complete! Device should be activated.", "Success");
            }
        }
    }
}
