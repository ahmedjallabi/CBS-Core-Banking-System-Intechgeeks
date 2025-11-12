# 🚀 Installation Fixe de Semgrep sur Windows

## ✅ Solution Recommandée : Installation via pip avec PATH automatique

Cette méthode installe Semgrep et configure automatiquement le PATH.

### Étape 1 : Installer Semgrep

```powershell
# Installer Semgrep
pip install --user semgrep
```

### Étape 2 : Ajouter automatiquement au PATH (Script PowerShell)

Exécutez ce script **UNE SEULE FOIS** après l'installation :

```powershell
# Détecter automatiquement le répertoire Scripts Python
$pythonScripts = "$env:APPDATA\Python\Python$($(python -c 'import sys; print(sys.version_info.major, sys.version_info.minor, sep="")') -replace ' ', '')\Scripts"

# Vérifier si le répertoire existe
if (Test-Path $pythonScripts) {
    # Obtenir le PATH utilisateur actuel
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    
    # Vérifier si déjà dans le PATH
    if ($currentPath -notlike "*$pythonScripts*") {
        # Ajouter au PATH utilisateur
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$pythonScripts", "User")
        Write-Host "✅ PATH mis à jour avec : $pythonScripts" -ForegroundColor Green
        Write-Host "⚠️  Redémarrez PowerShell pour que les changements prennent effet." -ForegroundColor Yellow
    } else {
        Write-Host "✅ PATH déjà configuré." -ForegroundColor Green
    }
    
    # Recharger le PATH pour cette session
    $env:Path += ";$pythonScripts"
    Write-Host "✅ PATH rechargé pour cette session." -ForegroundColor Green
} else {
    Write-Host "❌ Répertoire non trouvé : $pythonScripts" -ForegroundColor Red
    Write-Host "💡 Essayez de réinstaller Semgrep : pip install --user semgrep" -ForegroundColor Yellow
}
```

### Étape 3 : Redémarrer PowerShell

**IMPORTANT** : Fermez et rouvrez PowerShell pour que le PATH soit chargé.

### Étape 4 : Vérifier

```powershell
semgrep --version
```

---

## 🔧 Solution Alternative : Installation via pip avec configuration manuelle du PATH

Si le script automatique ne fonctionne pas, suivez ces étapes :

### Étape 1 : Installer Semgrep

```powershell
pip install --user semgrep
```

### Étape 2 : Trouver le répertoire d'installation

```powershell
# Trouver où pip a installé Semgrep
python -m pip show semgrep | Select-String "Location"
```

Ou cherchez dans :
```
C:\Users\VOTRE_NOM\AppData\Roaming\Python\Python313\Scripts
```
(Remplacez `VOTRE_NOM` et `Python313` par vos valeurs)

### Étape 3 : Ajouter au PATH manuellement

**Méthode A : Via PowerShell (Permanent)**

```powershell
# Remplacez le chemin par celui trouvé à l'étape 2
$scriptsPath = "C:\Users\VOTRE_NOM\AppData\Roaming\Python\Python313\Scripts"

# Ajouter au PATH utilisateur
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
[Environment]::SetEnvironmentVariable("Path", "$currentPath;$scriptsPath", "User")

# Recharger pour cette session
$env:Path += ";$scriptsPath"
```

**Méthode B : Via Interface Windows (Permanent)**

1. Appuyez sur `Windows + R`
2. Tapez : `sysdm.cpl` et appuyez sur Entrée
3. Onglet **"Avancé"** → **"Variables d'environnement"**
4. Dans **"Variables utilisateur"**, sélectionnez **"Path"** → **"Modifier"**
5. Cliquez sur **"Nouveau"**
6. Ajoutez le chemin trouvé à l'étape 2 (ex: `C:\Users\VOTRE_NOM\AppData\Roaming\Python\Python313\Scripts`)
7. Cliquez sur **"OK"** partout
8. **Redémarrez PowerShell**

### Étape 4 : Vérifier

```powershell
semgrep --version
```

---

## 🎯 Solution Rapide : Utiliser python -m semgrep (Temporaire)

Si vous ne voulez pas modifier le PATH, vous pouvez utiliser :

```powershell
# Utiliser python -m semgrep (fonctionne toujours)
python -m semgrep --version

# Scanner le projet
python -m semgrep --config=.semgrep.yml .
```

**Note** : Les scripts npm sont configurés pour utiliser cette méthode automatiquement.

---

## 📝 Script d'Installation Complet (Copier-Coller)

Exécutez ce script complet dans PowerShell :

```powershell
# Installation et configuration automatique de Semgrep
Write-Host "🚀 Installation de Semgrep..." -ForegroundColor Cyan

# Installer Semgrep
pip install --user semgrep

# Détecter le répertoire Scripts
$pythonVersion = python -c "import sys; print(f'Python{sys.version_info.major}{sys.version_info.minor}')"
$pythonScripts = "$env:APPDATA\Python\$pythonVersion\Scripts"

# Si le répertoire n'existe pas, essayer avec le format complet
if (-not (Test-Path $pythonScripts)) {
    $pythonVersionFull = python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
    $pythonScripts = "$env:APPDATA\Python\Python$pythonVersionFull\Scripts"
}

if (Test-Path $pythonScripts) {
    Write-Host "✅ Répertoire trouvé : $pythonScripts" -ForegroundColor Green
    
    # Ajouter au PATH utilisateur
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$pythonScripts*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$pythonScripts", "User")
        Write-Host "✅ PATH utilisateur mis à jour." -ForegroundColor Green
    }
    
    # Recharger pour cette session
    $env:Path += ";$pythonScripts"
    Write-Host "✅ PATH rechargé pour cette session." -ForegroundColor Green
    
    # Tester
    Write-Host "`n🔍 Vérification..." -ForegroundColor Cyan
    semgrep --version
    
    Write-Host "`n⚠️  Redémarrez PowerShell pour que le PATH soit permanent." -ForegroundColor Yellow
} else {
    Write-Host "❌ Répertoire non trouvé. Utilisez 'python -m semgrep' en attendant." -ForegroundColor Red
}
```

---

## ✅ Vérification Finale

Après l'installation et la configuration du PATH :

```powershell
# Vérifier la version
semgrep --version

# Tester un scan
semgrep --config=.semgrep.yml . --dry-run

# Utiliser les scripts npm
npm run security:semgrep
```

---

## 🚨 Dépannage

### "semgrep n'est pas reconnu" après redémarrage

1. Vérifiez que le PATH contient le bon répertoire :
   ```powershell
   $env:Path -split ';' | Select-String "Python.*Scripts"
   ```

2. Si le répertoire n'apparaît pas, réexécutez le script d'installation

3. Vérifiez que Semgrep est bien installé :
   ```powershell
   python -m pip show semgrep
   ```

### "pip n'est pas reconnu"

Installez Python depuis https://www.python.org/downloads/ et **cochez "Add Python to PATH"** lors de l'installation.

---

## 📚 Ressources

- [Documentation Semgrep](https://semgrep.dev/docs/)
- [Releases GitHub](https://github.com/returntocorp/semgrep/releases)

---

**💡 Astuce** : Après l'installation, redémarrez toujours PowerShell pour que le PATH soit chargé correctement.
