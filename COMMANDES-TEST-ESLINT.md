# 🧪 Commandes pour Tester ESLint

## ✅ Commandes Principales

### 1. Tester le Middleware

```powershell
cd middleware
npm run lint
```

**Corriger automatiquement:**
```powershell
cd middleware
npm run lint:fix
```

---

### 2. Tester le CBS Simulator

```powershell
cd cbs-simulator
npm run lint
```

**Corriger automatiquement:**
```powershell
cd cbs-simulator
npm run lint:fix
```

---

### 3. Tester le Dashboard (React)

```powershell
cd dashboard
npm run lint
```

**Corriger automatiquement:**
```powershell
cd dashboard
npm run lint:fix
```

---

### 4. Tester Tout le Projet

```powershell
# À la racine du projet
npm run lint
```

Cette commande lintera tous les projets en séquence.

---

## 🔍 Tests Avancés

### Linter un Fichier Spécifique

```powershell
# Middleware
cd middleware
npx eslint index.js

# CBS Simulator
cd cbs-simulator
npx eslint index.js

# Dashboard
cd dashboard
npx eslint src/App.js
```

---

### Linter avec Format JSON

```powershell
cd middleware
npx eslint . --format json
```

---

### Linter avec Format Compact

```powershell
cd middleware
npx eslint . --format compact
```

---

## 🧪 Test avec Code Vulnérable

### Créer un Fichier de Test

```powershell
cd middleware

# Créer un fichier avec des vulnérabilités
@"
// test-vulnerable.js
eval('console.log("test")'); // Vulnérable
const fs = require('fs');
const userInput = process.argv[2];
fs.readFile(userInput, 'utf8', (err, data) => {
  console.log(data);
});
"@ | Out-File -FilePath test-vulnerable.js -Encoding UTF8

# Linter le fichier
npm run lint

# Nettoyer
Remove-Item test-vulnerable.js
```

**Résultat attendu:**
- ❌ Erreur: `security/detect-eval-with-expression`
- ❌ Erreur: `security/detect-non-literal-fs-filename`

---

## 📊 Vérifier la Configuration

### Voir la Configuration ESLint

```powershell
# Middleware
Get-Content middleware\.eslintrc.js

# CBS Simulator
Get-Content cbs-simulator\.eslintrc.js

# Dashboard
Get-Content dashboard\.eslintrc.json
```

---

## 🔧 Commandes Utiles

### Voir la Version d'ESLint

```powershell
npx eslint --version
```

### Voir l'Aide

```powershell
npx eslint --help
```

### Linter avec Ignorer les Warnings

```powershell
cd middleware
npx eslint . --quiet
```

### Linter avec Max Warnings

```powershell
cd middleware
npx eslint . --max-warnings 10
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

✖ 6 problems (6 errors, 0 warnings)

middleware/index.js
  109:16  error  Expected { after 'if' condition  curly
  116:16  error  Expected { after 'if' condition  curly
```

---

## 🐛 Dépannage

### Problème: "eslint: command not found"

**Solution:**
```powershell
cd middleware
npm install
```

### Problème: "Cannot find module 'eslint-plugin-security'"

**Solution:**
```powershell
cd middleware
npm install --save-dev eslint-plugin-security
```

### Problème: Trop d'Erreurs

**Solution:**
```powershell
# Corriger automatiquement
npm run lint:fix

# Puis relancer
npm run lint
```

---

## ✅ Checklist de Test

- [ ] ✅ `npm run lint` fonctionne dans middleware
- [ ] ✅ `npm run lint` fonctionne dans cbs-simulator
- [ ] ✅ `npm run lint` fonctionne dans dashboard
- [ ] ✅ `npm run lint` fonctionne à la racine
- [ ] ✅ ESLint détecte les vulnérabilités de sécurité
- [ ] ✅ `npm run lint:fix` corrige automatiquement

---

## 📚 Documentation Complète

Pour plus de détails, consultez:
- `TEST-ESLINT.md` - Guide de test complet
- [Documentation ESLint](https://eslint.org/)
- [ESLint Security Plugin](https://github.com/nodesecurity/eslint-plugin-security)

---

**Date de création**: $(date)
**Version**: 1.0





