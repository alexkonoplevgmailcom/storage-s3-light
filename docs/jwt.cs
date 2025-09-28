using Microsoft.IdentityModel.Tokens;

using System.IdentityModel.Tokens.Jwt;

using System.Security.Claims;

using System.Text;

 

namespace BFB.JWTReverseProxySidecar.Api

{

    internal class JWTService

    {

        IConfiguration _config;

        private byte[] key;

 

        public JWTService(IConfiguration config)

        {

            this._config = config;

            var certificateFileName = _config["JWT:CertificateFileName"];

            key =  ReadKeyFromCertificateFile(certificateFileName);

        }

        internal async Task<ClaimsPrincipal> ValidateJwt(string token)

        {

            var validationParameters = new TokenValidationParameters

            {

 

                ValidateIssuer = false,

                ValidateAudience = false,

                ValidateLifetime = true,

                IssuerSigningKey = new SymmetricSecurityKey(key)

            };

 

            var handler = new JwtSecurityTokenHandler();

            try

            {

                return handler.ValidateToken(token, validationParameters, out _);

 

            }

            catch

            {

                return null;

            }

        }

 

        internal string CreateNewJwt(ClaimsPrincipal principal, string nextAudience)

        {

            var handler = new JwtSecurityTokenHandler();

            var securityKey = new SymmetricSecurityKey(key);

            var signingCredentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            var newClaims = ReplaceClaims(principal, nextAudience);

            var tokenDescriptor = new SecurityTokenDescriptor

            {

                Subject = new ClaimsIdentity(newClaims),

                Expires = DateTime.UtcNow.AddMinutes(30),

                SigningCredentials = signingCredentials

            };

 

            var token = handler.CreateToken(tokenDescriptor);

            return handler.WriteToken(token);

        }

        private byte[] ReadKeyFromCertificateFile(string certificateFileName)

        {

            if (!File.Exists(certificateFileName))

                throw new IOException($"Unable to load certificte from {certificateFileName}");

 

            using (var fileStream = File.OpenRead(certificateFileName))

            {

                var retval = new byte[(int)fileStream.Length];

                fileStream.Read(retval, 0, (int)fileStream.Length);

                fileStream.Close();

                if (null == retval || Encoding.UTF8.GetString(retval).Contains('\r'))

                    throw new InvalidDataException($"Token file is invalide. Please check its exists and in Unix format ('LF')");

                return retval;

            }

        }

        private List<Claim> ReplaceClaims(ClaimsPrincipal principal, string nextAudience)

        {

            var claims = principal.Claims.Where(c =>

                c.Type != JwtRegisteredClaimNames.Aud &&

                c.Type != JwtRegisteredClaimNames.Iss &&

                c.Type != JwtRegisteredClaimNames.Nbf &&

                c.Type != JwtRegisteredClaimNames.Exp &&

                c.Type != JwtRegisteredClaimNames.Iat).ToList();

 

            var newIssuer = principal.Claims.SingleOrDefault(c => c.Type == JwtRegisteredClaimNames.Aud)?.Value;//!!!!! This is not mistake !!!!! Setting current service as an Issuer of JWT for the next request

            claims.Add(new Claim(JwtRegisteredClaimNames.Aud, nextAudience));

            claims.Add(new Claim(JwtRegisteredClaimNames.Iss, newIssuer));

            claims.Add(new Claim(JwtRegisteredClaimNames.Nbf, DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString()));

            claims.Add(new Claim(JwtRegisteredClaimNames.Exp, DateTimeOffset.UtcNow.AddMinutes(30).ToUnixTimeSeconds().ToString()));

            claims.Add(new Claim(JwtRegisteredClaimNames.Iat, DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString()));

            return claims;

        }

 

    }

}

 