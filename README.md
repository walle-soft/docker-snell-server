# docker-snell-server

多架构(`linux/amd64` + `linux/arm64`)的 [Snell](https://kb.nssurge.com/surge-knowledge-base/release-notes/snell) 服务端 Docker 镜像,通过 GitHub Actions 自动构建并推送到 GHCR。

## 特性

- ✅ 同一个镜像 tag 同时支持 **amd64 / arm64**(Docker 自动按平台拉取)
- ✅ 通过环境变量生成配置,开箱即用;未设置 `PSK` 时自动随机生成
- ✅ Snell 版本可通过 build ARG 覆盖,默认 `v5.0.1`
- ✅ 以非 root 用户运行

## 快速开始

```bash
docker run -d --name snell-server \
  -p 9102:9102 \
  -e PSK=your-pre-shared-key \
  ghcr.io/walle-soft/docker-snell-server:latest
```

> 首次推送后镜像会出现在仓库的 Packages 里(默认为 private,可在 Package settings 改为 public)。

不设置 `PSK` 时会自动生成随机 PSK,可在日志里查看:

```bash
docker logs snell-server
```

### 使用 docker compose

参见仓库中的 [`docker-compose.yml`](./docker-compose.yml):

```bash
docker compose up -d
```

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `PORT` | `9102` | 监听端口 |
| `PSK` | (随机) | 预共享密钥,留空自动生成 |
| `OBFS` | `off` | 混淆方式:`off` / `http` / `tls` |
| `OBFS_HOST` | `icloud.com` | 混淆域名(仅 `OBFS` 非 off 时生效) |
| `IPV6` | `false` | 是否监听 IPv6(`true` 时监听 `::`) |
| `DNS` | (空) | 自定义 DNS,如 `1.1.1.1,8.8.8.8` |

## 客户端配置(Surge)

```
Proxy = snell, <服务器IP>, 9102, psk=<你的PSK>, version=5
```

若开启了混淆,追加 `obfs=<http|tls>, obfs-host=<OBFS_HOST>`。

## 本地构建

单架构(快速验证):

```bash
docker build -t snell-server .
```

指定 Snell 版本:

```bash
docker build --build-arg SNELL_VERSION=v6.0.0rc -t snell-server:v6 .
```

双架构构建(需 buildx):

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t snell-server .
```

## 自动构建(CI)

`.github/workflows/docker-publish.yml` 会在以下情况触发:

- push 到 `main` / `master` 分支 → 推 `latest`
- push `v*` tag → 推对应语义化版本 tag
- 手动触发(workflow_dispatch),可指定 Snell 版本

镜像通过内置 `GITHUB_TOKEN` 推送到 GHCR,**无需额外配置 Secret**。
仅需在仓库 Settings → Actions → General 中确认 Workflow permissions 允许写入 packages(默认工作流已声明 `packages: write`)。

## 支持的架构说明

| Docker 平台 | Snell 下载架构 |
|-------------|----------------|
| `linux/amd64` | `amd64` |
| `linux/arm64` | `aarch64` |

> Docker 的 `arm64` 对应 Snell 官方包的 `aarch64`,Dockerfile 内已做映射。
