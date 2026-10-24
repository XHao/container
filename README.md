# container

This project mirrors popular container images to the GitHub Container Registry (GHCR), with a focus on supporting users who utilize the `container` command on macOS. It also provides a multi-arch dev image with SSH access.

## Image Sync

### What gets synced

The image list lives in [`images.txt`](images.txt): one image per line, `#` comments and blank lines ignored. Every listed image is synced for both `linux/amd64` and `linux/arm64` (Apple Silicon compatible). Currently: Ubuntu, CentOS Stream, Alpine, and Debian — pure system bases only.

### How to trigger

1. **Monthly schedule** — automatically on the 1st of each month at 00:00 UTC
2. **On push to `main`** — when `images.txt` (or the workflow itself) changes
3. **Manually** via `workflow_dispatch` — optionally pass a single image (e.g. `alpine:latest`) for a one-off sync without editing the list

### Sync process

- Pulls the image for the target platform
- Retags it as `ghcr.io/<github-username>/<repository-name>/<image-name>-<platform>:<tag>`,
  where `<platform>` is the architecture suffix (`linux-arm64` / `linux-amd64`)
- Pushes it to GHCR

For example, `ubuntu:latest` for Apple Silicon becomes:
```
ghcr.io/<your-github-username>/container/ubuntu-linux-arm64:latest
```

## Dev Image (`dev/`)

A single Dockerfile builds for both architectures (`TARGETARCH` auto-detected) on top of the mirrored Ubuntu image. It ships zsh + powerline-shell, git, Go 1.24.4 (with `GOPROXY=https://goproxy.cn`), OpenJDK 21, Maven, Python 3, and an SSH server.

**No secret material is baked into the image**: there is no root password, and your SSH public key is mounted at runtime instead of being passed as a build arg.

```bash
# build (arm64 on Apple Silicon; add --platform linux/amd64 for x86)
docker build -t dev ./dev

# run with your public key mounted
docker run -d --name dev -p 2222:22 \
    -v ~/.ssh/id_ed25519.pub:/root/.ssh/id.pub:ro \
    dev

ssh -p 2222 root@localhost
```

The entrypoint copies the mounted key to `authorized_keys` with the ownership and permissions sshd requires (a direct bind mount would fail `StrictModes` checks), then starts sshd.

## Notes

- Designed for macOS users, especially those using the `container` command
- Requires the repository's `GITHUB_TOKEN` (enabled by default)
- Only public images are supported for syncing
- Image names and tags are lowercased when pushed to GHCR
