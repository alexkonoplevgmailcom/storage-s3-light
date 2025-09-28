using System.ComponentModel.DataAnnotations;

namespace BFB.AWSS3Light.Abstractions.Models;

public class JwtTokenRequest
{
    [Required]
    public string Token { get; set; } = string.Empty;
}