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
local jwt_obj = jwt:verify(os.getenv("JWT_SECRET"), token, claim_spec)
-- local public_key = "-----BEGIN CERTIFICATE-----\nMIIDHDCCAgSgAwIBAgIIe2BPje0Dj0wwDQYJKoZIhvcNAQEFBQAwMTEvMC0GA1UE\nAxMmc2VjdXJldG9rZW4uc3lzdGVtLmdzZXJ2aWNlYWNjb3VudC5jb20wHhcNMTgw\nNjI2MjEyMDE1WhcNMTgwNzEzMDkzNTE1WjAxMS8wLQYDVQQDEyZzZWN1cmV0b2tl\nbi5zeXN0ZW0uZ3NlcnZpY2VhY2NvdW50LmNvbTCCASIwDQYJKoZIhvcNAQEBBQAD\nggEPADCCAQoCggEBAKNRgCGiQWHMgMt3LuPY8DkusyZ7BZNdo0zmZCeuLgmS63uL\n5qZn9x8nVvz6TMnGI+3Vcw7G0cL0ePyG3NAI8WXElearxcq0yhY2sFcIRgksJhAA\ncRFz2JCPns4daxVJ+9UMYKgNdanqe+Ud9Ui8rMhXHmie1c/Mvn4mKXx6rI6XQi3H\nesnMIP76143UHOp7GvvEIoWGbt1mmQoVz3vARt7P4pUafF78Q1OQxD0/3I+HKHHa\nvMM/+LwNaoGzXwAtR9yQEGySL5rsj7ctzrqfYEvlJYf06t9ty32XVLR9ZppdRD5e\nIX5SK/ccTuS+nFbp3Pc9SatU/CdGR1C5enLetacCAwEAAaM4MDYwDAYDVR0TAQH/\nBAIwADAOBgNVHQ8BAf8EBAMCB4AwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwIwDQYJ\nKoZIhvcNAQEFBQADggEBAGWfb8Gt2GnGFiK9BdKpN+gN7HZjEH1gY2KAa63P1+cd\n74pc9UD0PoGr98L1aQ4Jb3bckZtBM+k286XRLpLRKYmBUhQ7vVqEk5/mrQ1BZ8+C\nKmCf52dHg9uwOPm33PejpBXBydrZIOAoTY+LcBnl1WeyLoxF8xwYqX978kURm9Ua\nNzKEfs7ZqxBKV3SqeVGDd/14hLjRzlNOlmLwKuItC5e9kmKvHUdyaToRSXm0/5cg\n+I6RQxM6vl3vzSurEj8TXVLM0cO41i9mDgOSv807COBU9pY5/6ziHEYeYcBx4PXg\n4HuYlfgTS2HEEHnmry7Rej+F47W4h31PNuHw+jKmHsU=\n-----END CERTIFICATE-----\n"
-- local jwt_obj = jwt:verify(public_key, token, claim_spec)
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
