import Joi from "joi";

export const createCategorySchema = Joi.object({
    name: Joi.string().trim().min(1).max(50).required().messages({
        "string.empty": "Category name is required",
        "string.min": "Category name must be at least 1 character",
        "string.max": "Category name must not exceed 50 characters"
    }),
    color: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/).messages({
        "string.pattern.base": "Color must be a valid hex color (e.g., #FF5733)"
    }),
    icon: Joi.string().trim().max(50).messages({
        "string.max": "Icon name must not exceed 50 characters"
    }),
    budget: Joi.number().min(0).messages({
        "number.min": "Budget cannot be negative"
    })
});

export const updateCategorySchema = Joi.object({
    name: Joi.string().trim().min(1).max(50).messages({
        "string.min": "Category name must be at least 1 character",
        "string.max": "Category name must not exceed 50 characters"
    }),
    color: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/).messages({
        "string.pattern.base": "Color must be a valid hex color (e.g., #FF5733)"
    }),
    icon: Joi.string().trim().max(50).messages({
        "string.max": "Icon name must not exceed 50 characters"
    }),
    budget: Joi.number().min(0).messages({
        "number.min": "Budget cannot be negative"
    })
});

export const itemsOperationSchema = Joi.object({
    itemIds: Joi.array().items(
        Joi.string().hex().length(24).messages({
            "string.hex": "Invalid item ID format",
            "string.length": "Invalid item ID length"
        })
    ).min(1).required().messages({
        "array.min": "At least one item ID is required",
        "any.required": "Item IDs array is required"
    })
});
