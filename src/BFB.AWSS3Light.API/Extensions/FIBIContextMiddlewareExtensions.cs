using BFB.AWSS3Light.API.Middleware;

namespace BFB.AWSS3Light.API.Extensions
{
    /// <summary>
    /// Extension methods for configuring FIBIContext middleware in the application pipeline.
    /// </summary>
    public static class FIBIContextMiddlewareExtensions
    {
        /// <summary>
        /// Adds the FIBIContext middleware to the application pipeline.
        /// This middleware automatically populates FIBIContext from HTTP request headers.
        /// </summary>
        /// <param name="builder">The application builder</param>
        /// <returns>The application builder for method chaining</returns>
        /// <remarks>
        /// This middleware should be added early in the pipeline, after authentication
        /// but before controllers, to ensure FIBIContext is properly populated for
        /// all downstream components.
        /// </remarks>
        public static IApplicationBuilder UseFIBIContext(this IApplicationBuilder builder)
        {
            return builder.UseMiddleware<FIBIContextMiddleware>();
        }
    }
}
