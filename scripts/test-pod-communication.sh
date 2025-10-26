#!/bin/bash

# Script de test pour vérifier la communication entre les pods dans le cluster Kubernetes
# Ce script teste la communication interne (ClusterIP) et externe (NodePort)

set -e

NAMESPACE="cbs-system"
CLUSTER_IP="192.168.90.129"  # Adresse IP du cluster

echo "=========================================="
echo "Test de Communication des Pods CBS System"
echo "=========================================="

# Fonction pour tester un endpoint
test_endpoint() {
    local url=$1
    local description=$2
    local expected_status=${3:-200}
    
    echo "Test: $description"
    echo "URL: $url"
    
    if response=$(curl -s -w "\n%{http_code}" "$url" 2>/dev/null); then
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

# Vérifier que le namespace existe
echo "Vérification du namespace..."
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    echo "❌ Namespace $NAMESPACE n'existe pas"
    exit 1
fi
echo "✅ Namespace $NAMESPACE existe"

# Vérifier les pods
echo "Vérification des pods..."
kubectl get pods -n "$NAMESPACE" -o wide

echo ""
echo "=========================================="
echo "TESTS DE COMMUNICATION INTERNE (ClusterIP)"
echo "=========================================="

# Test 1: CBS Simulator via ClusterIP
test_endpoint "http://cbs-simulator-service:4000/health" "CBS Simulator Health Check (ClusterIP)"

# Test 2: Middleware via ClusterIP
test_endpoint "http://middleware-service:3000/health" "Middleware Health Check (ClusterIP)"

# Test 3: Dashboard via ClusterIP
test_endpoint "http://dashboard-service:80/" "Dashboard Access (ClusterIP)"

echo ""
echo "=========================================="
echo "TESTS DE COMMUNICATION EXTERNE (NodePort)"
echo "=========================================="

# Test 4: CBS Simulator via NodePort
test_endpoint "http://$CLUSTER_IP:30005/health" "CBS Simulator Health Check (NodePort)"

# Test 5: Middleware via NodePort
test_endpoint "http://$CLUSTER_IP:30003/health" "Middleware Health Check (NodePort)"

# Test 6: Dashboard via NodePort
test_endpoint "http://$CLUSTER_IP:30004/" "Dashboard Access (NodePort)"

echo ""
echo "=========================================="
echo "TESTS DE COMMUNICATION INTER-SERVICES"
echo "=========================================="

# Test 7: Middleware -> CBS Simulator (communication interne)
echo "Test: Middleware vers CBS Simulator"
echo "Simulation d'un appel depuis le middleware vers CBS..."

# Créer un pod temporaire pour tester la communication interne
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: $NAMESPACE
spec:
  containers:
  - name: test-container
    image: curlimages/curl:latest
    command: ['sleep', '3600']
  restartPolicy: Never
EOF

# Attendre que le pod soit prêt
echo "Attente du pod de test..."
kubectl wait --for=condition=Ready pod/test-pod -n "$NAMESPACE" --timeout=60s

# Tester la communication depuis le pod de test
echo "Test de communication depuis le pod de test..."
kubectl exec -n "$NAMESPACE" test-pod -- curl -s "http://cbs-simulator-service:4000/health" || echo "❌ Échec communication CBS"
kubectl exec -n "$NAMESPACE" test-pod -- curl -s "http://middleware-service:3000/health" || echo "❌ Échec communication Middleware"
kubectl exec -n "$NAMESPACE" test-pod -- curl -s "http://dashboard-service:80/" || echo "❌ Échec communication Dashboard"

# Nettoyer le pod de test
kubectl delete pod test-pod -n "$NAMESPACE"

echo ""
echo "=========================================="
echo "RÉSUMÉ DES SERVICES"
echo "=========================================="

echo "Services ClusterIP (communication interne):"
kubectl get services -n "$NAMESPACE" --field-selector spec.type=ClusterIP

echo ""
echo "Services NodePort (accès externe):"
kubectl get services -n "$NAMESPACE" --field-selector spec.type=NodePort

echo ""
echo "Ports NodePort:"
echo "- CBS Simulator: $CLUSTER_IP:30005"
echo "- Middleware: $CLUSTER_IP:30003"
echo "- Dashboard: $CLUSTER_IP:30004"

echo ""
echo "=========================================="
echo "Test terminé"
echo "=========================================="
