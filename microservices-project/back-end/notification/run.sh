#!/bin/bash

echo "🚀 Starting Notification Service with Docker Compose..."

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
sleep 10

# Check if services are running
echo "📊 Service status:"
docker-compose ps

echo ""
echo "🎉 Services are starting! You can:"
echo "   - Check notification logs with: docker-compose logs -f notification"
echo "   - Access RabbitMQ Management at: http://localhost:15672 (guest/guest)"
echo "   - View all logs with: docker-compose logs -f"
echo "   - Monitor mp3 processing queue in RabbitMQ UI"
echo ""
echo "To stop all services: docker-compose down / make clean" 