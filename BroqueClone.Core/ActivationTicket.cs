using System;
using System.Collections.Generic;

namespace BroqueClone.Core.Models
{
    /// <summary>
    /// Represents an iOS activation ticket
    /// </summary>
    public class ActivationTicket
    {
        public string ActivationState { get; set; } = "Activated";
        public Dictionary<string, object> ActivationRecord { get; set; }
        public string SerialNumber { get; set; }
        public string UniqueDeviceID { get; set; }
        public string ProductType { get; set; }
        
        /// <summary>
        /// Creates a new activation ticket for a device
        /// </summary>
        public ActivationTicket(DeviceInfo device)
        {
            SerialNumber = device.SerialNumber;
            UniqueDeviceID = device.UDID;
            ProductType = device.ProductType;
            ActivationRecord = new Dictionary<string, object>();
        }
        
        /// <summary>
        /// Default constructor for serialization
        /// </summary>
        public ActivationTicket() { }
    }
}
