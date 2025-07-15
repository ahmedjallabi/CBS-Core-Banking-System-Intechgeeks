# CBS Middleware Project

This project contains a simulated CBS (Core Banking System), a middleware API, and a simple web dashboard to interact with it.

## Project Structure

- `cbs-simulator/`: A Dockerized Node.js/Express application that simulates the CBS backend.
- `middleware/`: A Node.js/Express API that exposes a public interface and communicates with the CBS simulator.
- `dashboard/`: A React application providing a simple UI to use the middleware API.
- `docs/`: Contains this documentation.
- `docker-compose.yml`: Defines and runs the `cbs-simulator` service.

## How to Run the Project

### Prerequisites

- Docker and Docker Compose
- Node.js and npm

### 1. Run the CBS Simulator

The CBS simulator runs in a Docker container.

```bash
docker-compose up --build
```

This will build the simulator image and start the container. The simulator will be available at `http://localhost:4000`.

### 2. Run the Middleware

The middleware is a standard Node.js application.

```bash
cd middleware
npm install
npm start
```

The middleware will run on `http://localhost:3000`. It will connect to the CBS simulator using the Docker container's service name. API documentation is available at `http://localhost:3000/api-docs`.

### 3. Run the Dashboard

The dashboard is a standard React application.

```bash
cd dashboard
npm install
npm start
```

The dashboard will open automatically in your browser at `http://localhost:3001`. It is pre-configured to proxy API requests to the middleware on port 3000.

---

## Available Mock Data

### Accounts

- `12345`
- `67890`

### Customers

- `cust1` (related to account `12345`)
- `cust2` (related to account `67890`) 