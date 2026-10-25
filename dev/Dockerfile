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
        tmux \
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

RUN chsh -s /bin/zsh root

# Dracula tmux theme from our fork (carries the weather icon fix).
# Overridable for local builds on networks where github HTTPS is blocked.
ARG DRACULA_REPO=https://github.com/XHao/tmux.git
RUN git clone --depth 1 "$DRACULA_REPO" /root/.tmux/dracula && \
    rm -rf /root/.tmux/dracula/.git

RUN cat > /root/.tmux.conf <<'EOF'
# Slim port of ~/dotfiles/.tmux.conf — drops macOS clipboard (pbcopy),
# AI popups (need dotfiles scripts), and the battery segment (no battery).
# Prefix stays Ctrl-b; Nerd Font glyphs render on the client terminal.

# ---- basics ----
set -g mouse on
set -s escape-time 0
set -g history-limit 50000
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g set-titles on
set -g set-titles-string '#S:#I:#W - "#T" #{session_alerts}'

# ---- colors: truecolor passthrough ----
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",*:Tc"

# ---- splits & panes ----
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# ---- copy mode (vi); copies stay in the tmux buffer, prefix ] pastes ----
setw -g mode-keys vi
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi y send -X copy-pipe-and-cancel
bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel

# ---- sync input / reload ----
bind S setw synchronize-panes \; display "同步输入: #{?pane_synchronized,ON ⚠️,OFF}"
bind r source-file ~/.tmux.conf \; display "已重载 ~/.tmux.conf"

# ---- Dracula status bar: cpu/ram/weather/time, Everforest palette ----
set -g status-interval 5
set -g @dracula-show-powerline true
set -g @dracula-show-left-icon session
set -g @dracula-plugins "cpu-usage ram-usage weather time"
set -g @dracula-colors "white=#d3c6aa gray=#3a464c dark_gray=#333c43 light_purple=#83c092 dark_purple=#4d5960 cyan=#7fbbb3 green=#a7c080 orange=#e69875 red=#e67e80 purple=#d699b6 pink=#d699b6 yellow=#dbbc7f"
set -g @dracula-show-fahrenheit false
set -g @dracula-show-location true
set -g @dracula-show-timezone false
set -g @dracula-fixed-location "Shanghai"
run-shell ~/.tmux/dracula/dracula.tmux

# ---- pane/message colors (Everforest, same palette as @dracula-colors) ----
set -g pane-border-style "fg=#3a464c"
set -g pane-active-border-style "fg=#83c092"
set -g message-style "bg=#3a464c,fg=#d3c6aa"
setw -g mode-style "bg=#a7c080,fg=#333c43"

# ---- machine-local hook ----
if-shell '[ -f ~/.tmux.conf.local ]' 'source-file ~/.tmux.conf.local'
EOF

# SSH/interactive logins land in tmux (window close destroys the session);
# same guard trio as dotfiles zshrc.d/05-tmux.zsh
RUN cat >> /root/.zshrc <<'EOF'
if [[ -o interactive && -z "${TMUX:-}" ]] && command -v tmux &>/dev/null; then
    exec tmux new \; set-option destroy-unattached on
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
