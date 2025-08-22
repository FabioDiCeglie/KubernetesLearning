#!/bin/bash

echo "🚀 Deploying Auth Service to GKE..."

# Check if kubectl is configured
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo "❌ kubectl is not configured or cluster is not accessible"
    echo "Please run: gcloud container clusters get-credentials microservices-cluster --zone=us-central1-a"
    exit 1
fi

# Check if PROJECT_ID is set
if [ -z "$PROJECT_ID" ]; then
    echo "❌ PROJECT_ID environment variable is not set"
    echo "Please run: export PROJECT_ID=your-microservices-project"
    exit 1
fi

echo "📊 Current cluster info:"
kubectl cluster-info

echo ""
echo "🐳 Building and pushing Docker image..."

# Configure Docker to use gcloud as a credential helper
echo "Configuring Docker for Google Container Registry..."
gcloud auth configure-docker gcr.io --quiet

cd ../
echo "Building auth service Docker image for linux/amd64..."
docker build --platform linux/amd64 -t gcr.io/$PROJECT_ID/auth:latest .

echo "Pushing image to Google Container Registry..."
docker push gcr.io/$PROJECT_ID/auth:latest

echo "✅ Docker image pushed successfully!"
cd gke-manifests/

echo ""
echo "🗃️  Creating namespace..."
kubectl apply -f namespace.yaml

echo ""
echo "🔐 Checking Secret Manager prerequisites..."

# Check if all required secrets exist
REQUIRED_SECRETS=("mysql-password" "jwt-secret" "mysql-root-password" "mysql-database" "mysql-user")
MISSING_SECRETS=()

for secret in "${REQUIRED_SECRETS[@]}"; do
    if ! gcloud secrets describe "$secret" > /dev/null 2>&1; then
        MISSING_SECRETS+=("$secret")
    fi
done

if [ ${#MISSING_SECRETS[@]} -ne 0 ]; then
    echo "❌ Missing required secrets in Google Secret Manager:"
    for secret in "${MISSING_SECRETS[@]}"; do
        echo "   - $secret"
    done
    echo ""
    echo "🔧 Please create the missing secrets first:"
    echo "   Run: ./setup-secrets.sh"
    echo "   Or create them manually with: gcloud secrets create <secret-name> --data-file=-"
    exit 1
fi

echo "✅ All required secrets found:"
for secret in "${REQUIRED_SECRETS[@]}"; do
    echo "   ✓ $secret"
done

echo ""
echo "🔐 Creating Kubernetes secrets from Google Secret Manager..."
kubectl create secret generic auth-secret -n microservices \
  --from-literal=MYSQL_PASSWORD="$(gcloud secrets versions access latest --secret=mysql-password)" \
  --from-literal=JWT_SECRET="$(gcloud secrets versions access latest --secret=jwt-secret)" \
  --from-literal=MYSQL_USER="$(gcloud secrets versions access latest --secret=mysql-user)" \
  --from-literal=MYSQL_DB="$(gcloud secrets versions access latest --secret=mysql-database)" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic mysql-secret -n microservices \
  --from-literal=MYSQL_ROOT_PASSWORD="$(gcloud secrets versions access latest --secret=mysql-root-password)" \
  --from-literal=MYSQL_PASSWORD="$(gcloud secrets versions access latest --secret=mysql-password)" \
  --from-literal=MYSQL_DATABASE="$(gcloud secrets versions access latest --secret=mysql-database)" \
  --from-literal=MYSQL_USER="$(gcloud secrets versions access latest --secret=mysql-user)" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Secrets created successfully!"

echo ""
echo "🔐 Deploying Auth service..."
kubectl apply -f configmap.yaml
kubectl apply -f deploy.yaml
kubectl apply -f service.yaml

echo ""
echo "⏳ Waiting for Auth service to be ready and secrets to be created..."
kubectl wait --for=condition=ready pod -l app=auth -n microservices --timeout=180s

echo ""
echo "🔍 Verifying secrets are created..."
kubectl get secrets -n microservices | grep -E "(auth-secret|mysql-secret)" || echo "⚠️  Secrets not yet available, continuing..."

echo ""
echo "🗄️  Setting up MySQL database..."
kubectl apply -f mysql-pvc.yaml
kubectl apply -f mysql-configmap.yaml
kubectl apply -f mysql-deploy.yaml
kubectl apply -f mysql-service.yaml

echo ""
echo "⏳ Waiting for MySQL to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql -n microservices --timeout=300s

echo ""
echo "📊 Deployment status:"
echo "Pods:"
kubectl get pods -n microservices -l app=auth
kubectl get pods -n microservices -l app=mysql

echo ""
echo "Services:"
kubectl get svc -n microservices

echo ""
echo "🎉 Auth Service deployed successfully!"
echo ""
echo "🧪 To test the auth service:"
echo "1. Port forward: kubectl port-forward svc/auth-service 8000:8000 -n microservices"
echo "2. Test health: curl http://localhost:8000/health"
echo "3. Test login: curl -u ftestf9@gmail.com:test -X POST http://localhost:8000/login"
echo ""
echo "📋 Useful commands:"
echo "- View logs: kubectl logs -f deployment/auth -n microservices"
echo "- View MySQL logs: kubectl logs -f deployment/mysql -n microservices"
echo "- Scale auth: kubectl scale deployment auth --replicas=3 -n microservices"
echo ""
echo "🗑️  To clean up:"
echo "kubectl delete -f . -n microservices"
