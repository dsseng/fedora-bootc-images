FROM quay.io/fedora/fedora-bootc:45@sha256:17eabee8f2f836d01315c30cf4e3e48cbb57c125469d72229ad9126d8a747d6b

RUN dnf update -y && dnf install -y --setopt=install_weak_deps=False \
    cloud-init \
    systemd-resolved \
    NetworkManager \
    openssh-server \
    sudo \
    curl \
    git \
    tar \
    tmux \
    procps-ng \
    iproute \
    iputils \
    && dnf clean all

RUN mkdir -p /usr/lib/ostree/ && \
    echo -e "[stage]\nread-write=true" > /usr/lib/ostree/prepare-root.conf

COPY 10-dns-resolved.conf /etc/NetworkManager/conf.d/10-dns-resolved.conf
RUN ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

COPY 99_nocloud_ch.cfg /etc/cloud/cloud.cfg.d/99_nocloud_ch.cfg
COPY 10-cloud-hypervisor.toml /usr/lib/bootc/kargs.d/10-cloud-hypervisor.toml
COPY 10-virtio.conf /etc/dracut.conf.d/10-virtio.conf

RUN systemctl enable \
    systemd-resolved.service \
    NetworkManager.service \
    cloud-init-local.service \
    cloud-config.service \
    cloud-final.service \
    sshd.service \
    fstrim.timer

RUN bootc container lint
