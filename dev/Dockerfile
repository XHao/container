# syntax=docker/dockerfile:1
# Dev image for both linux/amd64 and linux/arm64 (architecture auto-detected
# via TARGETARCH). No SSH key is baked in -- the public key is mounted at
# runtime (see entrypoint.sh).
#
# Build:     docker build -t dev ./dev
# amd64:     docker build --platform linux/amd64 -t dev ./dev
# Run:       docker run -d -p 2222:22 -v ~/.ssh/id_ed25519.pub:/root/.ssh/id.pub:ro dev
ARG TARGETARCH
# Pinned to a versioned mirror tag so base drift is an explicit upgrade:
# bump this tag (and images.txt) together when moving to a new Ubuntu release.
FROM ghcr.io/xhao/container/ubuntu-linux-${TARGETARCH}:26.04

ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Singapore

# arm64 pulls from the Ubuntu ports archive: use the TUNA mirror with the
# base image's release codename (ubuntu:latest may jump to a new LTS — never
# hardcode it). Also drop the deb822 default sources to avoid stacking.
# amd64 keeps the default sources.
# The resolute base ships no ca-certificates: bootstrap them from the base's
# default http sources first, or every https fetch below (TUNA, aliyun) fails
# certificate verification.
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        apt-get update && \
        apt-get install -y --no-install-recommends ca-certificates && \
        CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME") && \
        rm -f /etc/apt/sources.list /etc/apt/sources.list.d/ubuntu.sources && \
        { echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ $CODENAME main restricted universe multiverse"; \
          echo "deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ $CODENAME main restricted universe multiverse"; \
          echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ $CODENAME-updates main restricted universe multiverse"; \
          echo "deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ $CODENAME-updates main restricted universe multiverse"; \
          echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ $CODENAME-backports main restricted universe multiverse"; \
          echo "deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ $CODENAME-backports main restricted universe multiverse"; \
          echo "deb http://ports.ubuntu.com/ubuntu-ports/ $CODENAME-security main restricted universe multiverse"; \
          echo "deb-src http://ports.ubuntu.com/ubuntu-ports/ $CODENAME-security main restricted universe multiverse"; } > /etc/apt/sources.list ; \
    fi && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
        ca-certificates \
        curl \
        wget \
        net-tools \
        zsh \
        sudo \
        fonts-powerline \
        openssh-server \
        git \
        python3 python3-pip \
        openjdk-25-jdk maven && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -OL https://mirrors.aliyun.com/golang/go1.27.3.linux-${TARGETARCH}.tar.gz && \
    rm -rf /usr/local/go && \
    tar -C /usr/local -xzf go1.27.3.linux-${TARGETARCH}.tar.gz && \
    rm -rf go1.27.3.linux-${TARGETARCH}.tar.gz && \
    /usr/local/go/bin/go env -w GO111MODULE=on && \
    /usr/local/go/bin/go env -w GOPROXY=https://goproxy.cn,direct

ENV PATH=/usr/local/go/bin:$PATH

# sshd sessions rebuild PATH from login.defs and do not inherit ENV, so
# add go to the shells' startup files as well (.zshenv is sourced by
# every zsh invocation, including non-interactive ssh commands).
RUN echo 'export PATH=/usr/local/go/bin:$PATH' >> /root/.zshenv && \
    echo 'export PATH=/usr/local/go/bin:$PATH' >> /root/.bashrc

RUN pip install --break-system-packages powerline-shell && \
    chsh -s /bin/zsh root

RUN cat >> /root/.zshrc <<'EOF'
function _update_ps1() {
    PS1=$(powerline-shell $? --shell zsh)
}
if [[ $TERM != linux && -t 1 ]]; then
  precmd () { _update_ps1; }
fi
EOF

RUN cat >> /root/.bashrc <<'EOF'
function _update_ps1() {
    PS1="$(powerline-shell $? --shell bash)"
}
if [[ $TERM != linux && -t 1 ]]; then
  PROMPT_COMMAND="_update_ps1${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
fi
EOF

# SSH: root login with the mounted public key only -- no password set,
# no key material in the image.
RUN mkdir -p /var/run/sshd /root/.ssh && \
    chmod 700 /root/.ssh && \
    usermod -p '*' root && \
    touch /root/.ssh/id.pub && \
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh

EXPOSE 22
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
