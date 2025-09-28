namespace BFB.AWSS3Light.Abstractions.Models;

public class HttpClientConfiguration
{
    public string BaseUrl { get; set; } = string.Empty;
    public int TimeoutSeconds { get; set; } = 30;
    public Dictionary<string, string>? DefaultHeaders { get; set; }
}