# docker-fava

从 [beancount/fava](https://github.com/beancount/fava) 的最新 Git tag 构建并发布多架构 Docker 镜像。

## 自动发布

GitHub Actions 每周一 04:27 UTC 检查一次上游 tag。若对应镜像尚不存在，则从 PyPI 安装与该 tag 对应的 Fava 官方发布包，并将以下平台的统一 manifest 推送到 GitHub Container Registry（GHCR）：

- `linux/amd64`
- `linux/arm64`

镜像地址为：

```text
ghcr.io/<GitHub 用户或组织>/<本仓库名>:<Fava tag>
```

镜像 tag 会完整保留上游 tag，例如 Fava 的 `v1.30.14` 对应：

```text
ghcr.io/<GitHub 用户或组织>/<本仓库名>:v1.30.14
```

上游最新版本还会同时发布 `latest`：

```text
ghcr.io/<GitHub 用户或组织>/<本仓库名>:latest
```

手动构建历史版本不会覆盖 `latest`。

工作流也支持从 Actions 页面手动运行：`tag` 留空会选择最新 tag；指定 tag 可补建历史版本；启用 `force` 可覆盖重建已有 tag。

## 使用

准备账本文件：

```text
data/ledger.beancount
```

然后替换 `compose.yaml` 中的 `OWNER` 与镜像 tag，并启动：

```shell
docker compose up -d
```

访问 <http://localhost:5000>。

也可以直接运行：

```shell
docker run --rm \
  -p 5000:5000 \
  -v "$PWD/data:/data" \
  ghcr.io/OWNER/docker-fava:v1.30.14
```

若账本文件名不是 `ledger.beancount`，将容器命令改为其容器内路径：

```shell
docker run --rm \
  -p 5000:5000 \
  -v "$PWD/data:/data" \
  ghcr.io/OWNER/docker-fava:v1.30.14 /data/main.beancount
```

## 首次发布前

1. 将这些文件推送到 GitHub 仓库的默认分支。
2. 在仓库的 **Settings → Actions → General → Workflow permissions** 中确保 Actions 可以读取仓库；工作流已显式申请 `packages: write`。
3. 在 **Actions → Build and publish Fava image → Run workflow** 手动运行一次，或等待定时任务。
4. 如需公开拉取镜像，在 GHCR package 设置中将可见性改为 Public。

## 本地构建

构建当前平台镜像：

```shell
docker build --build-arg FAVA_TAG=v1.30.14 -t fava:v1.30.14 .
```

本地多架构构建可使用 Buildx；同时输出多个架构通常需要推送到 registry：

```shell
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg FAVA_TAG=v1.30.14 \
  -t registry.example.com/fava:v1.30.14 \
  --push .
```
