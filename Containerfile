# This builds the OCP4NV nodeimage/baseimage on top of the nodeimage/baseimage itself.
ARG FROM
FROM ${FROM}

COPY voyager.repo  /etc/yum.repos.d/
COPY doca.repo    /etc/yum.repos.d/

RUN <<EOF
set -euxo pipefail

    OLD_VERSION=$(grep "^OSTREE_VERSION=" /usr/lib/os-release | cut -d"'" -f2)
    [ -n "$OLD_VERSION" ] || { echo "Error: Could not extract version from os-release"; exit 1; }
#    sed -i "s|$OLD_VERSION|$VERSION|g" /usr/lib/os-release

arch="$(uname -m)"
dnf remove kernel-core --assumeyes

if [ "$arch" = 'aarch64' ]; then
    kernel_name='kernel-64k-core kernel-64k-modules-extra'
    mlnx_name='mlnx-ofa_kernel-64k-26.07-OFED.26.07.0.7.7.0.kver.6.12.0_259.26.el10nv.2.aarch64 mlnx-ofa_kernel-modules-64k'
    disable='doca-x86_64'
else
    kernel_name='kernel-core kernel-modules-extra'
    mlnx_name='mlnx-ofa_kernel-26.07-OFED.26.07.0.7.7.0.kver.6.12.0_259.26.el10nv.2.x86_64 mlnx-ofa_kernel-modules'
    disable='doca-aarch64'
fi

dnf install --assumeyes --disablerepo='*' --enablerepo=voyager $kernel_name
dnf remove --assumeyes openvswitch3.5


# See https://developers.redhat.com/articles/2025/09/23/customize-rhel-coreos-on-cluster-image-mode
# Mellanox packages are installed in /opt we need the workaround below
mkdir -p /usr/lib/opt/mellanox /var/opt /var/usrlocal

dnf install --assumeyes \
  --disablerepo=$disable \
  doca-networking-runtime \
  openvswitch-selinux-extra-policy \
  mft \
  libunwind \
  $mlnx_name
dnf clean all


# RHCOS does not preserve /var across boots. Move Mellanox files 
# See https://developers.redhat.com/articles/2025/09/23/customize-rhel-coreos-on-cluster-image-mode

mv /var/opt/mellanox /usr/lib/opt; \


printf '%s\n' 'L+ /opt/mellanox - - - - /usr/lib/opt/mellanox' > /usr/lib/tmpfiles.d/nvidia-doca.conf


printf '%s\n' \
        'd /var/lib/openvswitch 0750 openvswitch hugetlbfs - -' \
        'd /var/lib/openvswitch/pki 0750 openvswitch hugetlbfs - -' \
        'd /run/openvswitch 0755 root root - -' \
        > /usr/lib/tmpfiles.d/00-nvidia-ovs.conf; \

kver=$(ls /usr/lib/modules)
env DRACUT_NO_XATTR=1 dracut -vf /usr/lib/modules/$kver/initramfs.img "$kver"

bootc container lint
EOF
