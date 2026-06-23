#!/bin/bash
set -xeuo pipefail

# fetch repos from in-cluster mirrors if we're running in OpenShift CI
if [ "${OPENSHIFT_CI}" != 0 ]; then
    ci/get-ocp-repo.sh ocp.repo
fi

# just to parse the treefile, rpm-ostree still wants to read referenced "externals" (e.g. passwd, group)
# hack around this for now by deleting the problematic bits; we should tweak rpm-ostree instead
jq 'del(.["check-passwd","check-groups"])' /usr/share/rpm-ostree/treefile.json > filtered.json

. /etc/os-release
extensions_yaml="extensions/${ID}-${VERSION_ID}.yaml"
# Replace the __OCP_VERSION__ placeholder with the actual OpenShift version.
# This allows the same YAML file to be used across different OCP versions
# (e.g. 4.23 and 5.0) without duplication.
sed -i "s/__OCP_VERSION__/${OPENSHIFT_VERSION}/g" "$extensions_yaml"
rpm-ostree compose extensions filtered.json "$extensions_yaml" \
    --rootfs=/ --output-dir=/usr/share/rpm-ostree/extensions/
