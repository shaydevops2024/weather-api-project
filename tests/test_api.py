"""
Integration tests for Weather Coordinates API.
These tests can run against a live API instance.
"""
import pytest
import httpx
import os

# Get API URL from environment or use default
API_URL = os.getenv("API_URL", "http://localhost:8000")


@pytest.fixture
def client():
    """Create an HTTP client for testing."""
    return httpx.Client(base_url=API_URL, timeout=30.0)


class TestHealthEndpoint:
    """Tests for the /health endpoint."""

    def test_health_returns_200(self, client):
        response = client.get("/health")
        assert response.status_code == 200

    def test_health_returns_healthy_status(self, client):
        response = client.get("/health")
        data = response.json()
        assert data["status"] == "healthy"
        assert "timestamp" in data


class TestRootEndpoint:
    """Tests for the / endpoint."""

    def test_root_returns_200(self, client):
        response = client.get("/")
        assert response.status_code == 200

    def test_root_returns_api_info(self, client):
        response = client.get("/")
        data = response.json()
        assert data["message"] == "Weather Coordinates API"
        assert "version" in data
        assert "endpoints" in data


class TestCoordinatesEndpoint:
    """Tests for the /coordinates endpoint."""

    def test_coordinates_returns_200(self, client):
        response = client.get("/coordinates")
        assert response.status_code == 200

    def test_coordinates_returns_all_cities(self, client):
        response = client.get("/coordinates")
        data = response.json()

        assert "data" in data
        cities = data["data"]

        # Check all required cities are present
        assert "tel-aviv" in cities
        assert "beer-sheva" in cities
        assert "jerusalem" in cities
        assert "szeged" in cities

    def test_coordinates_have_lat_long(self, client):
        response = client.get("/coordinates")
        data = response.json()

        for city_key, city_data in data["data"].items():
            assert "latitude" in city_data, f"{city_key} missing latitude"
            assert "longitude" in city_data, f"{city_key} missing longitude"
            assert isinstance(city_data["latitude"], (int, float))
            assert isinstance(city_data["longitude"], (int, float))

    def test_coordinates_caching(self, client):
        # First request
        response1 = client.get("/coordinates")
        data1 = response1.json()

        # Second request should be cached
        response2 = client.get("/coordinates")
        data2 = response2.json()

        assert data2.get("cached") is True


class TestCityCoordinatesEndpoint:
    """Tests for the /coordinates/{city} endpoint."""

    @pytest.mark.parametrize("city", ["tel-aviv", "beer-sheva", "jerusalem", "szeged"])
    def test_city_endpoint_returns_200(self, client, city):
        response = client.get(f"/coordinates/{city}")
        assert response.status_code == 200

    def test_city_returns_coordinates(self, client):
        response = client.get("/coordinates/tel-aviv")
        data = response.json()

        assert data["city"] == "tel-aviv"
        assert "data" in data
        assert "latitude" in data["data"]
        assert "longitude" in data["data"]

    def test_invalid_city_returns_404(self, client):
        response = client.get("/coordinates/invalid-city")
        assert response.status_code == 404

    def test_invalid_city_error_message(self, client):
        response = client.get("/coordinates/invalid-city")
        data = response.json()
        assert "detail" in data
        assert "not found" in data["detail"].lower()


class TestMetricsEndpoint:
    """Tests for the /metrics endpoint."""

    def test_metrics_returns_200(self, client):
        response = client.get("/metrics")
        assert response.status_code == 200

    def test_metrics_returns_prometheus_format(self, client):
        response = client.get("/metrics")
        content = response.text

        # Check for expected Prometheus metrics
        assert "api_requests_total" in content
        assert "api_request_duration_seconds" in content

    def test_metrics_content_type(self, client):
        response = client.get("/metrics")
        assert "text/plain" in response.headers.get("content-type", "")
