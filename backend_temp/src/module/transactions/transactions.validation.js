import Joi from "joi";

export const createTextTransactionSchema = Joi.object({
    text: Joi.string().trim().min(1).max(500).required().messages({
        "string.empty": "Text is required",
        "string.min": "Text must be at least 1 character",
        "string.max": "Text must not exceed 500 characters"
    }),
    price: Joi.number().min(0).messages({
        "number.min": "Price cannot be negative"
    }),
    items: Joi.array().items(
        Joi.string().hex().length(24)
    ).default([]),
    categoryId: Joi.string().hex().length(24).messages({
        "string.hex": "Invalid category ID format",
        "string.length": "Invalid category ID length"
    }),
    type: Joi.string().valid('expense', 'income').default('expense'),
    notes: Joi.string().trim().max(1000)
});

export const updateTransactionSchema = Joi.object({
    text: Joi.string().trim().min(1).max(500).messages({
        "string.min": "Text must be at least 1 character",
        "string.max": "Text must not exceed 500 characters"
    }),
    price: Joi.number().min(0).messages({
        "number.min": "Price cannot be negative"
    }),
    category: Joi.string().hex().length(24).messages({
        "string.hex": "Invalid category ID format",
        "string.length": "Invalid category ID length"
    }),
    type: Joi.string().valid('expense', 'income'),
    notes: Joi.string().trim().max(1000)
});

export const dateRangeSchema = Joi.object({
    startDate: Joi.date().iso().required().messages({
        "date.format": "Start date must be in ISO format",
        "any.required": "Start date is required"
    }),
    endDate: Joi.date().iso().min(Joi.ref('startDate')).required().messages({
        "date.format": "End date must be in ISO format",
        "date.min": "End date must be after start date",
        "any.required": "End date is required"
    })
});
