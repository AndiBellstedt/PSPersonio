using Personio.Employee;
using System;

namespace Personio.Absence {
    /// <summary>
    ///
    /// </summary>
    [Serializable]
    public class AbsencePeriod : Personio.Object {
        #region Properties

        /// <summary>
        ///
        /// </summary>
        public AbsenceType Type;

        /// <summary>
        ///
        /// </summary>
        public BasicEmployee Employee;

        #endregion Properties
    }
}
