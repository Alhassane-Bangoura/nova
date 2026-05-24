class AppError extends Error {
    constructor(message, statusCode) {
        super(message);
        this.statusCode = statusCode;
        this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
        this.isOperational = true; // Permet de distinguer nos erreurs métiers des crashs inattendus

        Error.captureStackTrace(this, this.constructor);
    }
}
module.exports = AppError;
