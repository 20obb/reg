using System;
using System.Threading.Tasks;
using BroqueClone.Core.Models;

namespace BroqueClone.Core.Interfaces
{
    public interface IBootManager
    {
        Task<bool> BootRamdiskAsync(DeviceInfo device, IProgress<string> progress);
    }
}
