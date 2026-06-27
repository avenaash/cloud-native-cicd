from fastapi import FastAPI
from fastapi.responses import JSONResponse
import time
import random

app = FastAPI(
    title="Cloud Native Demo API",
    description="A sample FastAPI application for CI/CD demonstration",
    version="1.0.0"
)

# Metrics storage (in production, use Prometheus client)
request_count = 0
error_count = 0

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Welcome to Cloud Native CI/CD Demo",
        "version": "1.0.0",
        "status": "healthy"
    }

@app.get("/health")
async def health_check():
    """Health check endpoint for Kubernetes probes"""
    return {
        "status": "healthy",
        "timestamp": time.time()
    }

@app.get("/api/users")
async def get_users():
    """Sample API endpoint"""
    global request_count
    request_count += 1
    
    # Simulate some processing time
    time.sleep(random.uniform(0.1, 0.5))
    
    users = [
        {"id": 1, "name": "Alice", "email": "alice@example.com"},
        {"id": 2, "name": "Bob", "email": "bob@example.com"},
        {"id": 3, "name": "Charlie", "email": "charlie@example.com"}
    ]
    
    return {
        "users": users,
        "total": len(users),
        "request_count": request_count
    }

@app.get("/api/metrics")
async def get_metrics():
    """Custom metrics endpoint"""
    return {
        "request_count": request_count,
        "error_count": error_count,
        "uptime_seconds": time.time()
    }

@app.get("/api/error")
async def simulate_error():
    """Endpoint to simulate errors for testing alerts"""
    global error_count
    error_count += 1
    return JSONResponse(
        status_code=500,
        content={"error": "Simulated error", "error_count": error_count}
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
