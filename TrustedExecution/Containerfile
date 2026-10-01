ARG BASE
ARG KBC_IMG="quay.io/trusted-execution-clusters/trustee-attester:fedora-b13fd8a"
ARG CLEVIS_PIN_IMG="quay.io/trusted-execution-clusters/clevis-pin-trustee"
ARG IGNITION_IMG="ghcr.io/trusted-execution-clusters/ignition:20260112-85608d6"

FROM ${KBC_IMG} as kbc
FROM ${CLEVIS_PIN_IMG} as clevis
FROM ${IGNITION_IMG} as ignition
FROM ${BASE}

ARG ID=overridden
ARG VERSION=overridden
ARG DESCRIPTION=overridden
ARG STREAM=overridden
ARG NAME=overridden

COPY ./usr /usr
COPY --from=kbc /usr/local/bin/trustee-attester /usr/bin/trustee-attester
COPY --from=clevis /usr/bin/clevis-pin-trustee /usr/bin/clevis-pin-trustee
COPY --from=clevis /usr/bin/clevis-encrypt-trustee /usr/bin/clevis-encrypt-trustee
COPY --from=clevis /usr/bin/clevis-decrypt-trustee /usr/bin/clevis-decrypt-trustee
COPY --from=ignition /usr/bin/ignition /usr/lib/dracut/modules.d/30ignition/ignition

RUN set -xeuo pipefail && \
    KERNEL_VERSION="$(basename $(ls -d /lib/modules/*))" && \
    raw_args="$(lsinitrd /lib/modules/${KERNEL_VERSION}/initramfs.img | grep '^Arguments: ' | sed 's/^Arguments: //')" && \
    stock_arguments=$(echo "$raw_args" | sed "s/'//g") && \
    echo "Using kernel: $KERNEL_VERSION" && \
    echo "Dracut arguments: $stock_arguments" && \
    mkdir -p /tmp/dracut /var/roothome && \
    dracut $stock_arguments && \
    mv -v /boot/initramfs*.img "/lib/modules/${KERNEL_VERSION}/initramfs.img" && \
    bootc container lint

LABEL containers.bootc=1 \
      ostree.bootable=1 \
      org.opencontainers.image.version=$VERSION \
      com.coreos.osname=$NAME \
      org.opencontainers.image.title=$DESCRIPTION \
      org.opencontainers.image.description=$DESCRIPTION
