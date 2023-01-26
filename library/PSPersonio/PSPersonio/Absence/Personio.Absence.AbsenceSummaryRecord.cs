using Personio.Employee;
using System;

namespace Personio.Absence {
    /// <summary>
    ///
    /// </summary>
    [Serializable]
    public class AbsenceSummaryRecord {
        #region Properties

        /// <summary>
        ///
        /// </summary>
        public object BaseObject;

        /// <summary>
        ///
        /// </summary>
        public AbsenceType AbsenceType;

        /// <summary>
        ///
        /// </summary>
        public BasicEmployee Employee;

        /// <summary>
        ///
        /// </summary>
        public string[] Category;

        /// <summary>
        ///
        /// </summary>
        public int Balance;

        private string _returnValue;

        #endregion Properties


        #region Statics & Stuff
        /// <summary>
        /// Overrides the default ToString() method
        /// </summary>
        /// <returns></returns>
        public override string ToString () {
            if (!string.IsNullOrEmpty(Convert.ToString(Employee))) {
                _returnValue = Convert.ToString(Employee);
            }

            if (!string.IsNullOrEmpty(Convert.ToString(AbsenceType))) {
                _returnValue = _returnValue + " - " + Convert.ToString(AbsenceType);
            }

            if (!string.IsNullOrEmpty(Convert.ToString(Balance))) {
                _returnValue = _returnValue + ": " + Convert.ToString(Balance);
            }

            if (string.IsNullOrEmpty(_returnValue)) {
                _returnValue = this.GetType().Name;
            }

            return _returnValue;
        }
        #endregion Statics & Stuff    }
    }
}