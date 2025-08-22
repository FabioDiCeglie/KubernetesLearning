#!/bin/bash

echo "🔐 Setting up Google Secret Manager for Auth Service"
echo "=================================================="

# Check if PROJECT_ID is set
if [ -z "$PROJECT_ID" ]; then
    echo "❌ PROJECT_ID environment variable is not set"
    echo "Please run: export PROJECT_ID=video-converter-469811"
    exit 1
fi

echo "📋 Project ID: $PROJECT_ID"
echo ""

# Enable Secret Manager API
echo "🔧 Enabling Secret Manager API..."
gcloud services enable secretmanager.googleapis.com

echo ""
echo "🔑 Creating secrets in Secret Manager..."
echo "You'll be prompted to enter values for each secret:"

# Create MySQL password
echo ""
echo -n "Enter MySQL password for auth_user: "
read -s MYSQL_PASSWORD
echo ""
echo -n "$MYSQL_PASSWORD" | gcloud secrets create mysql-password --data-file=-

# Create JWT secret
echo ""
echo -n "Enter JWT secret key: "
read -s JWT_SECRET
echo ""
echo -n "$JWT_SECRET" | gcloud secrets create jwt-secret --data-file=-

# Create MySQL root password
echo ""
echo -n "Enter MySQL root password: "
read -s MYSQL_ROOT_PASSWORD
echo ""
echo -n "$MYSQL_ROOT_PASSWORD" | gcloud secrets create mysql-root-password --data-file=-

echo ""
echo "🔧 Creating Google Service Account..."
gcloud iam service-accounts create auth-secrets-sa \
    --display-name="Auth Service Account for Secret Manager"

echo ""
echo "🔐 Granting Secret Manager access..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:auth-secrets-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"

echo ""
echo "🔗 Setting up Workload Identity..."
gcloud iam service-accounts add-iam-policy-binding \
    auth-secrets-sa@$PROJECT_ID.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:$PROJECT_ID.svc.id.goog[microservices/auth-service-account]"

echo ""
echo "✅ Secret Manager setup complete!"
echo ""
echo "📋 Created secrets:"
gcloud secrets list --filter="name:mysql-password OR name:jwt-secret OR name:mysql-root-password"

echo ""
echo "🚀 You can now run: ./deploy.sh"
