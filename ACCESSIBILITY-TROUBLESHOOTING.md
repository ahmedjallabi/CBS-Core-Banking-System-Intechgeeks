# Guide de Résolution - Problèmes d'Accessibilité NodePort

## Problème Identifié

L'application n'est pas accessible depuis l'adresse IP du master (192.168.90.136) malgré la configuration correcte des services NodePort.

## Diagnostic

### État Actuel du Cluster
- **Master**: 192.168.90.136 (Ready)
- **Worker1**: 192.168.90.130 (Ready) - **Tous les pods sont ici**
- **Worker2**: 192.168.90.137 (NotReady)

### Services Configurés
- ✅ `cbs-simulator-nodeport` (NodePort: 30005)
- ✅ `middleware-nodeport` (NodePort: 30003)
- ✅ `dashboard-service` (NodePort: 30004)
- ❌ **Manque**: Service ClusterIP pour dashboard

## Causes Possibles

### 1. **Pods sur Worker1 uniquement**
Tous les pods sont déployés sur worker1 (192.168.90.130) au lieu du master.

### 2. **Configuration réseau du cluster**
Les services NodePort peuvent ne pas être correctement exposés sur tous les nœuds.

### 3. **Service ClusterIP manquant**
Le dashboard n'a pas de service ClusterIP pour la communication interne.

## Solutions

### Solution 1: Appliquer la Configuration Corrigée

```bash
# Appliquer la configuration corrigée
kubectl apply -f kubernetes/cbs-system-accessibility-fix.yaml

# Vérifier les services
kubectl get services -n cbs-system
```

### Solution 2: Tester l'Accessibilité

```bash
# Exécuter le script de diagnostic
chmod +x scripts/diagnose-accessibility.sh
./scripts/diagnose-accessibility.sh
```

### Solution 3: Accès Alternatif

Si les NodePort ne fonctionnent pas depuis le master, utilisez :

#### Option A: Accès via Worker1
```bash
# Accès direct via l'IP du worker1
curl http://192.168.90.130:30004/  # Dashboard
curl http://192.168.90.130:30003/health  # Middleware
curl http://192.168.90.130:30005/health  # CBS Simulator
```

#### Option B: Port Forward (Accès Local)
```bash
# Port forward pour accès local
kubectl port-forward -n cbs-system service/dashboard-service 8080:80
kubectl port-forward -n cbs-system service/middleware-service 8081:3000
kubectl port-forward -n cbs-system service/cbs-simulator-service 8082:4000

# Accès local
curl http://localhost:8080/  # Dashboard
curl http://localhost:8081/health  # Middleware
curl http://localhost:8082/health  # CBS Simulator
```

## Vérifications Nécessaires

### 1. Vérifier les Ports NodePort
```bash
# Sur le master
netstat -tlnp | grep -E ":30003|:30004|:30005"

# Sur worker1
ssh worker1 "netstat -tlnp | grep -E ':30003|:30004|:30005'"
```

### 2. Vérifier kube-proxy
```bash
# Vérifier que kube-proxy fonctionne
kubectl get pods -n kube-system -l k8s-app=kube-proxy

# Vérifier les logs de kube-proxy
kubectl logs -n kube-system -l k8s-app=kube-proxy
```

### 3. Vérifier les Règles iptables
```bash
# Vérifier les règles iptables pour NodePort
iptables -t nat -L KUBE-NODEPORTS | grep -E "30003|30004|30005"
```

## Configuration Recommandée

### URLs d'Accès Recommandées

**Depuis le master (192.168.90.136):**
- Dashboard: http://192.168.90.136:30004
- Middleware: http://192.168.90.136:30003
- CBS Simulator: http://192.168.90.136:30005

**Depuis worker1 (192.168.90.130):**
- Dashboard: http://192.168.90.130:30004
- Middleware: http://192.168.90.130:30003
- CBS Simulator: http://192.168.90.130:30005

### Services ClusterIP (Communication Interne)
- `dashboard-service:80`
- `middleware-service:3000`
- `cbs-simulator-service:4000`

## Tests de Validation

### Test 1: Connectivité NodePort
```bash
# Test depuis le master
curl -f http://192.168.90.136:30004/ || echo "Dashboard non accessible"
curl -f http://192.168.90.136:30003/health || echo "Middleware non accessible"
curl -f http://192.168.90.136:30005/health || echo "CBS Simulator non accessible"
```

### Test 2: Connectivité ClusterIP
```bash
# Test depuis un pod dans le cluster
kubectl run test-pod --image=curlimages/curl:latest --rm -it --restart=Never -n cbs-system -- sh

# Dans le pod de test
curl http://dashboard-service:80/
curl http://middleware-service:3000/health
curl http://cbs-simulator-service:4000/health
```

### Test 3: Communication Inter-Services
```bash
# Test Middleware -> CBS Simulator
kubectl exec -n cbs-system -l app=middleware -- curl http://cbs-simulator-service:4000/health
```

## Résolution de Problèmes Avancés

### Problème: kube-proxy ne fonctionne pas
```bash
# Redémarrer kube-proxy
kubectl delete pods -n kube-system -l k8s-app=kube-proxy
```

### Problème: Règles iptables corrompues
```bash
# Nettoyer les règles iptables
iptables -t nat -F KUBE-NODEPORTS
iptables -t nat -F KUBE-SERVICES

# Redémarrer kube-proxy
kubectl delete pods -n kube-system -l k8s-app=kube-proxy
```

### Problème: Configuration réseau du cluster
```bash
# Vérifier la configuration CNI
kubectl get pods -n kube-system | grep -E "flannel|calico|weave"

# Vérifier les logs CNI
kubectl logs -n kube-system -l k8s-app=flannel
```

## Monitoring et Logs

### Vérifier les Logs des Services
```bash
# Logs du CBS Simulator
kubectl logs -n cbs-system -l app=cbs-simulator --tail=50

# Logs du Middleware
kubectl logs -n cbs-system -l app=middleware --tail=50

# Logs du Dashboard
kubectl logs -n cbs-system -l app=dashboard --tail=50
```

### Vérifier les Événements
```bash
# Événements récents
kubectl get events -n cbs-system --sort-by='.lastTimestamp'
```

## Conclusion

Les problèmes d'accessibilité peuvent être résolus en :

1. ✅ Appliquant la configuration corrigée
2. ✅ Testant l'accessibilité depuis différentes IPs
3. ✅ Utilisant les solutions alternatives (port-forward, accès direct)
4. ✅ Vérifiant la configuration réseau du cluster

Le système devrait être accessible via les services NodePort sur les ports 30003, 30004, et 30005.






