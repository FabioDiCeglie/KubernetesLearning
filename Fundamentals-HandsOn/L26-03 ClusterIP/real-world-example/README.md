# Real World Microservices Example

This example demonstrates a typical microservices architecture using ClusterIP services for internal communication.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                       │
├─────────────────────────────────────────────────────────────┤
│  Frontend (NodePort)                                        │
│  ├─── nginx:1.21 (3 replicas)                              │
│  └─── Exposed on NodePort 30080                            │
│                                                             │
│  User Service (ClusterIP)                                  │
│  ├─── Node.js API (2 replicas)                             │
│  └─── Internal: http://user-service:8080                   │
│                                                             │
│  Order Service (ClusterIP)                                 │
│  ├─── Node.js API (2 replicas)                             │
│  └─── Internal: http://order-service:8080                  │
└─────────────────────────────────────────────────────────────┘
```

## Available Files

### Backend Pod Deployments
- `back-end-pod-user.yaml` - User service deployment only
- `back-end-pod-order.yaml` - Order service deployment only

### ClusterIP Services
- `service-user.yaml` - User service ClusterIP only  
- `service-order.yaml` - Order service ClusterIP only

### Frontend & Testing
- `frontend-deployment.yaml` - Frontend deployment + NodePort service
- `test-pod.yaml` - Test pod for internal testing

## Deploy All Services

```bash
# Deploy backend pods
kubectl apply -f back-end-pod-user.yaml
kubectl apply -f back-end-pod-order.yaml

# Deploy backend services
kubectl apply -f service-user.yaml
kubectl apply -f service-order.yaml

# Deploy frontend
kubectl apply -f frontend-deployment.yaml

# Deploy test pod
kubectl apply -f test-pod.yaml
```

## Verify Deployment

### Check all pods are running

```bash
kubectl get pods -o wide
```

### Check all services

```bash
kubectl get services
```

You should see:
- `user-service` (ClusterIP)
- `order-service` (ClusterIP)
- `frontend-service` (NodePort)

## Test ClusterIP Communication

### Test from within the cluster

```bash
# Connect to test pod
kubectl exec -it test-pod -- sh

# Test user service
curl http://user-service:8080

# Test order service
curl http://order-service:8080

# Exit the pod
exit
```

### Expected API Responses

**User Service:**
```json
{
  "service": "user-service",
  "users": [
    {"id": 1, "name": "John"},
    {"id": 2, "name": "Jane"}
  ],
  "timestamp": "2024-01-01T10:00:00.000Z"
}
```

**Order Service:**
```json
{
  "service": "order-service",
  "orders": [
    {"id": 101, "product": "Laptop", "amount": 999},
    {"id": 102, "product": "Phone", "amount": 599}
  ],
  "timestamp": "2024-01-01T10:00:00.000Z"
}
```

## Access Frontend Externally

### Get Node IP

```bash
kubectl get nodes -o wide
```

### Access Frontend

Open browser: `http://<NODE_IP>:30080`

## Key Points Demonstrated

1. **ClusterIP Services**: `user-service` and `order-service` are only accessible within the cluster
2. **Internal Communication**: Frontend can communicate with backend services using service names
3. **Load Balancing**: ClusterIP automatically distributes requests across multiple pod replicas
4. **Service Discovery**: Services can be reached by their names (e.g., `user-service:8080`)
5. **External Access**: Frontend is exposed via NodePort for external access

## Clean Up

```bash
kubectl delete -f back-end-pod-user.yaml
kubectl delete -f service-user.yaml
kubectl delete -f back-end-pod-order.yaml
kubectl delete -f service-order.yaml
kubectl delete -f frontend-deployment.yaml
kubectl delete -f test-pod.yaml
```

## Architecture Benefits

- **Scalability**: Each service can scale independently
- **Security**: Backend services are not exposed externally
- **Reliability**: Load balancing across multiple replicas
- **Maintainability**: Services are loosely coupled
- **Discovery**: Built-in service discovery via DNS names
- **Organization**: Separated deployments and services for better management 

## Complete Architecture Diagram

