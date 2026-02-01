# Weather API

A FastAPI service that returns geographic coordinates for cities. Includes Docker packaging, Kubernetes deployment via Helm, monitoring with Prometheus/Grafana, and GitLab CI/CD.

## Features

- FastAPI application with caching
- Docker + Docker Compose
- Helm charts for Kubernetes (with Prometheus & Grafana as subcharts)
- Plain Kubernetes manifests (`k8s/`)
- Prometheus metrics & Grafana dashboards
- GitLab CI/CD pipeline with integration tests

## Prerequisites

- Docker & Docker Compose
- kubectl & Helm
- kind (for local K8s)

## Quick Start

### Option 1: Docker Compose (fastest)

```bash
docker compose up --build -d
```

- API: http://localhost:8000
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin/admin)

### Option 2: Local Kubernetes

```bash
./deploy_helm.sh
```

Then port-forward:
```bash
kubectl port-forward -n helm-weather-api svc/weather-api 8000:80
```

## Test the API

```bash
curl http://localhost:8000/health
curl http://localhost:8000/
curl http://localhost:8000/coordinates
curl http://localhost:8000/coordinates/tel-aviv
curl http://localhost:8000/metrics
```

Supported cities: tel-aviv, beer-sheva, jerusalem, szeged

## Run Tests

```bash
pip install pytest pytest-asyncio httpx
pytest tests/ -v
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

## CI/CD Pipeline

The GitLab pipeline runs on every push:
1. **lint** - flake8 + black
2. **unit-test** - pytest
3. **build-and-deploy** - builds and deploys to kind cluster
4. **integration-test** - tests all endpoints

## Branch Structure

| Branch | Contents |
|--------|----------|
| `step1` | Docker + Monitoring |
| `step2` | + Helm charts & K8s manifests |
| `step3` | + GitLab CI/CD & tests |
| `main` | Everything |

## Cleanup

```bash
docker compose down
# or
kind delete cluster --name helm-local-weather-api-local
```

