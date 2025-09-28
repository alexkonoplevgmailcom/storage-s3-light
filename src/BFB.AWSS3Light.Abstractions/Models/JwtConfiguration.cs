namespace BFB.AWSS3Light.Abstractions.Models;

public class JwtConfiguration
{
    public string CertificateFileName { get; set; } = string.Empty;
    public string Audience { get; set; } = string.Empty;
    public string Issuer { get; set; } = string.Empty;
}