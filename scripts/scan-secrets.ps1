# Script PowerShell pour scanner les secrets dans le code avec Gitleaks
# Usage: .\scripts\scan-secrets.ps1 [options]

param(
    [switch]$Protect,
    [switch]$Staged,
    [switch]$Quiet,
    [string]$Source = ".",
    [switch]$Help
)

# Fonction pour afficher les messages colorés
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

# Afficher l'aide
if ($Help) {
    Write-Output "Usage: .\scripts\scan-secrets.ps1 [options]"
    Write-Output ""
    Write-Output "Options:"
    Write-Output "  -Protect     Mode protect (pour pre-commit hooks)"
    Write-Output "  -Staged      Scanner uniquement les fichiers stagés"
    Write-Output "  -Quiet       Mode silencieux"
    Write-Output "  -Source DIR  Répertoire à scanner (défaut: .)"
    Write-Output "  -Help        Afficher cette aide"
    Write-Output ""
    exit 0
}

Write-ColorOutput Green "🔍 Scan des secrets avec Gitleaks..."

# Vérifier si gitleaks est installé
$gitleaksPath = Get-Command gitleaks -ErrorAction SilentlyContinue
if (-not $gitleaksPath) {
    Write-ColorOutput Red "❌ Gitleaks n'est pas installé"
    Write-ColorOutput Yellow "📦 Installation de Gitleaks..."
    Write-Output ""
    Write-Output "Options d'installation:"
    Write-Output "  - Windows: scoop install gitleaks"
    Write-Output "  - Voir: https://github.com/gitleaks/gitleaks#installation"
    Write-Output ""
    exit 1
}

# Vérifier la version
$version = gitleaks version
Write-ColorOutput Green "✅ Gitleaks installé: $version"
Write-Output ""

# Déterminer le mode
$mode = "detect"
if ($Protect) {
    $mode = "protect"
} elseif ($Staged) {
    $mode = "detect-staged"
}

# Construire la commande
$verbose = if ($Quiet) { "" } else { "--verbose" }

# Exécuter le scan
try {
    switch ($mode) {
        "detect" {
            Write-ColorOutput Green "📊 Scan du repository complet..."
            gitleaks detect --source $Source $verbose
        }
        "detect-staged" {
            Write-ColorOutput Green "📊 Scan des fichiers stagés..."
            gitleaks detect --no-git --source $Source $verbose
        }
        "protect" {
            Write-ColorOutput Green "🛡️  Mode protect (recommandé pour pre-commit)..."
            gitleaks protect $verbose
        }
    }

    # Vérifier le code de sortie
    if ($LASTEXITCODE -eq 0) {
        Write-Output ""
        Write-ColorOutput Green "✅ Aucun secret détecté"
        exit 0
    } else {
        Write-Output ""
        Write-ColorOutput Red "❌ Des secrets ont été détectés !"
        Write-ColorOutput Yellow "⚠️  Veuillez corriger les problèmes avant de commiter"
        exit $LASTEXITCODE
    }
} catch {
    Write-ColorOutput Red "❌ Erreur lors du scan: $_"
    exit 1
}





