#!/usr/bin/env bash
set -euo pipefail
bash scripts/is-release-day.sh || { echo 'Production releases are allowed only on the 25th (Asia/Kolkata).'; exit 1; }
IMAGE_REF=$(cat image-digest.txt)
[[ "$IMAGE_REF" =~ ^mohdvaqui002/capstone-project@sha256:[a-f0-9]{64}$ ]] || { echo 'Invalid image digest'; exit 1; }
sed "s|IMAGE_REFERENCE|$IMAGE_REF|g" k8s/application.yaml > rendered-application.yaml
kubectl apply -f rendered-application.yaml
if ! kubectl -n capstone rollout status deployment/capstone-web --timeout=180s; then
  kubectl -n capstone rollout undo deployment/capstone-web || true
  exit 1
fi
kubectl -n capstone get deployment,service,pods -o wide
