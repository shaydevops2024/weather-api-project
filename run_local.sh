#!/bin/bash

# Script to run the weather API locally with Docker Compose

echo "🚀 Starting Weather API with monitoring stack..."

# Build and start containers
docker compose up --build -d

echo "⏳ Waiting for services to be ready..."
sleep 10

# Check if services are running
echo ""
echo "📊 Service Status:"
docker compose ps

echo ""
echo "✅ Services are up and running!"
echo ""
echo "🔗 Access the services:"
echo "   Weather API:  http://localhost:8000"
echo "   API Docs:     http://localhost:8000/docs"
echo "   Prometheus:   http://localhost:9090"
echo "   Grafana:      http://localhost:3000 (admin/admin)"
echo ""
echo "📈 API Endpoints:"
echo "   GET /              - API information"
echo "   GET /health        - Health check"
echo "   GET /coordinates   - All city coordinates"
echo "   GET /coordinates/{city} - Specific city coordinates"
echo "   GET /metrics       - Prometheus metrics"
echo ""
echo "🛑 To stop: docker-compose down"
echo "📜 To view logs: docker-compose logs -f"
