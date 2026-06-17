// Error handling function for general code errors
export const handleErrorCode = (err) => {
  console.log("[ERROR_HANDLER] Error in Code:", err); // Log general code errors
};

// Error handling function for runtime errors (errors during execution)
export const handleRuntimeError = (err) => {
  console.log("[ERROR_HANDLER] Error in Running Code:", err); // Log runtime errors during execution
};
