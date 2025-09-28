using BFB.AWSS3Light.API.Attributes;
using System.Reflection;

namespace BFB.AWSS3Light.API.Middleware;

public class TransactionIdMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<TransactionIdMiddleware> _logger;
    private readonly IWebHostEnvironment _environment;

    public TransactionIdMiddleware(RequestDelegate next, ILogger<TransactionIdMiddleware> logger, IWebHostEnvironment environment)
    {
        _next = next;
        _logger = logger;
        _environment = environment;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var endpoint = context.GetEndpoint();
        if (endpoint?.Metadata != null)
        {
            var controllerActionDescriptor = endpoint.Metadata.GetMetadata<Microsoft.AspNetCore.Mvc.Controllers.ControllerActionDescriptor>();
            if (controllerActionDescriptor != null)
            {
                var hasDevelopmentOnly = controllerActionDescriptor.ControllerTypeInfo.GetCustomAttribute<DevelopmentOnlyAttribute>() != null ||
                                       controllerActionDescriptor.MethodInfo.GetCustomAttribute<DevelopmentOnlyAttribute>() != null;

                if (!hasDevelopmentOnly)
                {
                    var transactionId = context.Request.Headers["x-fibi-transaction-id"].FirstOrDefault();
                    
                    if (string.IsNullOrEmpty(transactionId))
                    {
                        if (_environment.IsDevelopment() && IsSwaggerRequest(context))
                        {
                            transactionId = Guid.NewGuid().ToString("N")[..16];
                            context.Request.Headers["x-fibi-transaction-id"] = transactionId;
                            _logger.LogDebug("Auto-generated transaction ID for Swagger request: {TransactionId}", transactionId);
                        }
                        else
                        {
                            context.Response.StatusCode = 400;
                            await context.Response.WriteAsync("x-fibi-transaction-id header is required");
                            return;
                        }
                    }
                }
            }
        }

        await _next(context);
    }

    private static bool IsSwaggerRequest(HttpContext context)
    {
        var userAgent = context.Request.Headers["User-Agent"].FirstOrDefault();
        var referer = context.Request.Headers["Referer"].FirstOrDefault();
        
        return (userAgent?.Contains("swagger", StringComparison.OrdinalIgnoreCase) == true) ||
               (referer?.Contains("swagger", StringComparison.OrdinalIgnoreCase) == true);
    }
}