#!/bin/bash

echo "🚀 Starting Authentication Service with Docker Compose..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Build and start all services
echo "🐳 Building and starting all services..."
docker-compose up -d --build

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 5

# Check if services are running
echo "📊 Service status:"
docker-compose ps

echo ""
echo "🎉 Services are starting! You can:"
echo "   - Access the Flask app at: http://localhost:8000"
echo "   - Check logs with: docker-compose logs -f"
echo "   - Test the API with: curl -X POST http://localhost:8000/login -u \"ftestf9@gmail.com:test\""
echo ""
echo "To stop all services: make stop" 