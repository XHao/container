# container

This project provides a GitHub Actions workflow to automatically pull a specified Docker image and push it to the GitHub Container Registry (GHCR), with a focus on supporting users who utilize the `container` command on macOS.

## Purpose

The main goal of this project is to make popular container images easily accessible and compatible for macOS users, especially those using the `container` command. By mirroring images to GHCR, macOS users can benefit from improved reliability and performance when pulling images.

## Usage

1. **How to Trigger**  
   - On push to the `main` branch (excluding changes to `README.md`)  
   - Manually via the GitHub Actions `workflow_dispatch` event, with the option to specify the image to sync

2. **Customizing the Image**  
   When running the workflow manually from the Actions tab, you can specify the image to sync using the `image_to_sync` input (e.g., `ubuntu:latest`).  
   The default image is `ubuntu:latest`.

3. **Sync Process**  
   - Pulls the specified Docker image (for the `linux/arm64` platform, which is compatible with Apple Silicon Macs)
   - Extracts the image name and tag
   - Retags the image for GHCR as:  
     `ghcr.io/<github-username>/<repository-name>/<image-name>:<tag>`
   - Pushes the image to GHCR

4. **Example**  
   If you specify `nginx:alpine`, the resulting image will be available at:  
   ```
   ghcr.io/<your-github-username>/<repository-name>/nginx:alpine
   ```

## Notes

- Designed for macOS users, especially those using the `container` command
- Requires the repository's `GITHUB_TOKEN` (enabled by default)
- The workflow runs on `ubuntu-latest`
- Only public images are supported for syncing
- The image tag will always be converted to lowercase when syncing to GHCR