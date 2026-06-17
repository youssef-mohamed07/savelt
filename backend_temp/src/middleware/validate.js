import { AppError } from "../utils/AppError.js";

// Middleware for validating request body against a Joi schema and handling file/multi-file cases
export const validate = (schema) => {
  return (req, res, next) => {
    console.log("[VALIDATE] Start: Validating request");
    function handleError(error) {
      if (!error) {
        console.log("[VALIDATE] Success: Validation passed");
        next();
      } else {
        const errorMessages = error.details.map(detail => detail.message).join(', ');
        console.log(`[VALIDATE] Error: ${errorMessages}`);
        next(new AppError(`Validation error: ${errorMessages}`, 400));
      }
    }
    if (req.file) {
      console.log("[VALIDATE] Validating single file upload");
      const { error } = schema.validate(
        { 
          image: req.file,
          ...req.body,
          ...req.params,
          ...req.query
        },
        { abortEarly: false }
      );
      handleError(error);
    } else if (req.files) {
      console.log("[VALIDATE] Validating multiple file uploads");
      const { error } = schema.validate(
        {
          images: req.files.images,
          imageCover: req.files.imageCover[0],
          ...req.body,
          ...req.params,
          ...req.query
        },
        { abortEarly: false }
      );
      handleError(error);
    } else {
      console.log("[VALIDATE] Validating request without files");
      const { error } = schema.validate(
        { 
          ...req.body, 
          ...req.query 
        }, 
        { abortEarly: false }
      );
      handleError(error);
    }
  };
};
