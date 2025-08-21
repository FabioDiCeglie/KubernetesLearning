.PHONY: run stop logs build clean test help

run:
	@echo "🚀 Starting Notification Service..."
	@chmod +x run.sh
	@./run.sh

stop:
	@echo "🛑 Stopping all services..."
	@docker-compose down

logs:
	@echo "📋 Showing logs..."
	@docker-compose logs -f

build:
	@echo "🔨 Building images..."
	@docker-compose build

clean:
	@echo "🧹 Cleaning up..."
	@docker-compose down -v --rmi all

test:
	@echo "🧪 Testing Notification Service Health..."
	@sleep 3
	@echo "Checking RabbitMQ connectivity..."
	@docker-compose exec -T rabbitmq rabbitmq-diagnostics ping > /dev/null 2>&1 && \
	echo "✅ RabbitMQ is healthy" || echo "❌ RabbitMQ is not responding"
	@echo "Checking notification service container status..."
	@if docker-compose ps notification | grep -q "Up"; then \
		echo "✅ Notification service container is running"; \
	else \
		echo "❌ Notification service container is not running"; \
	fi
	@echo "Checking recent logs for errors..."
	@ERROR_COUNT=$$(docker-compose logs notification --tail=20 2>/dev/null | grep -i error | wc -l | tr -d ' '); \
	if [ "$$ERROR_COUNT" -eq "0" ]; then \
		echo "✅ No recent errors in logs"; \
	else \
		echo "⚠️  Found $$ERROR_COUNT error(s) in recent logs"; \
		docker-compose logs notification --tail=10 | grep -i error || true; \
	fi

