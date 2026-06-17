import { Transactions } from "../../DB/models/transactions.model.js";
import { Category } from "../../DB/models/category.model.js";
import { AppError } from "../../utils/AppError.js";
import { catchError } from "../../utils/catchError.js";

// Get summary analytics
export const getSummary = catchError(async (req, res, next) => {
    const userId = req.user._id;

    // Get date range (default: current month)
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);

    const [totalTransactions, monthlyTransactions, categories] = await Promise.all([
        Transactions.aggregate([
            { $match: { user: userId, isDeleted: { $ne: true } } },
            { $group: { _id: null, total: { $sum: "$price" }, count: { $sum: 1 } } }
        ]),
        Transactions.aggregate([
            { 
                $match: { 
                    user: userId,
                    isDeleted: { $ne: true },
                    createdAt: { $gte: startOfMonth, $lte: endOfMonth }
                } 
            },
            { $group: { _id: null, total: { $sum: "$price" }, count: { $sum: 1 } } }
        ]),
        Category.countDocuments({ user: userId })
    ]);

    res.status(200).json({
        message: "Summary retrieved successfully",
        data: {
            allTime: {
                totalAmount: totalTransactions[0]?.total || 0,
                transactionCount: totalTransactions[0]?.count || 0
            },
            thisMonth: {
                totalAmount: monthlyTransactions[0]?.total || 0,
                transactionCount: monthlyTransactions[0]?.count || 0,
                period: {
                    start: startOfMonth,
                    end: endOfMonth
                }
            },
            categoriesCount: categories
        }
    });
});

// Get analytics by category
export const getByCategory = catchError(async (req, res, next) => {
    const userId = req.user._id;
    const { startDate, endDate } = req.query;

    const matchStage = { user: userId, isDeleted: { $ne: true } };
    
    if (startDate && endDate) {
        matchStage.createdAt = {
            $gte: new Date(new Date(startDate).setHours(0, 0, 0, 0)),
            $lte: new Date(new Date(endDate).setHours(23, 59, 59, 999))
        };
    }

    const analytics = await Transactions.aggregate([
        { $match: matchStage },
        {
            $group: {
                _id: "$category",
                totalAmount: { $sum: "$price" },
                count: { $sum: 1 },
                avgAmount: { $avg: "$price" }
            }
        },
        {
            $lookup: {
                from: "categories",
                localField: "_id",
                foreignField: "_id",
                as: "categoryInfo"
            }
        },
        {
            $unwind: {
                path: "$categoryInfo",
                preserveNullAndEmptyArrays: true
            }
        },
        {
            $project: {
                _id: 1,
                categoryName: { $ifNull: ["$categoryInfo.name", "Uncategorized"] },
                categoryColor: { $ifNull: ["$categoryInfo.color", "#cccccc"] },
                totalAmount: { $round: ["$totalAmount", 2] },
                count: 1,
                avgAmount: { $round: ["$avgAmount", 2] }
            }
        },
        { $sort: { totalAmount: -1 } }
    ]);

    const grandTotal = analytics.reduce((sum, cat) => sum + cat.totalAmount, 0);

    // Add percentage to each category
    const analyticsWithPercentage = analytics.map(cat => ({
        ...cat,
        percentage: grandTotal > 0 ? Math.round((cat.totalAmount / grandTotal) * 100) : 0
    }));

    res.status(200).json({
        message: "Category analytics retrieved successfully",
        data: {
            grandTotal,
            categories: analyticsWithPercentage
        }
    });
});

