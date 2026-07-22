#!/bin/sh
set -e

CONF="/etc/snell/snell-server.conf"
mkdir -p /etc/snell

# 未提供 PSK 时自动生成一个随机 PSK
if [ -z "$PSK" ]; then
  PSK=$(head -c 32 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 20)
  echo "[entrypoint] No PSK provided, generated a random one: ${PSK}"
fi

# 监听地址:IPV6=true 时监听 ::,否则监听 0.0.0.0
if [ "$IPV6" = "true" ]; then
  LISTEN="::0:${PORT}"
else
  LISTEN="0.0.0.0:${PORT}"
fi

# 从环境变量生成配置文件
{
  echo "[snell-server]"
  echo "listen = ${LISTEN}"
  echo "psk = ${PSK}"
  echo "ipv6 = ${IPV6}"
  if [ "$OBFS" != "off" ] && [ -n "$OBFS" ]; then
    echo "obfs = ${OBFS}"
    # 仅在显式设置了 OBFS_HOST 时才写入
    if [ -n "$OBFS_HOST" ]; then
      echo "obfs-host = ${OBFS_HOST}"
    fi
  else
    echo "obfs = off"
  fi
  if [ -n "$DNS" ]; then
    echo "dns = ${DNS}"
  fi
} > "$CONF"

echo "----- ${CONF} -----"
cat "$CONF"
echo "-------------------------------------"

exec snell-server -c "$CONF"
