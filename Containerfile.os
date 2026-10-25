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

RUN cat <<'EOF' > /etc/NetworkManager/conf.d/10-dns-resolved.conf
[main]
dns=systemd-resolved
rc-manager=symlink
EOF

RUN ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

RUN cat <<'EOF' > /etc/cloud/cloud.cfg.d/99_nocloud_ch.cfg
datasource_list: [ NoCloud ]
network:
  renderers: ['network-manager']
EOF

RUN mkdir -p /usr/lib/bootc/kargs.d && cat <<'EOF' > /usr/lib/bootc/kargs.d/10-cloud-hypervisor.toml
kargs = [
    "console=ttyS0,115200n8",
    "rootflags=discard",
    "net.ifnames=0",
    "biosdevname=0",
    "audit=0"
]
EOF

RUN cat <<'EOF' > /etc/dracut.conf.d/10-virtio.conf
add_drivers+=" virtio_pci virtio_blk virtio_net virtio_balloon virtiofs "
EOF

RUN systemctl enable \
    systemd-resolved.service \
    NetworkManager.service \
    cloud-init-local.service \
    cloud-config.service \
    cloud-final.service \
    sshd.service \
    fstrim.timer

RUN bootc container lint
