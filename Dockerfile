FROM alpine AS builder
ARG curl=7.77.0
LABEL cURL=${curl}
RUN apk add build-base clang upx
RUN wget -c https://curl.haxx.se/download/curl-${curl}.tar.gz -O - | tar xz -C /tmp
WORKDIR /tmp/curl-${curl}
RUN mkdir /dist && \
    CC=clang LDFLAGS="-static" PKG_CONFIG="pkg-config --static" ./configure \
    --disable-alt-svc \
    --disable-crypto-auth \
    --disable-dict \
    --disable-file \
    --disable-ftp \
    --disable-gopher \
    --disable-imap \
    --disable-ipv6 \
    --disable-Largefile \
    --disable-libcurl-option \
    --disable-manual \
    --disable-mqtt \
    --disable-ntlm-wb \
    --disable-pop3 \
    --disable-rtsp \
    --disable-shared \
    --disable-smb \
    --disable-smtp \
    --disable-telnet \
    --disable-threaded-resolver \
    --disable-tftp \
    --disable-tls-srp \
    --disable-unix-sockets \
    --enable-static \
    --prefix=/dist \
    --without-brotli \
    --without-ssl \
    --without-zlib \
    && make -j4 V=1 curl_LDFLAGS=-all-static \
    && make install \
    && strip /dist/bin/curl \
    && upx /dist/bin/curl

FROM scratch
COPY --from=builder /dist/bin/curl /
ENTRYPOINT ["/curl"]
CMD ["--help", "all"]