restart: stop run

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
	@echo "  k8s-test   - Test complete video conversion pipeline (login → upload → convert → verify)"
	@echo "  k8s-clean  - Remove from Kubernetes"
	@echo "  k8s-restart - Restart Kubernetes pods (rollout restart)"
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
	@echo "🧪 Testing complete Kubernetes video conversion pipeline..."
	@echo "🔍 Checking if services are deployed..."
	@if ! kubectl get ingress gateway-ingress >/dev/null 2>&1; then \
		echo "❌ Gateway ingress not found. Deploy gateway first."; \
		exit 1; \
	fi
	@if ! kubectl get pods -l app=converter | grep -q Running; then \
		echo "❌ Converter service not running. Deploy converter first with 'make k8s-deploy'"; \
		exit 1; \
	fi
	@if ! kubectl get pods -l app=notification | grep -q Running; then \
		echo "❌ Notification service not running. Deploy notification first."; \
		exit 1; \
	fi
	@echo "📡 Testing complete pipeline via mp3converter.com..."
	@echo "💡 Make sure /etc/hosts contains: 127.0.0.1 mp3converter.com"
	@echo "💡 Make sure minikube tunnel is running"
	@sleep 2
	
	@echo ""
	@echo "🔐 Step 1: Testing login and getting JWT token..."
	@TOKEN=$$(curl -s -X POST http://mp3converter.com/login -u "ftestf9@gmail.com:test") && \
	if [ -n "$$TOKEN" ] && [ "$$TOKEN" != '{"error":"Missing credentials"}' ] && [ "$$TOKEN" != '{"error":"Invalid credentials"}' ]; then \
		echo "✅ Login successful - Token received"; \
		echo "Token: $${TOKEN:0:50}..."; \
		\
		echo ""; \
		echo "📤 Step 2: Uploading video file..."; \
		UPLOAD_RESPONSE=$$(curl -s -X POST http://mp3converter.com/upload \
			-H "Authorization: Bearer $$TOKEN" \
			-F "video=@assets/test_video.mp4" -w "\n%{http_code}"); \
		UPLOAD_BODY=$$(echo "$$UPLOAD_RESPONSE" | head -n -1); \
		UPLOAD_CODE=$$(echo "$$UPLOAD_RESPONSE" | tail -n 1); \
		\
		if [ "$$UPLOAD_CODE" = "200" ]; then \
			echo "✅ Video upload successful"; \
			echo "Response: $$UPLOAD_BODY"; \
			\
			echo ""; \
			echo "⏳ Step 3: Waiting for conversion and notification process (10 seconds)..."; \
			echo "   - Video → MP3 conversion"; \
			echo "   - Email notification processing"; \
			for i in $$(seq 1 10); do \
				printf "."; \
				sleep 1; \
			done; \
			echo ""; \
			\
			echo ""; \
			echo "🗄️  Step 4: Checking MongoDB for video storage..."; \
			MONGO_VIDEO_COUNT=$$(kubectl exec -i $$(kubectl get pods -l app=gateway -o jsonpath='{.items[0].metadata.name}') -- \
				python3 -c "from pymongo import MongoClient; \
				client = MongoClient('host.minikube.internal', 27017); \
				print(client.videos.fs.files.count_documents({}))" 2>/dev/null || echo "0"); \
			echo "Videos in MongoDB: $$MONGO_VIDEO_COUNT"; \
			\
			MONGO_MP3_COUNT=$$(kubectl exec -i $$(kubectl get pods -l app=gateway -o jsonpath='{.items[0].metadata.name}') -- \
				python3 -c "from pymongo import MongoClient; \
				client = MongoClient('host.minikube.internal', 27017); \
				print(client.mp3s.fs.files.count_documents({}))" 2>/dev/null || echo "0"); \
			echo "MP3s in MongoDB: $$MONGO_MP3_COUNT"; \
			\
			if [ "$$MONGO_MP3_COUNT" -gt "0" ]; then \
				echo "Getting MP3 file ID for download test..."; \
				MP3_FILE_ID=$$(kubectl exec -i $$(kubectl get pods -l app=gateway -o jsonpath='{.items[0].metadata.name}') -- \
					python3 -c "from pymongo import MongoClient; \
					client = MongoClient('host.minikube.internal', 27017); \
					doc = client.mp3s.fs.files.find_one({}); \
					print(str(doc['_id']) if doc else '')" 2>/dev/null || echo ""); \
				echo "MP3 File ID: $$MP3_FILE_ID"; \
			fi; \
			\
			echo ""; \
			echo "🐰 Step 5: Checking RabbitMQ queue status..."; \
			RABBITMQ_POD=$$(kubectl get pods -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
			if [ -n "$$RABBITMQ_POD" ]; then \
				echo "Checking video and mp3 queues..."; \
				QUEUE_STATUS=$$(kubectl exec $$RABBITMQ_POD -- rabbitmqctl list_queues name messages 2>/dev/null); \
				echo "$$QUEUE_STATUS" | grep -E "(video|mp3)" || echo "No video/mp3 queues found"; \
				\
				VIDEO_QUEUE_MSGS=$$(echo "$$QUEUE_STATUS" | grep "video" | awk '{print $$2}' || echo "0"); \
				MP3_QUEUE_MSGS=$$(echo "$$QUEUE_STATUS" | grep "mp3" | awk '{print $$2}' || echo "0"); \
				echo "📊 Video queue messages: $$VIDEO_QUEUE_MSGS"; \
				echo "📊 MP3 queue messages: $$MP3_QUEUE_MSGS"; \
			else \
				echo "⚠️  RabbitMQ pod not found in Kubernetes"; \
			fi; \
			\
			echo ""; \
			echo "📊 Step 6: Checking service logs..."; \
			echo "Recent converter logs:"; \
			kubectl logs -l app=converter --tail=10 2>/dev/null || echo "No converter logs available"; \
			\
			echo ""; \
			echo "Recent notification logs:"; \
			kubectl logs -l app=notification --tail=10 2>/dev/null || echo "No notification logs available"; \
			\
			echo ""; \
			echo "📥 Step 7: Testing download endpoint..."; \
			if [ -n "$$MP3_FILE_ID" ] && [ "$$MP3_FILE_ID" != "" ]; then \
				echo "Testing download with MP3 ID: $$MP3_FILE_ID"; \
				mkdir -p test-downloads; \
				DOWNLOAD_CODE=$$(curl -s -o "test-downloads/$$MP3_FILE_ID.mp3" -w "%{http_code}" \
					"http://mp3converter.com/download?file_id=$$MP3_FILE_ID" \
					-H "Authorization: Bearer $$TOKEN"); \
				\
				if [ "$$DOWNLOAD_CODE" = "200" ]; then \
					DOWNLOAD_SIZE=$$(wc -c < "test-downloads/$$MP3_FILE_ID.mp3" | tr -d ' '); \
					echo "✅ Download successful → test-downloads/$$MP3_FILE_ID.mp3 ($$DOWNLOAD_SIZE bytes)"; \
					DOWNLOAD_SUCCESS="YES"; \
				else \
					echo "❌ Download failed - Status: $$DOWNLOAD_CODE"; \
					DOWNLOAD_SUCCESS="NO"; \
				fi; \
			else \
				echo "⚠️  No MP3 file ID available for download test"; \
				DOWNLOAD_SUCCESS="SKIPPED"; \
			fi; \
			\
			echo ""; \
			echo "🎯 Complete Pipeline Test Results:"; \
			echo "==================================="; \
			echo "✅ Login: SUCCESS"; \
			echo "✅ Upload: SUCCESS"; \
			if [ "$$MONGO_VIDEO_COUNT" -gt "0" ]; then \
				echo "✅ Video Storage: SUCCESS ($$MONGO_VIDEO_COUNT videos)"; \
			else \
				echo "⚠️  Video Storage: No videos found"; \
			fi; \
			if [ "$$MONGO_MP3_COUNT" -gt "0" ]; then \
				echo "✅ MP3 Conversion: SUCCESS ($$MONGO_MP3_COUNT MP3s)"; \
			else \
				echo "⚠️  MP3 Conversion: No MP3s found (may still be processing)"; \
			fi; \
			if [ "$$MP3_QUEUE_MSGS" = "0" ]; then \
				echo "✅ MP3 Queue Processing: SUCCESS (queue empty - messages processed)"; \
			else \
				echo "⚠️  MP3 Queue Processing: $$MP3_QUEUE_MSGS messages still pending"; \
			fi; \
			if [ "$$DOWNLOAD_SUCCESS" = "YES" ]; then \
				echo "✅ Download Endpoint: SUCCESS"; \
			elif [ "$$DOWNLOAD_SUCCESS" = "NO" ]; then \
				echo "❌ Download Endpoint: FAILED"; \
			else \
				echo "⚠️  Download Endpoint: SKIPPED (no MP3 available)"; \
			fi; \
			echo ""; \
			echo "🎉 Complete end-to-end pipeline test finished!"; \
			echo ""; \
			echo "🔧 Troubleshooting Commands:"; \
			echo "   - Converter logs: kubectl logs -l app=converter -f"; \
			echo "   - Notification logs: kubectl logs -l app=notification -f"; \
			echo "   - Gateway logs: kubectl logs -l app=gateway -f"; \
			echo "   - RabbitMQ status: kubectl exec \$$(kubectl get pods -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}') -- rabbitmqctl list_queues"; \
			\
		else \
			echo "❌ Video upload failed - Status: $$UPLOAD_CODE"; \
			echo "Response: $$UPLOAD_BODY"; \
			echo "🔧 Troubleshooting:"; \
			echo "   - Check if auth service is running"; \
			echo "   - Verify token is valid"; \
			echo "   - Check gateway logs: kubectl logs -l app=gateway"; \
		fi; \
		\
		echo ""; \
		echo "🧹 Cleaning up test files..."; \
		rm -f test_video.mp4; \
		rm -rf test-downloads; \
		\
	else \
		echo "❌ Login failed"; \
		echo "Response: $$TOKEN"; \
		echo "🔧 Troubleshooting:"; \
		echo "   - Check if auth service is running"; \
		echo "   - Check gateway logs: kubectl logs -l app=gateway"; \
		echo "   - Check ingress: kubectl get ingress gateway-ingress"; \
	fi

k8s-clean:
	@echo "🧹 Cleaning up Kubernetes resources..."
	@kubectl delete deployment notification || true
	@kubectl delete configmap notification-configmap || true
	@kubectl delete secret notification-secret || true
	@echo "🧹 Cleaning up RabbitMQ Docker container and volume..."
	@docker stop rabbitmq 2>/dev/null || true
	@docker rm rabbitmq 2>/dev/null || true
	@docker volume rm rabbitmq_data 2>/dev/null || true
	@echo "✅ Kubernetes and RabbitMQ cleanup complete"

k8s-restart:
	@echo "🔄 Restarting Kubernetes pods..."
	@kubectl rollout restart deployment notification
	@echo "⏳ Waiting for rollout to complete..."
	@kubectl rollout status deployment notification
	@echo "✅ Pods restarted successfully"

k8s-context:
	@echo "🔍 Current Kubernetes context:"
	@kubectl config current-context
	@echo ""
	@echo "Cluster info:"
	@kubectl cluster-info 