#!/bin/bash

# This is how it works in real production!
# Environment variables can be set by:
# 1. CI/CD pipeline (Jenkins, GitLab, GitHub Actions)
# 2. Cloud provider secrets (AWS Secrets Manager, Azure Key Vault)
# 3. External secret operators
# 4. Manual export for local development

echo "🚀 Deploying Auth Service to Kubernetes"

# For LOCAL development (you can override these):
export MYSQL_HOST="localhost"
export MYSQL_USER="auth_user"
export MYSQL_DB="auth"
export MYSQL_PORT=3306
export MYSQL_PASSWORD="auth_password"
export JWT_SECRET="your-super-secret-jwt-key-change-this-in-production"

echo "📋 Using configuration:"
echo "  MYSQL_HOST: $MYSQL_HOST"
echo "  MYSQL_USER: $MYSQL_USER"
echo "  MYSQL_DB: $MYSQL_DB"
echo "  MYSQL_PORT: $MYSQL_PORT"
echo "  (Secrets are hidden for security)"

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
echo "  kubectl get pods -l app=auth"
echo "  kubectl logs -l app=auth"
echo ""
echo "🔍 For k9s monitoring:"
echo "  k9s"
