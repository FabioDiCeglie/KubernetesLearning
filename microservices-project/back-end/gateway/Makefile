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

# Test the API with complete flow
test:
	@echo "🧪 Testing complete Gateway API flow..."
	@sleep 5
	@echo "🔍 Step 1: Testing health endpoint..."
	@HEALTH_CODE=$$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health) && \
	if [ "$$HEALTH_CODE" = "204" ]; then \
		echo "✅ Health check passed - Gateway is running"; \
		\
		echo ""; \
		echo "🔐 Step 2: Testing login and getting JWT token..."; \
		TOKEN=$$(curl -s -X POST http://localhost:8080/login -u "ftestf9@gmail.com:test") && \
		if [ -n "$$TOKEN" ] && [ "$$TOKEN" != '{"error":"Missing credentials"}' ] && [ "$$TOKEN" != '{"error":"Invalid credentials"}' ]; then \
			echo "✅ Login successful - Token received"; \
			echo "Token: $${TOKEN:0:50}..."; \
			\
			echo ""; \
			echo "📤 Step 3: Testing video upload..."; \
			VIDEO_FILE="tests/assets/test_video.mp4"; \
			if [ ! -f "$$VIDEO_FILE" ]; then \
				if [ -f "../converter/assets/test_video.mp4" ]; then \
					VIDEO_FILE="../converter/assets/test_video.mp4"; \
				elif [ -f "../notification/assets/test_video.mp4" ]; then \
					VIDEO_FILE="../notification/assets/test_video.mp4"; \
				else \
					echo "❌ Test video not found. Expected at tests/assets/test_video.mp4"; \
					echo "   Also checked ../converter/assets/ and ../notification/assets/"; \
					exit 1; \
				fi; \
			fi; \
			\
			UPLOAD_RESPONSE=$$(curl -s -X POST http://localhost:8080/upload \
				-H "Authorization: Bearer $$TOKEN" \
				-F "video=@$$VIDEO_FILE" -w "\n%{http_code}"); \
			UPLOAD_BODY=$$(echo "$$UPLOAD_RESPONSE" | head -n -1); \
			UPLOAD_CODE=$$(echo "$$UPLOAD_RESPONSE" | tail -n 1); \
			\
			if [ "$$UPLOAD_CODE" = "200" ]; then \
				echo "✅ Video upload successful"; \
				echo "Response: $$UPLOAD_BODY"; \
				\
				echo ""; \
				echo "⏳ Step 4: Waiting for processing (15 seconds)..."; \
				echo "   - Video storage in MongoDB"; \
				echo "   - Message queuing to RabbitMQ"; \
				for i in $$(seq 1 15); do \
					printf "."; \
					sleep 1; \
				done; \
				echo ""; \
				\
				echo ""; \
				echo "🗄️  Step 5: Checking MongoDB connections..."; \
				echo "Checking if MongoDB is accessible..."; \
				if command -v mongosh >/dev/null 2>&1; then \
					MONGO_CMD="mongosh"; \
				elif command -v mongo >/dev/null 2>&1; then \
					MONGO_CMD="mongo"; \
				else \
					echo "⚠️  MongoDB client not found locally, skipping database checks"; \
					MONGO_CMD=""; \
				fi; \
				\
				if [ -n "$$MONGO_CMD" ]; then \
					VIDEO_COUNT=$$($$MONGO_CMD --quiet --host localhost:27017 --eval "db.getSiblingDB('videos').fs.files.countDocuments({})" 2>/dev/null || echo "0"); \
					echo "Videos in MongoDB: $$VIDEO_COUNT"; \
					\
					MP3_COUNT=$$($$MONGO_CMD --quiet --host localhost:27017 --eval "db.getSiblingDB('mp3s').fs.files.countDocuments({})" 2>/dev/null || echo "0"); \
					echo "MP3s in MongoDB: $$MP3_COUNT"; \
				fi; \
				\
				echo ""; \
				echo "🐰 Step 6: Checking RabbitMQ connection..."; \
				if command -v docker >/dev/null 2>&1 && docker ps | grep -q rabbitmq; then \
					echo "Checking RabbitMQ queues..."; \
					QUEUE_STATUS=$$(docker exec $$(docker ps --filter "name=rabbitmq" --format "{{.Names}}") rabbitmqctl list_queues name messages 2>/dev/null || echo ""); \
					if [ -n "$$QUEUE_STATUS" ]; then \
						echo "$$QUEUE_STATUS" | grep -E "(video|mp3)" || echo "No video/mp3 queues found"; \
					else \
						echo "⚠️  Could not access RabbitMQ queues"; \
					fi; \
				else \
					echo "⚠️  RabbitMQ container not found or not accessible"; \
				fi; \
				\
				echo ""; \
				echo "📊 Step 7: Checking service logs..."; \
				if command -v docker-compose >/dev/null 2>&1; then \
					echo "Recent gateway logs:"; \
					docker-compose logs --tail=10 gateway 2>/dev/null || echo "No gateway logs available via docker-compose"; \
				else \
					echo "⚠️  docker-compose not available for log checking"; \
				fi; \
				\
				echo ""; \
				echo "🎯 Complete Flow Test Results:"; \
				echo "=============================="; \
				echo "✅ Health Check: SUCCESS"; \
				echo "✅ Login: SUCCESS"; \
				echo "✅ Upload: SUCCESS"; \
				if [ -n "$$MONGO_CMD" ] && [ "$$VIDEO_COUNT" -gt "0" ]; then \
					echo "✅ Video Storage: SUCCESS ($$VIDEO_COUNT videos)"; \
				elif [ -n "$$MONGO_CMD" ]; then \
					echo "⚠️  Video Storage: No videos found"; \
				else \
					echo "⚠️  Video Storage: Cannot verify (MongoDB client not available)"; \
				fi; \
				echo ""; \
				echo "🎉 Gateway API test completed!"; \
				echo ""; \
				echo "🔧 Additional Commands:"; \
				echo "   - View logs: make logs"; \
				echo "   - Check status: make status"; \
				echo "   - For K8s testing: make k8s-test"; \
				\
			else \
				echo "❌ Video upload failed - Status: $$UPLOAD_CODE"; \
				echo "Response: $$UPLOAD_BODY"; \
				echo "🔧 Troubleshooting:"; \
				echo "   - Check if all services are running: make status"; \
				echo "   - Check logs: make logs"; \
				echo "   - Verify token is valid"; \
			fi; \
			\
		else \
			echo "❌ Login failed"; \
			echo "Response: $$TOKEN"; \
			echo "🔧 Troubleshooting:"; \
			echo "   - Check if auth service is running"; \
			echo "   - Check gateway logs: make logs"; \
			echo "   - Verify credentials"; \
		fi; \
		\
	else \
		echo "❌ Health check failed - Status: $$HEALTH_CODE"; \
		echo "🔧 Troubleshooting:"; \
		echo "   - Check if gateway is running: make status"; \
		echo "   - Check logs: make logs"; \
		echo "   - Try restarting: make restart"; \
	fi || echo "❌ Test failed - make sure services are running with 'make run'"

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
	@echo "  test     - Complete API flow test (health → login → upload → verify)"
	@echo "  restart  - Restart services"
	@echo "  status   - Show service status"
	@echo "  k8s-deploy - Deploy to Kubernetes"
	@echo "  k8s-status - Check Kubernetes deployment status"
	@echo "  k8s-logs   - Show Kubernetes pod logs"
	@echo "  k8s-test   - Complete end-to-end pipeline test (login → upload → convert → verify → download)"
	@echo "  k8s-restart - Restart Kubernetes pods"
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

k8s-test:
	@echo "🧪 Testing complete Kubernetes video conversion pipeline..."
	@echo "🔍 Checking if services are deployed..."
	@if ! kubectl get ingress gateway-ingress >/dev/null 2>&1; then \
		echo "❌ Gateway ingress not found. Deploy gateway first with 'make k8s-deploy'"; \
		exit 1; \
	fi
	@if ! kubectl get pods -l app=gateway | grep -q Running; then \
		echo "❌ Gateway service not running. Deploy gateway first with 'make k8s-deploy'"; \
		exit 1; \
	fi
	@if ! kubectl get pods -l app=auth | grep -q Running; then \
		echo "❌ Auth service not running. Deploy auth first."; \
		exit 1; \
	fi
	@echo "📡 Testing complete pipeline via mp3converter.com..."
	@echo "💡 Make sure /etc/hosts contains: 127.0.0.1 mp3converter.com"
	@echo "💡 Make sure minikube tunnel is running"
	@sleep 2
	
	@echo ""
	@echo "🔍 Step 1: Testing health endpoint..."
	@HEALTH_CODE=$$(curl -s -o /dev/null -w "%{http_code}" http://mp3converter.com/health) && \
	if [ "$$HEALTH_CODE" = "204" ]; then \
		echo "✅ Health check passed"; \
		\
		echo ""; \
		echo "🔐 Step 2: Testing login and getting JWT token..."; \
		TOKEN=$$(curl -s -X POST http://mp3converter.com/login -u "ftestf9@gmail.com:test") && \
		if [ -n "$$TOKEN" ] && [ "$$TOKEN" != '{"error":"Missing credentials"}' ] && [ "$$TOKEN" != '{"error":"Invalid credentials"}' ]; then \
			echo "✅ Login successful - Token received"; \
			echo "Token: $${TOKEN:0:50}..."; \
			\
			echo ""; \
			echo "📤 Step 3: Uploading video file..."; \
			VIDEO_FILE="tests/assets/test_video.mp4"; \
			if [ ! -f "$$VIDEO_FILE" ]; then \
				if [ -f "../converter/assets/test_video.mp4" ]; then \
					VIDEO_FILE="../converter/assets/test_video.mp4"; \
				elif [ -f "../notification/assets/test_video.mp4" ]; then \
					VIDEO_FILE="../notification/assets/test_video.mp4"; \
				else \
					echo "❌ Test video not found at tests/assets/test_video.mp4"; \
					echo "   Also checked ../converter/assets/ and ../notification/assets/"; \
					exit 1; \
				fi; \
			fi; \
			\
			UPLOAD_RESPONSE=$$(curl -s -X POST http://mp3converter.com/upload \
				-H "Authorization: Bearer $$TOKEN" \
				-F "video=@$$VIDEO_FILE" -w "\n%{http_code}"); \
			UPLOAD_BODY=$$(echo "$$UPLOAD_RESPONSE" | head -n -1); \
			UPLOAD_CODE=$$(echo "$$UPLOAD_RESPONSE" | tail -n 1); \
			\
			if [ "$$UPLOAD_CODE" = "200" ]; then \
				echo "✅ Video upload successful"; \
				echo "Response: $$UPLOAD_BODY"; \
				\
				echo ""; \
				echo "⏳ Step 4: Waiting for conversion and notification process (15 seconds)..."; \
				echo "   - Video → MP3 conversion"; \
				echo "   - Email notification processing"; \
				for i in $$(seq 1 15); do \
					printf "."; \
					sleep 1; \
				done; \
				echo ""; \
				\
				echo ""; \
				echo "🗄️  Step 5: Checking MongoDB for video storage..."; \
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
				echo "🐰 Step 6: Checking RabbitMQ queue status..."; \
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
				echo "📊 Step 7: Checking service logs..."; \
				echo "Recent gateway logs:"; \
				kubectl logs -l app=gateway --tail=10 2>/dev/null || echo "No gateway logs available"; \
				\
				echo ""; \
				echo "Recent converter logs:"; \
				kubectl logs -l app=converter --tail=10 2>/dev/null || echo "No converter logs available"; \
				\
				echo ""; \
				echo "Recent notification logs:"; \
				kubectl logs -l app=notification --tail=10 2>/dev/null || echo "No notification logs available"; \
				\
				echo ""; \
				echo "📥 Step 8: Testing download endpoint..."; \
				if [ -n "$$MP3_FILE_ID" ] && [ "$$MP3_FILE_ID" != "" ]; then \
					echo "Testing download with MP3 ID: $$MP3_FILE_ID"; \
					mkdir -p tests/downloads; \
					DOWNLOAD_CODE=$$(curl -s -o "tests/downloads/$$MP3_FILE_ID.mp3" -w "%{http_code}" \
						"http://mp3converter.com/download?file_id=$$MP3_FILE_ID" \
						-H "Authorization: Bearer $$TOKEN"); \
					\
					if [ "$$DOWNLOAD_CODE" = "200" ]; then \
						DOWNLOAD_SIZE=$$(wc -c < "tests/downloads/$$MP3_FILE_ID.mp3" | tr -d ' '); \
						echo "✅ Download successful → tests/downloads/$$MP3_FILE_ID.mp3 ($$DOWNLOAD_SIZE bytes)"; \
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
				echo "✅ Health Check: SUCCESS"; \
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
				echo "   - Gateway logs: kubectl logs -l app=gateway -f"; \
				echo "   - Converter logs: kubectl logs -l app=converter -f"; \
				echo "   - Notification logs: kubectl logs -l app=notification -f"; \
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
			rm -rf tests/downloads; \
			\
		else \
			echo "❌ Login failed"; \
			echo "Response: $$TOKEN"; \
			echo "🔧 Troubleshooting:"; \
			echo "   - Check if auth service is running"; \
			echo "   - Check gateway logs: kubectl logs -l app=gateway"; \
			echo "   - Check ingress: kubectl get ingress gateway-ingress"; \
		fi; \
		\
	else \
		echo "❌ Health check failed - Status: $$HEALTH_CODE"; \
		echo "🔧 Troubleshooting:"; \
		echo "   - Check if gateway is running: kubectl get pods -l app=gateway"; \
		echo "   - Check ingress: kubectl get ingress gateway-ingress"; \
		echo "   - Check minikube tunnel: minikube tunnel"; \
	fi

k8s-restart:
	@echo "🔄 Restarting Kubernetes pods..."
	@kubectl rollout restart deployment gateway
	@echo "⏳ Waiting for rollout to complete..."
	@kubectl rollout status deployment gateway
	@echo "✅ Pods restarted successfully"

k8s-clean:
	@echo "🧹 Cleaning up Kubernetes resources..."
	@kubectl delete deployment gateway || true
	@kubectl delete service gateway-service || true
	@kubectl delete configmap gateway-configmap || true
	@kubectl delete secret gateway-secret || true
	@echo "🧹 Cleaning up MongoDB Docker container and volume..."
	@docker stop mongodb 2>/dev/null || true
	@docker rm mongodb 2>/dev/null || true
	@docker volume rm mongodb_data 2>/dev/null || true
	@echo "✅ Kubernetes and MongoDB cleanup complete"

k8s-context:
	@echo "🔍 Current Kubernetes context:"
	@kubectl config current-context
	@echo ""
	@echo "Cluster info:"
	@kubectl cluster-info 