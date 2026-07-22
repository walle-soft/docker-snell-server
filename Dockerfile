# syntax=docker/dockerfile:1

# ---------- Builder ----------
# 固定跑在 BUILDPLATFORM(通常是 amd64 runner),原生下载/解压,免 QEMU 加速。
# snell 的官方压缩包按架构区分,通过 TARGETARCH 选择对应的包。
FROM --platform=$BUILDPLATFORM alpine:3.20 AS builder

# Docker buildx 自动注入:amd64 / arm64
ARG TARGETARCH
# 可通过 --build-arg SNELL_VERSION=vX.Y.Z 覆盖
ARG SNELL_VERSION=v5.0.1

RUN set -eux; \
    apk add --no-cache wget unzip ca-certificates; \
    # 关键:Docker 的 arm64 对应 Snell 的 aarch64
    case "${TARGETARCH}" in \
      amd64) SNELL_ARCH="amd64" ;; \
      arm64) SNELL_ARCH="aarch64" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    wget -O /tmp/snell.zip \
      "https://dl.nssurge.com/snell/snell-server-${SNELL_VERSION}-linux-${SNELL_ARCH}.zip"; \
    unzip /tmp/snell.zip -d /tmp/snell; \
    install -m 0755 /tmp/snell/snell-server /usr/local/bin/snell-server

# ---------- Runtime ----------
FROM alpine:3.20

LABEL org.opencontainers.image.title="snell-server" \
      org.opencontainers.image.description="Multi-arch (amd64/arm64) Snell server" \
      org.opencontainers.image.source="https://github.com"

RUN apk add --no-cache ca-certificates tzdata \
    && addgroup -S snell \
    && adduser -S -G snell snell

COPY --from=builder /usr/local/bin/snell-server /usr/local/bin/snell-server
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
    && mkdir -p /etc/snell \
    && chown -R snell:snell /etc/snell

# 运行时可覆盖的环境变量
ENV PORT=9102 \
    PSK="" \
    OBFS=off \
    OBFS_HOST=icloud.com \
    IPV6=false \
    DNS=""

EXPOSE 9102

USER snell

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
