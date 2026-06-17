export function catchError(callback) {
  // Higher-order function to catch errors in asynchronous route handlers.
  return (req, res, next) => {
      callback(req, res, next).catch(err => {
          next(err); // Pass the error to the next middleware
      });
  };
}
