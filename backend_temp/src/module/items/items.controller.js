import { Item } from "../../DB/models/item.model.js";
import { Category } from "../../DB/models/category.model.js";
import { ApiFeature } from "../../utils/API.Feature.js";
import { AppError } from "../../utils/AppError.js";
import { catchError } from "../../utils/catchError.js";

// Create a new item
export const createItem = catchError(async (req, res, next) => {
    const { name, price, categoryId } = req.body;

    if (!name) {
        return next(new AppError("Name is required", 400));
    }

    const item = await Item.create({
        user: req.user._id,
        name,
        price,
        category: categoryId || undefined   // store category reference on the item itself
    });

    console.log(`[ITEM] ✅ Created: "${name}" id=${item._id} user=${req.user._id} category=${categoryId || 'none'} | db=test | collection=items`);

    // Also push item into the category's items array
    if (categoryId) {
        await Category.findByIdAndUpdate(categoryId, {
            $push: { items: item._id }
        });
        console.log(`[ITEM] ✅ Added to category ${categoryId}`);
    }

    res.status(201).json({ message: "Item created successfully", data: item });
});

// Get all items for user
export const getMyItems = catchError(async (req, res, next) => {
    const apiFeature = new ApiFeature(
        Item.find({ user: req.user._id }),
        req.query
    );

    apiFeature.filter().search().sort().select().pagination();

    const items = await apiFeature.mongooseQuery;
    const responseDetails = await apiFeature.getResponseDetails();

    res.status(200).json({
        message: "Items retrieved successfully",
        meta: responseDetails,
        data: items
    });
});

// Get single item
export const getItem = catchError(async (req, res, next) => {
    const item = await Item.findOne({ _id: req.params.id, user: req.user._id });

    if (!item) {
        return next(new AppError("Item not found", 404));
    }

    res.status(200).json({ message: "Item retrieved successfully", data: item });
});

// Update item
export const updateItem = catchError(async (req, res, next) => {
    const { name, price } = req.body;

    const item = await Item.findOneAndUpdate(
        { _id: req.params.id, user: req.user._id },
        { name, price },
        { new: true }
    );

    if (!item) {
        return next(new AppError("Item not found", 404));
    }

    res.status(200).json({ message: "Item updated successfully", data: item });
});

// Delete item
export const deleteItem = catchError(async (req, res, next) => {
    const item = await Item.findOneAndDelete({ _id: req.params.id, user: req.user._id });

    if (!item) {
        return next(new AppError("Item not found", 404));
    }

    // Remove item from all categories
    await Category.updateMany(
        { items: item._id },
        { $pull: { items: item._id } }
    );

    res.status(200).json({ message: "Item deleted successfully", data: item });
});

// Add item to category
export const addItemToCategory = catchError(async (req, res, next) => {
    const { itemId, categoryId } = req.body;

    const item = await Item.findOne({ _id: itemId, user: req.user._id });
    if (!item) {
        return next(new AppError("Item not found", 404));
    }

    const category = await Category.findOne({ _id: categoryId, user: req.user._id });
    if (!category) {
        return next(new AppError("Category not found", 404));
    }

    if (category.items.includes(itemId)) {
        return next(new AppError("Item already in category", 400));
    }

    category.items.push(itemId);
    await category.save();

    res.status(200).json({ message: "Item added to category successfully", data: category });
});

// Remove item from category
export const removeItemFromCategory = catchError(async (req, res, next) => {
    const { itemId, categoryId } = req.body;

    const category = await Category.findOneAndUpdate(
        { _id: categoryId, user: req.user._id },
        { $pull: { items: itemId } },
        { new: true }
    );

    if (!category) {
        return next(new AppError("Category not found", 404));
    }

    res.status(200).json({ message: "Item removed from category successfully", data: category });
});
