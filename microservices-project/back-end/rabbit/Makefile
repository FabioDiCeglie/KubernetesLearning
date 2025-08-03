.PHONY: run stop logs build clean test help

# Default target
run:
	@echo "🚀 Starting RabbitMQ Service..."
	@echo "🐰 RabbitMQ uses the official Docker image"
	@echo "💡 Use 'make k8s-deploy' to deploy to Kubernetes"
	@echo "💡 Or run RabbitMQ locally with: docker run -d --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3-management"

# Show help
help:
	@echo "Available targets:"
	@echo "  run      - Show how to start RabbitMQ locally"
	@echo "  k8s-deploy - Deploy to Kubernetes"
	@echo "  k8s-status - Check Kubernetes deployment status"
	@echo "  k8s-logs   - Show Kubernetes pod logs"
	@echo "  k8s-restart - Restart Kubernetes deployment"
	@echo "  k8s-test   - Test RabbitMQ in Kubernetes (requires minikube tunnel)"
	@echo "  k8s-clean  - Remove from Kubernetes"
	@echo "  help     - Show this help"

# Kubernetes deployment targets
k8s-deploy:
	@echo "🚀 Deploying to Kubernetes..."
	@cd manifests && chmod +x deploy.sh && ./deploy.sh

k8s-status:
	@echo "📊 Kubernetes deployment status:"
	@echo "Pods:"
	@kubectl get pods -l app=rabbitmq
	@echo ""
	@echo "Services:"
	@kubectl get svc rabbitmq
	@echo ""
	@echo "PVC:"
	@kubectl get pvc rabbitmq-pvc
	@echo ""
	@echo "ConfigMaps:"
	@kubectl get configmap rabbitmq-configmap
	@echo ""
	@echo "Secrets:"
	@kubectl get secret rabbitmq-secret

k8s-logs:
	@echo "📋 Showing Kubernetes pod logs..."
	@kubectl logs -l app=rabbitmq --tail=50 -f

k8s-restart:
	@echo "🔄 Restarting RabbitMQ deployment..."
	@kubectl rollout restart deployment/rabbitmq
	@echo "⏳ Waiting for rollout to complete..."
	@kubectl rollout status deployment/rabbitmq
	@echo "✅ RabbitMQ deployment restarted successfully"

# Test RabbitMQ in Kubernetes
k8s-test:
	@echo "🧪 Testing RabbitMQ in Kubernetes with minikube tunnel..."
	@echo "🔍 Checking if minikube tunnel is running..."
	@if ! pgrep -f "minikube tunnel" > /dev/null; then \
		echo "⚠️  Minikube tunnel not detected. Start it with:"; \
		echo "   sudo minikube tunnel"; \
		echo ""; \
	fi
	@echo "📊 Pod status:"; \
	kubectl get pods -l app=rabbitmq; \
	echo ""; \
	echo "🌐 Getting LoadBalancer service info..."; \
	kubectl get svc rabbitmq; \
	echo ""; \
	echo "🔌 Getting external IP (may take a moment)..."; \
	EXTERNAL_IP=$$(kubectl get svc rabbitmq -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo ""); \
	if [ -z "$$EXTERNAL_IP" ] || [ "$$EXTERNAL_IP" = "null" ]; then \
		echo "⏳ External IP not yet assigned. Checking again..."; \
		sleep 2; \
		EXTERNAL_IP=$$(kubectl get svc rabbitmq -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo ""); \
	fi; \
	if [ -n "$$EXTERNAL_IP" ] && [ "$$EXTERNAL_IP" != "null" ]; then \
		echo "✅ RabbitMQ is accessible via LoadBalancer:"; \
		echo "  🌐 Management UI: http://$$EXTERNAL_IP:15672 (guest/guest)"; \
		echo "  🔌 AMQP Port: $$EXTERNAL_IP:5672"; \
		echo ""; \
		echo "💡 Test connection with:"; \
		echo "  curl -u guest:guest http://$$EXTERNAL_IP:15672/api/overview"; \
	else \
		echo "❌ External IP not available. Make sure:"; \
		echo "  1. minikube tunnel is running: sudo minikube tunnel"; \
		echo "  2. Service is of type LoadBalancer"; \
		echo "  3. Wait a few moments for IP assignment"; \
		echo ""; \
		echo "🔄 You can also try port-forwarding as fallback:"; \
		echo "  kubectl port-forward svc/rabbitmq 15672:15672"; \
	fi

k8s-clean:
	@echo "🧹 Cleaning up Kubernetes resources..."
	@cd manifests && kubectl delete -f ./ || true
	@echo "✅ Kubernetes cleanup complete"

k8s-context:
	@echo "🔍 Current Kubernetes context:"
	@kubectl config current-context
	@echo ""
	@echo "Cluster info:"
	@kubectl cluster-info 