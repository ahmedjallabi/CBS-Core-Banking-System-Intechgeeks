# Guide de Test - Sécurité Shift-Left

## 📋 Vue d'ensemble

Ce guide explique comment tester toutes les configurations de sécurité mises en place dans le projet CBS.

---

## 🚀 Installation des Dépendances

### 1. Installer les dépendances npm

```bash
# À la racine du projet
npm install

# Dans chaque sous-projet
cd middleware
npm install

cd ../cbs-simulator
npm install

cd ../dashboard
npm install
```

### 2. Installer Gitleaks

**Windows (Scoop):**
```powershell
scoop bucket add gitleaks https://github.com/zricethezav/gitleaks.git
scoop install gitleaks
```

**macOS (Homebrew):**
```bash
brew install gitleaks
```

**Linux:**
```bash
# Téléchargez depuis https://github.com/gitleaks/gitleaks/releases
# Ou utilisez go install
go install github.com/gitleaks/gitleaks/v8@latest
```

**Vérifier l'installation:**
```bash
gitleaks version
```

### 3. Initialiser Husky

```bash
# À la racine du projet
npx husky install

# Rendre les hooks exécutables (Linux/Mac)
chmod +x .husky/pre-commit
chmod +x .husky/pre-push
chmod +x .husky/commit-msg
```

---

## ✅ Tests des Configurations

### Test 1: Configuration CORS

**Test dans middleware:**

1. Démarrer le middleware:
```bash
cd middleware
npm start
```

2. Tester avec curl:
```bash
# Test avec origine autorisée
curl -H "Origin: http://localhost:3001" http://localhost:3000/health

# Test avec origine non autorisée (devrait être accepté en dev)
curl -H "Origin: http://evil.com" http://localhost:3000/health

# Test en production (devrait être rejeté)
NODE_ENV=production node index.js
curl -H "Origin: http://evil.com" http://localhost:3000/health
```

**Résultat attendu:**
- ✅ En développement: Toutes les origines acceptées (avec warning)
- ✅ En production: Seules les origines autorisées acceptées

---

### Test 2: Validation des Entrées (express-validator)

**Test de validation:**

1. Démarrer le middleware:
```bash
cd middleware
npm start
```

2. Tester une requête valide:
```bash
curl -X POST http://localhost:3000/transfer \
  -H "Content-Type: application/json" \
  -d '{
    "from": "A001",
    "to": "A002",
    "amount": 100.50,
    "description": "Test transfer"
  }'
```

3. Tester une requête invalide (montant négatif):
```bash
curl -X POST http://localhost:3000/transfer \
  -H "Content-Type: application/json" \
  -d '{
    "from": "A001",
    "to": "A002",
    "amount": -100
  }'
```

**Résultat attendu:**
- ✅ Requête valide: 200 OK
- ✅ Requête invalide: 400 Bad Request avec détails d'erreur

4. Tester une injection:
```bash
curl -X GET "http://localhost:3000/customers/<script>alert('XSS')</script>"
```

**Résultat attendu:**
- ✅ 400 Bad Request - Validation failed (caractères non autorisés)

---

### Test 3: Gitleaks - Détection de Secrets

**Test manuel:**

1. Scanner le repository:
```bash
npm run security:scan
```

2. Scanner les fichiers stagés:
```bash
npm run security:scan-staged
```

3. Tester avec un faux secret:
```bash
# Créer un fichier de test avec un faux secret
echo "API_KEY=sk_test_1234567890abcdef" > test-secret.js

# Scanner
gitleaks detect --source . --verbose

# Nettoyer
rm test-secret.js
```

**Résultat attendu:**
- ✅ Détection du faux secret
- ✅ Erreur avec code de sortie non-zéro

---

### Test 4: ESLint - Règles de Sécurité

**Test de linting:**

1. Linter le middleware:
```bash
cd middleware
npm run lint
```

2. Linter le cbs-simulator:
```bash
cd cbs-simulator
npm run lint
```

3. Linter le dashboard:
```bash
cd dashboard
npm run lint
```

4. Linter tout le projet:
```bash
# À la racine
npm run lint
```

**Test avec code vulnérable:**

1. Créer un fichier de test:
```javascript
// test-vulnerable.js
eval('console.log("test")'); // Vulnérable
const fs = require('fs');
fs.readFile(userInput, 'utf8', callback); // Vulnérable
```

2. Linter le fichier:
```bash
eslint test-vulnerable.js
```

