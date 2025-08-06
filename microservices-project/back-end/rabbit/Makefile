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
	@echo "  k8s-test   - Test RabbitMQ in Kubernetes"
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
	@echo "🧪 Testing RabbitMQ in Kubernetes with ClusterIP service..."
	@echo "📊 Pod status:"; \
	kubectl get pods -l app=rabbitmq; \
	echo ""; \
	echo "🌐 Service info:"; \
	kubectl get svc rabbitmq; \
	echo ""; \
	echo "🔌 Since service type is ClusterIP, using port-forwarding for access..."; \
	echo "✅ RabbitMQ is accessible via port-forwarding:"; \
	echo "  🌐 Management UI: http://localhost:15672 (guest/guest)"; \
	echo "  🔌 AMQP Port: localhost:5672"; \
	echo ""; \
	echo "💡 To access RabbitMQ, run in another terminal:"; \
	echo "  kubectl port-forward svc/rabbitmq 15672:15672 5672:5672"; \
	echo ""; \
	echo "💡 Test connection with:"; \
	echo "  curl -u guest:guest http://localhost:15672/api/overview"; \
	echo ""; \

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