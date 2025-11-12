# 🚀 Guide de Test Rapide - Sécurité Shift-Left

## 📋 Prérequis

### 1. Installer les dépendances

```bash
# À la racine du projet
npm install

# Dans chaque sous-projet
cd middleware && npm install && cd ..
cd cbs-simulator && npm install && cd ..
cd dashboard && npm install && cd ..
```

### 2. Installer Gitleaks

**Windows (PowerShell) - Option 1: Scoop (Recommandé):**
```powershell
# Installer Scoop si nécessaire
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# Ajouter le bucket Gitleaks
scoop bucket add gitleaks https://github.com/zricethezav/gitleaks.git

# Installer Gitleaks
scoop install gitleaks

# Vérifier
gitleaks version
```

**Windows (PowerShell) - Option 2: Téléchargement Direct:**
```powershell
# 1. Télécharger depuis: https://github.com/gitleaks/gitleaks/releases
# 2. Extraire gitleaks.exe dans un dossier (ex: C:\tools\gitleaks\)
# 3. Ajouter au PATH (voir docs/INSTALL-GITLEAKS.md)
# 4. Vérifier
gitleaks version
```

**Windows (PowerShell) - Option 3: winget:**
```powershell
winget install --id gitleaks.gitleaks -e --source winget
gitleaks version
```

**macOS/Linux:**
```bash
# Avec Homebrew (macOS)
brew install gitleaks

# Ou téléchargement direct (voir docs/INSTALL-GITLEAKS.md)
# Vérifier
gitleaks version
```

**💡 Pour plus d'options d'installation, consultez: `docs/INSTALL-GITLEAKS.md`**

### 3. Initialiser Husky

```bash
# À la racine du projet
npx husky install

# Sur Windows, les hooks sont déjà exécutables
# Sur Linux/Mac, rendre exécutables:
chmod +x .husky/pre-commit
chmod +x .husky/pre-push
chmod +x .husky/commit-msg
```

---

## ✅ Tests Rapides

### Test 1: ESLint - Vérifier les règles de sécurité

```bash
# Linter le middleware
cd middleware
npm run lint

# Linter le cbs-simulator
cd ../cbs-simulator
npm run lint

# Linter le dashboard
cd ../dashboard
npm run lint

# Linter tout le projet (à la racine)
cd ..
npm run lint
```

**✅ Résultat attendu:** Pas d'erreurs ESLint

---

### Test 2: Validation des Entrées - Tester express-validator

```bash
# Démarrer le middleware
cd middleware
npm start

# Dans un autre terminal, tester une requête valide
curl -X POST http://localhost:3000/transfer \
  -H "Content-Type: application/json" \
  -d '{"from": "A001", "to": "A002", "amount": 100.50}'

# Tester une requête invalide (montant négatif)
curl -X POST http://localhost:3000/transfer \
  -H "Content-Type: application/json" \
  -d '{"from": "A001", "to": "A002", "amount": -100}'
```

**✅ Résultat attendu:**
- Requête valide: 200 OK
- Requête invalide: 400 Bad Request avec message d'erreur

---

### Test 3: Gitleaks - Détecter les secrets

```bash
# Scanner le repository
npm run security:scan

# Scanner les fichiers stagés
npm run security:scan-staged
```

**✅ Résultat attendu:** Aucun secret détecté

**Test avec un faux secret:**
```bash
# Créer un fichier de test
echo "API_KEY=sk_test_1234567890abcdef" > test-secret.js

# Scanner
npm run security:scan

# Nettoyer
rm test-secret.js
```

**✅ Résultat attendu:** Détection du faux secret

---

### Test 4: Pre-commit Hook - Tester Husky

```bash
# Créer un fichier avec des erreurs ESLint
echo "const x = 1; const x = 2;" > test-error.js

# Ajouter au staging
git add test-error.js

# Essayer de committer
git commit -m "test: commit avec erreurs"
```

**✅ Résultat attendu:** Pre-commit hook bloque le commit avec erreur ESLint

**Nettoyer:**
```bash
git reset HEAD test-error.js
rm test-error.js
```

---

