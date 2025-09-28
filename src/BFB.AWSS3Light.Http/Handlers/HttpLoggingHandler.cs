using Microsoft.Extensions.Logging;
using System.Text;

namespace BFB.AWSS3Light.Http.Handlers;

public class HttpLoggingHandler : DelegatingHandler
{
    private readonly ILogger<HttpLoggingHandler> _logger;
    private readonly bool _isVerboseLoggingEnabled;

    public HttpLoggingHandler(ILogger<HttpLoggingHandler> logger, bool isVerboseLoggingEnabled = false)
    {
        _logger = logger;
        _isVerboseLoggingEnabled = isVerboseLoggingEnabled;
    }

    protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        if (!_isVerboseLoggingEnabled)
        {
            return await base.SendAsync(request, cancellationToken);
        }

        var requestId = Guid.NewGuid().ToString("N")[..8];
        
        // Log request details
        await LogRequestAsync(request, requestId);
        
        var stopwatch = System.Diagnostics.Stopwatch.StartNew();
        HttpResponseMessage response;
        
        try
        {
            response = await base.SendAsync(request, cancellationToken);
            stopwatch.Stop();
            
            // Log response details
            await LogResponseAsync(response, requestId, stopwatch.ElapsedMilliseconds);
            
            return response;
        }
        catch (Exception ex)
        {
            stopwatch.Stop();
            _logger.LogError(ex, "[HTTP-{RequestId}] Request failed after {ElapsedMs}ms: {Method} {Uri}", 
                requestId, stopwatch.ElapsedMilliseconds, request.Method, request.RequestUri);
            throw;
        }
    }

    private async Task LogRequestAsync(HttpRequestMessage request, string requestId)
    {
        var logBuilder = new StringBuilder();
        logBuilder.AppendLine($"[HTTP-{requestId}] Outgoing Request:");
        logBuilder.AppendLine($"Method: {request.Method}");
        logBuilder.AppendLine($"URI: {request.RequestUri}");
        
        // Log headers
        if (request.Headers.Any())
        {
            logBuilder.AppendLine("Headers:");
            foreach (var header in request.Headers)
            {
                logBuilder.AppendLine($"  {header.Key}: {string.Join(", ", header.Value)}");
            }
        }

        // Log content headers and body
        if (request.Content != null)
        {
            if (request.Content.Headers.Any())
            {
                logBuilder.AppendLine("Content Headers:");
                foreach (var header in request.Content.Headers)
                {
                    logBuilder.AppendLine($"  {header.Key}: {string.Join(", ", header.Value)}");
                }
            }

            var contentType = request.Content.Headers.ContentType?.MediaType;
            if (IsLoggableContent(contentType))
            {
                try
                {
                    var content = await request.Content.ReadAsStringAsync();
                    if (!string.IsNullOrEmpty(content))
                    {
                        logBuilder.AppendLine($"Body: {content}");
                    }
                }
                catch (Exception ex)
                {
                    logBuilder.AppendLine($"Body: [Error reading content: {ex.Message}]");
                }
            }
            else
            {
                logBuilder.AppendLine($"Body: [Binary/Non-text content - {contentType}]");
            }
        }

        _logger.LogDebug("{RequestLog}", logBuilder.ToString());
    }

    private async Task LogResponseAsync(HttpResponseMessage response, string requestId, long elapsedMs)
    {
        var logBuilder = new StringBuilder();
        logBuilder.AppendLine($"[HTTP-{requestId}] Incoming Response ({elapsedMs}ms):");
        logBuilder.AppendLine($"Status: {(int)response.StatusCode} {response.StatusCode}");
        
        // Log headers
        if (response.Headers.Any())
        {
            logBuilder.AppendLine("Headers:");
            foreach (var header in response.Headers)
            {
                logBuilder.AppendLine($"  {header.Key}: {string.Join(", ", header.Value)}");
            }
        }

        // Log content headers and body
        if (response.Content != null)
        {
            if (response.Content.Headers.Any())
            {
                logBuilder.AppendLine("Content Headers:");
                foreach (var header in response.Content.Headers)
                {
                    logBuilder.AppendLine($"  {header.Key}: {string.Join(", ", header.Value)}");
                }
            }

            var contentType = response.Content.Headers.ContentType?.MediaType;
            if (IsLoggableContent(contentType))
            {
                try
                {
                    var content = await response.Content.ReadAsStringAsync();
                    if (!string.IsNullOrEmpty(content))
                    {
                        logBuilder.AppendLine($"Body: {content}");
                    }
                }
                catch (Exception ex)
                {
                    logBuilder.AppendLine($"Body: [Error reading content: {ex.Message}]");
                }
            }
            else
            {
                logBuilder.AppendLine($"Body: [Binary/Non-text content - {contentType}]");
            }
        }

        var logLevel = response.IsSuccessStatusCode ? LogLevel.Debug : LogLevel.Warning;
        _logger.Log(logLevel, "{ResponseLog}", logBuilder.ToString());
    }

    private static bool IsLoggableContent(string? contentType)
    {
        if (string.IsNullOrEmpty(contentType)) return true;
        
        return contentType.StartsWith("text/", StringComparison.OrdinalIgnoreCase) ||
               contentType.StartsWith("application/json", StringComparison.OrdinalIgnoreCase) ||
               contentType.StartsWith("application/xml", StringComparison.OrdinalIgnoreCase) ||
               contentType.StartsWith("application/x-www-form-urlencoded", StringComparison.OrdinalIgnoreCase);
    }
}