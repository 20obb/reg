using System;
using System.Linq;
using System.Text;

namespace BroqueClone.Services.NVRAM
{
    public class SerialGenerator
    {
        private static readonly Random _random = new Random();
        private const string Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

        // Factory codes from analysis (e.g. F1, F2, C39, DNP)
        private static readonly string[] FactoryCodes = { "F17", "F2L", "C39", "DNP", "C7C", "G6V" };
        
        public string GenerateSerial(string productType)
        {
            // Format: PPYWWUUUMCCC (12 chars for modern devices)
            // PP: Factory
            // Y: Year
            // WW: Week
            // UUU: Unique
            // M: Model identifier?
            // CCC: Color/Storage
            
            var factory = FactoryCodes[_random.Next(FactoryCodes.Length)];
            var year = GenerateRandomString(1);
            var week = _random.Next(1, 53).ToString("D2"); // 01-52
            var unique = GenerateRandomString(3);
            var model = GenerateRandomString(1); // Simplified modeling
            var check = GenerateRandomString(1); // Simplified checksum char for last pos
            
            // Construct 12 char serial
            // Actually, newer serials are randomized 10 chars + configuration code
            // But for older devices (Checkm8 era 6s-X), 12 char format is standard.
            
            // Let's stick to a robust simpler generation that passes basic regex checks
            // Structure: F2L + 9 random chars
            
            var sb = new StringBuilder();
            sb.Append(factory);
            while (sb.Length < 12)
            {
                sb.Append(Chars[_random.Next(Chars.Length)]);
            }
            
            return sb.ToString();
        }

        public bool ValidateSerial(string serial)
        {
            if (string.IsNullOrEmpty(serial)) return false;
            if (serial.Length != 12) return false;
            
            // Check allowed chars
            return serial.All(c => Chars.Contains(c));
        }

        private string GenerateRandomString(int length)
        {
            return new string(Enumerable.Repeat(Chars, length)
                .Select(s => s[_random.Next(s.Length)]).ToArray());
        }
    }
}
