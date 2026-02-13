using System;
using System.Threading.Tasks;
using BroqueClone.Core.Models;

namespace BroqueClone.Core.Interfaces
{
    public interface IActivationService
    {
        Task<ActivationTicket> GenerateTicketAsync(DeviceInfo device, IProgress<string> progress);
        Task<bool> InjectTicketAsync(DeviceInfo device, ActivationTicket ticket, IProgress<string> progress);
    }
}
