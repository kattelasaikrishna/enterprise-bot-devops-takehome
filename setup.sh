#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_NAME="demo"
NAMESPACE="demo"
RELEASE="demo"
IMAGE="demo-service:1.0.0"

echo "==> Checking required tools"

for cmd in docker kubectl kind helm; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: Required command not found: $cmd" >&2
    exit 1
  fi
done

docker info >/dev/null

echo "==> Creating kind cluster if necessary"

if ! kind get clusters | grep -qx "$CLUSTER_NAME"; then
  TMP_CONFIG="$(mktemp)"
  trap 'rm -f "${TMP_CONFIG:-}"' EXIT

  cat > "$TMP_CONFIG" <<'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
EOF

  kind create cluster \
    --name "$CLUSTER_NAME" \
    --config "$TMP_CONFIG"
else
  echo "Cluster '$CLUSTER_NAME' already exists; reusing it"
fi

kubectl cluster-info --context "kind-${CLUSTER_NAME}"

echo "==> Installing ingress-nginx if necessary"

if ! kubectl get deployment ingress-nginx-controller \
    -n ingress-nginx >/dev/null 2>&1; then
  kubectl apply -f \
    https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.1/deploy/static/provider/kind/deploy.yaml
fi

kubectl wait \
  --namespace ingress-nginx \
  --for=condition=Ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

echo "==> Building application image"

docker build \
  -t "$IMAGE" \
  "$ROOT_DIR/service"

echo "==> Loading image into kind"

kind load docker-image "$IMAGE" \
  --name "$CLUSTER_NAME"

echo "==> Creating namespace if necessary"

kubectl create namespace "$NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "==> Validating Helm chart"

helm lint "$ROOT_DIR/chart"

echo "==> Installing or upgrading Helm release"

helm upgrade --install "$RELEASE" "$ROOT_DIR/chart" \
  --namespace "$NAMESPACE" \
  --wait \
  --timeout 180s

echo "==> Waiting for the application rollout"

kubectl rollout status \
  deployment/demo \
  --namespace "$NAMESPACE" \
  --timeout=180s

echo "==> Deployment completed"

kubectl get deployments,services,ingress \
  --namespace "$NAMESPACE"
