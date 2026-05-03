#!/usr/bin/env bash
# Re-applies athalabs fork overrides on top of upstream files.
# Idempotent. Run from the upstream-sync workflow after merging upstream/master
# so predictable conflicts on the chart files don't keep recurring.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

values=deploy/helm/csi-s3/values.yaml
chart=deploy/helm/csi-s3/Chart.yaml

if [ -f "$values" ]; then
  # Rewrite the main csi image to GHCR while preserving whatever version tag is there.
  sed -i.bak -E \
    "s|^([[:space:]]*csi:[[:space:]]*).*csi-s3-driver:([0-9A-Za-z._-]+)$|\1ghcr.io/athalabs/csi-s3:\2|" \
    "$values"
  rm -f "$values.bak"
fi

if [ -f "$chart" ]; then
  sed -i.bak -E \
    -e 's|github.com/yandex-cloud/k8s-csi-s3|github.com/athalabs/k8s-csi-s3|g' \
    "$chart"
  rm -f "$chart.bak"
fi
