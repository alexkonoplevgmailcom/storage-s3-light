using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;
using System.Reflection;
using BFB.AWSS3Light.API.Attributes;

namespace BFB.AWSS3Light.API.Attributes;

public class DevelopmentOnlyDocumentFilter : IDocumentFilter
{
    private readonly IWebHostEnvironment _environment;

    public DevelopmentOnlyDocumentFilter(IWebHostEnvironment environment)
    {
        _environment = environment;
    }

    public void Apply(OpenApiDocument swaggerDoc, DocumentFilterContext context)
    {
        if (_environment.IsDevelopment()) return;

        var pathsToRemove = new List<string>();

        foreach (var apiDescription in context.ApiDescriptions)
        {
            var controllerType = apiDescription.ActionDescriptor.EndpointMetadata
                .OfType<Microsoft.AspNetCore.Mvc.Controllers.ControllerActionDescriptor>()
                .FirstOrDefault()?.ControllerTypeInfo;

            if (controllerType?.GetCustomAttribute<DevelopmentOnlyAttribute>() != null)
            {
                var path = "/" + apiDescription.RelativePath;
                pathsToRemove.Add(path);
            }
        }

        foreach (var path in pathsToRemove.Distinct())
        {
            swaggerDoc.Paths.Remove(path);
        }
    }
}