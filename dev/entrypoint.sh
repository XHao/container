#!/bin/sh
# Copy the runtime-mounted public key into authorized_keys (a direct bind
# mount fails sshd's StrictModes ownership/permission checks) and start sshd.
# Expected usage:
#   docker run -v ~/.ssh/id_ed25519.pub:/root/.ssh/id.pub:ro ...
set -eu

install -d -m 700 /root/.ssh

if [ -s /root/.ssh/id.pub ]; then
    install -m 600 /root/.ssh/id.pub /root/.ssh/authorized_keys
else
    rm -f /root/.ssh/authorized_keys
    echo "entrypoint: no public key mounted at /root/.ssh/id.pub; SSH login disabled" >&2
fi

exec /usr/sbin/sshd -D
