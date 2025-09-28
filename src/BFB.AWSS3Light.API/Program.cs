using BFB.AWSS3Light.BusinessServices;
#region line:BFB.AWSS3Light.DataAccess.MongoDB
#endregion
#region line:BFB.AWSS3Light.DataAccess.DB2
#endregion
#region line:BFB.AWSS3Light.DataAccess.SqlServer
#endregion
#region line:BFB.AWSS3Light.DataAccess.Oracle
#endregion
using BFB.AWSS3Light.Abstractions.Interfaces;
using BFB.AWSS3Light.Abstractions.Models;
using BFB.AWSS3Light.API.Extensions;
#region line:BFB.AWSS3Light.Messaging.Kafka
#endregion
#region line:BFB.AWSS3Light.RemoteAccess.RestApi
#endregion
#region line:BFB.AWSS3Light.Cache.Redis
#endregion
using BFB.AWSS3Light.Http;
using BFB.AWSS3Light.Security.JWT;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.OpenApi.Models;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Globalization;
using BFB.AWSS3Light.API.Attributes;
using System.IO.Compression;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Server.Kestrel.Core;
using Microsoft.AspNetCore.ResponseCompression;
using Serilog;
using Serilog.Events;
using Serilog.Formatting.Elasticsearch;

// Health check extension imports

// Fix DB2 culture issue
CultureInfo.DefaultThreadCurrentCulture = CultureInfo.InvariantCulture;
CultureInfo.DefaultThreadCurrentUICulture = CultureInfo.InvariantCulture;

// Configure Serilog
Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(new ConfigurationBuilder()
        .SetBasePath(Directory.GetCurrentDirectory())
        .AddJsonFile("appsettings.json")
        .AddJsonFile($"appsettings.{Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production"}.json", optional: true)
        .AddEnvironmentVariables()
        .Build())
    .CreateLogger();

try
{
    Log.Information("Starting BFB AWSS3Light API application");

    var builder = WebApplication.CreateBuilder(args);

    // Use Serilog for logging
    builder.Host.UseSerilog();

    // .NET 9 Performance Optimizations
    builder.Services.Configure<KestrelServerOptions>(options =>
    {
        // Enable HTTP/2 and HTTP/3 support for better performance
        options.ConfigureEndpointDefaults(listenOptions =>
        {
            listenOptions.Protocols = HttpProtocols.Http1AndHttp2AndHttp3;
        });
        
        // Optimize connection limits
        options.Limits.MaxConcurrentConnections = 1000;
        options.Limits.MaxConcurrentUpgradedConnections = 1000;
        options.Limits.MaxRequestBodySize = 30_000_000; // 30MB
        options.Limits.RequestHeadersTimeout = TimeSpan.FromSeconds(30);
    });

    // Configure JSON serialization for performance
    builder.Services.ConfigureHttpJsonOptions(options =>
    {
        options.SerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
        options.SerializerOptions.WriteIndented = false; // Compact JSON for better performance
        options.SerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
    });

    // Configure response compression for better network performance
    builder.Services.AddResponseCompression(options =>
    {
        options.EnableForHttps = true;
        options.Providers.Add<BrotliCompressionProvider>();
        options.Providers.Add<GzipCompressionProvider>();
    });

    builder.Services.Configure<BrotliCompressionProviderOptions>(options =>
    {
        options.Level = CompressionLevel.Optimal;
    });

    builder.Services.Configure<GzipCompressionProviderOptions>(options =>
    {
        options.Level = CompressionLevel.SmallestSize;
    });

// Add services to the container.
builder.Services.AddControllers();

// Configure model validation behavior
builder.Services.Configure<ApiBehaviorOptions>(options =>
{
    // Customize validation error response
    options.InvalidModelStateResponseFactory = context =>
    {
        var errors = context.ModelState
            .Where(x => x.Value?.Errors.Count > 0)
            .SelectMany(x => x.Value?.Errors ?? [])
            .Select(x => x.ErrorMessage ?? "Unknown validation error");

        var errorResponse = new
        {
            Message = "Validation failed",
            Errors = errors
        };

        return new BadRequestObjectResult(errorResponse);
    };
});

// Add MongoDB data access services
#region line:BFB.AWSS3Light.DataAccess.MongoDB
#endregion

// Add DB2 data access services  
#region line:BFB.AWSS3Light.DataAccess.DB2
#endregion

// Add SQL Server data access services
#region line:BFB.AWSS3Light.DataAccess.SqlServer
#endregion

// Add Oracle data access services
#region line:BFB.AWSS3Light.DataAccess.Oracle
#endregion

// Add Redis cache services
#region line:BFB.AWSS3Light.Cache.Redis
#endregion

// Add JWT validation services
builder.Services.Configure<JwtConfiguration>(builder.Configuration.GetSection("JWT"));
builder.Services.AddJwtValidation();

// Add JWT Authentication
var jwtConfig = builder.Configuration.GetSection("JWT").Get<JwtConfiguration>();
var key = File.ReadAllBytes(jwtConfig.CertificateFileName);
builder.Services.AddAuthentication("Bearer")
    .AddJwtBearer("Bearer", options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = false,
            ValidateAudience = false,
            ValidateLifetime = true,
            IssuerSigningKey = new SymmetricSecurityKey(key)
        };
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var token = context.Token;
                if (!string.IsNullOrEmpty(token) && token.StartsWith('"') && token.EndsWith('"'))
                {
                    context.Token = token.Trim('"');
                }
                return Task.CompletedTask;
            }
        };
    });

