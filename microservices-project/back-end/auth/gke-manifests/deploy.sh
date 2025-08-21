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
echo "🗃️  Creating namespace..."
kubectl apply -f namespace.yaml

echo ""
echo "🗄️  Setting up MySQL database..."
kubectl apply -f mysql-pvc.yaml
kubectl apply -f mysql-configmap.yaml
kubectl apply -f mysql-secret.yaml
kubectl apply -f mysql-deploy.yaml
kubectl apply -f mysql-service.yaml

echo ""
echo "⏳ Waiting for MySQL to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql -n microservices --timeout=300s

echo ""
echo "🔐 Deploying Auth service..."
# Update the image in deploy.yaml with the actual project ID
sed "s/YOUR_PROJECT_ID/$PROJECT_ID/g" deploy.yaml > deploy-updated.yaml

kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
kubectl apply -f deploy-updated.yaml
kubectl apply -f service.yaml

echo ""
echo "⏳ Waiting for Auth service to be ready..."
kubectl wait --for=condition=ready pod -l app=auth -n microservices --timeout=180s

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

# Clean up temporary file
rm -f deploy-updated.yaml
