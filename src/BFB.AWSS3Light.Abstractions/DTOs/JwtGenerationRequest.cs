using System.ComponentModel.DataAnnotations;

namespace BFB.AWSS3Light.Abstractions.Models;

public class JwtGenerationRequest
{
    [Required]
    public string PublicKey { get; set; } = string.Empty;

    [Required]
    public string Audience { get; set; } = string.Empty;

    [Required]
    public string Issuer { get; set; } = string.Empty;

    [Required]
    public DateTime Expiration { get; set; }

    public Dictionary<string, object>? Claims { get; set; }
}