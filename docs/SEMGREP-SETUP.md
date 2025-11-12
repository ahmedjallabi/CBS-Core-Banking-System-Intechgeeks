# Guide d'Installation et Configuration de Semgrep

## 📋 Vue d'ensemble

Semgrep est un outil SAST (Static Application Security Testing) qui détecte les vulnérabilités de sécurité et les problèmes de code en analysant les patterns dans votre code source.

## 🚀 Installation

### ✅ Option 1 : Installation Automatique (Windows) - RECOMMANDÉ

**La méthode la plus simple et fiable pour Windows** :

```powershell
# Exécutez le script d'installation automatique
.\install-semgrep.ps1
```

Ce script :
- ✅ Installe Semgrep via pip
- ✅ Détecte automatiquement le répertoire d'installation
- ✅ Configure le PATH automatiquement
- ✅ Vérifie que tout fonctionne

**Après l'exécution, redémarrez PowerShell** et testez : `semgrep --version`

---

### Option 2 : Installation Manuelle via pip (Python)

**Prérequis** : Python 3.7+ installé

```powershell
# Installer Semgrep
pip install --user semgrep

# Puis configurer le PATH (voir INSTALL-SEMGREP-WINDOWS.md)
```

**Important** : Après l'installation, vous devez ajouter le répertoire Scripts au PATH. Voir `INSTALL-SEMGREP-WINDOWS.md` pour les instructions détaillées.

---

### Option 3 : Installation via Homebrew (macOS/Linux)

```bash
brew install semgrep
```

### Option 4 : Installation via Scoop (Windows)

```powershell
# Ajouter le bucket (si nécessaire)
scoop bucket add main

# Installer Semgrep
scoop install semgrep
```

### Option 5 : Installation via Docker

```bash
# Télécharger l'image
docker pull returntocorp/semgrep

# Utilisation
docker run --rm -v "${PWD}:/src" returntocorp/semgrep semgrep --config=.semgrep.yml /src
```

### Option 6 : Installation via Téléchargement Direct (Windows)

