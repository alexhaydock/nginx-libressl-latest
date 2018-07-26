# Most of the below is based on the Nginx Team's Alpine Dockerfile
#   https://github.com/nginxinc/docker-nginx/blob/e3e35236b2c77e02266955c875b74bdbceb79c44/mainline/alpine/Dockerfile

# --- Build Container --- #
FROM alpine:3.8 as builder

# LibreSSL Version (See: https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/)
ARG LIBRESSL_VERSION=2.7.4
ARG LIBRESSL_GPG=663AF51BD5E4D8D5

# Nginx Version (See: https://nginx.org/en/CHANGES)
ARG NGINX_VERSION=1.15.2
ARG NGINX_GPG=B0F4253373F8F6F510D42178520A9993A1C052F8

# Nginx build config
ARG CONFIG="\
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/usr/lib/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --user=nginx \
    --group=nginx \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_stub_status_module \
    --with-http_auth_request_module \
    --with-http_xslt_module=dynamic \
    --with-http_image_filter_module=dynamic \
    --with-http_geoip_module=dynamic \
    --with-threads \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-stream_realip_module \
    --with-stream_geoip_module=dynamic \
    --with-http_slice_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-compat \
    --with-file-aio \
    --with-http_v2_module \
    --with-openssl=/usr/src/libressl \
    --add-module=/usr/src/modules/ngx_headers_more \
    --add-module=/usr/src/modules/ngx_subs_filter \
    --add-module=/usr/src/modules/ngx_brotli \
"

# Download LibreSSL dependencies
# (We don't build LibreSSL independently but just download it and feed it to the Nginx
# build process by using the --with-openssl flag in the configure options.)
RUN set -xe \
    && apk add --no-cache curl git gnupg \
    \
# Download LibreSSL source
    && curl -fSL https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-$LIBRESSL_VERSION.tar.gz -o libressl.tar.gz \
    && curl -fSL https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-$LIBRESSL_VERSION.tar.gz.asc -o libressl.tar.gz.asc \
    \
# Verify LibreSSL source with GPG
    && export GNUPGHOME="$(mktemp -d)" \
    && found=''; \
    for server in \
        ha.pool.sks-keyservers.net \
        hkp://keyserver.ubuntu.com:80 \
        hkp://p80.pool.sks-keyservers.net:80 \
        pgp.mit.edu \
    ; do \
        echo "Fetching GPG key $LIBRESSL_GPG from $server"; \
        gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$LIBRESSL_GPG" && found=yes && break; \
    done; \
    test -z "$found" && echo >&2 "error: failed to fetch GPG key $LIBRESSL_GPG" && exit 1; \
    gpg --batch --verify libressl.tar.gz.asc libressl.tar.gz \
    && rm -rf "$GNUPGHOME" libressl.tar.gz.asc \
    \
# Extract LibreSSL source
    && mkdir -p /usr/src \
    && tar -zxC /usr/src -f libressl.tar.gz \
    && mv -v /usr/src/libressl-$LIBRESSL_VERSION /usr/src/libressl \
    && rm libressl.tar.gz \
    \
# Download additional Nginx modules (for each of these we need to include an --add-module line in the Nginx configuration step)
    && mkdir -p /usr/src/modules \
    && git clone --depth 1 https://github.com/openresty/headers-more-nginx-module.git /usr/src/modules/ngx_headers_more \
    && git clone --depth 1 https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git /usr/src/modules/ngx_subs_filter \
    && git clone --depth 1 https://github.com/google/ngx_brotli.git /usr/src/modules/ngx_brotli \
    && cd /usr/src/modules/ngx_brotli && git submodule update --init \
    \
# Download and prepare Nginx
    && cd /usr/src \
    && addgroup -S nginx \
    && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
    && apk add --no-cache --virtual .build-deps \
        gcc \
        libc-dev \
        make \
        pcre-dev \
        zlib-dev \
        linux-headers \
        curl \
        gnupg \
        libxslt-dev \
        gd-dev \
        geoip-dev \
    && curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
    && curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc  -o nginx.tar.gz.asc \
    && export GNUPGHOME="$(mktemp -d)" \
    && found=''; \
    for server in \
        ha.pool.sks-keyservers.net \
        hkp://keyserver.ubuntu.com:80 \
        hkp://p80.pool.sks-keyservers.net:80 \
        pgp.mit.edu \
    ; do \
        echo "Fetching GPG key $NGINX_GPG from $server"; \
        gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$NGINX_GPG" && found=yes && break; \
    done; \
    test -z "$found" && echo >&2 "error: failed to fetch GPG key $NGINX_GPG" && exit 1; \
    gpg --batch --verify nginx.tar.gz.asc nginx.tar.gz \
    && rm -rf "$GNUPGHOME" nginx.tar.gz.asc \
    && mkdir -p /usr/src \
    && tar -zxC /usr/src -f nginx.tar.gz \
    && rm nginx.tar.gz \
    && mv -v /usr/src/nginx-$NGINX_VERSION /usr/src/nginx

