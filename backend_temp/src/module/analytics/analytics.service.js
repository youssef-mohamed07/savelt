/**
 * Analytics service – pure Node.js + MongoDB aggregation.
 * Used for home real-time payload and top spending category (offers).
 */
import { Transactions } from "../../DB/models/transactions.model.js";

const activeMatch = { isDeleted: { $ne: true } };

/**
 * Build match for a user (and optionally expense-only).
 * @param {mongoose.Types.ObjectId} userId
 * @param {{ expenseOnly?: boolean }} [opts]
 */
function userMatch(userId, opts = {}) {
  const match = { user: userId, ...activeMatch };
  if (opts.expenseOnly) match.type = "expense";
  return match;
}

/**
 * Home analytics for WebSocket: total_amount, analysis_over_time (daily), category_analysis.
 * Matches the payload shape previously sent from Python (no base64 charts).
 * @param {mongoose.Types.ObjectId} userId
 * @param {{ start?: Date, end?: Date }} [timeRange]
 */
export async function getHomeAnalytics(userId, timeRange = {}) {
  const now = new Date();
  const start = timeRange.start || new Date('2020-01-01');
  const end = timeRange.end || now;

  const daysDiff = Math.ceil((end - start) / (1000 * 60 * 60 * 24));

  // Choose grouping based on range
  let groupFormat;
  if (daysDiff <= 31) {
    groupFormat = "%Y-%m-%d";        // daily:   "2026-04-17"
  } else if (daysDiff <= 365) {
    groupFormat = "%Y-%m";           // monthly: "2026-04"
  } else {
    groupFormat = "%Y";              // yearly:  "2026"
  }

  // Use transactionDate if set, otherwise createdAt
  const matchWithDate = {
    ...userMatch(userId),
    $or: [
      { transactionDate: { $gte: start, $lte: end } },
      { transactionDate: { $exists: false }, createdAt: { $gte: start, $lte: end } },
      { transactionDate: null, createdAt: { $gte: start, $lte: end } }
    ]
  };

  const dateExpr = { $ifNull: ["$transactionDate", "$createdAt"] };

  const [totalResult, dailyPipeline, categoryPipeline] = await Promise.all([
    Transactions.aggregate([
      { $match: userMatch(userId) },
      { $group: { _id: null, total_amount: { $sum: "$price" } } }
    ]),
    Transactions.aggregate([
      { $match: matchWithDate },
      {
        $group: {
          _id: { $dateToString: { format: groupFormat, date: dateExpr } },
          total: { $sum: "$price" }
        }
      },
      { $sort: { _id: 1 } }
    ]),
    Transactions.aggregate([
      { $match: match },
      { $group: { _id: "$category", total: { $sum: "$price" } } },
      { $lookup: { from: "categories", localField: "_id", foreignField: "_id", as: "cat" } },
      { $unwind: { path: "$cat", preserveNullAndEmptyArrays: true } },
      {
        $group: {
          _id: { $ifNull: ["$cat.name", "Uncategorized"] },
          total: { $sum: "$total" }
        }
      },
      { $sort: { total: -1 } }
    ])
  ]);

  const total_amount = totalResult[0]?.total_amount ?? 0;
  const analysis_over_time = Object.fromEntries(
    dailyPipeline.map((d) => [d._id, Number(d.total)])
  );
  const category_analysis = Object.fromEntries(
    categoryPipeline.map((c) => [c._id, Number(c.total)])
  );

  return {
    total_amount,
    analysis_over_time,
    category_analysis
  };
}

/**
 * Top spending category for a user (expense only). Returns { categoryId } or { categoryId: null }.
 * @param {mongoose.Types.ObjectId} userId
 */
export async function getTopSpendingCategory(userId) {
  const result = await Transactions.aggregate([
    { $match: userMatch(userId, { expenseOnly: true }) },
    { $match: { category: { $exists: true, $ne: null } } },
    { $group: { _id: "$category", total: { $sum: "$price" } } },
    { $sort: { total: -1 } },
    { $limit: 1 }
  ]);

  const categoryId = result[0]?._id ?? null;
  return { categoryId };
}
