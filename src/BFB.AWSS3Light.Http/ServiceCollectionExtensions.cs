using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using BFB.AWSS3Light.Abstractions.Interfaces;
using BFB.AWSS3Light.Http.Services;
using BFB.AWSS3Light.Http.Handlers;

namespace BFB.AWSS3Light.Http;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddHttpClientService(this IServiceCollection services)
    {
        services.AddHttpClient();
        
        // Register the logging handler
        services.AddTransient<HttpLoggingHandler>(provider =>
        {
            var logger = provider.GetRequiredService<ILogger<HttpLoggingHandler>>();
            var isVerboseEnabled = logger.IsEnabled(LogLevel.Debug);
            return new HttpLoggingHandler(logger, isVerboseEnabled);
        });
        
        // Configure named HttpClients with logging handler when verbose logging is enabled
        services.AddHttpClient("ExternalApi").AddHttpMessageHandler<HttpLoggingHandler>();
        services.AddHttpClient("PaymentService").AddHttpMessageHandler<HttpLoggingHandler>();
        services.AddHttpClient("CreditCardService").AddHttpMessageHandler<HttpLoggingHandler>();
        
        services.AddScoped<IHttpClientService, HttpClientService>();
        return services;
    }
}