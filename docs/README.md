# CBS Supervision Dashboard

Ce projet est un monorepo contenant une application full-stack conçue pour simuler et interagir avec un Core Banking System (CBS). Il inclut un tableau de bord frontend basé sur React, un middleware Node.js/Express, et un simulateur de CBS.

L'application est thématisée pour un contexte bancaire tunisien, avec des données fictives incluant des noms, des adresses et des informations financières en TND.

## Table des matières

- [Architecture](#architecture)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Démarrage](#démarrage)
-- [Endpoints de l'API](#endpoints-de-lapi)
- [Données Fictives Disponibles](#données-fictives-disponibles)
- [Guide d'Utilisation](#guide-dutilisation)
- [Développement](#développement)

## Architecture

Le projet est organisé en trois services principaux :

- **`dashboard/`** : Une application React qui sert d'interface utilisateur pour interagir avec les services bancaires. Elle offre des fonctionnalités de supervision du système, de consultation de comptes, de recherche de clients, d'historique des transactions et de virements de fonds.
- **`middleware/`** : Une API Node.js/Express qui sert de passerelle entre le frontend et le simulateur de CBS. Elle expose une API RESTful claire, gère la logique métier, et est documentée avec Swagger.
- **`cbs-simulator/`** : Une application Node.js/Express qui simule un backend de Core Banking System. Elle fournit des données fictives et des endpoints pour imiter les opérations bancaires du monde réel.

## Prérequis

- [Node.js](https://nodejs.org/) (v18 ou supérieure recommandée)
- [npm](https://www.npmjs.com/) (v8 ou supérieure recommandée)

## Installation

1. **Clonez le dépôt :**
   ```bash
   git clone <repository-url>
   cd cbs-middleware
   ```

2. **Installez les dépendances pour tous les services :**
   Ce projet utilise les workspaces `npm`, mais pour plus de simplicité, nous installerons les dépendances dans chaque répertoire de service. Exécutez les commandes suivantes depuis le répertoire racine :

   ```bash
   npm install --prefix dashboard
   npm install --prefix middleware
   npm install --prefix cbs-simulator
   ```

## Démarrage

L'application entière peut être démarrée avec une seule commande depuis la racine du projet. Cela lancera simultanément le tableau de bord, le middleware et le simulateur.

```bash
npm start
```

Une fois démarrés, les services suivants seront disponibles :

- **Dashboard** : `http://localhost:3001`
- **Middleware API** : `http://localhost:3000`
- **CBS Simulator** : `http://localhost:4000`

Le tableau de bord s'ouvrira automatiquement dans votre navigateur.

## Endpoints de l'API

L'API du middleware est disponible sur `http://localhost:3000`. La documentation complète de l'API (Swagger) est accessible à l'adresse `http://localhost:3000/api-docs`.

Voici un résumé des principaux endpoints :

| Méthode | Route                       | Description                                                  |
| :------ | :-------------------------- | :----------------------------------------------------------- |
| `GET`   | `/health`                   | Vérifie l'état de santé du service.                          |
| `GET`   | `/metrics`                  | Récupère les métriques de performance du service.            |
| `GET`   | `/customers/{id}`           | Récupère les détails d'un client, y compris ses comptes.     |
| `GET`   | `/accounts/{id}`            | Récupère les détails d'un compte bancaire.                   |
| `GET`   | `/accounts/{id}/history`    | Récupère l'historique des transactions d'un compte.          |
| `POST`  | `/transfer`                 | Effectue un virement entre deux comptes.                     |

## Données Fictives Disponibles

Le simulateur de CBS est pré-rempli avec des données fictives sur le thème de la Tunisie.

### Clients

| ID Client | Nom                 | Localisation      |
| :-------- | :------------------ | :---------------- |
| `C001`    | Mohamed Ben Ali     | Le Bardo, Tunis   |
| `C002`    | Fatima El Fihri     | Sousse            |
| `C003`    | Ali Trabelsi        | Tunis             |
| `C004`    | Aisha Bouslama      | Sfax              |

### Comptes

| ID Compte | ID Client | Type              | IBAN                             |
| :-------- | :---------- | :---------------- | :------------------------------- |
| `A001`    | `C001`      | Compte Courant    | `TN59...89`                      |
| `A002`    | `C001`      | Compte Épargne    | `TN59...45`                      |
| `A003`    | `C002`      | Compte Courant    | `TN59...21`                      |
| `A004`    | `C003`      | Compte Courant    | `TN59...89`                      |
| `A005`    | `C004`      | Compte Courant    | `TN59...10`                      |
| `A006`    | `C004`      | Compte Épargne    | `TN59...45`                      |

Vous pouvez utiliser ces IDs dans le tableau de bord pour tester les différentes fonctionnalités.

## Guide d'Utilisation

Le tableau de bord offre plusieurs onglets pour interagir avec le système :

- **Supervision** : Affiche l'état de santé en temps réel, les métriques de performance (mémoire, CPU) et l'historique des performances.
- **Transfert** : Permet d'effectuer des virements entre deux comptes en utilisant leurs IDs et le montant souhaité.
- **Consultation Compte** : Affiche les détails d'un compte spécifique, y compris son solde et son IBAN.
- **Consultation Client** : Affiche les informations d'un client et la liste de ses comptes.
- **Historique** : Affiche l'historique des transactions pour un compte donné.

## Développement

Pour lancer un service individuellement, utilisez les commandes suivantes depuis la racine du projet :

```bash
# Lancer uniquement le tableau de bord
npm run start:dashboard

# Lancer uniquement le middleware
npm run start:middleware

# Lancer uniquement le simulateur de CBS
npm run start:simulator
``` 