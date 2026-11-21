FROM quay.io/fedora/fedora-bootc:45

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
    zram-generator \
    && dnf clean all

COPY 10-dns-resolved.conf /etc/NetworkManager/conf.d/10-dns-resolved.conf
RUN ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

COPY 99_nocloud_ch.cfg /etc/cloud/cloud.cfg.d/99_nocloud_ch.cfg
COPY 10-cloud-hypervisor.toml /usr/lib/bootc/kargs.d/10-cloud-hypervisor.toml
COPY 10-virtio.conf /etc/dracut.conf.d/10-virtio.conf

# Use composefs as the primary generator
RUN rm -f /usr/lib/ostree/prepare-root.conf /etc/ostree/prepare-root.conf
COPY setup-root-conf.toml /usr/lib/composefs/setup-root-conf.toml

COPY zram-generator.conf /etc/systemd/zram-generator.conf

RUN systemctl enable \
    systemd-resolved.service \
    NetworkManager.service \
    cloud-init-local.service \
    cloud-config.service \
    cloud-final.service \
    sshd.service

RUN kver=$(cd /usr/lib/modules && echo *) && \
    dracut -vf /usr/lib/modules/$kver/initramfs.img $kver

RUN bootc container lint
