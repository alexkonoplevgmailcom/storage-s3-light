using System;

namespace BFB.AWSS3Light.Abstractions.Models
{
    /// <summary>
    /// Context class that holds FIBI-specific request information throughout the application lifecycle.
    /// This class is registered as a Scoped service to maintain state per request.
    /// </summary>
    public class FIBIContext
    {
        /// <summary>
        /// Gets or sets the FIBI transaction ID. Defaults to a new GUID if not provided.
        /// </summary>
        public string TransactionId { get; set; } = Guid.NewGuid().ToString();

        /// <summary>
        /// Gets or sets the authentication JWT token. Can be null if not authenticated.
        /// </summary>
        public string? AuthenticationJWT { get; set; }

        /// <summary>
        /// Gets or sets the forward access token. Can be null if not provided.
        /// </summary>
        public string? ForwardAccessToken { get; set; }

        /// <summary>
        /// Gets or sets the JWT token for HTTP client requests. Can be null if not provided.
        /// </summary>
        public string? JwtToken { get; set; }
    }
}