// Get analytics by date (daily/weekly/monthly)
export const getByDate = catchError(async (req, res, next) => {
    const userId = req.user._id;
    const { period = 'daily', startDate, endDate } = req.query;

    // Default to last 30 days if no dates provided
    const end = endDate ? new Date(new Date(endDate).setHours(23, 59, 59, 999)) : new Date();
    const start = startDate ? new Date(new Date(startDate).setHours(0, 0, 0, 0)) : new Date(end.getTime() - 30 * 24 * 60 * 60 * 1000);

    let groupBy;
    switch (period) {
        case 'weekly':
            groupBy = { $dateToString: { format: "%Y-W%V", date: { $ifNull: ["$transactionDate", "$createdAt"] } } };
            break;
        case 'monthly':
            groupBy = { $dateToString: { format: "%Y-%m", date: { $ifNull: ["$transactionDate", "$createdAt"] } } };
            break;
        case 'yearly':
            groupBy = { $dateToString: { format: "%Y", date: { $ifNull: ["$transactionDate", "$createdAt"] } } };
            break;
        default: // daily
            groupBy = { $dateToString: { format: "%Y-%m-%d", date: { $ifNull: ["$transactionDate", "$createdAt"] } } };
    }

    // Use transactionDate if available, fallback to createdAt for date range filter
    const dateField = { $ifNull: ["$transactionDate", "$createdAt"] };
    const analytics = await Transactions.aggregate([
        {
            $match: {
                user: userId,
                isDeleted: { $ne: true },
                $or: [
                    { transactionDate: { $gte: start, $lte: end } },
                    { transactionDate: { $exists: false }, createdAt: { $gte: start, $lte: end } },
                    { transactionDate: null, createdAt: { $gte: start, $lte: end } }
                ]
            }
        },
        {
            $group: {
                _id: groupBy,
                totalAmount: { $sum: "$price" },
                count: { $sum: 1 },
                year: { $first: { $year: "$createdAt" } }
            }
        },
        { $sort: { _id: 1 } }
    ]);

    res.status(200).json({
        message: "Date analytics retrieved successfully",
        data: {
            period,
            dateRange: { start, end },
            analytics
        }
    });
});

// Get top spending categories
export const getTopCategories = catchError(async (req, res, next) => {
    const userId = req.user._id;
    const limit = parseInt(req.query.limit) || 5;

    const topCategories = await Transactions.aggregate([
        { $match: { user: userId, isDeleted: { $ne: true }, category: { $exists: true } } },
        {
            $group: {
                _id: "$category",
                totalAmount: { $sum: "$price" },
                count: { $sum: 1 }
            }
        },
        { $sort: { totalAmount: -1 } },
        { $limit: limit },
        {
            $lookup: {
                from: "categories",
                localField: "_id",
                foreignField: "_id",
                as: "categoryInfo"
            }
        },
        { $unwind: "$categoryInfo" },
        {
            $project: {
                _id: 1,
                name: "$categoryInfo.name",
                color: "$categoryInfo.color",
                totalAmount: 1,
                count: 1
            }
        }
    ]);

    res.status(200).json({
        message: "Top categories retrieved successfully",
        data: topCategories
    });
});

// Get spending trends (compare periods)
export const getTrends = catchError(async (req, res, next) => {
    const userId = req.user._id;

    const now = new Date();
    
    // Current month
    const currentMonthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const currentMonthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);
    
    // Previous month
    const prevMonthStart = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const prevMonthEnd = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59);

    const [currentMonth, previousMonth] = await Promise.all([
        Transactions.aggregate([
            { $match: { user: userId, isDeleted: { $ne: true }, createdAt: { $gte: currentMonthStart, $lte: currentMonthEnd } } },
            { $group: { _id: null, total: { $sum: "$price" }, count: { $sum: 1 } } }
        ]),
        Transactions.aggregate([
            { $match: { user: userId, isDeleted: { $ne: true }, createdAt: { $gte: prevMonthStart, $lte: prevMonthEnd } } },
            { $group: { _id: null, total: { $sum: "$price" }, count: { $sum: 1 } } }
        ])
    ]);

    const currentTotal = currentMonth[0]?.total || 0;
    const previousTotal = previousMonth[0]?.total || 0;
    
    const percentageChange = previousTotal > 0 
        ? Math.round(((currentTotal - previousTotal) / previousTotal) * 100) 
        : 0;

    res.status(200).json({
        message: "Trends retrieved successfully",
        data: {
            currentMonth: {
                total: currentTotal,
                count: currentMonth[0]?.count || 0,
                period: { start: currentMonthStart, end: currentMonthEnd }
            },
            previousMonth: {
                total: previousTotal,
                count: previousMonth[0]?.count || 0,
                period: { start: prevMonthStart, end: prevMonthEnd }
            },
            comparison: {
                difference: currentTotal - previousTotal,
                percentageChange,
                trend: percentageChange > 0 ? 'increase' : percentageChange < 0 ? 'decrease' : 'stable'
            }
        }
    });
});
