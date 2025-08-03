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
echo "🐰 Setting up RabbitMQ in Kubernetes..."
if ! kubectl get pods -l app=rabbitmq --field-selector=status.phase=Running 2>/dev/null | grep -q rabbitmq; then
    echo "RabbitMQ not found in Kubernetes. Deploying RabbitMQ service..."
    cd ../../rabbit/manifests
    echo "Running RabbitMQ deployment script..."
    chmod +x deploy.sh
    ./deploy.sh
    cd ../../converter/manifests
    echo "✅ RabbitMQ service deployed to Kubernetes"
else
    echo "✅ RabbitMQ service is already running in Kubernetes"
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
    echo "  RabbitMQ Management UI: http://rabbitmq-manager.com (guest/guest)"
    echo "  Note: Add '127.0.0.1 rabbitmq-manager.com' to /etc/hosts"
    echo ""
fi

echo "🔍 For k9s monitoring:"
echo "  k9s"
echo ""
echo "📈 Queue monitoring:"
echo "  Check RabbitMQ Management UI for video/mp3 queue activity"
echo ""
echo "🛑 To stop local services:"
echo "  docker stop mongodb"
echo "  kubectl delete -f ../../rabbit/manifests/ (to stop RabbitMQ)" 