# container

This project mirrors popular container images to the GitHub Container Registry (GHCR), with a focus on supporting users who utilize the `container` command on macOS. It also provides a multi-arch dev image with SSH access.

## Image Sync

### What gets synced

The image list lives in [`images.txt`](images.txt): one image per line, `#` comments and blank lines ignored. Every listed image is synced for both `linux/amd64` and `linux/arm64` (Apple Silicon compatible). Currently: Ubuntu, CentOS Stream, Alpine, and Debian — pure system bases only.

Ubuntu is mirrored twice: `latest` (convenience) and a versioned tag (`26.04`) that downstream builds pin to, so base drift becomes an explicit upgrade instead of a surprise.

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

A personal dev environment built by CI ([`build-dev-image.yml`](.github/workflows/build-dev-image.yml)) and published to GHCR as a multi-arch tag — any machine just pulls it:

```bash
podman pull ghcr.io/xhao/container/dev:latest

# run with your public key mounted
podman run -d --name dev -p 2222:22 \
    -v ~/.ssh/id_ed25519.pub:/root/.ssh/id.pub:ro \
    ghcr.io/xhao/container/dev:latest

ssh -p 2222 root@localhost
```

The image builds for both `linux/amd64` and `linux/arm64` on native runners (no QEMU), pinned to the versioned `ubuntu-linux-<arch>:26.04` mirror tag — moving to a new Ubuntu release means bumping that tag in `dev/Dockerfile` plus `images.txt` together. It ships zsh + tmux with a Dracula status bar (SSH logins land in tmux automatically), git, Go 1.27.3 (with `GOPROXY=https://goproxy.cn`), OpenJDK 25, Maven, Python 3, and an SSH server.

**Triggers**: changes under `dev/`, every successful sync run (so the dev image tracks the pinned base's point releases), or manual dispatch. The very first run after adding the versioned base tag can race ahead of the sync workflow and fail — the post-sync trigger self-heals it.

**No secret material is baked into the image**: there is no root password, and your SSH public key is mounted at runtime instead of being passed as a build arg. The entrypoint copies the mounted key to `authorized_keys` with the ownership and permissions sshd requires (a direct bind mount would fail `StrictModes` checks), then starts sshd. Local iteration still works with `podman build ./dev`.

## Notes

- Designed for macOS users, especially those using the `container` command
- Requires the repository's `GITHUB_TOKEN` (enabled by default)
- Only public images are supported for syncing
- Image names and tags are lowercased when pushed to GHCR
