# alexhaydock/nginx-libressl-latest

[![](https://images.microbadger.com/badges/image/alexhaydock/nginx-libressl-latest.svg)](https://microbadger.com/images/alexhaydock/nginx-libressl-latest "Get your own image badge on microbadger.com")

This container builds the [latest mainline Nginx](https://nginx.org/en/CHANGES) with the [latest LibreSSL release](https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/). It was created to aid with the easy deployment of TLS 1.3 services at a time when most Linux distributions were not packaging a version of OpenSSL that could handle it.

There are versions of this container which build against:
* [BoringSSL](https://github.com/alexhaydock/BoringNginx)
* [LibreSSL](https://github.com/alexhaydock/nginx-libressl-latest)
* [OpenSSL](https://github.com/alexhaydock/nginx-openssl-latest)

### Quick Run This Container (Testing on x86_64)
Run this container as a quick test (it will listen on http://127.0.0.1 and you will see logs directly in the terminal when connections are made):
```
docker run --rm -it -p 80:80 alexhaydock/nginx-libressl-latest
```

### Quick Run This Container (Production on x86_64)
Run this container as a daemon with your own config file:
```
docker run -d -p 80:80 -p 443:443 -v /path/to/nginx.conf:/etc/nginx.conf:ro --name nginx alexhaydock/nginx-libressl-latest
```

### Build This Container Locally
If you have a regular install of Docker on an `x64_64` machine, you can build this container like so:
```
docker build --rm -t nginx-libressl-latest https://github.com/alexhaydock/nginx-libressl-latest.git
```

You can now use the run commands from above, simply substituting `alexhaydock/nginx-libressl-latest` with `nginx-libressl-latest`.

### Build This Container (Docker on Raspbian)
If you are running a Raspberry Pi with [Raspbian](https://www.raspberrypi.org/downloads/raspbian/), you will need to be using the version of the Docker daemon distributed by Docker, and not the package from the Raspbian repositories. The version distributed by Raspbian is currently too old to support multi-stage builds, which this image requires.

Then you can use the same build command as above, and the same run commands from above, simply substituting `alexhaydock/nginx-libressl-latest` with `nginx-libressl-latest`.

### Build This Container (Podman)
Podman is Red Hat's answer to Docker, and you may wish to use this particularly if you're using Fedora on a [Raspberry Pi](https://fedoraproject.org/wiki/Architectures/ARM/Raspberry_Pi), as the current version of Docker shipped by Fedora 28 is currently too old to support multi-stage builds, which this image requires.

You may also wish to use this if you are using Silverblue or another of Red Hat's atomic distributions which ship Podman natively.

Clone this repo and build with:
```
Build with:
```
sudo podman build --rm -t nginx-libressl-latest github.com/alexhaydock/nginx-libressl-latest
```

You can now run the container using the same run commands as above, simply substituting `docker` with `podman`, and `alexhaydock/nginx-libressl-latest` with `nginx-libressl-latest`.