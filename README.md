# cURL healthchecker [![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/eexit/curl-healthchecker?style=flat-square)](https://hub.docker.com/repository/docker/eexit/curl-healthchecker)

Latelely, I'm trying to set-up `HEALTHCHECK` to my Docker images and since I have many Go projects that run from scratch, I needed to find a way to test the health of my Go APIs.

At first, I tried to compile and build a binary like this:

```go
package main

import (
	"net/http"
	"os"
)

func main() {
	code := 0
	resp, err := http.Head("http://localhost/healthcheck")
	if err != nil || resp.StatusCode != http.StatusOK || resp.StatusCode != http.StatusNoContent {
		code = 1
	}
	os.Exit(code)
}
```

But even after compression (using [upx](https://upx.github.io/)), the binary is still 3.3M. Still too much for what it is.

After some digging and testing, I managed to build my own cURL binary with the bare mininum to handle a basic HTTP healthcheck request:

```bash
$ docker run --rm eexit/curl-healthchecker:v1.0.0 -V
curl 7.77.0 (x86_64-pc-linux-musl) libcurl/7.77.0
Release-Date: 2021-05-26
Protocols: http
Features: Largefile
```

The binary size is 194K, which is pretty slim.

## Usage

You only need to add 3 lines in your Dockerfile:

```dockerfile
FROM eexit/curl-healthchecker:v1.0.0 AS curl
# Other stages...

FROM scratch
COPY --from=curl /curl /
# Copy from other stages...

# Supposed your healthcheck endpoint is http://127.0.0.1/healthcheck
HEALTHCHECK --interval=5s --timeout=2s --retries=3 \
    CMD ["/curl", "-fIA", "cURL healthcheck", "http://127.0.0.1/healthcheck"]
```

Once you've up'd your container, the  health status is shown in the `docker ps` output:

```
CONTAINER ID   IMAGE                           COMMAND                  CREATED          STATUS                    PORTS                                                                                  NAMES
f6429b2318d3   eexit/http2smtp                 "/http2smtp"             29 seconds ago   Up 26 seconds (healthy)   80/tcp, 0.0.0.0:80->8080/tcp, :::80->8080/tcp                                          http2smtp_http2smtp_1
```

If you wish to troubleshoot:

```bash
docker inspect --format "{{json .State.Health }}" f6429b2318d3 | jq .
{
  "Status": "healthy",
  "FailingStreak": 0,
  "Log": [
    {
      "Start": "2021-05-31T20:34:47.239507658Z",
      "End": "2021-05-31T20:34:47.328378157Z",
      "ExitCode": 0,
      "Output": "  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current\n                                 Dload  Upload   Total   Spent    Left  Speed\n\r  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0\r  0    25    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0\nHTTP/1.1 200 OK\r\nContent-Type: application/json\r\nDate: Mon, 31 May 2021 20:34:47 GMT\r\nContent-Length: 25\r\n\r\n"
    }
  ]
}
```



---

Inspired from:

- https://medium.com/axiomzenteam/combining-docker-multi-stage-builds-and-health-checks-feea7cd2d85e
- https://github.com/hectorm/docker-curl
- https://github.com/moparisthebest/static-curl
- https://github.com/dtschan/curl-static
- https://github.com/curl/curl

