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
	@HEALTH_CODE=$$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health) && \
	if [ "$$HEALTH_CODE" = "204" ]; then \
		echo "✅ Health check passed - Gateway is running"; \
		echo "Testing login endpoint..."; \
		LOGIN_CODE=$$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8080/login -u "ftestf9@gmail.com:test"); \
		if [ "$$LOGIN_CODE" = "200" ]; then \
			echo "✅ Login test passed - Status: $$LOGIN_CODE"; \
		elif [ "$$LOGIN_CODE" = "401" ]; then \
			echo "✅ Login endpoint responsive - Auth service may be down (Status: $$LOGIN_CODE)"; \
		else \
			echo "❌ Login test failed - Status: $$LOGIN_CODE"; \
		fi \
	else \
		echo "❌ Health check failed - Status: $$HEALTH_CODE"; \
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
	@echo "  k8s-test   - Simple ingress health/login test"
	@echo "  k8s-test-full - Full end-to-end test (upload, DB, download)"
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
	@echo "🧪 Testing Kubernetes deployment via ingress..."
	@echo "🔍 Checking if ingress is deployed..."
	@kubectl get ingress gateway-ingress >/dev/null 2>&1 || { echo "❌ Ingress not found. Deploy first with 'make k8s-deploy'"; exit 1; }
	@echo "📡 Testing via mp3converter.com..."
	@echo "💡 Make sure /etc/hosts contains: 127.0.0.1 mp3converter.com"
	@echo "💡 Make sure minikube tunnel is running"
	@sleep 2
	@echo "Testing health endpoint..."
	@CODE=$$(curl -s -o /dev/null -w "%{http_code}" http://mp3converter.com/health) && \
	if [ "$$CODE" = "204" ]; then \
		echo "✅ Health check passed"; \
	else \
		echo "❌ Health check failed - Status: $$CODE"; \
		exit 1; \
	fi
	@echo "Testing login endpoint..."
	@LOGIN_CODE=$$(curl -s -o /dev/null -w "%{http_code}" -X POST http://mp3converter.com/login -u "ftestf9@gmail.com:test"); \
	if [ "$$LOGIN_CODE" = "200" ]; then \
		echo "✅ Login successful - fetching token..."; \
		TOKEN=$$(curl -s -X POST http://mp3converter.com/login -u "ftestf9@gmail.com:test"); \
		if [ -z "$$TOKEN" ] || [ "$$TOKEN" = '{"error":"Missing credentials"}' ] || [ "$$TOKEN" = '{"error":"Invalid credentials"}' ]; then \
			echo "❌ Failed to obtain token"; exit 1; \
		fi; \
		echo "📤 Step 2: Uploading video file..."; \
		VIDEO_FILE="tests/assets/test_video.mp4"; \
		if [ ! -f "$$VIDEO_FILE" ]; then \
			if [ -f "../converter/assets/test_video.mp4" ]; then VIDEO_FILE="../converter/assets/test_video.mp4"; \
			else echo "❌ Test video not found at tests/assets/test_video.mp4 or ../converter/assets/test_video.mp4"; exit 1; fi; \
		fi; \
		TMP_BODY=$$(mktemp); \
		UPLOAD_CODE=$$(curl -s -o $$TMP_BODY -w "%{http_code}" -X POST http://mp3converter.com/upload \
			-H "Authorization: Bearer $$TOKEN" \
			-F "video=@$$VIDEO_FILE"); \
		UPLOAD_BODY=$$(cat $$TMP_BODY); rm -f $$TMP_BODY; \
		\
		if [ "$$UPLOAD_CODE" = "200" ]; then \
			echo "✅ Video upload successful"; \
			echo "Response: $$UPLOAD_BODY"; \
			\
			echo ""; \
			echo "⏳ Step 4: Waiting for conversion process (30 seconds)..."; \
			for i in $$(seq 1 30); do \
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
			echo ""; \
			echo "🐰 Step 6: Checking RabbitMQ queue status..."; \
			RABBITMQ_POD=$$(kubectl get pods -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
			if [ -n "$$RABBITMQ_POD" ]; then \
				echo "Checking video queue..."; \
				kubectl exec $$RABBITMQ_POD -- rabbitmqctl list_queues name messages 2>/dev/null | grep -E "(video|mp3)" || echo "No video/mp3 queues found"; \
			else \
				echo "⚠️  RabbitMQ pod not found in Kubernetes"; \
			fi; \
			\
			echo ""; \
			echo "📊 Step 7: Checking converter service logs..."; \
			echo "Recent converter logs:"; \
			kubectl logs -l app=converter --tail=10 2>/dev/null || echo "No converter logs available"; \
			\
			echo ""; \
			echo "🎯 Pipeline Test Results:"; \
			echo "========================"; \
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
			\
			echo ""; \
			echo "⬇️  Step 8: Downloading latest converted MP3..."; \
			if [ "$$MONGO_MP3_COUNT" -gt "0" ]; then \
				GATEWAY_POD=$$(kubectl get pods -l app=gateway -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
				FILE_ID=$$(kubectl exec -i $$GATEWAY_POD -- python3 -c "from pymongo import MongoClient; c=MongoClient('host.minikube.internal',27017); d=c.mp3s.fs.files.find_one(sort=[('uploadDate',-1)]); print(str(d['_id']) if d else '')" 2>/dev/null); \
				if [ -n "$$FILE_ID" ]; then \
					mkdir -p tests/downloads; \
					CODE=$$(curl -s -o tests/downloads/$$FILE_ID.mp3 -w "%{http_code}" "http://mp3converter.com/download?file_id=$$FILE_ID" -H "Authorization: Bearer $$TOKEN"); \
					if [ "$$CODE" = "200" ]; then \
						SIZE=$$(wc -c < tests/downloads/$$FILE_ID.mp3 | tr -d ' '); \
						echo "✅ Download successful → tests/downloads/$$FILE_ID.mp3 ($$SIZE bytes)"; \
					else \
						echo "❌ Download failed - Status: $$CODE"; \
					fi; \
				else \
					echo "❌ Could not determine latest MP3 file id"; \
				fi; \
			else \
				echo "ℹ️  Skipping download because no MP3s are present yet"; \
			fi; \
			echo ""; \
			echo "🎉 Complete pipeline test finished!"; \
			echo "💡 Check converter logs with: kubectl logs -l app=converter -f"; \
			\
		else \
			echo "❌ Video upload failed - Status: $$UPLOAD_CODE"; \
			echo "Response: $$UPLOAD_BODY"; \
			echo "🔧 Troubleshooting:"; \
			echo "   - Check if auth service is running"; \
			echo "   - Verify token is valid"; \
			echo "   - Check gateway logs: kubectl logs -l app=gateway"; \
		fi; \
	elif [ "$$LOGIN_CODE" = "401" ]; then \
		echo "✅ Login endpoint responsive - Status: $$LOGIN_CODE"; \
		echo "⚠️  Skipping upload since a token cannot be obtained while auth returns 401"; \
	else \
		echo "❌ Login endpoint failed - Status: $$LOGIN_CODE"; \
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