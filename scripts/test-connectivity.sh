#!/bin/bash

# CBS Core Banking System - Connectivity Test Script
# This script tests pod-to-pod communication and NodePort access

set -e

NAMESPACE="cbs-system"
MASTER_IP="192.168.90.129"

echo "=========================================="
echo "CBS Core Banking System - Connectivity Test"
echo "=========================================="
echo "Master IP: $MASTER_IP"
echo "Namespace: $NAMESPACE"
echo "=========================================="

# Function to test HTTP endpoint
test_endpoint() {
    local url=$1
    local description=$2
    local expected_status=${3:-200}
    
    echo -n "Testing $description... "
    
    if response=$(curl -s -w "%{http_code}" -o /dev/null "$url" 2>/dev/null); then
        if [ "$response" = "$expected_status" ]; then
            echo "✅ PASS (HTTP $response)"
            return 0
        else
            echo "❌ FAIL (HTTP $response, expected $expected_status)"
            return 1
        fi
    else
        echo "❌ FAIL (Connection error)"
        return 1
    fi
}

# Function to test pod-to-pod communication
test_pod_communication() {
    echo ""
    echo "🔍 Testing Pod-to-Pod Communication..."
    echo "----------------------------------------"
    
    # Get pod names
    CBS_POD=$(kubectl get pods -n $NAMESPACE -l app=cbs-simulator -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    MIDDLEWARE_POD=$(kubectl get pods -n $NAMESPACE -l app=middleware -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    DASHBOARD_POD=$(kubectl get pods -n $NAMESPACE -l app=dashboard -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -z "$CBS_POD" ] || [ -z "$MIDDLEWARE_POD" ] || [ -z "$DASHBOARD_POD" ]; then
        echo "❌ Some pods are not running. Please check pod status:"
        kubectl get pods -n $NAMESPACE
        return 1
    fi
    
    echo "CBS Simulator Pod: $CBS_POD"
    echo "Middleware Pod: $MIDDLEWARE_POD"
    echo "Dashboard Pod: $DASHBOARD_POD"
    echo ""
    
    # Test CBS Simulator from Middleware pod
    echo "Testing CBS Simulator from Middleware pod..."
    if kubectl exec -n $NAMESPACE $MIDDLEWARE_POD -- curl -s -f "http://cbs-simulator-service:4000/health" > /dev/null 2>&1; then
        echo "✅ Middleware → CBS Simulator: PASS"
    else
        echo "❌ Middleware → CBS Simulator: FAIL"
    fi
    
    # Test Middleware from Dashboard pod
    echo "Testing Middleware from Dashboard pod..."
    if kubectl exec -n $NAMESPACE $DASHBOARD_POD -- curl -s -f "http://middleware-service:3000/health" > /dev/null 2>&1; then
        echo "✅ Dashboard → Middleware: PASS"
    else
        echo "❌ Dashboard → Middleware: FAIL"
    fi
    
    # Test API endpoints through middleware
    echo "Testing API endpoints through middleware..."
    if kubectl exec -n $NAMESPACE $MIDDLEWARE_POD -- curl -s -f "http://cbs-simulator-service:4000/api/accounts/12345" > /dev/null 2>&1; then
        echo "✅ Middleware → CBS Simulator API: PASS"
    else
        echo "❌ Middleware → CBS Simulator API: FAIL"
    fi
}

# Function to test NodePort access
test_nodeport_access() {
    echo ""
    echo "🌐 Testing NodePort External Access..."
    echo "----------------------------------------"
    
    # Test CBS Simulator NodePort
    test_endpoint "http://$MASTER_IP:30005/health" "CBS Simulator NodePort (30005)"
    
    # Test Middleware NodePort
    test_endpoint "http://$MASTER_IP:30003/health" "Middleware NodePort (30003)"
    
    # Test Dashboard NodePort
    test_endpoint "http://$MASTER_IP:30004/" "Dashboard NodePort (30004)"
}

# Function to test API communication flow
test_api_flow() {
    echo ""
    echo "🔄 Testing API Communication Flow..."
    echo "----------------------------------------"
    
    # Test Dashboard → Middleware → CBS Simulator flow
    echo "Testing complete API flow..."
    
    # Test middleware health
    if test_endpoint "http://$MASTER_IP:30003/health" "Middleware Health Check"; then
        echo "✅ Middleware is healthy"
    else
        echo "❌ Middleware health check failed"
        return 1
    fi
    
    # Test CBS Simulator health
    if test_endpoint "http://$MASTER_IP:30005/health" "CBS Simulator Health Check"; then
        echo "✅ CBS Simulator is healthy"
    else
        echo "❌ CBS Simulator health check failed"
        return 1
    fi
    
    # Test API endpoints
    echo "Testing API endpoints..."
    
    # Test account lookup through middleware
    if curl -s -f "http://$MASTER_IP:30003/api/accounts/12345" > /dev/null 2>&1; then
        echo "✅ Account lookup API: PASS"
    else
        echo "❌ Account lookup API: FAIL"
    fi
    
    # Test balance inquiry through middleware
    if curl -s -f "http://$MASTER_IP:30003/api/balance/12345" > /dev/null 2>&1; then
        echo "✅ Balance inquiry API: PASS"
    else
        echo "❌ Balance inquiry API: FAIL"
    fi
}

# Function to check pod status
check_pod_status() {
    echo ""
    echo "📊 Checking Pod Status..."
    echo "----------------------------------------"
    kubectl get pods -n $NAMESPACE -o wide
    echo ""
    echo "📊 Checking Services..."
    echo "----------------------------------------"
    kubectl get services -n $NAMESPACE
}

# Function to check logs for errors
check_logs() {
    echo ""
    echo "📋 Checking Recent Logs for Errors..."
    echo "----------------------------------------"
    
    echo "CBS Simulator logs (last 10 lines):"
    kubectl logs -n $NAMESPACE -l app=cbs-simulator --tail=10 || echo "No logs available"
    echo ""
    
    echo "Middleware logs (last 10 lines):"
    kubectl logs -n $NAMESPACE -l app=middleware --tail=10 || echo "No logs available"
    echo ""
    
    echo "Dashboard logs (last 10 lines):"
    kubectl logs -n $NAMESPACE -l app=dashboard --tail=10 || echo "No logs available"
}

# Main execution
main() {
    echo "Starting connectivity tests..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check if namespace exists
    if ! kubectl get namespace $NAMESPACE &> /dev/null; then
        echo "❌ Namespace '$NAMESPACE' does not exist"
        echo "Please deploy the application first:"
        echo "kubectl apply -f kubernetes/cbs-system-complete.yaml"
        exit 1
    fi
    
    # Run tests
    check_pod_status
    test_pod_communication
    test_nodeport_access
    test_api_flow
    check_logs
    
    echo ""
    echo "=========================================="
    echo "Connectivity Test Complete"
    echo "=========================================="
    echo "Access URLs:"
    echo "  Dashboard:  http://$MASTER_IP:30004"
    echo "  Middleware: http://$MASTER_IP:30003"
    echo "  CBS Simulator: http://$MASTER_IP:30005"
    echo "=========================================="
}

# Run main function
main "$@"
