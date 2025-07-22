#!/bin/bash

# This is how it works in real production!
# Environment variables can be set by:
# 1. CI/CD pipeline (Jenkins, GitLab, GitHub Actions)
# 2. Cloud provider secrets (AWS Secrets Manager, Azure Key Vault)
# 3. External secret operators
# 4. Manual export for local development

echo "🚀 Deploying Auth Service to Kubernetes"

# For LOCAL development (you can override these):
export MONGO_URI="mongodb://mongodb:27017/videos"
export AUTH_SERVICE_ADDRESS="auth:8000"

echo "📋 Using configuration:"
echo "  MONGO_URI: $MONGO_URI"
echo "  AUTH_SERVICE_ADDRESS: $AUTH_SERVICE_ADDRESS"

# Generate the actual YAML files with environment variables
echo "🔧 Generating manifests with environment variables..."
envsubst < configmap.yaml | kubectl apply -f -
envsubst < secret.yaml | kubectl apply -f -

# Apply the deployment and service
echo "🚢 Deploying application..."
kubectl apply -f deploy.yaml
kubectl apply -f service.yaml

echo "✅ Deployment complete!"
echo ""
echo "📊 Check status:"
echo "  kubectl get pods -l app=gateway"
echo "  kubectl logs -l app=gateway"
echo ""
echo "🔍 For k9s monitoring:"
echo "  k9s"