### Test 5: Pre-commit Hook - Tester Gitleaks

```bash
# Créer un fichier avec un secret
echo "API_KEY=sk_test_1234567890abcdef" > test-secret.js

# Ajouter au staging
git add test-secret.js

# Essayer de committer
git commit -m "test: commit avec secret"
```

**✅ Résultat attendu:** Pre-commit hook bloque le commit, Gitleaks détecte le secret

**Nettoyer:**
```bash
git reset HEAD test-secret.js
rm test-secret.js
```

---

### Test 6: npm audit - Vulnérabilités

```bash
# Scanner les vulnérabilités
npm run security:audit

# Essayer de corriger automatiquement
npm run security:audit-fix
```

**✅ Résultat attendu:** Liste des vulnérabilités (s'il y en a)

---

### Test 7: CORS - Tester la configuration

```bash
# Démarrer le middleware
cd middleware
npm start

# Dans un autre terminal, tester avec une origine autorisée
curl -H "Origin: http://localhost:3001" http://localhost:3000/health

# Tester avec une origine non autorisée (en dev, devrait être accepté avec warning)
curl -H "Origin: http://evil.com" http://localhost:3000/health
```

**✅ Résultat attendu:**
- Origine autorisée: 200 OK
- Origine non autorisée (dev): 200 OK avec warning dans les logs
- Origine non autorisée (prod): 403 Forbidden

---

## 🧪 Test Complet Automatisé

Créez un script `test-all.sh` (Linux/Mac) ou `test-all.ps1` (Windows):

**test-all.sh:**
```bash
#!/bin/bash

echo "🔍 Testing Security Configuration..."
echo ""

# Test 1: ESLint
echo "1. Testing ESLint..."
npm run lint
if [ $? -ne 0 ]; then
  echo "❌ ESLint failed"
  exit 1
fi
echo "✅ ESLint passed"
echo ""

# Test 2: Gitleaks
echo "2. Testing Gitleaks..."
if command -v gitleaks > /dev/null 2>&1; then
  gitleaks detect --source . --verbose
  if [ $? -ne 0 ]; then
    echo "❌ Gitleaks found secrets"
    exit 1
  fi
  echo "✅ Gitleaks passed"
else
  echo "⚠️  Gitleaks not installed"
fi
echo ""

# Test 3: npm audit
echo "3. Testing npm audit..."
npm run security:audit
echo "✅ npm audit completed"
echo ""

echo "✅ All security tests passed!"
```

**Exécuter:**
```bash
chmod +x test-all.sh
./test-all.sh
```

---

## 📊 Checklist de Test

- [ ] ✅ ESLint fonctionne (pas d'erreurs)
- [ ] ✅ Validation des entrées bloque les entrées invalides
- [ ] ✅ Gitleaks détecte les secrets
- [ ] ✅ Pre-commit hook bloque les commits non sécurisés
- [ ] ✅ Pre-push hook bloque les pushes non sécurisés
- [ ] ✅ npm audit fonctionne
- [ ] ✅ CORS fonctionne correctement

---

## 🐛 Dépannage Rapide

### Problème: Gitleaks non trouvé

```bash
# Vérifier l'installation
gitleaks version

# Réinstaller si nécessaire
# Windows: scoop install gitleaks
# macOS: brew install gitleaks
```

### Problème: Husky hooks non exécutés

```bash
# Réinitialiser Husky
npx husky install

# Sur Linux/Mac, rendre exécutables
chmod +x .husky/pre-commit
chmod +x .husky/pre-push
chmod +x .husky/commit-msg
```

### Problème: ESLint erreurs

```bash
# Corriger automatiquement
npm run lint:fix
```

---

## 📚 Documentation Complète

Pour plus de détails, consultez:
- `TESTING-GUIDE.md` - Guide de test complet
- `docs/GITLEAKS-SETUP.md` - Configuration Gitleaks
- `docs/SONARLINT-SETUP.md` - Configuration SonarLint
- `SECURITY-SHIFT-LEFT-ANALYSIS.md` - Analyse de sécurité

---

**Date de création**: $(date)
**Version**: 1.0

