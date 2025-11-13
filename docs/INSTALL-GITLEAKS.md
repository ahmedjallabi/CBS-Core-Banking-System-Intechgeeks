# 📦 Guide d'Installation de Gitleaks

## 🪟 Windows

### Option 1: Scoop (Recommandé)

**Prérequis:** Avoir Scoop installé

1. **Installer Scoop (si pas déjà installé):**
```powershell
# Ouvrir PowerShell en tant qu'administrateur
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
```

2. **Ajouter le bucket Gitleaks:**
```powershell
scoop bucket add gitleaks https://github.com/zricethezav/gitleaks.git
```

3. **Installer Gitleaks:**
```powershell
scoop install gitleaks
```

4. **Vérifier l'installation:**
```powershell
gitleaks version
```

### Option 2: Téléchargement Direct (Windows)

1. **Télécharger la dernière version:**
   - Aller sur: https://github.com/gitleaks/gitleaks/releases
   - Télécharger: `gitleaks_X.X.X_windows_amd64.zip` (pour Windows 64-bit)
   - Ou: `gitleaks_X.X.X_windows_386.zip` (pour Windows 32-bit)

2. **Extraire l'archive:**
   - Extraire `gitleaks.exe` dans un dossier (ex: `C:\tools\gitleaks\`)

3. **Ajouter au PATH:**
   ```powershell
   # Méthode 1: Via l'interface Windows
   # 1. Cliquez droit sur "Ce PC" > Propriétés
   # 2. Paramètres système avancés
   # 3. Variables d'environnement
   # 4. Ajouter C:\tools\gitleaks\ au PATH
   
   # Méthode 2: Via PowerShell (administrateur)
   [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\tools\gitleaks", [EnvironmentVariableTarget]::Machine)
   ```

4. **Vérifier l'installation:**
```powershell
gitleaks version
```

### Option 3: Chocolatey (Windows)

**Prérequis:** Avoir Chocolatey installé

```powershell
# Installer Chocolatey (si pas déjà installé)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Installer Gitleaks
choco install gitleaks
```

### Option 4: winget (Windows Package Manager)

**Prérequis:** Windows 10/11 avec winget installé

```powershell
winget install --id gitleaks.gitleaks -e --source winget
```

---

## 🍎 macOS

### Option 1: Homebrew (Recommandé)

```bash
# Installer Homebrew (si pas déjà installé)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Installer Gitleaks
brew install gitleaks

# Vérifier l'installation
gitleaks version
```

### Option 2: Téléchargement Direct (macOS)

1. **Télécharger la dernière version:**
   - Aller sur: https://github.com/gitleaks/gitleaks/releases
   - Télécharger: `gitleaks_X.X.X_darwin_amd64.tar.gz` (pour Intel)
   - Ou: `gitleaks_X.X.X_darwin_arm64.tar.gz` (pour Apple Silicon)

2. **Extraire et installer:**
```bash
# Extraire
tar -xzf gitleaks_X.X.X_darwin_amd64.tar.gz

# Déplacer vers /usr/local/bin
sudo mv gitleaks /usr/local/bin/

# Vérifier l'installation
gitleaks version
```

### Option 3: MacPorts

```bash
sudo port install gitleaks
```

---

## 🐧 Linux

### Option 1: Téléchargement Direct (Linux)

1. **Télécharger la dernière version:**
   - Aller sur: https://github.com/gitleaks/gitleaks/releases
   - Télécharger: `gitleaks_X.X.X_linux_amd64.tar.gz` (pour Linux 64-bit)
   - Ou: `gitleaks_X.X.X_linux_arm64.tar.gz` (pour ARM)

2. **Extraire et installer:**
```bash
# Extraire
tar -xzf gitleaks_X.X.X_linux_amd64.tar.gz

# Déplacer vers /usr/local/bin
sudo mv gitleaks /usr/local/bin/

# Vérifier l'installation
gitleaks version
```

### Option 2: Snap (Linux)

```bash
sudo snap install gitleaks
```

### Option 3: AUR (Arch Linux)

```bash
yay -S gitleaks
# ou
paru -S gitleaks
```

### Option 4: APT (Debian/Ubuntu)

```bash
# Ajouter le repository (si disponible)
# Ou utiliser le téléchargement direct
```

---

## 🐹 Go (Toutes plateformes)

**Prérequis:** Avoir Go installé (https://golang.org/)

```bash
# Installer Gitleaks via Go
go install github.com/gitleaks/gitleaks/v8@latest

# Ajouter Go bin au PATH (si nécessaire)
export PATH=$PATH:$(go env GOPATH)/bin

# Vérifier l'installation
gitleaks version
```

---

## 🐳 Docker (Toutes plateformes)

**Prérequis:** Avoir Docker installé

```bash
# Utiliser Gitleaks via Docker
docker run -v ${PWD}:/path zricethezav/gitleaks:latest detect --source="/path" --verbose

# Ou créer un alias
alias gitleaks='docker run -v ${PWD}:/path zricethezav/gitleaks:latest detect --source="/path"'
```

---

## ✅ Vérification de l'Installation

Après l'installation, vérifiez que Gitleaks fonctionne:

```bash
# Vérifier la version
gitleaks version

# Afficher l'aide
gitleaks help

# Tester avec un scan
gitleaks detect --source . --verbose
```

---

## 🔧 Configuration du PATH (Si nécessaire)

### Windows (PowerShell)

```powershell
# Ajouter au PATH utilisateur
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\chemin\vers\gitleaks", [EnvironmentVariableTarget]::User)

# Redémarrer PowerShell pour appliquer les changements
```

### macOS/Linux

```bash
# Ajouter au PATH dans ~/.bashrc ou ~/.zshrc
export PATH=$PATH:/usr/local/bin

# Recharger le shell
source ~/.bashrc
# ou
source ~/.zshrc
```

---

## 📚 Ressources

- **Repository GitHub:** https://github.com/gitleaks/gitleaks
- **Releases:** https://github.com/gitleaks/gitleaks/releases
- **Documentation:** https://github.com/gitleaks/gitleaks#installation
- **Documentation Scoop:** https://scoop.sh/

---

## 🐛 Dépannage

### Problème: "gitleaks: command not found"

**Solution:**
1. Vérifier que Gitleaks est dans le PATH
2. Redémarrer le terminal/PowerShell
3. Vérifier l'installation: `which gitleaks` (Linux/Mac) ou `where gitleaks` (Windows)

### Problème: "Permission denied" (Linux/Mac)

**Solution:**
```bash
# Rendre exécutable
chmod +x /usr/local/bin/gitleaks

# Ou installer avec sudo
sudo mv gitleaks /usr/local/bin/
```

### Problème: Scoop bucket not found

**Solution:**
```powershell
# Ajouter le bucket
scoop bucket add gitleaks https://github.com/zricethezav/gitleaks.git

# Vérifier les buckets installés
scoop bucket list
```

---

## 🎯 Recommandation

**Pour Windows:** Utiliser Scoop (le plus simple)
**Pour macOS:** Utiliser Homebrew (le plus simple)
**Pour Linux:** Téléchargement direct ou Snap

---

**Date de création**: $(date)
**Version**: 1.0





