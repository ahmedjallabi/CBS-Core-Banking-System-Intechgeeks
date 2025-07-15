const express = require('express');
const morgan = require('morgan');
const axios = require('axios');
const swaggerUi = require('swagger-ui-express');
const swaggerJsDoc = require('swagger-jsdoc');
const api = require('@opentelemetry/api');
const cors = require('cors'); // Importer cors

const app = express();
const port = 3000;

app.use(express.json());
app.use(cors()); // Activer CORS pour toutes les routes

// --- Axios Client for CBS ---
const cbsClient = axios.create({
    baseURL: 'http://localhost:4000', // Le simulateur tourne sur le port 4000
});

// Interceptor to measure response time for logging
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
        error.response.headers['x-response-time'] = Date.now() - startTime;
    }
    return Promise.reject(error);
});

// --- Logging ---
// Custom token to log CBS response time
morgan.token('cbs-response-time', (req, res) => {
    // res.locals is not shared with interceptors, so we attach time to the response header itself
    const time = res.getHeader('X-CBS-Response-Time');
    return time ? `${time}ms` : '-';
});

// Custom token for CBS status
morgan.token('cbs-status', (req, res) => res.getHeader('X-CBS-Status') || '-');

// Custom token for trace ID
morgan.token('traceid', (req, res) => {
    const span = api.trace.getSpan(api.context.active());
    if (!span) return '-';
    return span.spanContext().traceId;
});

// Custom token for span ID
morgan.token('spanid', (req, res) => {
    const span = api.trace.getSpan(api.context.active());
    if (!span) return '-';
    return span.spanContext().spanId;
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
        servers: [{ url: `http://localhost:${port}` }],
    },
    apis: ['./index.js'],
};
const swaggerDocs = swaggerJsDoc(swaggerOptions);
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocs));


// --- API Routes ---

// Health Check
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'OK',
        version: '1.0.0',
        uptime: process.uptime(),
    });
});

// Metrics
app.get('/metrics', (req, res) => {
    const memoryUsage = process.memoryUsage();
    res.status(200).json({
        uptime: process.uptime(),
        memory: {
            rss: memoryUsage.rss,
            heapTotal: memoryUsage.heapTotal,
            heapUsed: memoryUsage.heapUsed,
            external: memoryUsage.external,
        },
        cpu: process.cpuUsage(),
    });
});

// Get Account
app.get('/accounts/:id', async (req, res) => {
    try {
        const response = await cbsClient.get(`/cbs/account/${req.params.id}`);
        res.setHeader('X-CBS-Status', response.status);
        res.setHeader('X-CBS-Response-Time', response.headers['x-response-time']);
        res.status(response.status).json(response.data);
    } catch (error) {
        const status = error.response ? error.response.status : 500;
        const message = error.response ? error.response.data : 'Internal Server Error';
        res.setHeader('X-CBS-Status', status);
        if (error.response && error.response.headers['x-response-time']) {
           res.setHeader('X-CBS-Response-Time', error.response.headers['x-response-time']);
        }
        res.status(status).send(message);
    }
});

// Do Transfer
app.post('/transfer', async (req, res) => {
    try {
        const response = await cbsClient.post('/cbs/transfer', req.body);
        res.setHeader('X-CBS-Status', response.status);
        res.setHeader('X-CBS-Response-Time', response.headers['x-response-time']);
        res.status(response.status).json(response.data);
    } catch (error) {
        const status = error.response ? error.response.status : 500;
        const message = error.response ? error.response.data : 'Internal Server Error';
        res.setHeader('X-CBS-Status', status);
        if (error.response && error.response.headers['x-response-time']) {
           res.setHeader('X-CBS-Response-Time', error.response.headers['x-response-time']);
        }
        res.status(status).send(message);
    }
});

// Get Customer
app.get('/customers/:id', async (req, res) => {
    try {
        const response = await cbsClient.get(`/cbs/customer/${req.params.id}`);
        res.setHeader('X-CBS-Status', response.status);
        res.setHeader('X-CBS-Response-Time', response.headers['x-response-time']);
        res.status(response.status).json(response.data);
    } catch (error) {
        const status = error.response ? error.response.status : 500;
        const message = error.response ? error.response.data : 'Internal Server Error';
        res.setHeader('X-CBS-Status', status);
        if (error.response && error.response.headers['x-response-time']) {
           res.setHeader('X-CBS-Response-Time', error.response.headers['x-response-time']);
        }
        res.status(status).send(message);
    }
});

// Get History
app.get('/accounts/:id/history', async (req, res) => {
    try {
        const response = await cbsClient.get(`/cbs/history/${req.params.id}`);
        res.setHeader('X-CBS-Status', response.status);
        res.setHeader('X-CBS-Response-Time', response.headers['x-response-time']);
        res.status(response.status).json(response.data);
    } catch (error) {
        const status = error.response ? error.response.status : 500;
        const message = error.response ? error.response.data : 'Internal Server Error';
        res.setHeader('X-CBS-Status', status);
        if (error.response && error.response.headers['x-response-time']) {
           res.setHeader('X-CBS-Response-Time', error.response.headers['x-response-time']);
        }
        res.status(status).send(message);
    }
});


app.listen(port, () => {
    console.log(`Middleware listening at http://localhost:${port}`);
    console.log(`Swagger docs available at http://localhost:${port}/api-docs`);
}); 