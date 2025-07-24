#!/bin/bash

# This is how it works in real production!
# Environment variables can be set by:
# 1. CI/CD pipeline (Jenkins, GitLab, GitHub Actions)
# 2. Cloud provider secrets (AWS Secrets Manager, Azure Key Vault)
# 3. External secret operators
# 4. Manual export for local development

echo "🚀 Deploying RabbitMQ Service to Kubernetes"

# Note: RabbitMQ uses the official Docker image, no build needed
echo "🔨 Using official RabbitMQ image: rabbitmq:3-management"

# Apply manifests with proper environment variable substitution
echo "🔧 Generating and applying manifests with environment variables..."
envsubst < configmap.yaml | kubectl apply -f -
envsubst < secret.yaml | kubectl apply -f -

# Apply the StatefulSet and service
echo "🚢 Deploying application..."
kubectl apply -f statefulset.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
kubectl apply -f pvc.yaml

# Wait for the StatefulSet to be ready
echo "⏳ Waiting for RabbitMQ to be ready..."
kubectl rollout status statefulset/rabbitmq --timeout=300s

echo "✅ Deployment complete!"
echo ""
echo "📊 Check status:"
echo "  kubectl get pods -l app=rabbitmq"
echo "  kubectl get svc rabbitmq"
echo "  kubectl get pvc rabbitmq-pvc"
echo "  kubectl logs -l app=rabbitmq"
echo ""
echo "🌐 Access RabbitMQ:"
echo "  Add to /etc/hosts: 127.0.0.1 rabbitmq-manager.com"
echo "  Then visit: http://rabbitmq-manager.com (username: guest/password: guest) to see the management UI"
echo ""
echo "🔍 For k9s monitoring:"
echo "  k9s" 