1. Visitez : https://github.com/returntocorp/semgrep/releases
2. Téléchargez `semgrep.exe` pour Windows
3. Placez-le dans un dossier accessible (ex: `C:\tools\semgrep\`)
4. Ajoutez au PATH Windows
5. Vérifiez : `semgrep --version`

### Option 7 : Installation via winget (Windows 10/11)

```powershell
winget install --id Semgrep.Semgrep -e --source winget
```

## ✅ Vérification de l'Installation

```bash
# Vérifier la version
semgrep --version

# Tester avec un scan simple
semgrep --help
```

**Note** : Si `semgrep` n'est pas reconnu après l'installation :
- **Windows** : Redémarrez PowerShell ou ajoutez le chemin au PATH
- **Linux/Mac** : Vérifiez que le répertoire d'installation est dans votre PATH

## 🔍 Utilisation

**⚠️ Important** : Semgrep doit être installé (via pip, Homebrew, Scoop, etc.) avant d'utiliser les scripts npm.

### Scanner le projet avec la configuration personnalisée

```bash
# Scanner avec la configuration .semgrep.yml (nécessite Semgrep installé)
npm run security:semgrep

# Ou directement avec semgrep
semgrep --config=.semgrep.yml .
```

### Scanner avec sortie JSON

```bash
npm run security:semgrep-json

# Ou directement
semgrep --config=.semgrep.yml --json . > semgrep-results.json
```

### Scanner un répertoire spécifique

```bash
semgrep --config=.semgrep.yml ./middleware
semgrep --config=.semgrep.yml ./cbs-simulator
semgrep --config=.semgrep.yml ./dashboard
```

### Scanner avec les règles par défaut de Semgrep

```bash
# Utiliser les règles de sécurité par défaut
semgrep --config=auto .

# Utiliser uniquement les règles OWASP
semgrep --config=p/owasp-top-ten .
```

## 📊 Règles Configurées

Le fichier `.semgrep.yml` contient des règles personnalisées pour détecter :

### 🔴 Vulnérabilités Critiques
- ✅ **Injection SQL** - Détection des requêtes SQL non paramétrées
- ✅ **Command Injection** - Détection de l'exécution de commandes non sécurisées
- ✅ **Code Injection** - Détection de l'utilisation d'`eval()` et `Function()`
- ✅ **XSS (Cross-Site Scripting)** - Détection des manipulations DOM non sécurisées
- ✅ **Secrets Hardcodés** - Détection des mots de passe, clés API, tokens dans le code
- ✅ **CORS Mal Configuré** - Détection des configurations CORS permissives

### 🟠 Vulnérabilités Importantes
- ✅ **Cryptographie Faible** - Détection de MD5, SHA1, et algorithmes faibles
- ✅ **Logging de Secrets** - Détection des secrets dans les logs
- ✅ **Désérialisation Non Sécurisée** - Détection de `JSON.parse()` avec données non fiables
- ✅ **Path Traversal** - Détection des opérations de fichiers non sécurisées

### 🟡 Bonnes Pratiques
- ✅ **Validation d'Entrée Manquante** - Détection des endpoints API sans validation
- ✅ **Rate Limiting Manquant** - Suggestions pour ajouter le rate limiting
- ✅ **Protection CSRF Manquante** - Suggestions pour ajouter la protection CSRF
- ✅ **Helmet Manquant** - Suggestions pour ajouter les headers de sécurité

## 🔧 Configuration

### Fichier `.semgrep.yml`

Le fichier de configuration contient :
- **Règles personnalisées** pour votre projet
- **Exclusions** pour éviter les faux positifs (node_modules, dist, etc.)
- **Métadonnées** avec références OWASP et CWE

### Personnaliser les règles

Pour ajouter une nouvelle règle, éditez `.semgrep.yml` :

```yaml
rules:
  - id: detect-custom-vulnerability
    pattern: |
      $PATTERN_TO_DETECT
    message: "Description du problème"
    languages: [javascript, typescript]
    severity: ERROR
    metadata:
      category: security
      owasp: "A03:2021 - Injection"
      cwe: "CWE-XXX"
```

### Ajouter des exclusions

Pour ignorer des fichiers ou répertoires :

```yaml
exclude:
  - "node_modules"
  - "dist"
  - "custom-path/**"
```

## 🚨 Intégration avec CI/CD

### GitHub Actions

```yaml
name: Semgrep Security Scan
on: [push, pull_request]
jobs:
  semgrep:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: returntocorp/semgrep-action@v1
        with:
          config: .semgrep.yml
```

### Jenkins

```groovy
stage('Semgrep Security Scan') {
    steps {
        sh '''
            semgrep --config=.semgrep.yml . --json > semgrep-results.json
        '''
        archiveArtifacts artifacts: 'semgrep-results.json'
    }
}
```

## 📈 Interprétation des Résultats

### Niveaux de Sévérité

- **ERROR** : Vulnérabilité critique à corriger immédiatement
- **WARNING** : Problème de sécurité à corriger rapidement
- **INFO** : Suggestion d'amélioration

### Format de Sortie

Semgrep affiche :
- Le fichier et la ligne du problème
- Le message d'alerte
- Le code problématique
- Les références OWASP/CWE

## 🔒 Bonnes Pratiques

1. **Scanner régulièrement** : Exécutez `npm run security:semgrep` avant chaque commit
2. **Intégrer dans CI/CD** : Ajoutez Semgrep à votre pipeline CI/CD
3. **Réviser les résultats** : Vérifiez les faux positifs et ajustez les règles
4. **Mettre à jour les règles** : Adaptez `.semgrep.yml` à vos besoins spécifiques
5. **Combiner avec d'autres outils** : Utilisez Semgrep avec ESLint, SonarLint, et Gitleaks

## 🛠️ Dépannage

### Faux positifs

Si Semgrep détecte un faux positif :

1. **Ajouter une exclusion** dans `.semgrep.yml` :
```yaml
exclude:
  - "path/to/file.js"
```

2. **Utiliser un commentaire** dans le code :
```javascript
// semgrep-disable-next-line detect-xss-react
<div dangerouslySetInnerHTML={{ __html: sanitizedHtml }} />
```

### Ignorer temporairement

```bash
# Ignorer un fichier spécifique
semgrep --config=.semgrep.yml . --exclude="path/to/file.js"
```

### Vérifier une règle spécifique

```bash
# Tester une règle spécifique
semgrep --config=.semgrep.yml --severity=ERROR .
```

## 📚 Ressources

- [Documentation officielle](https://semgrep.dev/docs/)
- [Règles OWASP](https://semgrep.dev/r/owasp-top-ten)
- [Playground Semgrep](https://semgrep.dev/playground)
- [Règles de sécurité JavaScript](https://semgrep.dev/r/javascript)

## 🔗 Liens Utiles

- [GitHub Repository](https://github.com/returntocorp/semgrep)
- [Documentation complète](https://semgrep.dev/docs/)
- [Règles par défaut](https://semgrep.dev/r)
- [Semgrep Registry](https://semgrep.dev/r)

---

**Note** : Semgrep est un outil complémentaire à ESLint et SonarLint. Utilisez-les ensemble pour une couverture de sécurité maximale.

