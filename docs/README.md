# CBS Supervision Dashboard

This project is a monorepo containing a full-stack application designed to simulate and interact with a Core Banking System (CBS). It includes a React-based frontend dashboard, a Node.js/Express middleware, and a CBS simulator.

The application is themed for a Tunisian banking context, with mock data including Tunisian names, addresses, and financials in TND.

## Project Structure

The repository is organized into three main services:

-   `dashboard/`: A React application that serves as the user interface for interacting with the banking services. It provides features for system supervision, account consultation, customer lookup, transaction history, and fund transfers.
-   `middleware/`: A Node.js/Express API that acts as a bridge between the frontend and the CBS simulator. It exposes a clean, RESTful API and handles business logic.
-   `cbs-simulator/`: A Node.js/Express application that simulates a Core Banking System backend. It provides mock data and endpoints to mimic real-world banking operations.

## Prerequisites

-   [Node.js](https://nodejs.org/) (v18 or higher recommended)
-   [npm](https://www.npmjs.com/) (v8 or higher recommended)

## Installation

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd cbs-middleware
    ```

2.  **Install dependencies for all services:**
    This project uses `npm` workspaces, but for simplicity, we will install dependencies in each service directory. Run the following commands from the root directory:

    ```bash
    npm install --prefix dashboard
    npm install --prefix middleware
    npm install --prefix cbs-simulator
    ```
    *Note: You only need to do this once.*

## How to Run the Application

The entire application can be started with a single command from the root of the project. This will concurrently launch the dashboard, middleware, and simulator.

```bash
npm start
```

Once started, the following services will be available:

-   **Dashboard**: `http://localhost:3001`
-   **Middleware API**: `http://localhost:3000`
-   **CBS Simulator**: `http://localhost:4000`

The dashboard will open automatically in your browser.

## Available Mock Data

The CBS simulator is pre-populated with Tunisian-themed mock data.

### Customers

| Customer ID | Name                | Location          |
| :---------- | :------------------ | :---------------- |
| `C001`      | Mohamed Ben Ali     | Le Bardo, Tunis   |
| `C002`      | Fatima El Fihri     | Sousse            |
| `C003`      | Ali Trabelsi        | Tunis             |
| `C004`      | Aisha Bouslama      | Sfax              |

### Accounts

| Account ID | Customer ID | Type              | IBAN                             |
| :--------- | :---------- | :---------------- | :------------------------------- |
| `A001`     | `C001`      | Compte Courant    | `TN59...89`                      |
| `A002`     | `C001`      | Compte Épargne    | `TN59...45`                      |
| `A003`     | `C002`      | Compte Courant    | `TN59...21`                      |
| `A004`     | `C003`      | Compte Courant    | `TN59...89`                      |
| `A005`     | `C004`      | Compte Courant    | `TN59...10`                      |
| `A006`     | `C004`      | Compte Épargne    | `TN59...45`                      |

You can use these IDs in the dashboard to test the various features. 