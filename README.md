#OpenResty with lua-resty-auto-ssl and lua-resty-jwt

Build docker image: 
```
docker build . -t resty-autossl-jwt
```

Create a container from the image using the following command, with some notes:
1. Use host network to avoid issue at high volume.
2. Remember to set the secret for jwt.
3. Provide your own nginx config files, e.g., add -v /yourcfgpath/nginx:/etc/nginx
4. Make sure your 80/443 ports are not occupied.
```
docker run --name resty-autossl-jwt \
          --restart=always \
          --net=host \
           -e JWT_SECRET=testjwt \
           -p 80:80 -p 443:443 -d \
            resty-autossl-jwt

```
To verify jwt with default setting, please issue a http rest with header
```
curl -k --header "Authorization:Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJyZXN0eS1hdXRvc3NsLWp3dCIsImlhdCI6bnVsbCwiZXhwIjpudWxsLCJhdWQiOiJqd3QiLCJzdWIiOiJ0ZXN0In0.G6d_ZKaO3mjZkdc3a41jmRVZF0uuUyfvQl3xZMryrzQ" https://localhost/jwt/
```

