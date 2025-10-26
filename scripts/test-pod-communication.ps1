# Script PowerShell pour tester la communication entre les pods dans le cluster Kubernetes
# Ce script teste la communication interne (ClusterIP) et externe (NodePort)

param(
    [string]$ClusterIP = "192.168.90.129",
    [string]$Namespace = "cbs-system"
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Test de Communication des Pods CBS System" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Fonction pour tester un endpoint
function Test-Endpoint {
    param(
        [string]$Url,
        [string]$Description,
        [int]$ExpectedStatus = 200
    )
    
    Write-Host "Test: $Description" -ForegroundColor Yellow
    Write-Host "URL: $Url"
    
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10
        $statusCode = $response.StatusCode
        
        if ($statusCode -eq $ExpectedStatus) {
            Write-Host "✅ SUCCESS - Status: $statusCode" -ForegroundColor Green
            $body = $response.Content.Substring(0, [Math]::Min(100, $response.Content.Length))
            Write-Host "Response: $body..."
        } else {
            Write-Host "❌ FAILED - Expected: $ExpectedStatus, Got: $statusCode" -ForegroundColor Red
            Write-Host "Response: $($response.Content)"
        }
    } catch {
        Write-Host "❌ CONNECTION FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host "----------------------------------------"
}

# Vérifier que le namespace existe
Write-Host "Vérification du namespace..." -ForegroundColor Yellow
try {
    kubectl get namespace $Namespace | Out-Null
    Write-Host "✅ Namespace $Namespace existe" -ForegroundColor Green
} catch {
    Write-Host "❌ Namespace $Namespace n'existe pas" -ForegroundColor Red
    exit 1
}

# Vérifier les pods
Write-Host "Vérification des pods..." -ForegroundColor Yellow
kubectl get pods -n $Namespace -o wide

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "TESTS DE COMMUNICATION INTERNE (ClusterIP)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Test 1: CBS Simulator via ClusterIP
Test-Endpoint -Url "http://cbs-simulator-service:4000/health" -Description "CBS Simulator Health Check (ClusterIP)"

# Test 2: Middleware via ClusterIP
Test-Endpoint -Url "http://middleware-service:3000/health" -Description "Middleware Health Check (ClusterIP)"

# Test 3: Dashboard via ClusterIP
Test-Endpoint -Url "http://dashboard-service:80/" -Description "Dashboard Access (ClusterIP)"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "TESTS DE COMMUNICATION EXTERNE (NodePort)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Test 4: CBS Simulator via NodePort
Test-Endpoint -Url "http://$ClusterIP`:30005/health" -Description "CBS Simulator Health Check (NodePort)"

# Test 5: Middleware via NodePort
Test-Endpoint -Url "http://$ClusterIP`:30003/health" -Description "Middleware Health Check (NodePort)"

# Test 6: Dashboard via NodePort
Test-Endpoint -Url "http://$ClusterIP`:30004/" -Description "Dashboard Access (NodePort)"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "TESTS DE COMMUNICATION INTER-SERVICES" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Test 7: Middleware -> CBS Simulator (communication interne)
Write-Host "Test: Middleware vers CBS Simulator" -ForegroundColor Yellow
Write-Host "Simulation d'un appel depuis le middleware vers CBS..."

# Créer un pod temporaire pour tester la communication interne
$testPodYaml = @"
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: $Namespace
spec:
  containers:
  - name: test-container
    image: curlimages/curl:latest
    command: ['sleep', '3600']
  restartPolicy: Never
"@

$testPodYaml | kubectl apply -f -

# Attendre que le pod soit prêt
Write-Host "Attente du pod de test..." -ForegroundColor Yellow
kubectl wait --for=condition=Ready pod/test-pod -n $Namespace --timeout=60s

# Tester la communication depuis le pod de test
Write-Host "Test de communication depuis le pod de test..." -ForegroundColor Yellow
try {
    kubectl exec -n $Namespace test-pod -- curl -s "http://cbs-simulator-service:4000/health"
    Write-Host "✅ Communication CBS réussie" -ForegroundColor Green
} catch {
    Write-Host "❌ Échec communication CBS" -ForegroundColor Red
}

try {
    kubectl exec -n $Namespace test-pod -- curl -s "http://middleware-service:3000/health"
    Write-Host "✅ Communication Middleware réussie" -ForegroundColor Green
} catch {
    Write-Host "❌ Échec communication Middleware" -ForegroundColor Red
}

try {
    kubectl exec -n $Namespace test-pod -- curl -s "http://dashboard-service:80/"
    Write-Host "✅ Communication Dashboard réussie" -ForegroundColor Green
} catch {
    Write-Host "❌ Échec communication Dashboard" -ForegroundColor Red
}

# Nettoyer le pod de test
kubectl delete pod test-pod -n $Namespace

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "RÉSUMÉ DES SERVICES" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

Write-Host "Services ClusterIP (communication interne):" -ForegroundColor Yellow
kubectl get services -n $Namespace --field-selector spec.type=ClusterIP

Write-Host ""
Write-Host "Services NodePort (accès externe):" -ForegroundColor Yellow
kubectl get services -n $Namespace --field-selector spec.type=NodePort

Write-Host ""
Write-Host "Ports NodePort:" -ForegroundColor Yellow
Write-Host "- CBS Simulator: $ClusterIP`:30005" -ForegroundColor White
Write-Host "- Middleware: $ClusterIP`:30003" -ForegroundColor White
Write-Host "- Dashboard: $ClusterIP`:30004" -ForegroundColor White

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Test terminé" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
