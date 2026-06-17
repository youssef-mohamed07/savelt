import Joi from "joi";

export const createItemSchema = Joi.object({
    name: Joi.string().trim().min(1).max(100).required().messages({
        "string.empty": "Name is required",
        "string.min": "Name must be at least 1 character",
        "string.max": "Name must not exceed 100 characters"
    }),
    price: Joi.number().min(0).messages({
        "number.min": "Price cannot be negative"
    }),
    categoryId: Joi.string().hex().length(24).messages({
        "string.hex": "Invalid category ID format",
        "string.length": "Invalid category ID length"
    })
});

export const updateItemSchema = Joi.object({
    name: Joi.string().trim().min(1).max(100).messages({
        "string.min": "Name must be at least 1 character",
        "string.max": "Name must not exceed 100 characters"
    }),
    price: Joi.number().min(0).messages({
        "number.min": "Price cannot be negative"
    })
});

export const categoryOperationSchema = Joi.object({
    itemId: Joi.string().hex().length(24).required().messages({
        "string.empty": "Item ID is required",
        "string.hex": "Invalid item ID format",
        "string.length": "Invalid item ID length"
    }),
    categoryId: Joi.string().hex().length(24).required().messages({
        "string.empty": "Category ID is required",
        "string.hex": "Invalid category ID format",
        "string.length": "Invalid category ID length"
    })
});
