using System;

namespace Personio.Core {
    /// <summary>
    /// Hashtables for cache data to exchange content between runspaces
    /// </summary>
    public static class Cache {
        /// <summary>
        /// 
        /// </summary>
        public static System.Collections.Specialized.OrderedDictionary Data = new System.Collections.Specialized.OrderedDictionary();

        /// <summary>
        /// 
        /// </summary>
        public static bool StopValidationRunspace = new bool();
    }
}
