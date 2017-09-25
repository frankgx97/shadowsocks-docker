FROM alpine:3.6

ARG SS_VER=3.1.0
ARG SS_URL=https://github.com/shadowsocks/shadowsocks-libev/releases/download/v$SS_VER/shadowsocks-libev-$SS_VER.tar.gz

RUN set -ex  \
    && echo "http://mirrors.ustc.edu.cn/alpine/v3.6/main/" > /etc/apk/repositories \
    && echo "http://mirrors.ustc.edu.cn/alpine/v3.6/community/" >> /etc/apk/repositories \
    apk add --no-cache --virtual .build-deps \
                                autoconf \
                                build-base \
                                curl \
                                libev-dev \
                                libtool \
                                linux-headers \
                                libsodium-dev \
                                mbedtls-dev \
                                pcre-dev \
                                tar \
                                c-ares-dev \
                                ca-certificates \
                                wget \
                                openssl && \
    update-ca-certificates && \
    cd /tmp && \

    # Installation of Libsodium
    export LIBSODIUM_VER=1.0.13 && \
    wget https://download.libsodium.org/libsodium/releases/libsodium-$LIBSODIUM_VER.tar.gz && \
    tar xvf libsodium-$LIBSODIUM_VER.tar.gz && \
    pushd libsodium-$LIBSODIUM_VER && \
    ./configure --prefix=/usr && make && \
    make install && \
    popd && \
    ldconfig && \

    # Installation of MbedTLS
    export MBEDTLS_VER=2.6.0 && \
    wget https://tls.mbed.org/download/mbedtls-$MBEDTLS_VER-gpl.tgz && \
    tar xvf mbedtls-$MBEDTLS_VER-gpl.tgz && \
    pushd mbedtls-$MBEDTLS_VER && \
    make SHARED=1 CFLAGS=-fPIC && \
    make DESTDIR=/usr install && \
    popd && \
    ldconfig && \

    curl -sSL $SS_URL | tar xz --strip 1 && \
    ./configure --prefix=/usr --disable-documentation && \
    make install && \
    cd .. && \

    runDeps="$( \
        scanelf --needed --nobanner /usr/bin/ss-* \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | xargs -r apk info --installed \
            | sort -u \
    )" && \
    apk add --no-cache --virtual .run-deps $runDeps && \
    apk del .build-deps && \
    rm -rf /tmp/*

USER nobody

EXPOSE 1984

CMD ss-server -c /root/shadowsocks.json