# alexhaydock/nginx-openssl-latest

[![](https://images.microbadger.com/badges/image/alexhaydock/nginx-openssl-latest.svg)](https://microbadger.com/images/alexhaydock/nginx-openssl-latest "Get your own image badge on microbadger.com")

This container builds the [latest mainline Nginx](https://nginx.org/en/CHANGES) with the [latest OpenSSL release](https://www.openssl.org/source/). It was created to aid with the easy deployment of TLS 1.3 services at a time when most Linux distributions were not packaging a version of OpenSSL that could handle it.

Run this container as a quick test (you will see logs directly in the terminal when connections are made):
```
docker run --rm -it -p 80:80 alexhaydock/nginx-openssl-latest
```

Run this container as a daemon with your own config file:
```
docker run -d -p 80:80 -p 443:443 -v /path/to/nginx.conf:/etc/nginx.conf:ro --name nginx alexhaydock/nginx-openssl-latest
```