# Build debug bits
RUN cd /usr/src/nginx \
    && ./configure $CONFIG --with-debug \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && mv objs/nginx objs/nginx-debug \
    && mv objs/ngx_http_xslt_filter_module.so objs/ngx_http_xslt_filter_module-debug.so \
    && mv objs/ngx_http_image_filter_module.so objs/ngx_http_image_filter_module-debug.so \
    && mv objs/ngx_http_geoip_module.so objs/ngx_http_geoip_module-debug.so \
    && mv objs/ngx_stream_geoip_module.so objs/ngx_stream_geoip_module-debug.so

# Build main bits
RUN cd /usr/src/nginx \
    && ./configure $CONFIG \
    && make -j$(getconf _NPROCESSORS_ONLN)


# --- Runtime Container --- #
FROM alpine:3.8
LABEL maintainer "Alex Haydock <alex@alexhaydock.co.uk>"

COPY --from=builder /usr/src/nginx /usr/src/nginx
COPY --from=builder /usr/src/modules /usr/src/modules
COPY --from=builder /usr/src/libressl/.openssl /usr/src/libressl/.openssl

RUN set -xe \
    \
# Re-add the Nginx user
    && addgroup -S nginx \
    && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
	\
# Add some more deps to install Nginx
    && apk add --no-cache --virtual .installdeps binutils make \
    \
# Install Nginx
    && cd /usr/src/nginx \
    && make install \
    && rm -rf /etc/nginx/html/ \
    && mkdir /etc/nginx/conf.d/ \
    && mkdir -p /usr/share/nginx/html/ \
    && install -m644 html/index.html /usr/share/nginx/html/ \
    && install -m644 html/50x.html /usr/share/nginx/html/ \
    && install -m755 objs/nginx-debug /usr/sbin/nginx-debug \
    && install -m755 objs/ngx_http_xslt_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_xslt_filter_module-debug.so \
    && install -m755 objs/ngx_http_image_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_image_filter_module-debug.so \
    && install -m755 objs/ngx_http_geoip_module-debug.so /usr/lib/nginx/modules/ngx_http_geoip_module-debug.so \
    && install -m755 objs/ngx_stream_geoip_module-debug.so /usr/lib/nginx/modules/ngx_stream_geoip_module-debug.so \
    && ln -s ../../usr/lib/nginx/modules /etc/nginx/modules \
    && strip /usr/sbin/nginx* \
    && strip /usr/lib/nginx/modules/*.so \
    \
# Bring in gettext so we can get `envsubst`, then throw
# the rest away. To do this, we need to install `gettext`
# then move `envsubst` out of the way so `gettext` can
# be deleted completely, then move `envsubst` back.
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /tmp/ \
    \
# Work out our runtime dependencies
    && runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )" \
# Install the runtime dependencies as virtual metapackage called ".nginx-rundeps"
    && apk add --no-cache --virtual .nginx-rundeps $runDeps \
    \
# Bring in tzdata so users can set the timezone through environment variables
    && apk add --no-cache tzdata \
    \
# Forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    \
# Remove our virtual metapackages
    && apk del .installdeps .gettext \
    && mv /tmp/envsubst /usr/local/bin/ \
    \
# Delete source files to save space in final image
    && rm -rf /usr/src/* \
    \
# Print built version (for debug purposes)
    && echo "" && nginx -V

# Add the default Nginx config files
# (these are taken directly from the Nginx team's Docker repo without modification)
COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx.vh.default.conf /etc/nginx/conf.d/default.conf

# Runtime settings
EXPOSE 80
STOPSIGNAL SIGTERM
CMD ["nginx", "-g", "daemon off;"]

