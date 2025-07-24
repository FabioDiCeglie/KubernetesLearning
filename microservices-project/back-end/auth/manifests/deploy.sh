#!/bin/bash

# This is how it works in real production!
# Environment variables can be set by:
# 1. CI/CD pipeline (Jenkins, GitLab, GitHub Actions)
# 2. Cloud provider secrets (AWS Secrets Manager, Azure Key Vault)
# 3. External secret operators
# 4. Manual export for local development

echo "🚀 Deploying Auth Service to Kubernetes"

# For LOCAL development (you can override these):
export MYSQL_HOST="host.minikube.internal"
export MYSQL_USER="auth_user"
export MYSQL_DB="auth"
export MYSQL_PASSWORD="auth_password"
export JWT_SECRET="your-super-secret-jwt-key-change-this-in-production"

echo "📋 Using configuration:"
echo "  MYSQL_HOST: $MYSQL_HOST"
echo "  MYSQL_USER: $MYSQL_USER"
echo "  MYSQL_DB: $MYSQL_DB"
echo "  (Secrets are hidden for security)"

# Setup local MySQL using Docker
echo "🗄️  Setting up local MySQL database..."

# Check if MySQL container is already running
if [ "$(docker ps -q -f name=mysql)" ]; then
    echo "MySQL container 'mysql' is already running"
else
    echo "Starting MySQL container..."
    
    # Remove existing container if it exists but is stopped
    docker rm -f mysql 2>/dev/null || true
    
    # Start MySQL container
    docker run -d \
        --name mysql \
        -e MYSQL_ROOT_PASSWORD=rootpassword \
        -e MYSQL_DATABASE=$MYSQL_DB \
        -e MYSQL_USER=$MYSQL_USER \
        -e MYSQL_PASSWORD=$MYSQL_PASSWORD \
        -v "$(pwd)/../init.sql:/docker-entrypoint-initdb.d/init.sql" \
        -p 3306:3306 \
        mysql:8.0
    
    echo "Waiting for MySQL to be ready..."
    # Wait for MySQL to be ready (max 60 seconds)
    for i in {1..60}; do
        if docker exec mysql mysqladmin ping --silent; then
            echo "MySQL is ready!"
            break
        fi
        echo "Waiting for MySQL... ($i/60)"
        sleep 1
    done
    
    if [ $i -eq 60 ]; then
        echo "❌ MySQL failed to start within 60 seconds"
        exit 1
    fi
fi

echo "✅ MySQL is running and accessible on localhost:3306"

# Build and push the latest Docker image
echo "🔨 Building and pushing Docker image..."
cd ..
echo "Building image fabiodiceglie/auth:latest..."
docker build -t fabiodiceglie/auth:latest .
echo "Pushing image to Docker Hub..."
docker push fabiodiceglie/auth:latest
cd manifests

# Apply manifests with proper environment variable substitution
echo "🔧 Generating and applying manifests with environment variables..."
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
echo "🗄️  MySQL connection info:"
echo "  Host: localhost:3306"
echo "  Database: $MYSQL_DB"
echo "  User: $MYSQL_USER"
echo "  Connect: mysql -h localhost -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DB"
echo ""
echo "🔍 For k9s monitoring:"
echo "  k9s"
