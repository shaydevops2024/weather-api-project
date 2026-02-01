# Weather API - Step 1: Dockerization & Monitoring

A FastAPI service that returns coordinates for cities, packaged with Docker and monitored via Prometheus and Grafana.

## What's in this branch

- Dockerized FastAPI application
- Prometheus for metrics collection
- Grafana for visualization
- Docker Compose for local development

## Prerequisites

- Docker
- Docker Compose

## Quick Start

```bash
# Start everything
docker compose up --build -d

# Check it's running
docker compose ps
```

Services will be available at:
- API: http://localhost:8000
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin/admin)

## Test the API

```bash
curl http://localhost:8000/health
curl http://localhost:8000/
curl http://localhost:8000/coordinates
curl http://localhost:8000/coordinates/tel-aviv
curl http://localhost:8000/metrics
```

Supported cities: tel-aviv, beer-sheva, jerusalem, szeged

## Test Prometheus

Verify Prometheus is scraping metrics correctly:

```bash
# Check Prometheus is running
curl -s http://localhost:9090/-/healthy
```

- **Targets (scrape status):** http://localhost:9090/targets
- **Graph (query metrics):** http://localhost:9090/graph

Run in the search bar `api_requests_total` and execute.

## Test Grafana

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

## Stop

```bash
docker compose down
```
