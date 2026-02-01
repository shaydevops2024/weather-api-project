# Weather API - Step 3: GitLab CI/CD Pipeline

Building on step1 and step2, this branch adds a GitLab CI/CD pipeline that builds, deploys, and tests the application automatically.

## What's in this branch

- Everything from step1 & step2
- GitLab CI/CD pipeline (`.gitlab-ci.yml`)
- Integration tests (`tests/test_api.py`)

## Prerequisites

- Docker
- kubectl
- Helm
- kind
- GitLab repository (for CI/CD)

## Pipeline Overview

The pipeline runs on every push and has these stages:

```
test -> build -> integration-test
```

| Stage | What it does |
|-------|--------------|
| `lint` | Runs flake8 and black |
| `unit-test` | Runs pytest |
| `build-and-deploy` | Creates kind cluster, builds image, deploys with Helm |
| `integration-test` | Deploys fresh and runs endpoint tests |

## Local Development

```bash
# Docker Compose (quickest)
docker compose up --build -d

# Or deploy to local kind cluster
./deploy_helm.sh
```

## Run Tests Locally

### pytest

```bash
# Install test dependencies
pip install pytest pytest-asyncio httpx

# Run tests (start the API first)
docker compose up -d
pytest tests/ -v
```

### Testing with Helm Deployment

After running `./deploy_helm.sh`, the Weather API is available at `http://localhost:8000` via NodePort. For Prometheus and Grafana, start port-forwarding in separate terminals:

```bash
# Terminal 1 - Prometheus
kubectl port-forward -n helm-weather-api svc/weather-api-prometheus-server 9090:9090

# Terminal 2 - Grafana
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

## Integration Tests

The pipeline tests these endpoints:
- `/health` - returns healthy status
- `/` - returns API info
- `/coordinates` - returns all 4 cities
- `/coordinates/tel-aviv` - returns single city coordinates
- `/coordinates/jerusalem` - returns single city coordinates
- `/metrics` - Prometheus metrics
- Invalid city returns 404
- Cache verification - second request returns cached data

## Cleanup

```bash
# Delete the Helm kind cluster
kind delete cluster --name helm-local-weather-api-local

# Delete the K8s kind cluster
kind delete cluster --name k8s-local-weather-api-local
```

