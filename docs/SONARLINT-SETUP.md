# Guide d'Installation et Configuration de SonarLint

## 📋 Vue d'ensemble

SonarLint est une extension IDE qui fournit un feedback instantané sur les problèmes de qualité de code et de sécurité pendant que vous écrivez du code.

## 🚀 Installation

### VS Code

1. Ouvrez VS Code
2. Allez dans Extensions (Ctrl+Shift+X)
3. Recherchez "SonarLint"
4. Installez l'extension "SonarLint" par SonarSource

### IntelliJ IDEA / WebStorm

1. Ouvrez Settings (File > Settings)
2. Allez dans Plugins
3. Recherchez "SonarLint"
4. Installez le plugin "SonarLint"

## ⚙️ Configuration

### VS Code

1. Ouvrez les paramètres de SonarLint (Ctrl+Shift+P > "SonarLint: Show Output")
2. Cliquez sur "Add SonarQube Connection"
3. Entrez les informations de connexion :
   - **Server URL**: `http://192.168.90.136:9000`
   - **Token**: Votre token SonarQube (généré dans SonarQube > My Account > Security)

### IntelliJ IDEA / WebStorm

1. Ouvrez Settings (File > Settings)
2. Allez dans Tools > SonarLint
3. Cliquez sur "Add SonarQube Connection"
4. Entrez les informations de connexion :
   - **Server URL**: `http://192.168.90.136:9000`
   - **Token**: Votre token SonarQube

## 🔗 Synchronisation avec SonarQube

Le fichier `.sonarlint/sonarlint.json` est déjà configuré pour se connecter à votre instance SonarQube.

Pour synchroniser les règles :
1. Ouvrez la palette de commandes (Ctrl+Shift+P)
2. Exécutez "SonarLint: Update All Bindings to SonarQube"

## 📊 Règles de Sécurité

SonarLint détecte automatiquement :
- ✅ Failles de sécurité (OWASP Top 10)
- ✅ Bugs et erreurs
- ✅ Code smells
- ✅ Vulnérabilités de sécurité
- ✅ Dettes techniques

## 🔍 Utilisation

### Détection en temps réel

SonarLint analyse automatiquement votre code pendant que vous écrivez et affiche :
- Des soulignements dans l'éditeur
- Des suggestions de correction
- Des explications détaillées des problèmes

### Vérification manuelle

1. Cliquez droit sur un fichier
2. Sélectionnez "SonarLint: Analyze File"
3. Consultez les résultats dans la fenêtre "SonarLint"

### Correction automatique

Certains problèmes peuvent être corrigés automatiquement :
1. Cliquez sur le problème dans l'éditeur
2. Cliquez sur "Quick Fix" (Ctrl+.)
3. Sélectionnez la correction suggérée

## 📚 Ressources

- [Documentation SonarLint](https://www.sonarlint.org/)
- [Règles de sécurité](https://rules.sonarsource.com/)
- [SonarQube Server](http://192.168.90.136:9000)

## 🔗 Liens Utiles

- [VS Code Extension](https://marketplace.visualstudio.com/items?itemName=SonarSource.sonarlint-vscode)
- [IntelliJ Plugin](https://plugins.jetbrains.com/plugin/7973-sonarlint)
- [Documentation complète](https://www.sonarlint.org/documentation)

---

**Note** : SonarLint fonctionne hors ligne, mais la synchronisation avec SonarQube permet d'avoir les mêmes règles que votre serveur SonarQube.




