# 🧪 Guide de Test ESLint

## 📋 Commandes pour Tester ESLint

### 1. Installer les Dépendances (si nécessaire)

```powershell
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

---

## ✅ Tests ESLint

### Test 1: Linter le Middleware

```powershell
cd middleware
npm run lint
```

**Résultat attendu:**
- ✅ Pas d'erreurs ESLint
- ⚠️ Avertissements possibles (warnings)

**Corriger automatiquement:**
```powershell
cd middleware
npm run lint:fix
```

---

### Test 2: Linter le CBS Simulator

```powershell
cd cbs-simulator
npm run lint
```

**Résultat attendu:**
- ✅ Pas d'erreurs ESLint
- ⚠️ Avertissements possibles (warnings)

**Corriger automatiquement:**
```powershell
cd cbs-simulator
npm run lint:fix
```

---

### Test 3: Linter le Dashboard (React)

```powershell
cd dashboard
npm run lint
```

**Résultat attendu:**
- ✅ Pas d'erreurs ESLint
- ⚠️ Avertissements possibles (warnings)

**Corriger automatiquement:**
```powershell
cd dashboard
npm run lint:fix
```

---

### Test 4: Linter Tout le Projet

```powershell
# À la racine du projet
npm run lint
```

Cette commande lintera tous les projets en séquence.

---

## 🔍 Tests avec Code Vulnérable

### Test 5: Créer un Fichier de Test avec Vulnérabilités

```powershell
# Créer un fichier de test dans middleware
cd middleware
@"
// test-vulnerable.js
eval('console.log("test")'); // Vulnérable - ESLint devrait détecter
const fs = require('fs');
const userInput = process.argv[2];
fs.readFile(userInput, 'utf8', (err, data) => { // Vulnérable
  console.log(data);
});
"@ | Out-File -FilePath test-vulnerable.js -Encoding UTF8

# Linter le fichier
npm run lint
```

**Résultat attendu:**
- ❌ Erreur: `security/detect-eval-with-expression`
- ❌ Erreur: `security/detect-non-literal-fs-filename`

**Nettoyer:**
```powershell
Remove-Item test-vulnerable.js
```

---

### Test 6: Tester avec un Fichier Existant

```powershell
# Linter un fichier spécifique
cd middleware
npx eslint index.js
```

---

## 📊 Vérifier la Configuration ESLint

### Voir la Configuration

```powershell
# Middleware
Get-Content middleware\.eslintrc.js

# CBS Simulator
Get-Content cbs-simulator\.eslintrc.js

# Dashboard
Get-Content dashboard\.eslintrc.json
```

---

## 🐛 Dépannage

### Problème: "eslint: command not found"

**Solution:**
```powershell
# Installer les dépendances
cd middleware
npm install
```

### Problème: "Cannot find module 'eslint-plugin-security'"

**Solution:**
```powershell
# Installer les plugins manquants
cd middleware
npm install --save-dev eslint-plugin-security eslint-plugin-node
```

### Problème: Trop d'erreurs ESLint

**Solution:**
```powershell
# Corriger automatiquement ce qui peut l'être
npm run lint:fix

# Puis relancer
npm run lint
```

---

## 📝 Exemples de Sortie

### Sortie Normale (Pas d'erreurs)

```
> middleware@1.0.0 lint
> eslint . --ext .js --max-warnings 0

✅ No errors found
```

### Sortie avec Erreurs

```
> middleware@1.0.0 lint
> eslint . --ext .js --max-warnings 0

✖ 2 problems (2 errors, 0 warnings)

middleware/test-vulnerable.js
  1:1  error  Unexpected use of eval  security/detect-eval-with-expression
  3:1  error  Detected fs.readFile with non-literal filename  security/detect-non-literal-fs-filename
```

---

## 🎯 Checklist de Test

- [ ] ✅ ESLint installé dans middleware
- [ ] ✅ ESLint installé dans cbs-simulator
- [ ] ✅ ESLint installé dans dashboard
- [ ] ✅ `npm run lint` fonctionne dans middleware
- [ ] ✅ `npm run lint` fonctionne dans cbs-simulator
- [ ] ✅ `npm run lint` fonctionne dans dashboard
- [ ] ✅ `npm run lint` fonctionne à la racine
- [ ] ✅ ESLint détecte les vulnérabilités de sécurité
- [ ] ✅ `npm run lint:fix` corrige automatiquement

---

## 📚 Commandes Utiles

```powershell
# Voir la version d'ESLint
npx eslint --version

# Voir l'aide
npx eslint --help

# Linter un fichier spécifique
npx eslint path/to/file.js

# Linter avec format JSON
npx eslint . --format json

# Linter avec format HTML (nécessite eslint-formatter-html)
npx eslint . --format html -o report.html
```

---

## 🔗 Ressources

- [Documentation ESLint](https://eslint.org/)
- [ESLint Security Plugin](https://github.com/nodesecurity/eslint-plugin-security)
- [Configuration ESLint](https://eslint.org/docs/user-guide/configuring/)

---

**Date de création**: $(date)
**Version**: 1.0





