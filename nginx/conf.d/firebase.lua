local jwt = require "resty.jwt"

-- first try to find JWT token as url parameter e.g. ?token=BLAH
local token = ngx.var.arg_token

-- next try to find JWT token as Cookie e.g. token=BLAH
if token == nil then
  token = ngx.var.cookie_token
end

-- try to find JWT token in Authorization header Bearer string
if token == nil then
  local auth_header = ngx.var.http_Authorization
  if auth_header then
    _, _, token = string.find(auth_header, "Bearer%s+(.+)")
  end
end

-- finally, if still no JWT token, kick out an error and exit
if token == nil then
  ngx.status = ngx.HTTP_UNAUTHORIZED
  ngx.header.content_type = "application/json; charset=utf-8"
  ngx.say("{error: \"missing JWT token or Authorization header\"}")
  ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

-- firebase keys
local function fbkey(kid)
  if kid == "0096ad6ff7c12037931b0c4c98aa83e6fad93e0a" then
    return "-----BEGIN CERTIFICATE-----\nMIIDHDCCAgSgAwIBAgIIe2BPje0Dj0wwDQYJKoZIhvcNAQEFBQAwMTEvMC0GA1UE\nAxMmc2VjdXJldG9rZW4uc3lzdGVtLmdzZXJ2aWNlYWNjb3VudC5jb20wHhcNMTgw\nNjI2MjEyMDE1WhcNMTgwNzEzMDkzNTE1WjAxMS8wLQYDVQQDEyZzZWN1cmV0b2tl\nbi5zeXN0ZW0uZ3NlcnZpY2VhY2NvdW50LmNvbTCCASIwDQYJKoZIhvcNAQEBBQAD\nggEPADCCAQoCggEBAKNRgCGiQWHMgMt3LuPY8DkusyZ7BZNdo0zmZCeuLgmS63uL\n5qZn9x8nVvz6TMnGI+3Vcw7G0cL0ePyG3NAI8WXElearxcq0yhY2sFcIRgksJhAA\ncRFz2JCPns4daxVJ+9UMYKgNdanqe+Ud9Ui8rMhXHmie1c/Mvn4mKXx6rI6XQi3H\nesnMIP76143UHOp7GvvEIoWGbt1mmQoVz3vARt7P4pUafF78Q1OQxD0/3I+HKHHa\nvMM/+LwNaoGzXwAtR9yQEGySL5rsj7ctzrqfYEvlJYf06t9ty32XVLR9ZppdRD5e\nIX5SK/ccTuS+nFbp3Pc9SatU/CdGR1C5enLetacCAwEAAaM4MDYwDAYDVR0TAQH/\nBAIwADAOBgNVHQ8BAf8EBAMCB4AwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwIwDQYJ\nKoZIhvcNAQEFBQADggEBAGWfb8Gt2GnGFiK9BdKpN+gN7HZjEH1gY2KAa63P1+cd\n74pc9UD0PoGr98L1aQ4Jb3bckZtBM+k286XRLpLRKYmBUhQ7vVqEk5/mrQ1BZ8+C\nKmCf52dHg9uwOPm33PejpBXBydrZIOAoTY+LcBnl1WeyLoxF8xwYqX978kURm9Ua\nNzKEfs7ZqxBKV3SqeVGDd/14hLjRzlNOlmLwKuItC5e9kmKvHUdyaToRSXm0/5cg\n+I6RQxM6vl3vzSurEj8TXVLM0cO41i9mDgOSv807COBU9pY5/6ziHEYeYcBx4PXg\n4HuYlfgTS2HEEHnmry7Rej+F47W4h31PNuHw+jKmHsU=\n-----END CERTIFICATE-----\n"
  end
  if kid == "958a44fa58fdedd15a15bc03958394ec00497cc0" then
    return "-----BEGIN CERTIFICATE-----\nMIIDHDCCAgSgAwIBAgIIOY6dSWz3XVkwDQYJKoZIhvcNAQEFBQAwMTEvMC0GA1UE\nAxMmc2VjdXJldG9rZW4uc3lzdGVtLmdzZXJ2aWNlYWNjb3VudC5jb20wHhcNMTgw\nNzA0MjEyMDE1WhcNMTgwNzIxMDkzNTE1WjAxMS8wLQYDVQQDEyZzZWN1cmV0b2tl\nbi5zeXN0ZW0uZ3NlcnZpY2VhY2NvdW50LmNvbTCCASIwDQYJKoZIhvcNAQEBBQAD\nggEPADCCAQoCggEBAJpI8JYGWg9aEOW4KYznkam+lkwoRiNtl11e84mQfjk7xCsw\nJNL33InMP0J9d8k5deWLLbus8t0BPrv5Nemtxs9ZJmzxqnbgx0u1QBfyVzMNSdht\n0USqiE/6tyiD5H+2gzmWXz7Qy76bsCKpBthIvbi0ppdgVxV20XwHz6iTy07/X83m\nZZSMaqGbge+Jla8X3lPUjmi+EUzA93BOVylNA5wYKdUO+hARC3X2n1/NlsAL0GYC\nfs/B7IjXQQhGncQjM6NQI+uRxLzl/nhmmiReWULHBqfAsXSewZ1wax8g/Yc+CiVd\naEibJ9IuD307F+kxrpQIRjghYJ7iy0Ld0fzeqmkCAwEAAaM4MDYwDAYDVR0TAQH/\nBAIwADAOBgNVHQ8BAf8EBAMCB4AwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwIwDQYJ\nKoZIhvcNAQEFBQADggEBAC/VdgCckc1iBDi0r5qtp52rSMZuymhpvVYtsty9lp+S\ns8TwLiG3qVE78r/wyFjx92GG6F2lulY+5Yz4rhX+IzlrHzEjnGK69kCszSrzLJBZ\nh0v6UyjvIRsjoLsp19XfNNg7C9GNGEvploZ0551TxuBWSRyMRkpxlX7fFm8r7eD6\n5dvDlbnMnEymcLSWcE+JLTVefzHqRV8kyRsrJS6XcV8d9IYspKw5ksmMuCx5y7+s\ngC0M1v7e0ZM/4yce3yDVma8TYHzh30E5vK18hh9MvJeE3dcpp158OV2tT8CMx+wh\nmnSI2lMyfBvM2qWdGw1WfyHTWqhlti7UBjXs31ke+hA=\n-----END CERTIFICATE-----\n"
  end
  if kid == "620846d145c7ec6448592acef30eaba57086c0ae" then
    return "-----BEGIN CERTIFICATE-----\nMIIDHDCCAgSgAwIBAgIITXurtKxmghAwDQYJKoZIhvcNAQEFBQAwMTEvMC0GA1UE\nAxMmc2VjdXJldG9rZW4uc3lzdGVtLmdzZXJ2aWNlYWNjb3VudC5jb20wHhcNMTgw\nNjE4MjEyMDEzWhcNMTgwNzA1MDkzNTEzWjAxMS8wLQYDVQQDEyZzZWN1cmV0b2tl\nbi5zeXN0ZW0uZ3NlcnZpY2VhY2NvdW50LmNvbTCCASIwDQYJKoZIhvcNAQEBBQAD\nggEPADCCAQoCggEBAMGZ0XLyPend8PWd3pBJRbjCgbsoYb9uZNi92hxLDV5nNxB1\nmXQrmUdBucEtARcDae/mxQaRnaM0l/njFtsQ35IabACHUuVOItOO1FD5Ur23o1Fw\nieVTRDH4dDLOI94WVDR7POzR8b6mmhvChuUKqaGJ2R/NskD0d8EHUqWuqfpoKEeZ\nabqr7I6i7iCR8ns7bCUgfLSUQzrPwFjbJ55xxl/RPyIFA4Hyek1XUgbQ781vFeme\nvJujEZSNENAkZA/AVcNej7h5tJfrCeFji28Ygw6dVNiwoE+Xf+EhWKdf+dlZrV+d\ngexlMr0EQD9IamnphWRjxQ8ufrKh79diEPrhb5UCAwEAAaM4MDYwDAYDVR0TAQH/\nBAIwADAOBgNVHQ8BAf8EBAMCB4AwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwIwDQYJ\nKoZIhvcNAQEFBQADggEBAAuie+4asrp03jralnzE6Hi9Gyiq910IOVW9m2x7C47F\nO2kgszKXTvd1CGGfueMl4eYnOtvrp1Aq7jBVVqX7clpqLbqcPcLHjIm8dRvJcgIs\ng3FaIWPutV25tQe5ddEG2yBjKus3Osnwt/j9vh5PW4bRX6/iijuafrXD+65pA+/f\nJ27INjAS0SkJPGHBJU8dnbjvpY0UZ3a3VSBlLPgP/Sm5kBv0zsVg39tvtpWxVItU\n1whYghE3dv7MRs6YwGfywqKM5LqzJ0msJWsdBfIu00cGoQMYxLfLBLoQY6YTdfb4\nD4/A3VaERMpTbzkAu8T31cWMxZZnW6xcwY/09TpK0Z8=\n-----END CERTIFICATE-----\n"
  end
