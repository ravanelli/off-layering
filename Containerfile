# This builds the OCP4NV node image on top of the base image itself.
FROM quay.io/openshift-release-dev/ocp-v4.0-art-dev:4.21-10.1-node-image
ARG KERNEL_VERSION="209.2.el10nv"
RUN set -eux; \
    arch="$(uname -m)"; \
    if { [ "$arch" = "x86_64" ] || [ "$arch" = "aarch64" ]; }; then \
        baseurl="https://download-01.beak-001.prod.iad2.dc.redhat.com/brewroot/vol/rhel-10/packages/kernel/6.12.0/${KERNEL_VERSION}/${arch}"; \
        cd /tmp; \
        curl -s "${baseurl}/" \
          | grep -oE 'kernel(-64k)?(-(core|modules|modules-core|modules-extra))?-[0-9][^"]+\.rpm' \
          | grep -vE '(modules-internal|modules-partner|devel|headers|debug)' \
          | sort -u \
          | xargs -r -I{} curl -s -O "${baseurl}/{}"; \
        # The package names are different, we need to remote/install
        echo "Removing existing kernel packages..."; \
        rpm-ostree override remove \
          kernel \
          kernel-core \
          kernel-modules \
          kernel-modules-core \
          kernel-modules-extra; \
        echo "Installing new kernel packages..."; \
        rpm-ostree install /tmp/kernel*.rpm; \
        rm -f /tmp/kernel*.rpm; \
    fi
RUN ostree container commit
