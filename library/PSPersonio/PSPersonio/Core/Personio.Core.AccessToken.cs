using System;
using System.Security;

namespace Personio.Core {
    /// <summary>
    ///
    /// </summary>
    [Serializable]
    public class AccessToken {
        #region Properties
        /// <summary>
        ///
        /// </summary>
        public Guid TokenID;

        /// <summary>
        ///
        /// </summary>
        public string ClientId;

        /// <summary>
        ///
        /// </summary>
        public string ApplicationId;

        /// <summary>
        ///
        /// </summary>
        public string ApplicationPartnerId;

        /// <summary>
        ///
        /// </summary>
        public string Issuer;

        /// <summary>
        ///
        /// </summary>
        public string[] Scope;

        /// <summary>
        /// The actual access token
        /// </summary>
        public SecureString Token;

        /// <summary>
        ///
        /// </summary>
        public string ApiUri;

        /// <summary>
        ///
        /// </summary>
        public DateTime TimeStampCreated;

        /// <summary>
        ///
        /// </summary>
        public DateTime TimeStampNotBefore;

        /// <summary>
        ///
        /// </summary>
        public DateTime TimeStampExpires;

        /// <summary>
        ///
        /// </summary>
        public DateTime TimeStampModified;

        /// <summary>
        /// Whether the token is valid for connections
        /// </summary>
        public bool IsValid {
            get {
                if (TimeStampExpires < DateTime.Now)
                    return false;
                if (TimeStampExpires == null)
                    return false;
                if (Token == null)
                    return false;
                if(Scope == null)
                    return false;
                return true;
            }

            set {
            }
        }

        /// <summary>
        /// The Lifetime of the Access Token
        /// </summary>
        public TimeSpan AccessTokenLifeTime {
            get {
                return TimeStampExpires.Subtract(TimeStampCreated);
            }

            set {
            }
        }

        /// <summary>
        /// Remaining time of the token Lifetime
        /// </summary>
        public TimeSpan TimeRemaining {
            get {
                if (TimeStampExpires > DateTime.Now) {
                    TimeSpan timeSpan = TimeStampExpires - DateTime.Now;
                    return TimeSpan.Parse(timeSpan.ToString(@"dd\.hh\:mm\:ss"));
                } else {
                    TimeSpan timeSpan = TimeSpan.Parse("0:0:0:0");
                    return timeSpan;
                }
            }

            set {
            }
        }

        /// <summary>
        /// Percentage value of the Tokenlifetime
        /// </summary>
        public Int16 PercentRemaining {
            get {
                if (TimeStampExpires > DateTime.Now) {
                    Int16 percentage = (Int16)(Math.Round(TimeRemaining.TotalMilliseconds / AccessTokenLifeTime.TotalMilliseconds * 100, 0));
                    return percentage;
                } else {
                    return 0;
                }
            }

            set {
            }
        }

        private string _returnValue;

        #endregion Properties


        #region Statics & Stuff
        /// <summary>
        /// Overrides the default ToString() method
        /// </summary>
        /// <returns></returns>
        public override string ToString () {
            if (!string.IsNullOrEmpty(ApiUri)) {
                _returnValue = ApiUri;
                if(! string.IsNullOrEmpty( Convert.ToString(TimeRemaining) )) {
                    _returnValue = string.Concat(_returnValue, " | ", Convert.ToString(TimeRemaining));
                }
            } else {
                _returnValue = this.GetType().Name;
            }

            return _returnValue;
        }
        #endregion Statics & Stuff
    }
}
