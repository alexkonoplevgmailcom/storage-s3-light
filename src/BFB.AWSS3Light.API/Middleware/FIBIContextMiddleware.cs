using BFB.AWSS3Light.Abstractions.Models;

namespace BFB.AWSS3Light.API.Middleware
{
    /// <summary>
    /// Middleware to automatically populate FIBIContext from HTTP request headers.
    /// This ensures consistent TransactionId handling across all requests and eliminates
    /// the need for manual header extraction in controllers.
    /// </summary>
    public class FIBIContextMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<FIBIContextMiddleware> _logger;

        /// <summary>
        /// Initializes a new instance of the FIBIContextMiddleware.
        /// </summary>
        /// <param name="next">The next middleware in the pipeline</param>
        /// <param name="logger">Logger for middleware operations</param>
        public FIBIContextMiddleware(RequestDelegate next, ILogger<FIBIContextMiddleware> logger)
        {
            _next = next ?? throw new ArgumentNullException(nameof(next));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        /// <summary>
        /// Invokes the middleware to populate FIBIContext from request headers.
        /// </summary>
        /// <param name="context">The HTTP context</param>
        /// <param name="fibiContext">The FIBI context to populate</param>
        /// <returns>A task representing the asynchronous operation</returns>
        public async Task InvokeAsync(HttpContext context, FIBIContext fibiContext)
        {
            try
            {
                // Extract TransactionId from header if present, otherwise keep auto-generated GUID
                var headerTransactionId = context.Request.Headers["X-Fibi-Transaction-Id"].FirstOrDefault();
                if (!string.IsNullOrWhiteSpace(headerTransactionId))
                {
                    fibiContext.TransactionId = headerTransactionId;
                    _logger.LogDebug("FIBIContext populated with TransactionId from header: {TransactionId}", headerTransactionId);
                }
                else
                {
                    _logger.LogDebug("No TransactionId header found, using auto-generated: {TransactionId}", fibiContext.TransactionId);
                }

                // Extract JWT token from Authorization header if present
                var authHeader = context.Request.Headers["Authorization"].FirstOrDefault();
                if (!string.IsNullOrWhiteSpace(authHeader))
                {
                    // Handle Bearer token format
                    if (authHeader.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
                    {
                        fibiContext.AuthenticationJWT = authHeader.Substring(7); // Remove "Bearer " prefix
                    }
                    else
                    {
                        fibiContext.AuthenticationJWT = authHeader;
                    }
                    _logger.LogDebug("FIBIContext populated with JWT token for transaction: {TransactionId}", fibiContext.TransactionId);
                }

                // Extract ForwardAccessToken from custom header if present
                var forwardTokenHeader = context.Request.Headers["X-Fibi-Forward-Token"].FirstOrDefault();
                if (!string.IsNullOrWhiteSpace(forwardTokenHeader))
                {
                    fibiContext.ForwardAccessToken = forwardTokenHeader;
                    _logger.LogDebug("FIBIContext populated with ForwardAccessToken for transaction: {TransactionId}", fibiContext.TransactionId);
                }

                // Add TransactionId to response headers for client tracking
                context.Response.Headers["X-Fibi-Transaction-Id"] = fibiContext.TransactionId;

                _logger.LogInformation("FIBIContext middleware processed request with TransactionId: {TransactionId}", fibiContext.TransactionId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in FIBIContext middleware while processing headers for request: {RequestPath}", context.Request.Path);
                // Don't throw - continue with default FIBIContext values
            }

            // Continue to next middleware
            await _next(context);
        }
    }
}
