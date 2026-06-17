import { Category } from "../../DB/models/category.model.js";
import { Item } from "../../DB/models/item.model.js";
import { Transactions } from "../../DB/models/transactions.model.js";
import { ApiFeature } from "../../utils/API.Feature.js";
import { AppError } from "../../utils/AppError.js";
import { catchError } from "../../utils/catchError.js";

// Get all categories for user
export const getMyCategory = catchError(async (req, res, next) => {
    const apiFeature = new ApiFeature(
        Category.find({ user: req.user._id }),
        req.query
    );

    apiFeature.filter().search().sort().select().pagination();

    const categories = await apiFeature.mongooseQuery;
    const totalCount = await Category.countDocuments({ user: req.user._id });
    const responseDetails = await apiFeature.getResponseDetails();

    res.status(200).json({
        message: "Categories retrieved successfully",
        meta: responseDetails,
        count: totalCount,
        data: categories
    });
});

// Get single category
export const getCategory = catchError(async (req, res, next) => {
    const category = await Category.findOne({
        _id: req.params.id,
        user: req.user._id
    });

    if (!category) {
        return next(new AppError("Category not found", 404));
    }

    res.status(200).json({ message: "Category retrieved successfully", data: category });
});

// Get category with populated items
export const getCategoryWithItems = catchError(async (req, res, next) => {
    const category = await Category.findOne({
        _id: req.params.id,
        user: req.user._id
    }).populate('items');

    if (!category) {
        return next(new AppError("Category not found", 404));
    }

    res.status(200).json({ message: "Category retrieved successfully", data: category });
});

// Create a new category
export const createCategory = catchError(async (req, res, next) => {
    const { name, color } = req.body;

    if (!name) {
        return next(new AppError("Name is required", 400));
    }

    // Check if category with same name exists for user
    const existingCategory = await Category.findOne({ user: req.user._id, name });
    if (existingCategory) {
        return next(new AppError("Category with this name already exists", 400));
    }

    const category = await Category.create({
        user: req.user._id,
        name,
        color: color || "#ffffff",
        items: []
    });

    console.log(`[CATEGORY] ✅ Created: "${name}" id=${category._id} user=${req.user._id} | db=test | collection=categories`);

    res.status(201).json({ message: "Category created successfully", data: category });
});

// Update category
export const updateCategory = catchError(async (req, res, next) => {
    const { name, color } = req.body;

    // Check if new name conflicts with existing category
    if (name) {
        const existingCategory = await Category.findOne({
            user: req.user._id,
            name,
            _id: { $ne: req.params.id }
        });
        if (existingCategory) {
            return next(new AppError("Category with this name already exists", 400));
        }
    }

    const category = await Category.findOneAndUpdate(
        { _id: req.params.id, user: req.user._id },
        { name, color },
        { new: true }
    );

    if (!category) {
        return next(new AppError("Category not found", 404));
    }

    res.status(200).json({ message: "Category updated successfully", data: category });
});

// Delete a category
export const deleteCategory = catchError(async (req, res, next) => {
    const category = await Category.findOneAndDelete({
        _id: req.params.id,
        user: req.user._id
    });

    if (!category) {
        return next(new AppError("Category not found", 404));
    }

    // Update transactions to remove category reference
    await Transactions.updateMany(
        { category: req.params.id },
        { $unset: { category: 1 } }
    );

    res.status(200).json({ message: "Category deleted successfully", data: category });
});

// Add items to category
export const addItemsToCategory = catchError(async (req, res, next) => {
    const { itemIds } = req.body;

    if (!itemIds || !Array.isArray(itemIds) || itemIds.length === 0) {
        return next(new AppError("Item IDs array is required", 400));
    }

    // Verify all items belong to user
    const items = await Item.find({ _id: { $in: itemIds }, user: req.user._id });
    if (items.length !== itemIds.length) {
        return next(new AppError("Some items not found or don't belong to you", 404));
    }

    const category = await Category.findOneAndUpdate(
        { _id: req.params.id, user: req.user._id },
        { $addToSet: { items: { $each: itemIds } } },
        { new: true }
    ).populate('items');

    if (!category) {
        return next(new AppError("Category not found", 404));
    }

    res.status(200).json({ message: "Items added to category successfully", data: category });
});

// Remove items from category
export const removeItemsFromCategory = catchError(async (req, res, next) => {
    const { itemIds } = req.body;

    if (!itemIds || !Array.isArray(itemIds) || itemIds.length === 0) {
        return next(new AppError("Item IDs array is required", 400));
    }

    const category = await Category.findOneAndUpdate(
        { _id: req.params.id, user: req.user._id },
        { $pull: { items: { $in: itemIds } } },
        { new: true }
    ).populate('items');

    if (!category) {
        return next(new AppError("Category not found", 404));
    }

    res.status(200).json({ message: "Items removed from category successfully", data: category });
});
