#!/bin/bash

# This is how it works in real production!
# Environment variables can be set by:
# 1. CI/CD pipeline (Jenkins, GitLab, GitHub Actions)
# 2. Cloud provider secrets (AWS Secrets Manager, Azure Key Vault)
# 3. External secret operators
# 4. Manual export for local development

echo "🚀 Deploying Converter Service to Kubernetes"

# For LOCAL development (you can override these by setting environment variables):
export VIDEO_QUEUE="${VIDEO_QUEUE:-video}"
export MP3_QUEUE="${MP3_QUEUE:-mp3}"

echo "📋 Using configuration:"
echo "  VIDEO_QUEUE: $VIDEO_QUEUE"
echo "  MP3_QUEUE: $MP3_QUEUE"

# Start MongoDB locally for Kubernetes pods to access via host.minikube.internal
echo "🍃 Setting up MongoDB locally..."
if ! docker ps | grep -q mongodb; then
    echo "Starting MongoDB container..."
    docker run -d --name mongodb -p 27017:27017 -v mongodb_data:/data/db mongo:7.0
    echo "⏳ Waiting for MongoDB to be ready..."
    sleep 10
    echo "✅ MongoDB is running on localhost:27017"
else
    echo "✅ MongoDB container is already running"
fi

# Check if RabbitMQ is running and start if needed
echo "🐰 Setting up RabbitMQ locally..."
if ! docker ps | grep -q rabbitmq; then
    echo "Starting RabbitMQ container..."
    docker run -d --name rabbitmq -p 5672:5672 -p 15672:15672 \
        -e RABBITMQ_DEFAULT_USER=guest \
        -e RABBITMQ_DEFAULT_PASS=guest \
        -v rabbitmq_data:/var/lib/rabbitmq \
        rabbitmq:3.12-management
    echo "⏳ Waiting for RabbitMQ to be ready..."
    sleep 15
    echo "✅ RabbitMQ is running on localhost:5672 (Management UI: localhost:15672)"
else
    echo "✅ RabbitMQ container is already running"
fi

# Build and push the latest Docker image
echo "🔨 Building and pushing Docker image..."
cd ..
echo "Building image fabiodiceglie/converter:latest..."
docker build -t fabiodiceglie/converter:latest .
echo "Pushing image to Docker Hub..."
docker push fabiodiceglie/converter:latest
cd manifests

# Check if we're running on minikube
if kubectl config current-context | grep -q minikube; then
    echo "🔍 Detected minikube environment"
fi

# Apply manifests with proper environment variable substitution
echo "🔧 Generating and applying manifests with environment variables..."
envsubst < configmap.yaml | kubectl apply -f -
envsubst < secret.yaml | kubectl apply -f -

# Apply the deployment (converter is a background worker, no service/ingress needed)
echo "🚢 Deploying application..."
kubectl apply -f deploy.yaml

echo "✅ Deployment complete!"
echo ""
echo "📊 Check status:"
echo "  kubectl get pods -l app=converter"
echo "  kubectl logs -l app=converter"
echo ""

echo "🔍 Monitor processing:"
echo "  kubectl logs -l app=converter -f  # Follow logs in real-time"
echo ""

if kubectl config current-context | grep -q minikube; then
    echo "🌐 Local services access:"
    echo "  MongoDB: localhost:27017"
    echo "  RabbitMQ Management UI: http://localhost:15672 (guest/guest)"
    echo ""
fi

echo "🔍 For k9s monitoring:"
echo "  k9s"
echo ""
echo "📈 Queue monitoring:"
echo "  Check RabbitMQ Management UI for video/mp3 queue activity"
echo ""
echo "🛑 To stop local services:"
echo "  docker stop mongodb rabbitmq" 