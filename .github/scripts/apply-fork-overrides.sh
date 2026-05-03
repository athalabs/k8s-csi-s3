#!/usr/bin/env bash
# Re-applies athalabs fork overrides on top of upstream files.
# Idempotent. Run from upstream-sync after merging upstream/master so
# predictable conflicts on the chart files don't keep recurring.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

values=deploy/helm/csi-s3/values.yaml
chart=deploy/helm/csi-s3/Chart.yaml

if [ -f "$values" ]; then
  # 1. Main csi image -> ghcr.io/athalabs (preserve whatever version tag is there).
  sed -i.bak -E \
    "s|^([[:space:]]*csi:[[:space:]]*).*csi-s3-driver:([0-9A-Za-z._-]+)$|\1ghcr.io/athalabs/csi-s3:\2|" \
    "$values"
  # 2. Sidecars -> upstream sig-storage (multi-arch). cr.yandex mirrors are amd64-only.
  sed -i.bak -E \
    "s|^([[:space:]]*registrar:[[:space:]]*).*csi-node-driver-registrar:([0-9A-Za-z._-]+)$|\1registry.k8s.io/sig-storage/csi-node-driver-registrar:\2|" \
    "$values"
  sed -i.bak -E \
    "s|^([[:space:]]*provisioner:[[:space:]]*).*csi-provisioner:([0-9A-Za-z._-]+)$|\1registry.k8s.io/sig-storage/csi-provisioner:\2|" \
    "$values"
  # Drop the upstream "Source: quay.io/k8scsi/..." comments that referred to the cr.yandex mirror history.
  sed -i.bak -E '/# Source: quay\.io\/k8scsi\//d' "$values"
  rm -f "$values.bak"
fi

if [ -f "$chart" ]; then
  # 3. Chart home/sources point at our fork.
  sed -i.bak -E \
    -e 's|github.com/yandex-cloud/k8s-csi-s3|github.com/athalabs/k8s-csi-s3|g' \
    "$chart"
  rm -f "$chart.bak"
fi