**Résultat attendu:**
- ✅ Détection des vulnérabilités
- ✅ Erreurs ESLint pour `eval()` et `readFile()` avec entrée non-littérale

---

### Test 5: Husky - Pre-commit Hooks

**Test des hooks:**

1. Créer un commit avec du code non-linté:
```bash
# Créer un fichier avec des erreurs ESLint
echo "const x = 1; const x = 2;" > test-error.js
git add test-error.js
git commit -m "test: commit avec erreurs"
```

**Résultat attendu:**
- ✅ Pre-commit hook bloque le commit
- ✅ Message d'erreur ESLint affiché

2. Créer un commit avec un secret:
```bash
# Créer un fichier avec un secret
echo "API_KEY=sk_test_1234567890abcdef" > test-secret.js
git add test-secret.js
git commit -m "test: commit avec secret"
```

**Résultat attendu:**
- ✅ Pre-commit hook bloque le commit
- ✅ Gitleaks détecte le secret

3. Créer un commit valide:
```bash
# Créer un fichier valide
echo "const x = 1;" > test-valid.js
git add test-valid.js
git commit -m "test: commit valide"
```

**Résultat attendu:**
- ✅ Commit réussi
- ✅ Pas d'erreurs

---

### Test 6: Pre-push Hooks

**Test du hook pre-push:**

1. Essayer de push avec des erreurs ESLint:
```bash
# Créer un commit avec des erreurs
echo "const x = 1; const x = 2;" > test-error.js
git add test-error.js
git commit -m "test: commit avec erreurs"
git push
```

**Résultat attendu:**
- ✅ Pre-push hook bloque le push
- ✅ Message d'erreur ESLint affiché

---

### Test 7: npm audit - Vulnérabilités

**Test des vulnérabilités npm:**

1. Scanner les vulnérabilités:
```bash
npm run security:audit
```

2. Essayer de corriger automatiquement:
```bash
npm run security:audit-fix
```

**Résultat attendu:**
- ✅ Liste des vulnérabilités trouvées
- ✅ Suggestions de correction

---

### Test 8: SonarLint (IDE)

**Test dans VS Code:**

1. Installer l'extension SonarLint
2. Ouvrir un fichier avec du code vulnérable:
```javascript
// middleware/test-vulnerable.js
eval('console.log("test")');
const crypto = require('crypto');
const secret = crypto.randomBytes(32).toString('hex'); // Devrait utiliser crypto.randomBytes()
```

3. Vérifier les avertissements SonarLint:
   - ✅ Soulignement du code vulnérable
   - ✅ Message d'explication
   - ✅ Suggestion de correction

---

## 🧪 Tests Automatisés

### Script de test complet

Créez un script `test-security.sh`:

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

### Exécuter les tests

```bash
chmod +x test-security.sh
./test-security.sh
```

---

## 📊 Checklist de Test

- [ ] Configuration CORS fonctionne correctement
- [ ] Validation des entrées bloque les entrées invalides
- [ ] Gitleaks détecte les secrets
- [ ] ESLint détecte les vulnérabilités de sécurité
- [ ] Pre-commit hooks bloquent les commits non sécurisés
- [ ] Pre-push hooks bloquent les pushes non sécurisés
- [ ] npm audit fonctionne
- [ ] SonarLint fonctionne dans l'IDE

---

## 🐛 Dépannage

### Problème: Gitleaks non trouvé

**Solution:**
```bash
# Vérifier l'installation
which gitleaks

# Réinstaller si nécessaire
# Voir: https://github.com/gitleaks/gitleaks#installation
```

### Problème: Husky hooks non exécutés

**Solution:**
```bash
# Réinitialiser Husky
npx husky install

# Vérifier les permissions (Linux/Mac)
chmod +x .husky/pre-commit
chmod +x .husky/pre-push
```

### Problème: ESLint erreurs

**Solution:**
```bash
# Corriger automatiquement
npm run lint:fix

# Vérifier la configuration
cat middleware/.eslintrc.js
```

---

## 📚 Ressources

- [Documentation Gitleaks](https://github.com/gitleaks/gitleaks)
- [Documentation ESLint Security](https://github.com/nodesecurity/eslint-plugin-security)
- [Documentation Husky](https://typicode.github.io/husky/)
- [Documentation SonarLint](https://www.sonarlint.org/)

---

**Date de création**: $(date)
**Version**: 1.0





