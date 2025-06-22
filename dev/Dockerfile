FROM ghcr.io/xhao/container/ubuntu-linux-amd64:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    curl \
    wget \
    net-tools \
    zsh \
    openssh-server \
    git \
    fonts-powerline \
    sudo \
    python3 python3-pip \
    openjdk-21-jdk maven && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -OL https://mirrors.aliyun.com/golang/go1.24.4.linux-amd64.tar.gz && \
    rm -rf /usr/local/go && \
    tar -C /usr/local -xzf go1.24.4.linux-amd64.tar.gz && \
    rm -rf go1.24.4.linux-amd64.tar.gz

RUN echo 'export PATH=$PATH:/usr/local/go/bin' >> /root/.bashrc

RUN export PATH=$PATH:/usr/local/go/bin && \
    go env -w GO111MODULE=on && \
    go env -w GOPROXY=https://goproxy.cn,direct

RUN pip install powerline-shell --break-system-packages

RUN echo '' >> /root/.bashrc && \
    echo 'function _update_ps1() {' >> /root/.bashrc && \
    echo '    PS1=$(powerline-shell $?)' >> /root/.bashrc && \
    echo '}' >> /root/.bashrc && \
    echo '' >> /root/.bashrc && \
    echo 'if [[ $TERM != linux && ! $PROMPT_COMMAND =~ _update_ps1 ]]; then' >> /root/.bashrc && \
    echo '    PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"' >> /root/.bashrc && \
    echo 'fi' >> /root/.bashrc

RUN mkdir /var/run/sshd && \
    echo 'root:password' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

ARG SSH_PUB_KEY

RUN mkdir -p /root/.ssh && \
    echo "${SSH_PUB_KEY}" > /root/.ssh/authorized_keys && \
    chmod 700 /root/.ssh && \
    chmod 600 /root/.ssh/authorized_keys

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
