import { Category } from "../../DB/models/category.model.js";
import { Item } from "../../DB/models/item.model.js";
import { Transactions } from "../../DB/models/transactions.model.js";
import { ApiFeature } from "../../utils/API.Feature.js";
import { AppError } from "../../utils/AppError.js";
import { catchError } from "../../utils/catchError.js";
import { broadcastAnalysis } from "../analysis/wsServer.js";
import { getHomeAnalytics } from "../analytics/analytics.service.js";
import { createUserNotification } from "../notifications/notification.service.js";

// Create a transaction with text
export const createWithText = catchError(async (req, res, next) => {
    console.log("Received data:", req.body);

    const { text, price, categoryId, transactionDate } = req.body;
    // Normalize items — Dio sometimes serializes arrays as {0: val, 1: val}
    let items = req.body.items;
    if (items && !Array.isArray(items) && typeof items === 'object') {
        items = Object.values(items);
    }

    if (!text) {
        return next(new AppError("Text is required", 400));
    }

    let category = null;

    // Priority 1: categoryId sent directly in the body
    if (categoryId) {
        category = await Category.findOne({ _id: categoryId, user: req.user._id });
    }

    // Priority 2: resolve category from items array
    if (!category && Array.isArray(items) && items.length > 0) {
        const firstItemId = items[0];

        if (firstItemId) {
            // 2a: category that has this item in its items array
            category = await Category.findOne({
                user: req.user._id,
                items: firstItemId
            });

            // 2b: item's own category field
            if (!category) {
                const item = await Item.findOne({ _id: firstItemId, user: req.user._id });
                if (item && item.category) {
                    category = await Category.findById(item.category);
                }
            }
        }
    }

    // Priority 3: fallback — any category belonging to this user
    if (!category) {
        category = await Category.findOne({ user: req.user._id });
    }

    if (!category) {
        return next(new AppError("No category found. Please create a category first.", 404));
    }

    const data = await Transactions.create({
        text,
        category: category._id,
        price,
        quantity: req.body.quantity || 1,
        user: req.user._id,
        transactionDate: transactionDate ? new Date(transactionDate) : new Date(),
    });

    // Verify it was actually saved
    const verify = await Transactions.findById(data._id).lean();
    console.log(`[TX] ✅ Saved & verified | id=${data._id} | exists=${!!verify} | db=test | collection=transactions | user=${req.user._id}`);

    // Persist in-app notification
    try {
        await createUserNotification(req.user._id, {
            title: "Expense recorded",
            body: `${text}${price != null ? ` — ${price} EGP` : ""}`,
            type: "transaction",
            referenceId: data._id.toString(),
        });
    } catch (err) {
        console.error("[NOTIFICATION] failed to create:", err.message);
    }

    // Real-time home analytics — send to this user only
    (async () => {
        try {
            const payload = await getHomeAnalytics(req.user._id);
            broadcastAnalysis(payload, req.user._id);
        } catch (err) {
            console.error('[ANALYSIS] error computing home analytics', err.message || err);
        }
    })();

    res.status(201).json({ message: "Transaction created successfully", data });
});

// Get all transactions with API features
export const getAllData = catchError(async (req, res, next) => {
    const apiFeature = new ApiFeature(Transactions.find(), req.query);

    apiFeature.filter().search().sort().select().pagination();

    const transactions = await apiFeature.mongooseQuery;
    const totalCount = await Transactions.countDocuments();
    const responseDetails = await apiFeature.getResponseDetails();

    res.status(200).json({
        message: "Data retrieved successfully",
        meta: responseDetails,
        count: totalCount,
        data: transactions
    });
});

// Get single transaction
export const getTransaction = catchError(async (req, res, next) => {
    const transaction = await Transactions.findOne({
        _id: req.params.id,
        user: req.user._id
    }).populate('category');

    if (!transaction) {
        return next(new AppError("Transaction not found", 404));
    }

    res.status(200).json({ message: "Transaction retrieved successfully", data: transaction });
});

// Get my transactions
export const getMyTransactions = catchError(async (req, res, next) => {
    console.log("REQ USER:", req.user._id);

    const apiFeature = new ApiFeature(
        Transactions.find({ user: req.user._id }).populate('category'),
        req.query
    );

    apiFeature.filter().search().sort().select().pagination();

    const transactions = await apiFeature.mongooseQuery;
    const totalCount = await Transactions.countDocuments({ user: req.user._id });

    console.log("FOUND:", transactions.length, "total:", totalCount);

    const responseDetails = await apiFeature.getResponseDetails();

    res.status(200).json({
        message: "Transactions retrieved successfully",
        meta: responseDetails,
        count: totalCount,
        data: transactions
    });
});

// Get transactions by category
export const getTransactionsByCategory = catchError(async (req, res, next) => {
    const { categoryId } = req.params;

    const transactions = await Transactions.find({
        user: req.user._id,
        category: categoryId
    }).populate('category').sort('-createdAt');

    res.status(200).json({
        message: "Transactions retrieved successfully",
        count: transactions.length,
        data: transactions
    });
});

// Get transactions by date range
export const getTransactionsByDateRange = catchError(async (req, res, next) => {
    const { startDate, endDate } = req.query;

    if (!startDate || !endDate) {
        return next(new AppError("Start date and end date are required", 400));
    }

    const transactions = await Transactions.find({
        user: req.user._id,
        createdAt: {
            $gte: new Date(startDate),
            $lte: new Date(endDate)
        }
    }).populate('category').sort('-createdAt');

    const totalAmount = transactions.reduce((sum, t) => sum + (t.price || 0), 0);

    res.status(200).json({
        message: "Transactions retrieved successfully",
        count: transactions.length,
        totalAmount,
        data: transactions
    });
});

// Update transaction
export const updateTransaction = catchError(async (req, res, next) => {
    const { text, price, category } = req.body;

    const transaction = await Transactions.findOneAndUpdate(
        { _id: req.params.id, user: req.user._id },
        { text, price, category },
        { new: true }
    ).populate('category');

    if (!transaction) {
        return next(new AppError("Transaction not found", 404));
    }

    res.status(200).json({ message: "Transaction updated successfully", data: transaction });
});

// Delete transaction
export const deleteTransaction = catchError(async (req, res, next) => {
    const transaction = await Transactions.findOneAndDelete({
        _id: req.params.id,
        user: req.user._id
    });

    if (!transaction) {
        return next(new AppError("Transaction not found", 404));
    }

    res.status(200).json({ message: "Transaction deleted successfully", data: transaction });
});

