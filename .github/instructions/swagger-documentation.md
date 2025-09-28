### API Documentation Requirements

#### Swagger/OpenAPI Implementation
- **MANDATORY**: Implement Swagger/OpenAPI documentation in all WebAPI projects
- **Configure Swagger in Program.cs** using the standard AddSwaggerGen and UseSwagger middleware
- **Enable XML documentation generation** in the project file (.csproj) to integrate code comments with Swagger UI
- **Use proper API versioning** and document each version separately in Swagger

#### API Documentation Configuration
```csharp
// Program.cs Swagger Configuration
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "BFB AWSS3Light API",
        Version = "v1",
        Description = "API for the Backend For Business (BFB) Template application",
        Contact = new OpenApiContact
        {
            Name = "BFB Team"
        }
    });
    
    // Enable XML comments
    var xmlFilename = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
    options.IncludeXmlComments(Path.Combine(AppContext.BaseDirectory, xmlFilename));
});

// Middleware configuration
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "BFB AWSS3Light API v1");
        options.RoutePrefix = "swagger";
    });
}
```

#### Project File Configuration (.csproj)
```xml
<PropertyGroup>
  <GenerateDocumentationFile>true</GenerateDocumentationFile>
  <NoWarn>$(NoWarn);1591</NoWarn>
</PropertyGroup>
```

#### Controller Documentation Requirements
- **ALWAYS add XML documentation** to all controller methods
- **Include ProducesResponseType attributes** for all possible response types
- **Document all possible error responses** (400, 401, 403, 404, 500, etc.)

Example:
```csharp
/// <summary>
/// Gets a bank by its unique identifier
/// </summary>
/// <param name="id">The unique identifier of the bank</param>
/// <returns>The bank information</returns>
/// <response code="200">Returns the bank information</response>
/// <response code="404">If the bank is not found</response>
/// <response code="500">If there was an internal server error</response>
[HttpGet("{id}")]
[ProducesResponseType(typeof(BankDto), StatusCodes.Status200OK)]
[ProducesResponseType(StatusCodes.Status404NotFound)]
[ProducesResponseType(StatusCodes.Status500InternalServerError)]
public async Task<ActionResult<BankDto>> GetBank(Guid id)
{
    // Implementation
}
```

This specification is now considered **MANDATORY** for all WebAPI projects in the BFB template application, ensuring consistent API documentation and improved developer experience.
