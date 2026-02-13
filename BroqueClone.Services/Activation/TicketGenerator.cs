using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using BroqueClone.Core.Models;
using System.Security.Cryptography;
using System.Text;

namespace BroqueClone.Services.Activation
{
    public class TicketGenerator
    {
        public ActivationTicket GenerateTicket(DeviceInfo device)
        {
            var ticket = new ActivationTicket(device);
            
            // Generate fake activation record
            // This logic mimics the "magic" found in bypass tools:
            // creating a valid-looking plist structure that iOS accepts (sometimes)
            // or that works when injected into the right path with other file mods.
            
            var record = new Dictionary<string, object>();
            
            record.Add("ActivationState", "Activated");
            record.Add("ActivationRandomness", Guid.NewGuid().ToString().ToUpper());
            record.Add("UniqueDeviceID", device.UDID);
            record.Add("SerialNumber", device.SerialNumber);
            
            // Fake signatures - in a real reverse engineering scenario, 
            // we'd extract the exact algorithm or key used to sign this.
            // For now, we generate a dummy signature.
            record.Add("FairPlaySignature", GenerateFakeSignature(device.UDID));
            record.Add("AccountTokenSignature", GenerateFakeSignature(device.SerialNumber));
            
            ticket.ActivationRecord = record;
            
            return ticket;
        }
        
        private string GenerateFakeSignature(string input)
        {
            using (var sha = SHA256.Create())
            {
                var bytes = Encoding.UTF8.GetBytes(input + "SALT"); // Salt would be from analysis
                var hash = sha.ComputeHash(bytes);
                return Convert.ToBase64String(hash);
            }
        }
    }
}
