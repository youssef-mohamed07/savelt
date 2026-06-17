// Custom error class to represent application-specific errors with a status code
export class AppError extends Error {
    // Initializes the error with a message and status code
    constructor(message, statusCode) {
        super(message);
        this.statusCode = statusCode;
        Error.captureStackTrace(this, this.constructor);
    }

    // Returns a string representation of the error for logging
    toString() {
        return `${this.name}: ${this.message} (Status Code: ${this.statusCode})`;
    }
}