builder.Services.AddAuthorization();

// Add all business services
builder.Services.AddAllBusinessServices();



// Add FIBI context for request tracking
builder.Services.AddScoped<FIBIContext>();

// Add REST API remote access services
#region line:BFB.AWSS3Light.RemoteAccess.RestApi
#endregion

// Add Kafka messaging services
#region line:BFB.AWSS3Light.Messaging.Kafka
#endregion

// Add standardized health checks for all infrastructure modules
#region line:BFB.AWSS3Light.DataAccess.SqlServer
#endregion
#region line:BFB.AWSS3Light.DataAccess.DB2
#endregion
#region line:BFB.AWSS3Light.DataAccess.Oracle
#endregion
#region line:BFB.AWSS3Light.DataAccess.MongoDB
#endregion
#region line:BFB.AWSS3Light.Cache.Redis
#endregion
#region line:BFB.AWSS3Light.Messaging.Kafka
#endregion
#region line:BFB.AWSS3Light.RemoteAccess.RestApi
#endregion 
     

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
// builder.Services.AddOpenApi(); // .NET 9 specific - removed for .NET 8 compatibility

// Add Swagger services
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Title = "BFB AWSS3Light API",
        Version = "v1",
        Description = "Backend For Business Template REST API with comprehensive credit card services, business logic enhancement, and external service integration."
    });
    
    // Add x-fibi-transaction-id header parameter
    c.AddSecurityDefinition("TransactionId", new OpenApiSecurityScheme
    {
        Description = "FIBI Transaction ID (auto-generated in Development)",
        Name = "x-fibi-transaction-id",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey
    });
    
    // Add JWT Bearer authorization
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "Enter JWT token (Bearer will be added automatically)",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT"
    });
    
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "TransactionId"
                }
            },
            Array.Empty<string>()
        },
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
    
    // Hide development-only controllers in non-development environments
    c.DocumentFilter<DevelopmentOnlyDocumentFilter>();
    
    // Include XML comments for better documentation
    var xmlFile = $"{System.Reflection.Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    if (File.Exists(xmlPath))
    {
        c.IncludeXmlComments(xmlPath);
    }
});

var app = builder.Build();

// Add Serilog request logging
app.UseSerilogRequestLogging(options =>
{
    // Customize the message template
    options.MessageTemplate = "Handled {RequestMethod} {RequestPath} responded {StatusCode} in {Elapsed:0.0000} ms";
    
    // Emit debug-level events instead of the defaults
    options.GetLevel = (httpContext, elapsed, ex) => ex != null
        ? LogEventLevel.Error 
        : httpContext.Response.StatusCode > 499 
            ? LogEventLevel.Error 
            : LogEventLevel.Information;
    
    // Attach additional properties to the request completion event
    options.EnrichDiagnosticContext = (diagnosticContext, httpContext) =>
    {
        diagnosticContext.Set("RequestHost", httpContext.Request.Host.Value);
        diagnosticContext.Set("RequestScheme", httpContext.Request.Scheme);
        diagnosticContext.Set("UserAgent", httpContext.Request.Headers["User-Agent"]);
        if (httpContext.User.Identity?.IsAuthenticated == true)
        {
            diagnosticContext.Set("UserName", httpContext.User.Identity.Name);
        }
    };
});

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    // app.MapOpenApi(); // .NET 9 specific - removed for .NET 8 compatibility
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "BFB AWSS3Light API v1");
        c.RoutePrefix = "swagger";
    });
}

app.UseHttpsRedirection();

// Add authentication and authorization
app.UseAuthentication();
app.UseAuthorization();

// Add transaction ID validation middleware
app.UseMiddleware<BFB.AWSS3Light.API.Middleware.TransactionIdMiddleware>();

// Add FIBIContext middleware to automatically populate context from request headers
app.UseFIBIContext();

// Enable response compression for better performance
app.UseResponseCompression();

// Map health check endpoints
app.MapHealthChecks("/health", new HealthCheckOptions
{
    ResponseWriter = async (context, report) =>
    {
        context.Response.ContentType = "application/json";
        var response = new
        {
            Status = report.Status.ToString(),
            Duration = report.TotalDuration,
            Checks = report.Entries.Select(x => new
            {
                Name = x.Key,
                Status = x.Value.Status.ToString(),
                Duration = x.Value.Duration,
                Description = x.Value.Description
            })
        };
        await context.Response.WriteAsync(System.Text.Json.JsonSerializer.Serialize(response));
    }
});

// Simple health check endpoint
app.MapHealthChecks("/health/ready");

// Map controllers
app.MapControllers();

app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Application terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}
