using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using BroqueClone.Core.Models;

namespace BroqueClone.Core.Interfaces
{
    /// <summary>
    /// Interface for device management operations
    /// </summary>
    public interface IDeviceManager
    {
        /// <summary>
        /// Detects all connected iOS devices
        /// </summary>
        /// <returns>List of detected devices</returns>
        Task<List<DeviceInfo>> DetectDevicesAsync();
        
        /// <summary>
        /// Gets detailed information about a specific device
        /// </summary>
        /// <param name="udid">Device UDID</param>
        /// <returns>Device information</returns>
        Task<DeviceInfo> GetDeviceInfoAsync(string udid);
        
        /// <summary>
        /// Checks if device is in specified mode
        /// </summary>
        /// <param name="udid">Device UDID</param>
        /// <param name="mode">Expected mode</param>
        /// <returns>True if in specified mode</returns>
        Task<bool> IsDeviceInModeAsync(string udid, DeviceMode mode);
        
        /// <summary>
        /// Enters DFU mode on device
        /// </summary>
        /// <param name="deviceInfo">Device information</param>
        /// <param name="progress">Progress callback</param>
        /// <returns>True if successful</returns>
        Task<bool> EnterDFUModeAsync(DeviceInfo deviceInfo, IProgress<string> progress = null);
    }
}
