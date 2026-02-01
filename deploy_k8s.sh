#!/bin/bash

# Script to deploy Weather API on local Kubernetes (kind)

set -e

CLUSTER_NAME="k8s-local-weather-api-local"
NAMESPACE="k8s-local-weather-api"

echo "🚀 Deploying Weather API..."

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo "❌ kind is not installed. Please install it first:"
    echo "   https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install it first."
    exit 1
fi

# Create kind cluster if it doesn't exist
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "📦 Creating kind cluster: ${CLUSTER_NAME}..."
    kind create cluster --name ${CLUSTER_NAME} --config kind-config-k8s.yaml
else
    echo "✅ Kind cluster '${CLUSTER_NAME}' already exists"
fi

# Set kubeconfig context
kubectl config use-context kind-${CLUSTER_NAME}

# Build Docker image
echo "🐳 Building Docker image..."
docker build -t weather-api:latest .

# Load image into kind cluster
echo "📥 Loading image into kind cluster..."
kind load docker-image weather-api:latest --name ${CLUSTER_NAME}

# Apply Kubernetes manifests
echo "📁 Applying Kubernetes manifests from k8s/..."
kubectl apply -f ./k8s/namespace.yaml
kubectl apply -f ./k8s/serviceaccount.yaml
kubectl apply -f ./k8s/deployment.yaml
kubectl apply -f ./k8s/service.yaml

# Wait for deployment
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s \
    deployment/weather-api -n ${NAMESPACE}

# Get service information
echo ""
echo "✅ Deployment successful!"
echo ""
echo "📊 Deployed Resources:"
kubectl get all -n ${NAMESPACE}

echo ""
echo "🔗 To access the services, run the following commands:"
echo ""
echo "Weather API:"
echo "  kubectl port-forward -n ${NAMESPACE} svc/weather-api 8001:80"
echo "  Then visit: http://localhost:8001"
echo ""
echo "🛑 To uninstall:"
echo "  kubectl delete -f ./k8s/"
echo ""
echo "🗑️  To delete the kind cluster:"
echo "  kind delete cluster --name ${CLUSTER_NAME}"
