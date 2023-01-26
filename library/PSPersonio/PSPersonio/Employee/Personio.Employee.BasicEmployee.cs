using System;

namespace Personio.Employee {
    /// <summary>
    ///
    /// </summary>
    [Serializable]
    public class BasicEmployee : Personio.Object {
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
            } else if (string.IsNullOrEmpty(Name) && !string.IsNullOrEmpty(Convert.ToString(Id))) {
                _returnValue = Convert.ToString(Id);
            } else {
                _returnValue = this.GetType().Name;
            }

            return _returnValue;
        }
        #endregion Statics & Stuff


        #region Constructors
        /// <summary>
        /// 
        /// </summary>
        public BasicEmployee () {
        }

        /// <summary>
        /// input Id
        /// </summary>
        public BasicEmployee (int Id) {
            this.Id = Id;
        }

        #endregion Constructors

    }
}
