const AppError = require('../errors/AppError');

const errorHandler = (err, req, res, next) => {
    err.statusCode = err.statusCode || 500;
    err.status = err.status || 'error';

    // Logging interne pour l'administrateur
    console.error(`[ERROR LOG] ${err.statusCode} - ${err.message}`);

    if (err.isOperational) {
        // Erreur métier (ex: "Stock insuffisant") -> On informe le frontend proprement
        return res.status(err.statusCode).json({
            status: err.status,
            message: err.message
        });
    }

    // Bug technique (ex: Erreur de syntaxe Node.js, Base de données corrompue)
    console.error('💥 ERREUR NON GÉRÉE (CRASH INTERNE):', err);
    res.status(500).json({
        status: 'error',
        message: 'Une erreur interne inattendue est survenue au sein de l\'ERP.'
    });
};

module.exports = errorHandler;
