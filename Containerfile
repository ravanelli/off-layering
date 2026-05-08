# This builds the OCP4NV nodeimage/baseimage on top of the nodeimage/baseimage itself.
ARG FROM
ARG VERSION
ARG TYPE
FROM ${FROM}

ARG VERSION
ARG TYPE
COPY voyager.repo  /etc/yum.repos.d/

ARG KERNEL_URL="https://kojihub.stream.centos.org/kojifiles/vol/koji02/packages/kernel/6.12.0"
ARG KERNEL_VERSION="218.1.el10nv"

RUN <<EOF

if [ "$TYPE" = "baseimage" ]; then
    OLD_VERSION=$(grep "^OSTREE_VERSION=" /usr/lib/os-release | cut -d"'" -f2)
    [ -n "$OLD_VERSION" ] || { echo "Error: Could not extract version from os-release"; exit 1; }
    sed -i "s|$OLD_VERSION|$VERSION|g" /usr/lib/os-release
fi

arch="$(uname -m)"
dnf remove kernel-core --assumeyes

kernel_name='kernel'
[ "$arch" = 'aarch64' ] && kernel_name='kernel-64k'

baseurl="${KERNEL_URL}/${KERNEL_VERSION}/${arch}"; \
mkdir -p /tmp/new-kernel && cd /tmp/new-kernel; \
curl -s "${baseurl}/" \
  | grep -oE "${kernel_name}-((core|modules|modules-core|modules-extra))-[0-9][^\"]+\.rpm" \
  | xargs -r -I{} curl -s -O "${baseurl}/{}"; \
dnf install --assumeyes --disablerepo=* /tmp/new-kernel/*.rpm; \
rm -rf /tmp/new-kernel

kver=$(ls /usr/lib/modules)
env DRACUT_NO_XATTR=1 dracut -vf /usr/lib/modules/$kver/initramfs.img "$kver"
EOF

LABEL org.opencontainers.image.version=$VERSION
