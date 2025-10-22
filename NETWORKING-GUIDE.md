# CBS Core Banking System - Networking & Communication Guide

## Overview
This document explains how the three components (Dashboard, Middleware, CBS Simulator) communicate with each other within the Kubernetes cluster and how external access is configured.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    External Access (NodePort)                   │
├─────────────────────────────────────────────────────────────────┤
│ Dashboard:30004  │ Middleware:30003  │ CBS Simulator:30005      │
│ (192.168.90.129)│ (192.168.90.129) │ (192.168.90.129)         │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Internal Communication (ClusterIP)            │
├─────────────────────────────────────────────────────────────────┤
│ dashboard-service:80    │ middleware-service:3000 │ cbs-simulator-service:4000 │
│ (ClusterIP)             │ (ClusterIP)            │ (ClusterIP)               │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Pods                                    │
├─────────────────────────────────────────────────────────────────┤
│ dashboard-pod:80        │ middleware-pod:3000   │ cbs-simulator-pod:4000    │
│ (nginx)                 │ (Node.js)             │ (Node.js)                 │
└─────────────────────────────────────────────────────────────────┘
```

## Communication Flow

### 1. External User → Dashboard
- **URL**: `http://192.168.90.129:30004`
- **Flow**: User → NodePort 30004 → dashboard-service → dashboard-pod:80

### 2. Dashboard → Middleware (API Calls)
- **URL**: `http://192.168.90.129:30003` (configured via REACT_APP_API_URL)
- **Flow**: Dashboard → NodePort 30003 → middleware-service → middleware-pod:3000

### 3. Middleware → CBS Simulator (Internal)
- **URL**: `http://cbs-simulator-service:4000` (configured via CBS_SIMULATOR_URL)
- **Flow**: Middleware → ClusterIP service → cbs-simulator-pod:4000

## Port Configuration

### CBS Simulator
- **Container Port**: 4000
- **ClusterIP Service**: `cbs-simulator-service:4000`
- **NodePort Service**: `cbs-simulator-nodeport:30005`
- **External Access**: `http://192.168.90.129:30005`

### Middleware
- **Container Port**: 3000
- **ClusterIP Service**: `middleware-service:3000`
- **NodePort Service**: `middleware-nodeport:30003`
- **External Access**: `http://192.168.90.129:30003`

### Dashboard
- **Container Port**: 80 (nginx)
- **NodePort Service**: `dashboard-service:30004`
- **External Access**: `http://192.168.90.129:30004`

## API Endpoints

### CBS Simulator API
- `GET /health` - Health check
- `GET /api/accounts/:accountNumber` - Get account details
- `GET /api/balance/:accountNumber` - Get account balance
- `POST /api/transactions` - Process transaction
- `GET /cbs/customers` - List customers
- `GET /cbs/accounts` - List accounts

### Middleware API (Proxy to CBS Simulator)
- `GET /health` - Health check
- `GET /api/accounts/:accountNumber` - Proxy to CBS Simulator
- `GET /api/balance/:accountNumber` - Proxy to CBS Simulator
- `POST /api/transactions` - Proxy to CBS Simulator

### Dashboard (Frontend)
- `GET /` - Main application
- Static files served by nginx

## Environment Variables

### Dashboard
```yaml
env:
  - name: REACT_APP_API_URL
    value: "http://192.168.90.129:30003"  # External NodePort
  - name: REACT_APP_MIDDLEWARE_URL
    value: "http://192.168.90.129:30003"  # External NodePort
```

### Middleware
```yaml
env:
  - name: PORT
    value: "3000"
  - name: NODE_ENV
    value: "production"
  - name: CBS_SIMULATOR_URL
    value: "http://cbs-simulator-service:4000"  # Internal ClusterIP
```

### CBS Simulator
```yaml
env:
  - name: PORT
    value: "4000"
  - name: NODE_ENV
    value: "production"
```

## Dockerfile Verification

### Dashboard Dockerfile ✅
- Uses multi-stage build (Node.js → nginx)
- Correctly exposes port 80
- Includes health check
- Builds React app with proper API URL

### Middleware Dockerfile ✅
- Uses Node.js 20-alpine
- Correctly exposes port 3000
- Includes health check
- Runs as non-root user for security

### CBS Simulator Dockerfile ✅
- Uses Node.js 20-alpine
- Correctly exposes port 4000
- Includes health check
- Runs as non-root user for security

## Network Policies

The deployment includes a NetworkPolicy that:
- Allows all ingress traffic within the `cbs-system` namespace
- Allows all egress traffic within the `cbs-system` namespace
- Allows DNS resolution (ports 53)
- Blocks all other external traffic

## Deployment Commands

### Deploy the complete system:
```bash
kubectl apply -f kubernetes/cbs-system-complete.yaml
```

### Check deployment status:
```bash
kubectl get pods -n cbs-system
kubectl get services -n cbs-system
kubectl get deployments -n cbs-system
```

### Test connectivity:
```bash
./scripts/test-connectivity.sh
```

### View logs:
```bash
kubectl logs -n cbs-system -l app=cbs-simulator
kubectl logs -n cbs-system -l app=middleware
kubectl logs -n cbs-system -l app=dashboard
```

## Troubleshooting

### Common Issues:

1. **Pods not starting**: Check resource limits and image availability
2. **Service not accessible**: Verify NodePort configuration and firewall rules
3. **API calls failing**: Check environment variables and service URLs
4. **Health checks failing**: Verify health check endpoints and timing

### Debug Commands:
```bash
# Check pod status
kubectl describe pod <pod-name> -n cbs-system

# Check service endpoints
kubectl get endpoints -n cbs-system

# Test internal connectivity
kubectl exec -n cbs-system <pod-name> -- curl http://service-name:port/health

# Check network policies
kubectl get networkpolicy -n cbs-system
```

## Security Considerations

1. **Non-root containers**: All containers run as non-root users
2. **Network policies**: Restrict pod-to-pod communication to namespace
3. **Resource limits**: Prevent resource exhaustion
4. **Health checks**: Ensure service availability
5. **Image security**: Use specific image tags, not `latest` in production

## Performance Optimization

1. **Resource requests/limits**: Properly configured for each component
2. **Replica count**: 2 replicas for high availability
3. **Health checks**: Optimized timing for quick failure detection
4. **Session affinity**: None for load balancing
5. **Image pull policy**: Always pull latest images
