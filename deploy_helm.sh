#!/bin/bash

# Script to deploy Weather API with Helm on local Kubernetes (kind or minikube)

set -e

CLUSTER_NAME="helm-local-weather-api-local"
NAMESPACE="helm-weather-api"
RELEASE_NAME="weather-api"

echo "🚀 Deploying Weather API with Helm..."

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

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Please install it first:"
    echo "   https://helm.sh/docs/intro/install/"
    exit 1
fi

# Create kind cluster if it doesn't exist
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "📦 Creating kind cluster: ${CLUSTER_NAME}..."
    kind create cluster --name ${CLUSTER_NAME} --config kind-config.yaml
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

# Create namespace
echo "📁 Creating namespace: ${NAMESPACE}..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Add Helm repositories
echo "📚 Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Build Helm chart dependencies
echo "📦 Building Helm chart dependencies..."
helm dependency build ./helm/weather-api

# Install/Upgrade Helm chart
echo "📊 Installing/Upgrading Helm chart..."
helm upgrade --install ${RELEASE_NAME} ./helm/weather-api \
    --namespace ${NAMESPACE} \
    --create-namespace \
    --set image.tag=latest \
    --set service.type=NodePort \
    --set service.nodePort=30000 \
    --wait \
    --timeout 10m

# Wait for deployment
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s \
    deployment/${RELEASE_NAME} -n ${NAMESPACE}

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
echo "  kubectl port-forward -n ${NAMESPACE} svc/${RELEASE_NAME}-weather-api 8000:80"
echo "  Then visit: http://localhost:8000"
echo ""
echo "Prometheus:"
echo "  kubectl port-forward -n ${NAMESPACE} svc/${RELEASE_NAME}-prometheus-server 9090:9090"
echo "  Then visit: http://localhost:9090"
echo ""
echo "Grafana:"
echo "  kubectl port-forward -n ${NAMESPACE} svc/${RELEASE_NAME}-grafana 3000:80"
echo "  Then visit: http://localhost:3000 (admin/admin)"
echo ""
echo "🛑 To uninstall:"
echo "  helm uninstall ${RELEASE_NAME} -n ${NAMESPACE}"
echo ""
echo "🗑️  To delete the kind cluster:"
echo "  kind delete cluster --name ${CLUSTER_NAME}"
