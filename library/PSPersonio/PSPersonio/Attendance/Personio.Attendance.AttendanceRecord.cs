using Personio.Employee;
using System;

namespace Personio.Attendance {
    /// <summary>
    ///
    /// </summary>
    [Serializable]
    public class AttendanceRecord : Personio.Object {
        #region Properties

        /// <summary>
        ///
        /// </summary>
        public BasicEmployee Employee;

        #endregion Properties
    }
}
