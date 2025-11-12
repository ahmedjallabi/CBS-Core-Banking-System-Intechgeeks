# Guide d'Installation et Configuration de Gitleaks

## 📋 Vue d'ensemble

Gitleaks est un outil SAST (Static Application Security Testing) qui détecte les secrets et les informations sensibles dans votre code avant qu'ils ne soient commités dans Git.

## 🚀 Installation

### Option 1 : Installation via Homebrew (macOS/Linux)

```bash
brew install gitleaks
```

### Option 2 : Installation via Scoop (Windows)

```powershell
scoop bucket add gitleaks https://github.com/zricethezav/gitleaks.git
scoop install gitleaks
```

### Option 3 : Téléchargement direct

1. Visitez la [page de releases](https://github.com/gitleaks/gitleaks/releases)
2. Téléchargez la version correspondant à votre système d'exploitation
3. Extrayez et ajoutez au PATH

### Option 4 : Installation via Go

```bash
go install github.com/gitleaks/gitleaks/v8@latest
```

## ✅ Vérification de l'Installation

```bash
gitleaks version
```

## 🔍 Utilisation

### Scanner le repository actuel

```bash
# Scanner tout le repository
npm run security:scan

# Ou directement avec gitleaks
gitleaks detect --source . --verbose
```

### Scanner un répertoire spécifique

```bash
gitleaks detect --source ./middleware --verbose
```

### Scanner les fichiers stagés (avant commit)

```bash
npm run security:scan-staged

# Ou directement avec gitleaks
gitleaks detect --no-git --source . --verbose
```

### Mode protect (recommandé pour les pre-commit hooks)

```bash
npm run security:protect

# Ou directement avec gitleaks
gitleaks protect --verbose
```

## 🔧 Configuration

### Fichier de configuration

Le fichier `.gitleaks.toml` à la racine du projet contient :
- Les règles de détection des secrets
- Les patterns à ignorer (allowlist)
- Les exclusions de fichiers

### Personnalisation

Pour ajouter des règles personnalisées, modifiez `.gitleaks.toml` :

```toml
[rule]
id = "custom-secret"
description = "Détection des secrets personnalisés"
regex = '''your-custom-regex-pattern'''
```

### Ajouter des exclusions

Pour ignorer des fichiers ou des patterns, ajoutez dans la section `allowlist` :

```toml
[allowlist]
paths = [
    '''\.env\.example''',
    '''test/fixtures/''',
]
```

## 🚨 Intégration avec Git Hooks

### Pre-commit Hook (Recommandé)

Gitleaks peut être intégré avec Husky pour vérifier les secrets avant chaque commit.

Voir la section "Husky + lint-staged" dans le guide de sécurité.

### Installation manuelle du pre-commit hook

```bash
# Créer le répertoire .git/hooks si nécessaire
mkdir -p .git/hooks

# Créer le hook pre-commit
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/sh
gitleaks protect --verbose --staged
EOF

# Rendre le hook exécutable
chmod +x .git/hooks/pre-commit
```

## 📊 Exemples de Secrets Détectés

Gitleaks détecte automatiquement :

- ✅ Clés API (API keys)
- ✅ Tokens d'authentification (GitHub, AWS, etc.)
- ✅ Mots de passe
- ✅ Clés privées RSA
- ✅ Chaînes de connexion de base de données
- ✅ Secrets JWT
- ✅ Tokens OAuth

## 🔒 Bonnes Pratiques

1. **Ne jamais commiter de secrets** : Utilisez des variables d'environnement
2. **Scanner régulièrement** : Exécutez `npm run security:scan` avant chaque push
3. **Utiliser les pre-commit hooks** : Empêchez les commits non sécurisés
4. **Mettre à jour les règles** : Adaptez `.gitleaks.toml` à vos besoins
5. **Revue de code** : Vérifiez les résultats des scans dans les PRs

## 🛠️ Dépannage

### Faux positifs

Si Gitleaks détecte un faux positif :

1. Ajoutez le pattern dans la section `allowlist` de `.gitleaks.toml`
2. Ou utilisez des commentaires dans le code : `// gitleaks:allow`

### Ignorer temporairement

```bash
# Ignorer une détection spécifique (non recommandé)
gitleaks detect --source . --verbose --no-banner
```

### Vérifier un fichier spécifique

```bash
gitleaks detect --path ./path/to/file.js --verbose
```

## 📚 Ressources

- [Documentation officielle](https://github.com/gitleaks/gitleaks)
- [Règles par défaut](https://github.com/gitleaks/gitleaks/blob/master/config/gitleaks.toml)
- [Exemples de configuration](https://github.com/gitleaks/gitleaks/tree/master/examples)

## 🔗 Liens Utiles

- [GitHub Repository](https://github.com/gitleaks/gitleaks)
- [Issues et Discussions](https://github.com/gitleaks/gitleaks/issues)
- [Changelog](https://github.com/gitleaks/gitleaks/releases)

---

**Note** : Gitleaks est un outil de détection, pas de prévention. Utilisez-le en complément d'autres mesures de sécurité.




