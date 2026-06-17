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
    items: Joi.alternatives().try(
        Joi.array().items(Joi.string().hex().length(24)),
        Joi.string()
    ).default([]),
    categoryId: Joi.string().hex().length(24).messages({
        "string.hex": "Invalid category ID format",
        "string.length": "Invalid category ID length"
    }),
    type: Joi.string().valid('expense', 'income').default('expense'),
    notes: Joi.string().trim().max(1000),
    voice_path: Joi.string().trim().max(500),
    OCR_path: Joi.string().trim().max(500),
    quantity: Joi.number().integer().min(1),
    transactionDate: Joi.date().iso(),
});

export const createMediaTransactionSchema = Joi.object({
    text: Joi.string().trim().min(1).max(500).required(),
    price: Joi.alternatives().try(Joi.number().min(0), Joi.string()).optional(),
    items: Joi.alternatives().try(
        Joi.array().items(Joi.string().hex().length(24)),
        Joi.string()
    ).optional(),
    categoryId: Joi.string().hex().length(24).optional(),
    type: Joi.string().valid('expense', 'income').optional(),
    notes: Joi.string().trim().max(1000).optional(),
    quantity: Joi.alternatives().try(Joi.number().integer().min(1), Joi.string()).optional(),
    transactionDate: Joi.alternatives().try(Joi.date().iso(), Joi.string()).optional(),
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
