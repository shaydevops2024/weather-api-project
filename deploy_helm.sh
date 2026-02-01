#!/bin/bash

# Script to deploy Weather API with Helm on local Kubernetes (kind)

set -e

CLUSTER_NAME="helm-local-weather-api-local"
NAMESPACE="helm-weather-api"
RELEASE_NAME="weather-api"

echo "🚀 Deploying Weather API with Helm..."

# Check prerequisites
for cmd in kind kubectl helm docker; do
    if ! command -v $cmd &> /dev/null; then
        echo "❌ $cmd is not installed."
        exit 1
    fi
done

# Create kind cluster if it doesn't exist
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "📦 Creating kind cluster: ${CLUSTER_NAME}..."
    kind create cluster --name ${CLUSTER_NAME} --config kind-config.yaml
else
    echo "✅ Kind cluster '${CLUSTER_NAME}' already exists"
fi

kubectl config use-context kind-${CLUSTER_NAME}

# Build and load image
echo "🐳 Building Docker image..."
docker build -t weather-api:latest .
echo "📥 Loading image into kind cluster..."
kind load docker-image weather-api:latest --name ${CLUSTER_NAME}

# Deploy with Helm
echo "📦 Building Helm dependencies..."
helm dependency build ./helm/weather-api

echo "📊 Installing/Upgrading Helm chart..."
helm upgrade --install ${RELEASE_NAME} ./helm/weather-api \
    --namespace ${NAMESPACE} \
    --create-namespace \
    --set image.tag=latest \
    --wait \
    --timeout 5m

echo ""
echo "✅ Deployment successful!"
echo ""
kubectl get all -n ${NAMESPACE}

echo ""
echo "🔗 Access:"
echo "  kubectl port-forward -n ${NAMESPACE} svc/${RELEASE_NAME} 8000:80"
echo "  Then visit: http://localhost:8000"
echo ""
echo "🛑 Uninstall:  helm uninstall ${RELEASE_NAME} -n ${NAMESPACE}"
echo "🗑️  Delete cluster:  kind delete cluster --name ${CLUSTER_NAME}"
