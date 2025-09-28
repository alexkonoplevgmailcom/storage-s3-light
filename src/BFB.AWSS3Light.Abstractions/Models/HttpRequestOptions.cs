namespace BFB.AWSS3Light.Abstractions.Models;

public enum JwtMode
{
    None,
    UseExisting,
    GenerateFresh,
    EnhanceExisting
}

public class FibiHttpRequestOptions
{
    public JwtMode JwtMode { get; set; } = JwtMode.None;
    public Dictionary<string, object>? JwtClaims { get; set; }
    public Dictionary<string, string>? Headers { get; set; }
    public string? ExistingJwt { get; set; }
}