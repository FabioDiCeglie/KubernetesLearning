#!/bin/bash

# This is how it works in real production!
# Environment variables can be set by:
# 1. CI/CD pipeline (Jenkins, GitLab, GitHub Actions)
# 2. Cloud provider secrets (AWS Secrets Manager, Azure Key Vault)
# 3. External secret operators
# 4. Manual export for local development

echo "🚀 Deploying Gateway Service to Kubernetes"

# For LOCAL development (you can override these):
export MONGO_URI="mongodb://mongodb:27017/videos"
export AUTH_SERVICE_ADDRESS="auth:8000"

echo "📋 Using configuration:"
echo "  MONGO_URI: $MONGO_URI"
echo "  AUTH_SERVICE_ADDRESS: $AUTH_SERVICE_ADDRESS"

# Build and push the latest Docker image
echo "🔨 Building and pushing Docker image..."
cd ..
echo "Building image fabiodiceglie/gateway:latest..."
docker build -t fabiodiceglie/gateway:latest .
echo "Pushing image to Docker Hub..."
docker push fabiodiceglie/gateway:latest
cd manifests

# Check if we're running on minikube
if kubectl config current-context | grep -q minikube; then
    echo "🔍 Detected minikube environment"
    
    # Enable ingress addon if not already enabled
    echo "🔌 Ensuring ingress addon is enabled..."
    minikube addons enable ingress
    
    # Start minikube tunnel in background if not already running
    if ! pgrep -f "minikube tunnel" > /dev/null; then
        echo "🚇 Starting minikube tunnel in background..."
        minikube tunnel > /dev/null 2>&1 &
        echo "⚠️  Note: minikube tunnel is running in background. You might be prompted for sudo password."
        sleep 3
    else
        echo "✅ minikube tunnel is already running"
    fi
fi

# Generate the actual YAML files with environment variables
echo "🔧 Generating manifests with environment variables..."
envsubst < configmap.yaml | kubectl apply -f -
envsubst < secret.yaml | kubectl apply -f -

# Apply the deployment, service, and ingress
echo "🚢 Deploying application..."
kubectl apply -f ./

echo "✅ Deployment complete!"
echo ""
echo "📊 Check status:"
echo "  kubectl get pods -l app=gateway"
echo "  kubectl get svc gateway"
echo "  kubectl get ingress gateway-ingress"
echo "  kubectl logs -l app=gateway"
echo ""

if kubectl config current-context | grep -q minikube; then
    echo "🌐 Local minikube access:"
    echo "  Add to /etc/hosts: 127.0.0.1 mp3converter.com"
    echo "  Then access via: http://mp3converter.com"
    echo ""
    echo "💡 Alternative direct access:"
    GATEWAY_PORT=$(kubectl get svc gateway -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
    if [ ! -z "$GATEWAY_PORT" ]; then
        echo "  minikube service gateway --url"
    fi
    echo ""
fi

echo "🔍 For k9s monitoring:"
echo "  k9s"
echo ""
echo "🛑 To stop minikube tunnel:"
echo "  pkill -f 'minikube tunnel'"
