const { body, param, validationResult } = require('express-validator');

// Middleware pour gérer les erreurs de validation
const handleValidationErrors = (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({
            error: 'Validation failed',
            details: errors.array()
        });
    }
    next();
};

// Sanitisation des paramètres de route
const sanitizeParam = (paramName) => {
    return param(paramName)
        .trim()
        .escape()
        .matches(/^[A-Za-z0-9-_]+$/)
        .withMessage(`${paramName} doit contenir uniquement des lettres, chiffres, tirets et underscores`);
};

// Validation des IDs (customer, account)
const validateId = (paramName, pattern = /^[A-Z][0-9]{3}$/) => {
    return [
        sanitizeParam(paramName),
        param(paramName)
            .matches(pattern)
            .withMessage(`${paramName} doit respecter le format (ex: C001, A001)`)
    ];
};

// Validation du transfert
const validateTransfer = [
    body('from')
        .trim()
        .notEmpty()
        .withMessage('Le compte source est requis')
        .matches(/^[A-Z][0-9]{3}$/)
        .withMessage('Le compte source doit respecter le format (ex: A001)'),
    
    body('to')
        .trim()
        .notEmpty()
        .withMessage('Le compte destination est requis')
        .matches(/^[A-Z][0-9]{3}$/)
        .withMessage('Le compte destination doit respecter le format (ex: A001)'),
    
    body('amount')
        .isFloat({ min: 0.01 })
        .withMessage('Le montant doit être un nombre positif supérieur à 0.01')
        .custom((value) => {
            if (value > 1000000) {
                throw new Error('Le montant ne peut pas dépasser 1,000,000');
            }
            return true;
        }),
    
    body('description')
        .optional()
        .trim()
        .escape()
        .isLength({ max: 500 })
        .withMessage('La description ne peut pas dépasser 500 caractères'),
    
    handleValidationErrors
];

// Validation de l'account ID
const validateAccountId = [
    ...validateId('id', /^[A-Z][0-9]{3}$/),
    handleValidationErrors
];

// Validation du customer ID
const validateCustomerId = [
    ...validateId('id', /^[A-Z][0-9]{3}$/),
    handleValidationErrors
];

// Validation de la transaction
const validateTransaction = [
    body('accountNumber')
        .trim()
        .notEmpty()
        .withMessage('Le numéro de compte est requis')
        .matches(/^[A-Z][0-9]{3}$/)
        .withMessage('Le numéro de compte doit respecter le format (ex: A001)'),
    
    body('amount')
        .isFloat({ min: 0.01 })
        .withMessage('Le montant doit être un nombre positif supérieur à 0.01')
        .custom((value) => {
            if (value > 1000000) {
                throw new Error('Le montant ne peut pas dépasser 1,000,000');
            }
            return true;
        }),
    
    body('type')
        .isIn(['credit', 'debit'])
        .withMessage('Le type de transaction doit être "credit" ou "debit"'),
    
    body('description')
        .optional()
        .trim()
        .escape()
        .isLength({ max: 500 })
        .withMessage('La description ne peut pas dépasser 500 caractères'),
    
    handleValidationErrors
];

// Validation de accountNumber
const validateAccountNumber = [
    param('accountNumber')
        .trim()
        .notEmpty()
        .withMessage('Le numéro de compte est requis')
        .matches(/^[A-Z][0-9]{3}$/)
        .withMessage('Le numéro de compte doit respecter le format (ex: A001)')
        .escape(),
    
    handleValidationErrors
];

// Validation de la transaction de validation
const validateTransactionValidation = [
    body('amount')
        .isFloat({ min: 0.01 })
        .withMessage('Le montant doit être un nombre positif supérieur à 0.01'),
    
    body('accountNumber')
        .trim()
        .notEmpty()
        .withMessage('Le numéro de compte est requis')
        .matches(/^[A-Z][0-9]{3}$/)
        .withMessage('Le numéro de compte doit respecter le format (ex: A001)'),
    
    handleValidationErrors
];

module.exports = {
    handleValidationErrors,
    validateTransfer,
    validateAccountId,
    validateCustomerId,
    validateTransaction,
    validateAccountNumber,
    validateTransactionValidation,
    sanitizeParam
};





