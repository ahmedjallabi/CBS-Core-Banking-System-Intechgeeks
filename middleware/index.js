const express = require('express');
const morgan = require('morgan');
const axios = require('axios');
const swaggerUi = require('swagger-ui-express');
const swaggerJsDoc = require('swagger-jsdoc');
const api = require('@opentelemetry/api');
const cors = require('cors'); // Importer cors
const { 
    validateTransfer, 
    validateAccountId, 
    validateCustomerId,
    validateTransaction,
    validateAccountNumber,
    validateTransactionValidation
} = require('./validators');

const app = express();
const port = 3000;

app.use(express.json());

// --- CORS Configuration (Sécurisé) ---
const allowedOrigins = process.env.CORS_ALLOWED_ORIGINS 
    ? process.env.CORS_ALLOWED_ORIGINS.split(',')
    : process.env.NODE_ENV === 'production'
    ? [
        'http://localhost:30004', // Dashboard NodePort (dev)
        'http://dashboard-service:80', // Dashboard ClusterIP (K8s)
      ]
    : [
        'http://localhost:3001', // Dashboard en développement
        'http://localhost:30004', 
        'http://dashboard-service:80', 
        'http://localhost:3000',
      ];

const corsOptions = {
  origin: function (origin, callback) {
    // Autoriser les requêtes sans origin (ex: K8s probes, curl, Postman)
    if (!origin) {return callback(null, true);}

    if (allowedOrigins.indexOf(origin) !== -1) {
      return callback(null, true);
    }

    if (process.env.NODE_ENV === 'development') {
      console.warn(`CORS: Origine non autorisée mais autorisée en dev: ${origin}`);
      return callback(null, true);
    }

    console.warn(`CORS: Origine non autorisée: ${origin}`);
    callback(new Error('Non autorisé par la politique CORS'));
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  exposedHeaders: ['X-Response-Time', 'X-CBS-Status'],
  maxAge: 86400
};

app.use(cors(corsOptions));

// --- Axios Client for CBS ---
const cbsClient = axios.create({
    baseURL: process.env.CBS_SIMULATOR_URL || 'http://cbs-simulator-service:4000',
});

cbsClient.interceptors.request.use(config => {
    config.headers['x-request-start-time'] = Date.now();
    return config;
});

cbsClient.interceptors.response.use(response => {
    const startTime = response.config.headers['x-request-start-time'];
    response.headers['x-response-time'] = Date.now() - startTime;
    return response;
}, error => {
    if (error.config && error.config.headers['x-request-start-time']) {
        const startTime = error.config.headers['x-request-start-time'];
        if (error.response) {
            error.response.headers['x-response-time'] = Date.now() - startTime;
        }
    }
    return Promise.reject(error);
});

// --- Logging ---
morgan.token('cbs-response-time', (req, res) => {
    const time = res.getHeader('X-CBS-Response-Time');
    return time ? `${time}ms` : '-';
});

morgan.token('cbs-status', (req, res) => res.getHeader('X-CBS-Status') || '-');

morgan.token('traceid', (_req, _res) => {
    const span = api.trace.getSpan(api.context.active());
    return span ? span.spanContext().traceId : '-';
});

morgan.token('spanid', (_req, _res) => {
    const span = api.trace.getSpan(api.context.active());
    return span ? span.spanContext().spanId : '-';
});

app.use(morgan('[:date[clf]] :method :url :status | trace_id=:traceid span_id=:spanid | CBS Status: :cbs-status | CBS Time: :cbs-response-time'));

// --- Swagger ---
const swaggerOptions = {
    swaggerDefinition: {
        openapi: '3.0.0',
        info: {
            title: 'Middleware API',
            version: '1.0.0',
            description: 'API for interacting with the CBS Simulator',
        },
        servers: [{ url: `http://localhost:${process.env.PORT || port}` }],
        tags: [
            { name: 'Monitoring', description: 'Health and metrics' },
            { name: 'Customers', description: 'Customer operations' },
            { name: 'Accounts', description: 'Account operations' },
            { name: 'Transactions', description: 'Financial transactions' }
        ]
    },
    apis: ['./index.js'],
};
const swaggerDocs = swaggerJsDoc(swaggerOptions);
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocs));

// --- Routes (extraits pour simplification) ---
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'OK', version: '1.0.0', uptime: process.uptime() });
});

// Exemple route proxy CBS
app.get('/api/accounts/:accountNumber', validateAccountNumber, async (req, res) => {
    try {
        const { accountNumber } = req.params;
        const response = await axios.get(`${process.env.CBS_SIMULATOR_URL || 'http://cbs-simulator-service:4000'}/api/accounts/${accountNumber}`);
        res.status(200).json(response.data);
    } catch (error) {
        res.status(error.response?.status || 500).json({ error: 'Failed to fetch account', message: error.message });
    }
});

// Error handling middleware
app.use((err, req, res, _next) => {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error', message: err.message });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Not found', path: req.path, message: 'The requested endpoint does not exist' });
});

// --- Start server ---
const PORT = process.env.PORT || port;
const HOST = '0.0.0.0';
app.listen(PORT, HOST, () => {
    console.log(`CBS Middleware Service Started on ${HOST}:${PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', () => { console.log('SIGTERM received, shutting down...'); process.exit(0); });
process.on('SIGINT', () => { console.log('SIGINT received, shutting down...'); process.exit(0); });
