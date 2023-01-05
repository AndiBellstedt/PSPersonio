using System;

namespace Personio.Absence {
    /// <summary>
    ///
    /// </summary>
    [Serializable]
    public class AbsenceType : Personio.Object {
        #region Properties

        /// <summary>
        ///
        /// </summary>
        public string Name;

        private string _returnValue;

        #endregion Properties


        #region Statics & Stuff
        /// <summary>
        /// Overrides the default ToString() method
        /// </summary>
        /// <returns></returns>
        public override string ToString () {
            if (!string.IsNullOrEmpty(Name)) {
                _returnValue = Name;
            } else {
                _returnValue = this.GetType().Name;
            }

            return _returnValue;
        }
        #endregion Statics & Stuff
    }
}
