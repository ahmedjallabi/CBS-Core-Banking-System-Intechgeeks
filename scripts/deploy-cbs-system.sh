#!/bin/bash

# CBS Core Banking System - Deployment Script
# This script deploys the complete CBS system with proper networking

set -e

NAMESPACE="cbs-system"
KUBECONFIG_PATH="/var/lib/jenkins/.kube/config"

echo "=========================================="
echo "CBS Core Banking System - Deployment"
echo "=========================================="
echo "Namespace: $NAMESPACE"
echo "Kubeconfig: $KUBECONFIG_PATH"
echo "=========================================="

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl is not installed or not in PATH"
        exit 1
    fi
    echo "✅ kubectl is available"
}

# Function to check cluster connectivity
check_cluster() {
    echo "🔍 Checking cluster connectivity..."
    if kubectl cluster-info &> /dev/null; then
        echo "✅ Cluster is accessible"
        kubectl cluster-info
    else
        echo "❌ Cannot connect to cluster"
        exit 1
    fi
}

# Function to deploy the application
deploy_application() {
    echo ""
    echo "🚀 Deploying CBS Core Banking System..."
    echo "----------------------------------------"
    
    # Apply the optimized configuration
    if kubectl apply -f kubernetes/cbs-system-optimized.yaml; then
        echo "✅ Kubernetes manifests applied successfully"
    else
        echo "❌ Failed to apply Kubernetes manifests"
        exit 1
    fi
    
    echo ""
    echo "⏳ Waiting for deployments to be ready..."
    
    # Wait for deployments to be ready
    echo "Waiting for CBS Simulator..."
    kubectl wait --for=condition=available --timeout=300s deployment/cbs-simulator -n $NAMESPACE
    
    echo "Waiting for Middleware..."
    kubectl wait --for=condition=available --timeout=300s deployment/middleware -n $NAMESPACE
    
    echo "Waiting for Dashboard..."
    kubectl wait --for=condition=available --timeout=300s deployment/dashboard -n $NAMESPACE
    
    echo "✅ All deployments are ready"
}

# Function to verify deployment
verify_deployment() {
    echo ""
    echo "🔍 Verifying deployment..."
    echo "----------------------------------------"
    
    echo "Pod Status:"
    kubectl get pods -n $NAMESPACE -o wide
    
    echo ""
    echo "Service Status:"
    kubectl get services -n $NAMESPACE
    
    echo ""
    echo "Deployment Status:"
    kubectl get deployments -n $NAMESPACE
    
    echo ""
    echo "Network Policy Status:"
    kubectl get networkpolicy -n $NAMESPACE
}

# Function to test connectivity
test_connectivity() {
    echo ""
    echo "🧪 Testing connectivity..."
    echo "----------------------------------------"
    
    # Make the test script executable and run it
    chmod +x scripts/test-connectivity.sh
    if ./scripts/test-connectivity.sh; then
        echo "✅ Connectivity tests passed"
    else
        echo "⚠️ Some connectivity tests failed - check logs above"
    fi
}

# Function to show access information
show_access_info() {
    echo ""
    echo "=========================================="
    echo "Deployment Complete - Access Information"
    echo "=========================================="
    echo ""
    echo "🌐 External Access URLs:"
    echo "  Dashboard:  http://192.168.90.129:30004"
    echo "  Middleware: http://192.168.90.129:30003"
    echo "  CBS Simulator: http://192.168.90.129:30005"
    echo ""
    echo "🔗 Internal Service URLs (for pod-to-pod communication):"
    echo "  CBS Simulator: http://cbs-simulator-service:4000"
    echo "  Middleware: http://middleware-service:3000"
    echo ""
    echo "📊 Monitoring Commands:"
    echo "  kubectl get pods -n $NAMESPACE"
    echo "  kubectl get services -n $NAMESPACE"
    echo "  kubectl logs -n $NAMESPACE -l app=cbs-simulator"
    echo "  kubectl logs -n $NAMESPACE -l app=middleware"
    echo "  kubectl logs -n $NAMESPACE -l app=dashboard"
    echo ""
    echo "🧪 Run connectivity tests:"
    echo "  ./scripts/test-connectivity.sh"
    echo "=========================================="
}

# Function to cleanup (optional)
cleanup() {
    echo ""
    echo "🧹 Cleaning up previous deployment..."
    echo "----------------------------------------"
    
    if kubectl get namespace $NAMESPACE &> /dev/null; then
        kubectl delete namespace $NAMESPACE
        echo "✅ Previous deployment cleaned up"
    else
        echo "ℹ️ No previous deployment found"
    fi
}

# Main execution
main() {
    local action=${1:-deploy}
    
    case $action in
        "deploy")
            check_kubectl
            check_cluster
            deploy_application
            verify_deployment
            test_connectivity
            show_access_info
            ;;
        "cleanup")
            cleanup
            ;;
        "test")
            test_connectivity
            ;;
        "status")
            verify_deployment
            ;;
        *)
            echo "Usage: $0 [deploy|cleanup|test|status]"
            echo "  deploy  - Deploy the complete system (default)"
            echo "  cleanup - Remove the deployment"
            echo "  test    - Run connectivity tests"
            echo "  status  - Show deployment status"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
