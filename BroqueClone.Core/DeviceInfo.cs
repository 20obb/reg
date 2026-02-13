using System;

namespace BroqueClone.Core.Models
{
    /// <summary>
    /// Represents information about an iOS device
    /// </summary>
    public class DeviceInfo
    {
        /// <summary>
        /// Unique Device Identifier (40 hex characters)
        /// </summary>
        public string UDID { get; set; }
        
        /// <summary>
        /// Exclusive Chip ID (decimal or hex)
        /// </summary>
        public string ECID { get; set; }
        
        /// <summary>
        /// Device serial number
        /// </summary>
        public string SerialNumber { get; set; }
        
        /// <summary>
        /// Product type (e.g., "iPhone9,1")
        /// </summary>
        public string ProductType { get; set; }
        
        /// <summary>
        /// iOS version (e.g., "15.7.1")
        /// </summary>
        public string ProductVersion { get; set; }
        
        /// <summary>
        /// Build version (e.g., "19H117")
        /// </summary>
        public string BuildVersion { get; set; }
        
        /// <summary>
        /// Hardware model (e.g., "D10AP")
        /// </summary>
        public string HardwareModel { get; set; }
        
        /// <summary>
        /// Chip ID (integer)
        /// </summary>
        public int ChipID { get; set; }
        
        /// <summary>
        /// Board ID (integer)
        /// </summary>
        public int BoardID { get; set; }
        
        /// <summary>
        /// Device class (e.g., "iPhone", "iPad")
        /// </summary>
        public string DeviceClass { get; set; }
        
        /// <summary>
        /// Current device mode
        /// </summary>
        public DeviceMode CurrentMode { get; set; }
        
        /// <summary>
        /// Whether device is supported for bypass
        /// </summary>
        public bool IsSupported { get; set; }
    }
    
    /// <summary>
    /// Device operating mode
    /// </summary>
    public enum DeviceMode
    {
        Unknown,
        Normal,
        Recovery,
        DFU,
        Ramdisk
    }
}
