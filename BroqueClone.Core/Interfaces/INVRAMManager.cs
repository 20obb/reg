using System;
using System.Threading.Tasks;
using BroqueClone.Core.Models;

namespace BroqueClone.Core.Interfaces
{
    public interface INVRAMManager
    {
        string GenerateSerial(string productType);
        bool ValidateSerial(string serial);
        Task<bool> ChangeSerialAsync(DeviceInfo device, string newSerial, IProgress<string> progress);
    }
}
