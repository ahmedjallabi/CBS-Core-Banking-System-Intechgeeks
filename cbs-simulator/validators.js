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

// Validation des IDs (customer, account)
const validateId = (paramName, pattern = /^[A-Z][0-9]{3}$/) => {
    return [
        param(paramName)
            .trim()
            .notEmpty()
            .withMessage(`${paramName} est requis`)
            .matches(pattern)
            .withMessage(`${paramName} doit respecter le format (ex: C001, A001)`)
            .escape(),
        handleValidationErrors
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
    ...validateId('id', /^[A-Z][0-9]{3}$/)
];

// Validation du customer ID
const validateCustomerId = [
    ...validateId('id', /^[A-Z][0-9]{3}$/)
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

module.exports = {
    handleValidationErrors,
    validateTransfer,
    validateAccountId,
    validateCustomerId,
    validateTransaction,
    validateAccountNumber
};




