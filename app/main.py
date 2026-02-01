from fastapi import FastAPI, HTTPException
import httpx
from datetime import datetime
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from fastapi.responses import Response
import time

app = FastAPI(title="Weather Coordinates API", version="1.0.0")

# Prometheus metrics
REQUEST_COUNT = Counter(
    "api_requests_total", "Total API requests", ["endpoint", "method"]
)
REQUEST_LATENCY = Histogram(
    "api_request_duration_seconds", "Request latency", ["endpoint"]
)
CACHE_HITS = Counter("cache_hits_total", "Total cache hits")
CACHE_MISSES = Counter("cache_misses_total", "Total cache misses")

# Cache storage
cache = {"data": None, "timestamp": None, "ttl": 3600}  # 1 hour cache

CITIES = {
    "tel-aviv": "Tel Aviv",
    "beer-sheva": "Beersheba",
    "jerusalem": "Jerusalem",
    "szeged": "Szeged",
}


async def fetch_coordinates():
    """Fetch coordinates from Open-Meteo Geocoding API"""
    async with httpx.AsyncClient(timeout=30.0) as client:
        results = {}

        for city_key, city_name in CITIES.items():
            try:
                response = await client.get(
                    "https://geocoding-api.open-meteo.com/v1/search",
                    params={
                        "name": city_name,
                        "count": 1,
                        "language": "en",
                        "format": "json",
                    },
                )
                response.raise_for_status()
                data = response.json()

                if data.get("results"):
                    result = data["results"][0]
                    results[city_key] = {
                        "name": result.get("name"),
                        "latitude": result.get("latitude"),
                        "longitude": result.get("longitude"),
                        "country": result.get("country"),
                        "timezone": result.get("timezone"),
                    }
            except Exception as e:
                results[city_key] = {"error": str(e)}

        return results


def is_cache_valid():
    """Check if cache is still valid"""
    if cache["data"] is None or cache["timestamp"] is None:
        return False

    elapsed = (datetime.now() - cache["timestamp"]).total_seconds()
    return elapsed < cache["ttl"]


@app.get("/")
async def root():
    """Root endpoint with API information"""
    REQUEST_COUNT.labels(endpoint="/", method="GET").inc()
    return {
        "message": "Weather Coordinates API",
        "version": "1.0.0",
        "endpoints": {
            "/coordinates": "Get coordinates for all cities",
            "/coordinates/{city}": "Get coordinates for a specific city",
            "/health": "Health check endpoint",
            "/metrics": "Prometheus metrics",
        },
    }


@app.get("/health")
async def health():
    """Health check endpoint"""
    REQUEST_COUNT.labels(endpoint="/health", method="GET").inc()
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}


@app.get("/coordinates")
async def get_all_coordinates():
    """Get coordinates for all cities (cached)"""
    start_time = time.time()
    REQUEST_COUNT.labels(endpoint="/coordinates", method="GET").inc()

    if is_cache_valid():
        CACHE_HITS.inc()
        duration = time.time() - start_time
        REQUEST_LATENCY.labels(endpoint="/coordinates").observe(duration)
        return {
            "data": cache["data"],
            "cached": True,
            "cached_at": cache["timestamp"].isoformat(),
        }

    CACHE_MISSES.inc()

    # Fetch fresh data
    coordinates = await fetch_coordinates()

    # Update cache
    cache["data"] = coordinates
    cache["timestamp"] = datetime.now()

    duration = time.time() - start_time
    REQUEST_LATENCY.labels(endpoint="/coordinates").observe(duration)

    return {
        "data": coordinates,
        "cached": False,
        "fetched_at": cache["timestamp"].isoformat(),
    }


@app.get("/coordinates/{city}")
async def get_city_coordinates(city: str):
    """Get coordinates for a specific city"""
    start_time = time.time()
    REQUEST_COUNT.labels(endpoint=f"/coordinates/{city}", method="GET").inc()

    city_lower = city.lower()

    if city_lower not in CITIES:
        raise HTTPException(
            status_code=404,
            detail=f"City '{city}' not found. Available cities: {', '.join(CITIES.keys())}",
        )

    # Ensure cache is populated
    if not is_cache_valid():
        CACHE_MISSES.inc()
        coordinates = await fetch_coordinates()
        cache["data"] = coordinates
        cache["timestamp"] = datetime.now()
    else:
        CACHE_HITS.inc()

    duration = time.time() - start_time
    REQUEST_LATENCY.labels(endpoint=f"/coordinates/{city}").observe(duration)

    return {
        "city": city_lower,
        "data": cache["data"].get(city_lower, {}),
        "cached": True,
        "cached_at": cache["timestamp"].isoformat(),
    }


@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)
