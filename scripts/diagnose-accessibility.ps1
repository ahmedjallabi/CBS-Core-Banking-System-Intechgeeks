# Script PowerShell de diagnostic et correction pour l'accessibilité des services NodePort
# Ce script identifie et corrige les problèmes d'accessibilité depuis l'IP du master

param(
    [string]$MasterIP = "192.168.90.136",
    [string]$Worker1IP = "192.168.90.130",
    [string]$Namespace = "cbs-system"
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Diagnostic d'Accessibilité CBS System" -ForegroundColor Cyan
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

Write-Host "1. Vérification des nœuds du cluster..." -ForegroundColor Yellow
kubectl get nodes -o wide

Write-Host ""
Write-Host "2. Vérification des pods et leur localisation..." -ForegroundColor Yellow
kubectl get pods -n $Namespace -o wide

Write-Host ""
Write-Host "3. Vérification des services..." -ForegroundColor Yellow
kubectl get services -n $Namespace

Write-Host ""
Write-Host "4. Vérification des endpoints..." -ForegroundColor Yellow
kubectl get endpoints -n $Namespace

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "TESTS D'ACCESSIBILITÉ DEPUIS LE MASTER" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Test des services NodePort depuis le master
Write-Host "Tests depuis l'IP du master ($MasterIP):" -ForegroundColor Yellow
Test-Endpoint -Url "http://$MasterIP`:30004/" -Description "Dashboard (NodePort)"
Test-Endpoint -Url "http://$MasterIP`:30003/health" -Description "Middleware Health (NodePort)"
Test-Endpoint -Url "http://$MasterIP`:30005/health" -Description "CBS Simulator Health (NodePort)"

Write-Host ""
Write-Host "Tests depuis l'IP du worker1 ($Worker1IP):" -ForegroundColor Yellow
Test-Endpoint -Url "http://$Worker1IP`:30004/" -Description "Dashboard (NodePort)"
Test-Endpoint -Url "http://$Worker1IP`:30003/health" -Description "Middleware Health (NodePort)"
Test-Endpoint -Url "http://$Worker1IP`:30005/health" -Description "CBS Simulator Health (NodePort)"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "DIAGNOSTIC DES PROBLÈMES" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Vérifier si les ports sont ouverts sur le master
Write-Host "Vérification des ports ouverts sur le master..." -ForegroundColor Yellow
try {
    $ports = Get-NetTCPConnection -LocalPort @(30003, 30004, 30005) -ErrorAction SilentlyContinue
    if ($ports) {
        Write-Host "Ports NodePort trouvés sur le master:" -ForegroundColor Green
        $ports | Format-Table LocalAddress, LocalPort, State
    } else {
        Write-Host "Aucun port NodePort trouvé sur le master" -ForegroundColor Red
    }
} catch {
    Write-Host "Impossible de vérifier les ports: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "CORRECTIONS SUGGÉRÉES" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

Write-Host "1. Ajouter le service ClusterIP manquant pour le dashboard..." -ForegroundColor Yellow
$clusteripService = @"
apiVersion: v1
kind: Service
metadata:
  name: dashboard-service-clusterip
  namespace: $Namespace
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
"@

$clusteripService | kubectl apply -f -

Write-Host ""
Write-Host "2. Vérifier la configuration du réseau du cluster..." -ForegroundColor Yellow
Write-Host "Vérification de la configuration kube-proxy..." -ForegroundColor Yellow
kubectl get pods -n kube-system -l k8s-app=kube-proxy

Write-Host ""
Write-Host "3. Test de connectivité directe aux pods..." -ForegroundColor Yellow
Write-Host "Test depuis le master vers les pods sur worker1:" -ForegroundColor Yellow
try {
    kubectl exec -n $Namespace -l app=dashboard -- curl -s http://localhost/ | Out-Null
    Write-Host "✅ Dashboard pod accessible" -ForegroundColor Green
} catch {
    Write-Host "❌ Dashboard pod non accessible" -ForegroundColor Red
}

try {
    kubectl exec -n $Namespace -l app=middleware -- curl -s http://localhost:3000/health | Out-Null
    Write-Host "✅ Middleware pod accessible" -ForegroundColor Green
} catch {
    Write-Host "❌ Middleware pod non accessible" -ForegroundColor Red
}

try {
    kubectl exec -n $Namespace -l app=cbs-simulator -- curl -s http://localhost:4000/health | Out-Null
    Write-Host "✅ CBS Simulator pod accessible" -ForegroundColor Green
} catch {
    Write-Host "❌ CBS Simulator pod non accessible" -ForegroundColor Red
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "SOLUTIONS ALTERNATIVES" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

Write-Host "Si les services NodePort ne sont pas accessibles depuis le master:" -ForegroundColor Yellow
Write-Host "1. Utiliser l'IP du worker1: http://$Worker1IP`:30004" -ForegroundColor White
Write-Host "2. Configurer un LoadBalancer ou Ingress" -ForegroundColor White
Write-Host "3. Utiliser kubectl port-forward pour l'accès local" -ForegroundColor White

Write-Host ""
Write-Host "Commandes de port-forward pour l'accès local:" -ForegroundColor Yellow
Write-Host "kubectl port-forward -n $Namespace service/dashboard-service 8080:80" -ForegroundColor White
Write-Host "kubectl port-forward -n $Namespace service/middleware-service 8081:3000" -ForegroundColor White
Write-Host "kubectl port-forward -n $Namespace service/cbs-simulator-service 8082:4000" -ForegroundColor White

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Test terminé" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

