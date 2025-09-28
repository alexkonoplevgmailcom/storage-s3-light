using BFB.AWSS3Light.Abstractions.Interfaces;
using Microsoft.Extensions.DependencyInjection;

namespace BFB.AWSS3Light.BusinessServices;

/// <summary>
/// Extension methods for registering business services
/// </summary>
public static class ServiceCollectionExtensions
{
    /// <summary>
    /// Adds all business services to the dependency injection container
    /// </summary>
    /// <param name="services">The service collection</param>
    /// <returns>The service collection for chaining</returns>
    public static IServiceCollection AddAllBusinessServices(this IServiceCollection services)
    {
        // Add database-specific business services
        #region line:BFB.AWSS3Light.DataAccess.MongoDB
        #endregion
        #region line:BFB.AWSS3Light.DataAccess.SqlServer
        #endregion
        #region line:BFB.AWSS3Light.DataAccess.DB2
        #endregion
        #region line:BFB.AWSS3Light.DataAccess.Oracle
        #endregion
        
        // Add infrastructure-specific business services
        #region line:BFB.AWSS3Light.Messaging.Kafka
        #endregion
        #region line:BFB.AWSS3Light.RemoteAccess.RestApi
        #endregion
        
        return services;
    }

    /// <summary>
    /// Adds MongoDB-based business services to the dependency injection container
    /// </summary>
    /// <param name="services">The service collection</param>
    /// <returns>The service collection for chaining</returns>
    /// <summary>
    /// Adds SQL Server-based business services to the dependency injection container
    /// </summary>
    /// <param name="services">The service collection</param>
    /// <returns>The service collection for chaining</returns>
    
    /// <summary>
    /// Adds DB2-based business services to the dependency injection container
    /// </summary>
    /// <param name="services">The service collection</param>
    /// <returns>The service collection for chaining</returns>
    
    /// <summary>
    /// Adds Oracle-based business services to the dependency injection container
    /// </summary>
    /// <param name="services">The service collection</param>
    /// <returns>The service collection for chaining</returns>

    /// <summary>
    /// Adds cash withdrawal service to the dependency injection container
    /// </summary>
    /// <param name="services">The service collection</param>
    /// <returns>The service collection for chaining</returns>

    /// <summary>
    /// Adds credit card service to the dependency injection container
    /// </summary>
    /// <param name="services">The service collection</param>
    /// <returns>The service collection for chaining</returns>
}
