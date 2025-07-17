.PHONY: run stop logs build clean test help

# Default target
run:
	@echo "🚀 Starting Gateway Service..."
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
	@sleep 5
	@echo "Testing health endpoint..."
	@RESPONSE=$$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health) && \
	if [ "$$RESPONSE" = "204" ]; then \
		echo "✅ Health check passed - Gateway is running"; \
		echo "Testing login endpoint..."; \
		LOGIN_RESPONSE=$$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8080/login -u "test@test.com:test"); \
		if [ "$$LOGIN_RESPONSE" = "200" ] || [ "$$LOGIN_RESPONSE" = "401" ]; then \
			echo "✅ Login endpoint is responsive (status: $$LOGIN_RESPONSE)"; \
		else \
			echo "❌ Login endpoint test failed - Status: $$LOGIN_RESPONSE"; \
		fi \
	else \
		echo "❌ Health check failed - Status: $$RESPONSE"; \
	fi || echo "❌ Test failed - make sure services are running"

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
	@echo "  k8s-clean  - Remove from Kubernetes"
	@echo "  help     - Show this help"

# Kubernetes deployment targets
k8s-deploy:
	@echo "🚀 Deploying to Kubernetes..."
	@cd manifests && chmod +x deploy.sh && ./deploy.sh

k8s-status:
	@echo "📊 Kubernetes deployment status:"
	@echo "Pods:"
	@kubectl get pods -l app=gateway
	@echo ""
	@echo "Services:"
	@kubectl get svc -l app=gateway
	@echo ""
	@echo "ConfigMaps:"
	@kubectl get configmap gateway-configmap
	@echo ""
	@echo "Secrets:"
	@kubectl get secret gateway-secret

k8s-logs:
	@echo "📋 Showing Kubernetes pod logs..."
	@kubectl logs -l app=gateway --tail=50 -f

k8s-clean:
	@echo "🧹 Cleaning up Kubernetes resources..."
	@kubectl delete deployment gateway || true
	@kubectl delete service gateway-service || true
	@kubectl delete configmap gateway-configmap || true
	@kubectl delete secret gateway-secret || true
	@echo "✅ Kubernetes cleanup complete"

k8s-context:
	@echo "🔍 Current Kubernetes context:"
	@kubectl config current-context
	@echo ""
	@echo "Cluster info:"
	@kubectl cluster-info 