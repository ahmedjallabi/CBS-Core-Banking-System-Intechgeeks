#!/bin/bash

# Script de diagnostic et correction pour l'accessibilité des services NodePort
# Ce script identifie et corrige les problèmes d'accessibilité depuis l'IP du master

set -e

NAMESPACE="cbs-system"
MASTER_IP="192.168.90.136"
WORKER1_IP="192.168.90.130"

echo "=========================================="
echo "Diagnostic d'Accessibilité CBS System"
echo "=========================================="

# Fonction pour tester un endpoint
test_endpoint() {
    local url=$1
    local description=$2
    local expected_status=${3:-200}
    
    echo "Test: $description"
    echo "URL: $url"
    
    if response=$(curl -s -w "\n%{http_code}" "$url" --connect-timeout 10 2>/dev/null); then
        status_code=$(echo "$response" | tail -n1)
        body=$(echo "$response" | head -n -1)
        
        if [ "$status_code" -eq "$expected_status" ]; then
            echo "✅ SUCCESS - Status: $status_code"
            echo "Response: $(echo "$body" | head -c 100)..."
        else
            echo "❌ FAILED - Expected: $expected_status, Got: $status_code"
            echo "Response: $body"
        fi
    else
        echo "❌ CONNECTION FAILED"
    fi
    echo "----------------------------------------"
}

echo "1. Vérification des nœuds du cluster..."
kubectl get nodes -o wide

echo ""
echo "2. Vérification des pods et leur localisation..."
kubectl get pods -n $NAMESPACE -o wide

echo ""
echo "3. Vérification des services..."
kubectl get services -n $NAMESPACE

echo ""
echo "4. Vérification des endpoints..."
kubectl get endpoints -n $NAMESPACE

echo ""
echo "=========================================="
echo "TESTS D'ACCESSIBILITÉ DEPUIS LE MASTER"
echo "=========================================="

# Test des services NodePort depuis le master
echo "Tests depuis l'IP du master ($MASTER_IP):"
test_endpoint "http://$MASTER_IP:30004/" "Dashboard (NodePort)"
test_endpoint "http://$MASTER_IP:30003/health" "Middleware Health (NodePort)"
test_endpoint "http://$MASTER_IP:30005/health" "CBS Simulator Health (NodePort)"

echo ""
echo "Tests depuis l'IP du worker1 ($WORKER1_IP):"
test_endpoint "http://$WORKER1_IP:30004/" "Dashboard (NodePort)"
test_endpoint "http://$WORKER1_IP:30003/health" "Middleware Health (NodePort)"
test_endpoint "http://$WORKER1_IP:30005/health" "CBS Simulator Health (NodePort)"

echo ""
echo "=========================================="
echo "DIAGNOSTIC DES PROBLÈMES"
echo "=========================================="

# Vérifier si les ports sont ouverts sur le master
echo "Vérification des ports ouverts sur le master..."
if command -v netstat &> /dev/null; then
    echo "Ports NodePort sur le master:"
    netstat -tlnp | grep -E ":30003|:30004|:30005" || echo "Aucun port NodePort trouvé"
else
    echo "netstat non disponible, utilisation de ss..."
    ss -tlnp | grep -E ":30003|:30004|:30005" || echo "Aucun port NodePort trouvé"
fi

echo ""
echo "Vérification des ports ouverts sur worker1..."
if command -v netstat &> /dev/null; then
    echo "Ports NodePort sur worker1:"
    ssh worker1 "netstat -tlnp | grep -E ':30003|:30004|:30005'" 2>/dev/null || echo "Impossible de se connecter à worker1"
else
    echo "netstat non disponible"
fi

echo ""
echo "=========================================="
echo "CORRECTIONS SUGGÉRÉES"
echo "=========================================="

echo "1. Ajouter le service ClusterIP manquant pour le dashboard..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: dashboard-service-clusterip
  namespace: $NAMESPACE
  labels:
    app: dashboard
spec:
  type: ClusterIP
  selector:
    app: dashboard
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      name: http
  sessionAffinity: None
EOF

echo ""
echo "2. Vérifier la configuration du réseau du cluster..."
echo "Vérification de la configuration kube-proxy..."
kubectl get pods -n kube-system -l k8s-app=kube-proxy

echo ""
echo "3. Vérifier les règles iptables pour les services NodePort..."
echo "Sur le master:"
iptables -t nat -L KUBE-NODEPORTS 2>/dev/null | grep -E "30003|30004|30005" || echo "Aucune règle iptables trouvée"

echo ""
echo "4. Test de connectivité directe aux pods..."
echo "Test depuis le master vers les pods sur worker1:"
kubectl exec -n $NAMESPACE -l app=dashboard -- curl -s http://localhost/ || echo "Dashboard pod non accessible"
kubectl exec -n $NAMESPACE -l app=middleware -- curl -s http://localhost:3000/health || echo "Middleware pod non accessible"
kubectl exec -n $NAMESPACE -l app=cbs-simulator -- curl -s http://localhost:4000/health || echo "CBS Simulator pod non accessible"

echo ""
echo "=========================================="
echo "SOLUTIONS ALTERNATIVES"
echo "=========================================="

echo "Si les services NodePort ne sont pas accessibles depuis le master:"
echo "1. Utiliser l'IP du worker1: http://$WORKER1_IP:30004"
echo "2. Configurer un LoadBalancer ou Ingress"
echo "3. Utiliser kubectl port-forward pour l'accès local"

echo ""
echo "Commandes de port-forward pour l'accès local:"
echo "kubectl port-forward -n $NAMESPACE service/dashboard-service 8080:80"
echo "kubectl port-forward -n $NAMESPACE service/middleware-service 8081:3000"
echo "kubectl port-forward -n $NAMESPACE service/cbs-simulator-service 8082:4000"

echo ""
echo "=========================================="
echo "Test terminé"
echo "=========================================="
