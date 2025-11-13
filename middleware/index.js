/* eslint-disable no-console */
/* eslint-disable no-unused-vars */

const express = require('express');
const morgan = require('morgan');
const axios = require('axios');
const swaggerUi = require('swagger-ui-express');
const swaggerJsDoc = require('swagger-jsdoc');
const api = require('@opentelemetry/api');
const cors = require('cors');
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

// --- CORS Configuration ---
const allowedOrigins = process.env.CORS_ALLOWED_ORIGINS 
    ? process.env.CORS_ALLOWED_ORIGINS.split(',')
    : process.env.NODE_ENV === 'production'
    ? [
        'http://localhost:30004',
        'http://dashboard-service:80',
      ]
    : [
        'http://localhost:3001',
        'http://localhost:30004',
        'http://dashboard-service:80',
        'http://localhost:3000',
      ];

const corsOptions = {
  origin: (origin, callback) => {
    if (!origin) {return callback(null, true);} // K8s probes, curl, Postman
    if (allowedOrigins.includes(origin)) {return callback(null, true);}
    if (process.env.NODE_ENV === 'development') {
      console.warn(`CORS: Origine non autorisée mais autorisée en dev: ${origin}`);
      return callback(null, true);
    }
    console.warn(`CORS: Origine non autorisée: ${origin}`);
    callback(new Error('Non autorisé par la politique CORS'));
  },
  credentials: true,
  methods: ['GET','POST','PUT','DELETE','OPTIONS'],
  allowedHeaders: ['Content-Type','Authorization','X-Requested-With'],
  exposedHeaders: ['X-Response-Time','X-CBS-Status'],
  maxAge: 86400
};

app.use(cors(corsOptions));

// --- Axios Client ---
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
    if (error.config?.headers['x-request-start-time']) {
        const startTime = error.config.headers['x-request-start-time'];
        if (error.response) {error.response.headers['x-response-time'] = Date.now() - startTime;}
    }
    return Promise.reject(error);
});

// --- Logging ---
morgan.token('cbs-response-time', (req, res) => res.getHeader('X-CBS-Response-Time') ? `${res.getHeader('X-CBS-Response-Time')}ms` : '-');
morgan.token('cbs-status', (req, res) => res.getHeader('X-CBS-Status') || '-');
morgan.token('traceid', () => {
    const span = api.trace.getSpan(api.context.active());
    return span ? span.spanContext().traceId : '-';
});
morgan.token('spanid', () => {
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

// --- Routes ---
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'OK', version: '1.0.0', uptime: process.uptime() });
});

app.get('/api/accounts/:accountNumber', validateAccountNumber, async (req, res) => {
    try {
        const { accountNumber } = req.params;
        const response = await axios.get(`${process.env.CBS_SIMULATOR_URL || 'http://cbs-simulator-service:4000'}/api/accounts/${accountNumber}`);
        res.status(200).json(response.data);
    } catch (error) {
        res.status(error.response?.status || 500).json({ error: 'Failed to fetch account', message: error.message });
    }
});

// Error handling
app.use((err, req, res, _next) => {
    res.status(500).json({ error: 'Internal server error', message: err.message });
});

// 404
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
process.on('SIGTERM', () => process.exit(0));
process.on('SIGINT', () => process.exit(0));
