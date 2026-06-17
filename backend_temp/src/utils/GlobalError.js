// Global error handling middleware to catch and respond to unhandled errors in the app
export const GlobalError = (err, req, res, next) => {
    const code = Number(err.statusCode) || 500;
    console.error("[GLOBAL_ERROR] Handler triggered", {
        statusCode: code,
        message: err.message,
        stack: err.stack
    });
    res.status(code).json({
        error: "Some Errors in the Global..",
        message: err.message,
        code: code
    });
};
