import Joi from "joi";

// Schema: Signup Validation
export const signupValidationSchema = Joi.object({
  firstName: Joi.string().trim().min(3).max(50).required().messages({
    "string.empty": "Name is required",
    "string.min": "Name must be at least 3 characters long",
    "string.max": "Name must not exceed 50 characters",
  }),
  lastName: Joi.string().trim().min(3).max(50).required().messages({
    "string.empty": "Name is required",
    "string.min": "Name must be at least 3 characters long",
    "string.max": "Name must not exceed 50 characters",
  }),
  email: Joi.string().email().trim().required().messages({
    "string.empty": "Email is required",
    "string.email": "Invalid email format",
  }),
  password: Joi.string().trim().min(6).max(100).required().messages({
    "string.empty": "Password is required",
    "string.min": "Password must be at least 6 characters long",
    "string.max": "Password must not exceed 100 characters",
  }),
  phone: Joi.string()
    .pattern(/^\d{8,12}$/)
    .required()
    .messages({
      "string.pattern.base": "Phone number must contain only digits and be 8 to 12 digits long",
      "string.empty": "Phone number is required",
    }),
  countryCode: Joi.string()
    .pattern(/^\+\d{1,3}$/)
    .required()
    .messages({
      "string.pattern.base": "Country code must start with + and contain 1 to 3 digits",
      "string.empty": "Country code is required",
    }),
  country: Joi.string().trim().min(2).max(50).required().messages({
    "string.empty": "Country is required",
    "string.min": "Country must be at least 2 characters long",
    "string.max": "Country must not exceed 50 characters",
  }),
});

// Schema: Signin Validation
export const signinValidationSchema = Joi.object({
  email: Joi.string().email().trim().required().messages({
    "string.empty": "Email is required",
    "string.email": "Invalid email format",
  }),
  password: Joi.string().trim().min(6).max(100).required().messages({
    "string.empty": "Password is required",
    "string.min": "Password must be at least 6 characters long",
    "string.max": "Password must not exceed 100 characters",
  }),
});

// Schema: OTP Configuration Validation
export const otpValidationSchema = Joi.object({
  otp: Joi.string().length(6).pattern(/^[0-9]+$/).required().messages({
    "string.empty": "OTP is required",
    "string.length": "OTP must be exactly 6 digits",
    "string.pattern.base": "OTP must contain only numbers",
  }),
});
