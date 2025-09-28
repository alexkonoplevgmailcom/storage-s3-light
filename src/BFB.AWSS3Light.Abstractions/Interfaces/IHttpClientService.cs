using BFB.AWSS3Light.Abstractions.Models;

namespace BFB.AWSS3Light.Abstractions.Interfaces;

public interface IHttpClientService
{
    HttpClient CreateClient(string clientName, FibiHttpRequestOptions? options = null);
}