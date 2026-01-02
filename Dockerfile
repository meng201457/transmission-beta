###############################################
# 第一阶段：构建 Transmission（Ubuntu 22.04）
###############################################
FROM ubuntu:22.04 AS builder

ARG TRANSMISSION_TAG

RUN apt-get update && apt-get install -y \
    git cmake build-essential pkg-config ninja-build \
    libevent-dev libcurl4-openssl-dev libssl-dev zlib1g-dev \
    libfmt-dev libpsl-dev libdeflate-dev libmbedtls-dev \
    ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --branch ${TRANSMISSION_TAG} --single-branch --depth 1 \
    https://github.com/transmission/transmission.git /src && \
    cd /src && git submodule update --init --recursive

WORKDIR /src/build

RUN cmake -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DENABLE_GTK=OFF -DENABLE_QT=OFF -DENABLE_MAC=OFF -DENABLE_WX=OFF \
      -DENABLE_CLI=ON -DENABLE_DAEMON=ON -DENABLE_UTILS=ON \
      -DENABLE_TESTS=OFF -DINSTALL_DOC=OFF -DWITH_INOTIFY=ON \
      -DCRC32C_USE_HELPER=ON -DCRC32C_BUILD_TESTS=OFF -DCRC32C_BUILD_BENCHMARKS=OFF \
      ..

RUN ninja

RUN mkdir -p /out && \
    cp /src/build/daemon/transmission-daemon /out/ && \
    cp /src/build/utils/transmission-remote /out/ || true


###############################################
# 第二阶段：最终运行镜像（极简 + s6-overlay）
###############################################
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    libevent-2.1-7 libssl3 zlib1g libpsl5 libdeflate0 libcurl4 \
    ca-certificates curl wget xz-utils \
    && rm -rf /var/lib/apt/lists/*

# 使用仓库内的 s6-overlay（永不失败）
COPY assets/s6-overlay-aarch64.tar.xz /tmp/s6-overlay.tar.xz
RUN tar -xJf /tmp/s6-overlay.tar.xz -C / && \
    rm /tmp/s6-overlay.tar.xz && \
    test -f /init

# 拷贝 Transmission 二进制
COPY --from=builder /out/transmission-daemon /usr/bin/
COPY --from=builder /out/transmission-remote /usr/bin/

ENV TRANSMISSION_HOME=/config
ENV PUID=1000
ENV PGID=1000

RUN mkdir -p \
    /config \
    /downloads \
    /config/blocklists \
    /etc/cont-init.d \
    /etc/services.d/transmission \
    /etc/services.d/save-settings \
    /etc/services.d/blocklist

COPY docker/20-config /etc/cont-init.d/20-config
COPY docker/transmission.run /etc/services.d/transmission/run
COPY docker/save-settings.run /etc/services.d/save-settings/run
COPY docker/blocklist.run /etc/services.d/blocklist/run

RUN chmod +x /etc/cont-init.d/20-config \
    /etc/services.d/transmission/run \
    /etc/services.d/save-settings/run \
    /etc/services.d/blocklist/run

HEALTHCHECK CMD curl -fs http://localhost:9091/transmission/web/ || exit 1

EXPOSE 9091 51413 51413/udp

ENTRYPOINT ["/init"]