end
-- validate any specific claims you need here
-- https://github.com/SkyLothar/lua-resty-jwt#jwt-validators
local validators = require "resty.jwt-validators"
local claim_spec = {
  -- validators.set_system_leeway(15), -- time in seconds
  -- exp = validators.is_not_expired(),
  -- iat = validators.is_not_before(),
  -- iss = validators.opt_matches("^http[s]?://yourdomain.auth0.com/$"),
  -- sub = validators.opt_matches("^[0-9]+$"),
  -- name = validators.equals_any_of({ "John Doe", "Mallory", "Alice", "Bob" }),
}

-- make sure to set and put "env JWT_SECRET;" in nginx.conf
local kid = jwt_key_dict:get(kid)
local key = fbkey(kid)
local jwt_obj = jwt:verify(key, token, claim_spec)
if not jwt_obj["verified"] then
  ngx.status = ngx.HTTP_UNAUTHORIZED
  ngx.log(ngx.WARN, jwt_obj.reason)
  ngx.header.content_type = "application/json; charset=utf-8"
  ngx.say("{error: \"" .. jwt_obj.reason .. "\"}")
  ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

-- optionally set Authorization header Bearer token style regardless of how token received
-- if you want to forward it by setting your nginx.conf something like:
--     proxy_set_header Authorization $http_authorization;`
ngx.req.set_header("Authorization", "Bearer " .. token)
