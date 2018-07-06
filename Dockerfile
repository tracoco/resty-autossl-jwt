FROM openresty/openresty:alpine-fat

RUN apk add --no-cache --virtual .run-deps \
    bash \
    curl \
    diffutils \
    grep \
    sed \
    openssl \
    && mkdir -p /etc/resty-auto-ssl \
    && addgroup -S nginx \
    && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
    && chown -R nginx /etc/resty-auto-ssl /usr/local/openresty/ 

RUN apk add --no-cache --virtual .build-deps \
        gcc \
        libc-dev \
        make \
        openssl-dev \
        pcre-dev \
        zlib-dev \
        linux-headers \
        gnupg \
        libxslt-dev \
        gd-dev \
        geoip-dev \
        perl-dev \
        tar \
        unzip \
        zip \
        unzip \
        g++ \
        cmake \
        lua \
        lua-dev \
        make \
        autoconf \
        automake \
        libcap \
    && setcap 'cap_net_bind_service=+ep' /usr/local/openresty/nginx/sbin/nginx \
    && /usr/local/openresty/luajit/bin/luarocks install lua-resty-auto-ssl \
    && /usr/local/openresty/luajit/bin/luarocks install lua-resty-jwt \
    && apk del .build-deps \
    && rm -rf /usr/local/openresty/nginx/conf/* \
    && mkdir -p /var/cache/nginx 

COPY ./autossl /etc/autossl
COPY ./nginx /etc/nginx
RUN chown -R nginx /etc/nginx /etc/autossl
USER nginx
ENTRYPOINT ["/usr/local/openresty/bin/openresty", "-g", "daemon off;", "-c", "/etc/nginx/nginx.conf"]
