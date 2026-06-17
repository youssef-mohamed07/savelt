// Middleware to handle requests to undefined routes (404 error)
export const URL_Error = (req, res, next) => {
  console.log("[URL_ERROR] 404 - Route not found ->", req.originalUrl); // Log the 404 error with the requested URL

  res.status(404).json({
    error: "Not Found", // Return error response for undefined routes
    message: `The requested URL ${req.originalUrl} was not found on this server.` // Inform the user about the missing route
  });
};
