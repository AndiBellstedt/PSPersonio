using System;

namespace Personio {
    /// <summary>
    ///
    /// </summary>
    [Serializable]
    public class Object {
        #region Properties

        /// <summary>
        ///
        /// </summary>
        public object BaseObject;

        /// <summary>
        ///
        /// </summary>
        public int Id;

        private string _returnValue;

        #endregion Properties


        #region Statics & Stuff
        /// <summary>
        /// Overrides the default ToString() method
        /// </summary>
        /// <returns></returns>
        public override string ToString () {
            if (!string.IsNullOrEmpty(Convert.ToString(Id))) {
                _returnValue = Convert.ToString(Id);
            } else {
                _returnValue = this.GetType().Name;
            }

            return _returnValue;
        }
        #endregion Statics & Stuff
    }
}
