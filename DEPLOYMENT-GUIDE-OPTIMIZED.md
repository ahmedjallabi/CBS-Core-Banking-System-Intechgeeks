# Guide de Déploiement CBS System - Communication Pods et NodePort

## Vue d'ensemble

Ce guide explique comment déployer le système CBS avec une communication correcte entre les pods et l'exposition via NodePort.

## Architecture du Système

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Dashboard     │    │   Middleware    │    │ CBS Simulator   │
│   (Frontend)    │◄───┤   (API Gateway) │◄───┤   (Backend)     │
│   Port: 80      │    │   Port: 3000    │    │   Port: 4000    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
    NodePort:30004         NodePort:30003         NodePort:30005
```

## Services et Communication

### Services ClusterIP (Communication Interne)
- **cbs-simulator-service**: `http://cbs-simulator-service:4000`
- **middleware-service**: `http://middleware-service:3000`
- **dashboard-service**: `http://dashboard-service:80`

### Services NodePort (Accès Externe)
- **CBS Simulator**: `http://192.168.90.129:30005`
- **Middleware**: `http://192.168.90.129:30003`
- **Dashboard**: `http://192.168.90.129:30004`

## Déploiement

### 1. Prérequis
```bash
# Vérifier que kubectl est configuré
kubectl cluster-info

# Vérifier l'accès au cluster
kubectl get nodes
```

### 2. Déploiement du Système Complet
```bash
# Déployer avec la configuration optimisée
kubectl apply -f kubernetes/cbs-system-optimized.yaml

# Vérifier le déploiement
kubectl get all -n cbs-system
```

### 3. Vérification des Services
```bash
# Vérifier les services ClusterIP
kubectl get services -n cbs-system --field-selector spec.type=ClusterIP

# Vérifier les services NodePort
kubectl get services -n cbs-system --field-selector spec.type=NodePort
```

## Tests de Communication

### Test Automatique
```bash
# Linux/Mac
./scripts/test-pod-communication.sh

# Windows PowerShell
.\scripts\test-pod-communication.ps1
```

### Test Manuel

#### 1. Test des Services ClusterIP (Communication Interne)
```bash
# Créer un pod de test
kubectl run test-pod --image=curlimages/curl:latest --rm -it --restart=Never -n cbs-system -- sh

# Dans le pod de test, tester la communication interne
curl http://cbs-simulator-service:4000/health
curl http://middleware-service:3000/health
curl http://dashboard-service:80/
```

#### 2. Test des Services NodePort (Accès Externe)
```bash
# Depuis votre machine locale
curl http://192.168.90.129:30005/health  # CBS Simulator
curl http://192.168.90.129:30003/health  # Middleware
curl http://192.168.90.129:30004/         # Dashboard
```

## Configuration des Variables d'Environnement

### Dashboard
Le dashboard est configuré pour utiliser les services ClusterIP internes :
```yaml
env:
  - name: REACT_APP_API_URL
    value: "http://middleware-service:3000"
  - name: REACT_APP_MIDDLEWARE_URL
    value: "http://middleware-service:3000"
```

### Middleware
Le middleware est configuré pour communiquer avec CBS Simulator via ClusterIP :
```yaml
env:
  - name: CBS_SIMULATOR_URL
    value: "http://cbs-simulator-service:4000"
```

## Flux de Communication

### 1. Communication Frontend → Backend
```
Dashboard (Browser) → Dashboard Pod → Middleware Service → Middleware Pod → CBS Simulator Service → CBS Simulator Pod
```

### 2. Communication Interne (Pod à Pod)
```
Middleware Pod → cbs-simulator-service:4000 → CBS Simulator Pod
Dashboard Pod → middleware-service:3000 → Middleware Pod
```

### 3. Accès Externe
```
Browser → NodePort (30004) → Dashboard Pod
Browser → NodePort (30003) → Middleware Pod
Browser → NodePort (30005) → CBS Simulator Pod
```

## Résolution de Problèmes

### Problème: Les pods ne peuvent pas communiquer entre eux
```bash
# Vérifier les services ClusterIP
kubectl get services -n cbs-system

# Vérifier les endpoints
kubectl get endpoints -n cbs-system

# Vérifier la connectivité réseau
kubectl exec -n cbs-system <pod-name> -- nslookup cbs-simulator-service
```

### Problème: Les NodePort ne sont pas accessibles
```bash
# Vérifier les services NodePort
kubectl get services -n cbs-system --field-selector spec.type=NodePort

# Vérifier que les ports sont ouverts sur le nœud
netstat -tlnp | grep :30003
netstat -tlnp | grep :30004
netstat -tlnp | grep :30005
```

### Problème: Le dashboard ne peut pas atteindre le middleware
```bash
# Vérifier les variables d'environnement du dashboard
kubectl describe pod -n cbs-system -l app=dashboard

# Tester la connectivité depuis le pod dashboard
kubectl exec -n cbs-system -l app=dashboard -- curl http://middleware-service:3000/health
```

## Monitoring et Logs

### Vérifier les Logs
```bash
# Logs du CBS Simulator
kubectl logs -n cbs-system -l app=cbs-simulator --tail=50

# Logs du Middleware
kubectl logs -n cbs-system -l app=middleware --tail=50

# Logs du Dashboard
kubectl logs -n cbs-system -l app=dashboard --tail=50
```

### Monitoring des Services
```bash
# Vérifier le statut des pods
kubectl get pods -n cbs-system -o wide

# Vérifier les événements
kubectl get events -n cbs-system --sort-by='.lastTimestamp'
```

## URLs d'Accès

Une fois déployé, vous pouvez accéder aux services via :

- **Dashboard**: http://192.168.90.129:30004
- **Middleware API**: http://192.168.90.129:30003
- **CBS Simulator**: http://192.168.90.129:30005
- **Documentation API**: http://192.168.90.129:30003/api-docs

## Sécurité

- Les services ClusterIP ne sont accessibles que depuis l'intérieur du cluster
- Les services NodePort sont exposés sur tous les nœuds du cluster
- Une NetworkPolicy est configurée pour limiter la communication entre les pods

## Maintenance

### Redéploiement
```bash
# Redéployer un service spécifique
kubectl rollout restart deployment/cbs-simulator -n cbs-system
kubectl rollout restart deployment/middleware -n cbs-system
kubectl rollout restart deployment/dashboard -n cbs-system
```

### Mise à jour des Images
```bash
# Mettre à jour l'image d'un déploiement
kubectl set image deployment/cbs-simulator cbs-simulator=ahm2022/cbs-simulator:latest -n cbs-system
```

### Nettoyage
```bash
# Supprimer le namespace complet
kubectl delete namespace cbs-system
```
