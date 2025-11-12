# Script d'Installation et Configuration Automatique de Semgrep
# Exécutez : .\install-semgrep.ps1

Write-Host "🚀 Installation de Semgrep..." -ForegroundColor Cyan
Write-Host ""

# Étape 1 : Installer Semgrep
Write-Host "📦 Installation de Semgrep via pip..." -ForegroundColor Yellow
pip install --user semgrep

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors de l'installation. Vérifiez que Python et pip sont installés." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Semgrep installé avec succès!" -ForegroundColor Green
Write-Host ""

# Étape 2 : Détecter le répertoire Scripts
Write-Host "🔍 Détection du répertoire d'installation..." -ForegroundColor Yellow

# Obtenir la version Python
$pythonVersion = python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>&1
$pythonVersionShort = python -c "import sys; print(f'{sys.version_info.major}{sys.version_info.minor}')" 2>&1

# Essayer différents formats de chemin
$possiblePaths = @(
    "$env:APPDATA\Python\Python$pythonVersion\Scripts",
    "$env:APPDATA\Python\Python$pythonVersionShort\Scripts",
    "$env:LOCALAPPDATA\Programs\Python\Python$pythonVersion\Scripts",
    "$env:LOCALAPPDATA\Programs\Python\Python$pythonVersionShort\Scripts"
)

$pythonScripts = $null
foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $semgrepExe = Join-Path $path "semgrep.exe"
        if (Test-Path $semgrepExe) {
            $pythonScripts = $path
            break
        }
    }
}

# Si non trouvé, chercher dans tous les Scripts Python
if (-not $pythonScripts) {
    $allPythonScripts = Get-ChildItem -Path "$env:APPDATA\Python" -Recurse -Filter "semgrep.exe" -ErrorAction SilentlyContinue
    if ($allPythonScripts) {
        $pythonScripts = $allPythonScripts[0].DirectoryName
    }
}

if (-not $pythonScripts) {
    Write-Host "❌ Répertoire Scripts non trouvé automatiquement." -ForegroundColor Red
    Write-Host "💡 Utilisez 'python -m semgrep' en attendant." -ForegroundColor Yellow
    Write-Host "💡 Ou trouvez manuellement le répertoire avec : python -m pip show semgrep" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Répertoire trouvé : $pythonScripts" -ForegroundColor Green
Write-Host ""

# Étape 3 : Ajouter au PATH utilisateur
Write-Host "🔧 Configuration du PATH..." -ForegroundColor Yellow

$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

if ($currentPath -like "*$pythonScripts*") {
    Write-Host "✅ Le répertoire est déjà dans le PATH utilisateur." -ForegroundColor Green
} else {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$pythonScripts", "User")
    Write-Host "✅ PATH utilisateur mis à jour." -ForegroundColor Green
}

# Recharger le PATH pour cette session
$env:Path += ";$pythonScripts"
Write-Host "✅ PATH rechargé pour cette session." -ForegroundColor Green
Write-Host ""

# Étape 4 : Vérification
Write-Host "🔍 Vérification de l'installation..." -ForegroundColor Cyan

try {
    $version = semgrep --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Semgrep fonctionne ! Version : $version" -ForegroundColor Green
        Write-Host ""
        Write-Host "🎉 Installation terminée avec succès !" -ForegroundColor Green
        Write-Host ""
        Write-Host "⚠️  IMPORTANT : Redémarrez PowerShell pour que le PATH soit permanent." -ForegroundColor Yellow
        Write-Host "   Après redémarrage, testez : semgrep --version" -ForegroundColor White
    } else {
        Write-Host "⚠️  Semgrep installé mais pas encore accessible dans cette session." -ForegroundColor Yellow
        Write-Host "💡 Redémarrez PowerShell et testez : semgrep --version" -ForegroundColor White
        Write-Host "💡 Ou utilisez maintenant : python -m semgrep --version" -ForegroundColor White
    }
} catch {
    Write-Host "⚠️  Semgrep installé mais pas encore accessible dans cette session." -ForegroundColor Yellow
    Write-Host "💡 Redémarrez PowerShell et testez : semgrep --version" -ForegroundColor White
    Write-Host "💡 Ou utilisez maintenant : python -m semgrep --version" -ForegroundColor White
}

Write-Host ""
Write-Host "📝 Utilisation :" -ForegroundColor Cyan
Write-Host "   semgrep --config=.semgrep.yml ." -ForegroundColor White
Write-Host "   npm run security:semgrep" -ForegroundColor White

