# Weather API - Step 2: Helm & Local Kubernetes

Building on step1, this branch adds Helm charts and plain K8s manifests for deploying to a local Kubernetes cluster using kind.

## What's in this branch

- Everything from step1 (Docker, Prometheus, Grafana)
- Helm chart for the weather API (with Prometheus & Grafana as subcharts)
- Plain Kubernetes manifests (`k8s/`)
- kind configuration for local K8s cluster
- Deployment scripts (`deploy_helm.sh`, `deploy_k8s.sh`)

## Prerequisites

- Docker
- kubectl
- Helm
- kind (Kubernetes in Docker)

## Quick Start with Docker Compose

Same as step1 - just run:

```bash
docker compose up --build -d
```

## Deploy to Local Kubernetes

### Option 1: Helm (with monitoring)

```bash
./deploy_helm.sh
```

This will:
1. Create a kind cluster called `helm-local-weather-api-local`
2. Build and load the Docker image
3. Deploy the app with Prometheus and Grafana via Helm

### Option 2: Plain K8s manifests (app only)

```bash
./deploy_k8s.sh
```

## Testing with Helm Deployment

After running `./deploy_helm.sh`, start port-forwarding in separate terminals:

```bash
# Terminal 1 - API
kubectl port-forward -n helm-weather-api svc/weather-api 8000:80

# Terminal 2 - Prometheus
kubectl port-forward -n helm-weather-api svc/weather-api-prometheus-server 9090:9090

# Terminal 3 - Grafana
kubectl port-forward -n helm-weather-api svc/weather-api-grafana 3000:80
```

### Test the API

```bash
curl http://localhost:8000/health
curl http://localhost:8000/
curl http://localhost:8000/coordinates
curl http://localhost:8000/coordinates/tel-aviv
curl http://localhost:8000/metrics
```

Supported cities: tel-aviv, beer-sheva, jerusalem, szeged

### Test Prometheus

Verify Prometheus is scraping metrics correctly:

```bash
# Check Prometheus is running
curl -s http://localhost:9090/-/healthy
```

- **Targets (scrape status):** http://localhost:9090/targets
- **Graph (query metrics):** http://localhost:9090/graph

Run in the search bar `api_requests_total` and execute.

### Test Grafana

Verify Grafana is running and configured:

```bash
# Check Grafana health
curl -s http://localhost:3000/api/health | jq '.'

# List configured datasources (requires auth)
curl -s -u admin:admin http://localhost:3000/api/datasources | jq '.[].name'

# Verify Prometheus datasource connectivity
curl -s -u admin:admin http://localhost:3000/api/datasources/1/health | jq '.'

# List available dashboards
curl -s -u admin:admin http://localhost:3000/api/search | jq '.[].title'
```

## Cleanup

```bash
# Delete the Helm kind cluster
kind delete cluster --name helm-local-weather-api-local

# Or just uninstall the Helm release
helm uninstall weather-api -n helm-weather-api

# Delete the K8s kind cluster
kind delete cluster --name k8s-local-weather-api-local
```