```
                                EXTERNAL ACCESS
                                ┌─────────────┐
                                │User/Browser │
                                └─────────────┘
                                       │
                                       │ HTTP Request
                                       ▼
                                ┌─────────────┐
                                │Node IP:30080│
                                └─────────────┘
                                       │
                                       │ Port 30080
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           KUBERNETES CLUSTER                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  FRONTEND TIER (NodePort Service)                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    frontend-service                                 │   │
│  │                   NodePort: 30080                                   │   │
│  │                                                                     │   │
│  │    ┌─────────────┐   ┌─────────────┐   ┌─────────────┐           │   │
│  │    │frontend-pod1│   │frontend-pod2│   │frontend-pod3│           │   │
│  │    │  nginx:1.21 │   │  nginx:1.21 │   │  nginx:1.21 │           │   │
│  │    └─────────────┘   └─────────────┘   └─────────────┘           │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│                    │                            │                          │
│                    │                            │                          │
│                    ▼                            ▼                          │
│                                                                             │
│  BACKEND SERVICES (ClusterIP)                                              │
│  ┌──────────────────────────────┐    ┌──────────────────────────────┐    │
│  │        USER SERVICE          │    │        ORDER SERVICE         │    │
│  │                              │    │                              │    │
│  │    ┌─────────────────────┐   │    │    ┌─────────────────────┐   │    │
│  │    │   user-service      │   │    │    │   order-service     │   │    │
│  │    │   ClusterIP:8080    │   │    │    │   ClusterIP:8080    │   │    │
│  │    └─────────────────────┘   │    │    └─────────────────────┘   │    │
│  │             │                │    │             │                │    │
│  │             │                │    │             │                │    │
│  │    ┌────────┴────────┐       │    │    ┌────────┴────────┐       │    │
│  │    │                 │       │    │    │                 │       │    │
│  │    ▼                 ▼       │    │    ▼                 ▼       │    │
│  │ ┌─────────────┐ ┌─────────────┐ │    │ ┌─────────────┐ ┌─────────────┐ │
│  │ │ user-pod-1  │ │ user-pod-2  │ │    │ │order-pod-1  │ │order-pod-2  │ │
│  │ │ Node.js API │ │ Node.js API │ │    │ │ Node.js API │ │ Node.js API │ │
│  │ └─────────────┘ └─────────────┘ │    │ └─────────────┘ └─────────────┘ │
│  └──────────────────────────────────┘    └──────────────────────────────────┘
│                                                                             │
│                                                                             │
│  TESTING                                                                    │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                            test-pod                                 │   │
│  │                         (curl/debugging)                           │   │
│  │                                                                     │   │
│  │  Can access:                                                        │   │
│  │  • http://user-service:8080                                         │   │
│  │  • http://order-service:8080                                        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Communication Flow

**1. External Access**
```
User/Browser → Node IP:30080 → frontend-service (NodePort)
```

**2. Frontend Load Balancing**
```
frontend-service → [frontend-pod1, frontend-pod2, frontend-pod3] (Round Robin)
```

**3. Internal API Calls**
```
frontend-pods → http://user-service:8080  (DNS Resolution)
frontend-pods → http://order-service:8080 (DNS Resolution)
```

**4. Backend Load Balancing**
```
user-service  → [user-pod-1, user-pod-2]   (Round Robin)
order-service → [order-pod-1, order-pod-2] (Round Robin)
```

**5. Testing Access**
```
test-pod → http://user-service:8080  (Internal ClusterIP)
test-pod → http://order-service:8080 (Internal ClusterIP)
```

### Service Types Summary

| Service Type | Name              | Access         | Port  | Purpose                    |
|--------------|-------------------|----------------|-------|----------------------------|
| NodePort     | frontend-service  | External       | 30080 | Web interface access       |
| ClusterIP    | user-service      | Internal only  | 8080  | User API microservice      |
| ClusterIP    | order-service     | Internal only  | 8080  | Order API microservice     |

### Key Architecture Points

✅ **Security**: Backend services are not exposed externally
✅ **Scalability**: Each service has multiple replicas for high availability
✅ **Service Discovery**: Services communicate using DNS names
✅ **Load Balancing**: Automatic distribution across pod replicas
✅ **Testing**: Internal test pod for debugging and validation
✅ **Separation**: Frontend and backend are properly decoupled 