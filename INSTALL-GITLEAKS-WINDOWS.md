# 🚀 Installation Rapide de Gitleaks sur Windows

## 📋 Option 1: Scoop (Le Plus Simple) ⭐

### Étape 1: Installer Scoop (si pas déjà installé)

Ouvrez PowerShell en tant qu'administrateur et exécutez:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
```

### Étape 2: Ajouter le bucket Gitleaks

```powershell
scoop bucket add gitleaks https://github.com/zricethezav/gitleaks.git
```

### Étape 3: Installer Gitleaks

```powershell
scoop install gitleaks
```

### Étape 4: Vérifier l'installation

```powershell
gitleaks version
```

✅ **C'est tout !** Gitleaks est maintenant installé et prêt à être utilisé.

---

## 📋 Option 2: Téléchargement Direct

### Étape 1: Télécharger Gitleaks

1. Aller sur: https://github.com/gitleaks/gitleaks/releases
2. Télécharger la dernière version pour Windows:
   - `gitleaks_X.X.X_windows_amd64.zip` (pour Windows 64-bit)
   - `gitleaks_X.X.X_windows_386.zip` (pour Windows 32-bit)

### Étape 2: Extraire l'archive

1. Extraire le fichier `gitleaks.exe`
2. Créer un dossier (ex: `C:\tools\gitleaks\`)
3. Déplacer `gitleaks.exe` dans ce dossier

### Étape 3: Ajouter au PATH

**Méthode 1: Via l'interface Windows**
1. Cliquez droit sur "Ce PC" > Propriétés
2. Paramètres système avancés
3. Variables d'environnement
4. Ajouter `C:\tools\gitleaks\` au PATH utilisateur

**Méthode 2: Via PowerShell (administrateur)**
```powershell
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\tools\gitleaks", [EnvironmentVariableTarget]::User)
```

### Étape 4: Vérifier l'installation

Fermez et rouvrez PowerShell, puis:

```powershell
gitleaks version
```

---

## 📋 Option 3: winget (Windows Package Manager)

Si vous avez Windows 10/11 avec winget installé:

```powershell
winget install --id gitleaks.gitleaks -e --source winget
gitleaks version
```

---

## 📋 Option 4: Chocolatey

Si vous avez Chocolatey installé:

```powershell
choco install gitleaks
gitleaks version
```

---

## ✅ Vérification

Après l'installation, vérifiez que Gitleaks fonctionne:

```powershell
# Vérifier la version
gitleaks version

# Afficher l'aide
gitleaks help

# Tester avec un scan
gitleaks detect --source . --verbose
```

---

## 🐛 Dépannage

### Problème: "gitleaks: command not found"

**Solution:**
1. Vérifiez que Gitleaks est dans le PATH
2. Redémarrez PowerShell
3. Vérifiez l'installation: `where.exe gitleaks`

### Problème: Scoop bucket not found

**Solution:**
```powershell
# Vérifier que Scoop est installé
scoop --version

# Ajouter le bucket
scoop bucket add gitleaks https://github.com/zricethezav/gitleaks.git

# Vérifier les buckets installés
scoop bucket list
```

### Problème: Permission denied

**Solution:**
```powershell
# Exécuter PowerShell en tant qu'administrateur
# Ou vérifier les permissions du dossier
```

---

## 🎯 Recommandation

**⭐ Utilisez Scoop (Option 1)** - C'est le plus simple et le plus rapide !

---

## 📚 Ressources

- **Repository GitHub:** https://github.com/gitleaks/gitleaks
- **Releases:** https://github.com/gitleaks/gitleaks/releases
- **Documentation complète:** `docs/INSTALL-GITLEAKS.md`

---

**Date de création**: $(date)
**Version**: 1.0




