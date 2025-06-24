FROM ghcr.io/xhao/container/ubuntu-linux-arm64:latest

RUN rm /etc/apt/sources.list && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://ports.ubuntu.com/ubuntu-ports/ noble-security main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb-src http://ports.ubuntu.com/ubuntu-ports/ noble-security main restricted universe multiverse" >> /etc/apt/sources.list

ENV DEBIAN_FRONTEND=noninteractive

ENV TZ=Asia/Singapore
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    curl \
    wget \
    net-tools \
    openssh-server \
    git \
    python3 python3-pip \
    openjdk-21-jdk maven && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -OL https://mirrors.aliyun.com/golang/go1.24.4.linux-arm64.tar.gz && \
    rm -rf /usr/local/go && \
    tar -C /usr/local -xzf go1.24.4.linux-arm64.tar.gz && \
    rm -rf go1.24.4.linux-arm64.tar.gz

RUN echo 'export PATH=$PATH:/usr/local/go/bin' >> /root/.bashrc

RUN export PATH=$PATH:/usr/local/go/bin && \
    go env -w GO111MODULE=on && \
    go env -w GOPROXY=https://goproxy.cn,direct

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
