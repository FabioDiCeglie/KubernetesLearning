# L26-03

## Deploy the service

    kubectl apply -f clusterip.yaml

## Deploy the app

    kubectl apply -f deploy-app.yaml

## Deploy Busybox

    kubectl apply -f pod.yaml

## Get the pods list

    kubectl get pods -o wide

## Connect to the BusyBox container

    kubectl exec mybox -it -- /bin/sh

## Get the Nginx home page thru the ClusterIP service

    wget -qO- http://svc-example:8080
    exit

## Cleanup

    kubectl delete -f clusterip.yaml
    kubectl delete -f deploy-app.yaml
    kubectl delete -f pod.yaml --grace-period=0 --force

# Real world example diagram
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
│  FRONTEND TIER (NodePort Service)                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    frontend-service                                 │   │
│  │                   NodePort: 30080                                   │   │
│  │                                                                     │   │
│  │    ┌─────────────┐   ┌─────────────┐   ┌─────────────┐              │   │
│  │    │frontend-pod1│   │frontend-pod2│   │frontend-pod3│              │   │
│  │    │  nginx:1.21 │   │  nginx:1.21 │   │  nginx:1.21 │              │   │
│  │    └─────────────┘   └─────────────┘   └─────────────┘              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                            │
│                    │                            │                          │
│                    │                            │                          │
│                    ▼                            ▼                          │
│                                                                            │
│  BACKEND SERVICES (ClusterIP)                                              │
│  ┌──────────────────────────────┐    ┌──────────────────────────────┐      │
│  │        USER SERVICE          │    │        ORDER SERVICE         │      │
│  │                              │    │                              │      │
│  │    ┌─────────────────────┐   │    │    ┌─────────────────────┐   │      │
│  │    │   user-service      │   │    │    │   order-service     │   │      │
│  │    │   ClusterIP:8080    │   │    │    │   ClusterIP:8080    │   │      │
│  │    └─────────────────────┘   │    │    └─────────────────────┘   │      │
│  │             │                │    │             │                │      │
│  │             │                │    │             │                │      │
│  │    ┌────────┴────────┐       │    │    ┌────────┴────────┐       │      │
│  │    │                 │       │    │    │                 │       │      │
│  │    ▼                 ▼       │    │    ▼                 ▼       │      │
│  │ ┌─────────────┐ ┌─────────────┐ │    │ ┌─────────────┐ ┌─────────────┐  │
│  │ │ user-pod-1  │ │ user-pod-2  │ │    │ │order-pod-1  │ │order-pod-2  │  │
│  │ │ Node.js API │ │ Node.js API │ │    │ │ Node.js API │ │ Node.js API │  │
│  │ └─────────────┘ └─────────────┘ │    │ └─────────────┘ └─────────────┘  │
│  └──────────────────────────────────┘    └──────────────────────────────────┘
│                                                                            │
│                                                                            │
│  TESTING                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                            test-pod                                 │   │
│  │                         (curl/debugging)                            │   │
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