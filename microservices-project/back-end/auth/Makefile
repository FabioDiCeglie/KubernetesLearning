.PHONY: run stop logs build clean test k8s-test help

# Default target
run:
	@echo "🚀 Starting Authentication Service..."
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
	@RESPONSE=$$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health) && \
	if [ "$$RESPONSE" = "204" ]; then \
		echo "✅ Health check passed - Auth service is running"; \
		echo "Testing login endpoint..."; \
		LOGIN_CODE=$$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8000/login -u "test@test.com:test"); \
		if [ "$$LOGIN_CODE" = "200" ]; then \
			echo "✅ Login test passed - JWT token received"; \
			echo "Testing validate endpoint..."; \
			TOKEN=$$(curl -s -X POST http://localhost:8000/login -u "test@test.com:test"); \
			VALIDATE_CODE=$$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8000/validate -H "Authorization: Bearer $$TOKEN"); \
			if [ "$$VALIDATE_CODE" = "200" ]; then \
				echo "✅ Validate test passed - Token validated successfully"; \
			else \
				echo "❌ Validate test failed - Status: $$VALIDATE_CODE"; \
			fi \
		else \
			echo "❌ Login test failed - Status: $$LOGIN_CODE"; \
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
	@echo "  k8s-test   - Test the API in Kubernetes"
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
	@kubectl get pods -l app=auth
	@echo ""
	@echo "Services:"
	@kubectl get svc -l app=auth
	@echo ""
	@echo "ConfigMaps:"
	@kubectl get configmap auth-configmap
	@echo ""
	@echo "Secrets:"
	@kubectl get secret auth-secret

# Test the API in Kubernetes
k8s-test:
	@echo "🧪 Testing API in Kubernetes..."
	@echo "🔌 Setting up port-forward to auth service..."
	@kubectl port-forward service/auth 8000:8000 > /dev/null 2>&1 & \
	PORT_FORWARD_PID=$$!; \
	sleep 5; \
	echo "Testing health endpoint..."; \
	RESPONSE=$$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health) && \
	if [ "$$RESPONSE" = "204" ]; then \
		echo "✅ Health check passed - Auth service is running in Kubernetes"; \
		echo "Testing login endpoint..."; \
		LOGIN_CODE=$$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8000/login -u "test@test.com:test"); \
		if [ "$$LOGIN_CODE" = "200" ]; then \
			echo "✅ Login test passed - JWT token received"; \
			echo "Testing validate endpoint..."; \
			TOKEN=$$(curl -s -X POST http://localhost:8000/login -u "test@test.com:test"); \
			VALIDATE_CODE=$$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8000/validate -H "Authorization: Bearer $$TOKEN"); \
			if [ "$$VALIDATE_CODE" = "200" ]; then \
				echo "✅ Validate test passed - Token validated successfully"; \
			else \
				echo "❌ Validate test failed - Status: $$VALIDATE_CODE"; \
			fi \
		else \
			echo "❌ Login test failed - Status: $$LOGIN_CODE"; \
		fi \
	else \
		echo "❌ Health check failed - Status: $$RESPONSE"; \
	fi || echo "❌ Test failed - make sure auth service is deployed and running"; \
	echo "🔌 Cleaning up port-forward..."; \
	kill $$PORT_FORWARD_PID > /dev/null 2>&1 || true


k8s-logs:
	@echo "📋 Showing Kubernetes pod logs..."
	@kubectl logs -l app=auth --tail=50 -f

k8s-clean:
	@echo "🧹 Cleaning up Kubernetes resources..."
	@kubectl delete deployment auth || true
	@kubectl delete service auth-service || true
	@kubectl delete configmap auth-configmap || true
	@kubectl delete secret auth-secret || true
	@echo "✅ Kubernetes cleanup complete"

k8s-context:
	@echo "🔍 Current Kubernetes context:"
	@kubectl config current-context
	@echo ""
	@echo "Cluster info:"
	@kubectl cluster-info