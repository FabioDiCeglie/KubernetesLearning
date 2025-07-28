.PHONY: run stop logs build clean test help

# Default target
run:
	@echo "🚀 Starting Converter Service..."
	@chmod +x run.sh
	@./run.sh

# Stop all services
stop:
	@echo "🛑 Stopping all services..."
	@docker-compose down

# View logs
logs:
	@echo "📋 Showing logs..."
	@docker-compose logs -f

# Build images
build:
	@echo "🔨 Building images..."
	@docker-compose build

# Clean up everything (containers, images, volumes)
clean:
	@echo "🧹 Cleaning up..."
	@docker-compose down -v --rmi all

# Test the API
test:
	@echo "🧪 Testing API..."

# Restart services
restart: stop run

# Show service status
status:
	@echo "📊 Service status:"
	@docker-compose ps

# Show help
help:
	@echo "Available targets:"
	@echo "  run      - Start all services"
	@echo "  stop     - Stop all services"
	@echo "  logs     - Show service logs"
	@echo "  build    - Build Docker images"
	@echo "  clean    - Clean up everything"
	@echo "  test     - Test the API"
	@echo "  restart  - Restart services"
	@echo "  status   - Show service status"
	@echo "  k8s-deploy - Deploy to Kubernetes"
	@echo "  k8s-status - Check Kubernetes deployment status"
	@echo "  k8s-logs   - Show Kubernetes pod logs"
	@echo "  k8s-test   - Test Kubernetes deployment via ingress"
	@echo "  k8s-clean  - Remove from Kubernetes"
	@echo "  help     - Show this help"

# Kubernetes deployment targets
k8s-deploy:
	@echo "🚀 Deploying to Kubernetes..."
	@cd manifests && chmod +x deploy.sh && ./deploy.sh

k8s-status:
	@echo "📊 Kubernetes deployment status:"
	@echo "Pods:"
	@kubectl get pods -l app=converter
	@echo ""
	@echo "Services:"
	@kubectl get svc -l app=converter
	@echo ""
	@echo "ConfigMaps:"
	@kubectl get configmap converter-configmap
	@echo ""
	@echo "Secrets:"
	@kubectl get secret converter-secret

k8s-logs:
	@echo "📋 Showing Kubernetes pod logs..."
	@kubectl logs -l app=converter --tail=50 -f

k8s-test:
	@echo "🧪 Testing Kubernetes deployment via ingress..."

k8s-clean:
	@echo "🧹 Cleaning up Kubernetes resources..."
	@kubectl delete deployment converter || true
	@kubectl delete service converter-service || true
	@kubectl delete configmap converter-configmap || true
	@kubectl delete secret converter-secret || true
	@echo "🧹 Cleaning up RabbitMQ Docker container and volume..."
	@docker stop rabbitmq 2>/dev/null || true
	@docker rm rabbitmq 2>/dev/null || true
	@docker volume rm rabbitmq_data 2>/dev/null || true
	@echo "✅ Kubernetes and RabbitMQ cleanup complete"

k8s-context:
	@echo "🔍 Current Kubernetes context:"
	@kubectl config current-context
	@echo ""
	@echo "Cluster info:"
	@kubectl cluster-info 