# This builds the OCP4NV node image on top of the base image itself.
ARG FROM
FROM ${FROM}
COPY voyager.repo /etc/yum.repos.d/
RUN <<EOF
arch="$(uname -m)"
dnf remove kernel-core --assumeyes

kernel_name='kernel-core'
[ "$arch" = 'aarch64' ] && kernel_name='kernel-64k-core'

dnf install --assumeyes --disablerepo=* --enablerepo=voyager "$kernel_name"

kver=$(ls /usr/lib/modules)
env DRACUT_NO_XATTR=1 dracut -vf /usr/lib/modules/$kver/initramfs.img "$kver"
EOF
