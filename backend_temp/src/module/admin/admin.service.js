import { Types } from "mongoose";
import { User } from "../../DB/models/user.model.js";
import { Category } from "../../DB/models/category.model.js";
import { Item } from "../../DB/models/item.model.js";
import { Transactions } from "../../DB/models/transactions.model.js";
import { AppError } from "../../utils/AppError.js";
import { getAmazonProductSearchSuggestions, getOffersCacheAdminSnapshot } from "../offers/offer.service.js";

const activeTransactionMatch = { isDeleted: { $ne: true } };

function startOfToday() {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  return d;
}

export async function getStats() {
  const todayStart = startOfToday();

  const [
    totalUsers,
    newUsersToday,
    totalTransactions,
    totalCategories,
    popularRows
  ] = await Promise.all([
    User.countDocuments({ isDeleted: { $ne: true } }),
    User.countDocuments({
      isDeleted: { $ne: true },
      createdAt: { $gte: todayStart }
    }),
    Transactions.countDocuments(activeTransactionMatch),
    Category.countDocuments(),
    Transactions.aggregate([
      {
        $match: {
          ...activeTransactionMatch,
          type: "expense",
          category: { $exists: true, $ne: null }
        }
      },
      { $group: { _id: "$category", totalAmount: { $sum: "$price" }, count: { $sum: 1 } } },
      { $sort: { totalAmount: -1 } },
      { $limit: 1 },
      {
        $lookup: {
          from: "categories",
          localField: "_id",
          foreignField: "_id",
          as: "cat"
        }
      },
      { $unwind: { path: "$cat", preserveNullAndEmptyArrays: true } },
      {
        $project: {
          categoryId: "$_id",
          name: "$cat.name",
          totalAmount: 1,
          transactionCount: "$count"
        }
      }
    ])
  ]);

  const { entries, stats: cacheStats } = getOffersCacheAdminSnapshot();
  const totalCachedProducts = entries.reduce((s, e) => s + e.productCount, 0);

  const mostPopularCategory = popularRows[0]
    ? {
        categoryId: popularRows[0].categoryId,
        name: popularRows[0].name || "Unknown",
        totalAmount: popularRows[0].totalAmount ?? 0,
        transactionCount: popularRows[0].transactionCount ?? 0
      }
    : null;

  return {
    totalUsers,
    newUsersToday,
    totalTransactions,
    totalCategories,
    mostPopularCategory,
    offers: {
      cachedLists: entries.length,
      totalCachedProducts,
      cacheHits: cacheStats.hits,
      cacheMisses: cacheStats.misses,
      cacheKeys: cacheStats.keys
    }
  };
}

export async function getAllUsers(page = 1, limit = 10) {
  const p = Math.max(1, Number(page) || 1);
  const l = Math.min(100, Math.max(1, Number(limit) || 10));
  const skip = (p - 1) * l;

  const filter = {};
  const [users, totalCount] = await Promise.all([
    User.find(filter)
      .select("-password -OTP")
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(l)
      .lean(),
    User.countDocuments(filter)
  ]);

  return {
    data: users,
    meta: {
      page: p,
      limit: l,
      skip,
      totalCount,
      totalPages: Math.ceil(totalCount / l) || 0
    }
  };
}

export async function getUserById(id) {
  if (!Types.ObjectId.isValid(id)) {
    throw new AppError("Invalid user id", 400);
  }

  const user = await User.findById(id).select("-password -OTP").lean();
  if (!user) {
    throw new AppError("User not found", 404);
  }

  const spendingRows = await Transactions.aggregate([
    { $match: { user: new Types.ObjectId(id), ...activeTransactionMatch } },
    {
      $group: {
        _id: "$type",
        totalAmount: { $sum: "$price" },
        count: { $sum: 1 }
      }
    }
  ]);

  let expenseTotal = 0;
  let incomeTotal = 0;
  let expenseCount = 0;
  let incomeCount = 0;

  for (const row of spendingRows) {
    if (row._id === "expense") {
      expenseTotal = row.totalAmount ?? 0;
      expenseCount = row.count ?? 0;
    } else if (row._id === "income") {
      incomeTotal = row.totalAmount ?? 0;
      incomeCount = row.count ?? 0;
    }
  }

  const spendingSummary = {
    expenseTotal,
    incomeTotal,
    expenseCount,
    incomeCount,
    transactionCount: expenseCount + incomeCount
  };

  return { user, spendingSummary };
}

export async function toggleBlockUser(id) {
  if (!Types.ObjectId.isValid(id)) {
    throw new AppError("Invalid user id", 400);
  }

  const user = await User.findById(id).select("-password -OTP");
  if (!user) {
    throw new AppError("User not found", 404);
  }

  user.isBlocked = !user.isBlocked;
  await user.save();

  return {
    message: user.isBlocked ? "User blocked" : "User unblocked",
    user: {
      _id: user._id,
      email: user.email,
      isBlocked: user.isBlocked,
      role: user.role
    }
  };
}

export async function deleteUser(id, { hard = false } = {}) {
  if (!Types.ObjectId.isValid(id)) {
    throw new AppError("Invalid user id", 400);
  }

  const user = await User.findById(id);
  if (!user) {
    throw new AppError("User not found", 404);
  }

  if (hard) {
    await User.findByIdAndDelete(id);
    return { message: "User permanently deleted", hard: true };
  }

  if (user.isDeleted) {
    return { message: "User was already deactivated", soft: true };
  }

  user.isDeleted = true;
  await user.save();
  return { message: "User deactivated (soft delete)", soft: true };
}

export async function getAllCategories() {
  const categories = await Category.find()
    .populate("user", "email firstName lastName fullname role")
    .sort({ createdAt: -1 })
    .lean();
  return categories;
}

export async function getAllItems() {
  const items = await Item.find()
    .populate("user", "email firstName lastName fullname role")
    .sort({ createdAt: -1 })
    .lean();
  return items;
}

export async function getAllTransactions(filters = {}) {
  const { userId, category, startDate, endDate, page = 1, limit = 20 } = filters;

  const query = { ...activeTransactionMatch };

  if (userId) {
    if (!Types.ObjectId.isValid(userId)) {
      throw new AppError("Invalid userId filter", 400);
    }
    query.user = new Types.ObjectId(userId);
  }
  if (category) {
    if (!Types.ObjectId.isValid(category)) {
      throw new AppError("Invalid category filter", 400);
    }
    query.category = new Types.ObjectId(category);
  }
  if (startDate || endDate) {
    query.createdAt = {};
    if (startDate) query.createdAt.$gte = new Date(startDate);
    if (endDate) query.createdAt.$lte = new Date(endDate);
  }

  const p = Math.max(1, Number(page) || 1);
  const l = Math.min(100, Math.max(1, Number(limit) || 20));
  const skip = (p - 1) * l;

  const [data, totalCount] = await Promise.all([
    Transactions.find(query)
      .populate("user", "email firstName lastName fullname")
      .populate("category")
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(l)
      .lean(),
    Transactions.countDocuments(query)
  ]);

  return {
    data,
    meta: {
      page: p,
      limit: l,
      skip,
      totalCount,
      totalPages: Math.ceil(totalCount / l) || 0,
      filters: { userId: userId || null, category: category || null, startDate: startDate || null, endDate: endDate || null }
    }
  };
}

export function getOffersAdmin() {
  return getOffersCacheAdminSnapshot();
}

export async function updateUser(id, body) {
  if (!Types.ObjectId.isValid(id)) {
    throw new AppError("Invalid user id", 400);
  }

  const { firstName, lastName, email, role } = body;
  const user = await User.findById(id);
  if (!user) {
    throw new AppError("User not found", 404);
  }

  if (email !== undefined && email !== user.email) {
    const normalized = String(email).trim().toLowerCase();
    const taken = await User.findOne({ email: normalized, _id: { $ne: id } });
    if (taken) {
      throw new AppError("Email already in use", 400);
    }
    user.email = normalized;
  }

  if (role !== undefined) {
    if (!["customer", "admin"].includes(role)) {
      throw new AppError("Invalid role", 400);
    }
    user.role = role;
  }

  if (firstName !== undefined) {
    user.firstName = String(firstName).trim();
  }
  if (lastName !== undefined) {
    user.lastName = String(lastName).trim();
  }

  await user.save();
  return User.findById(id).select("-password -OTP").lean();
}

export async function deleteCategory(id) {
  if (!Types.ObjectId.isValid(id)) {
    throw new AppError("Invalid category id", 400);
  }

  const category = await Category.findOneAndDelete({ _id: id });
  if (!category) {
    throw new AppError("Category not found", 404);
  }

  await Transactions.updateMany({ category: id }, { $unset: { category: 1 } });

  return category;
}

export async function updateCategoryName(id, body) {
  if (!Types.ObjectId.isValid(id)) {
    throw new AppError("Invalid category id", 400);
  }

  const { name } = body;
  if (name === undefined || String(name).trim() === "") {
    throw new AppError("Name is required", 400);
  }

  const category = await Category.findById(id);
  if (!category) {
    throw new AppError("Category not found", 404);
  }

  const trimmed = String(name).trim();
  const existing = await Category.findOne({
    user: category.user,
    name: trimmed,
    _id: { $ne: id }
  });
  if (existing) {
    throw new AppError("Category with this name already exists for this user", 400);
  }

  category.name = trimmed;
  await category.save();
  return category;
}

export async function deleteItem(id) {
  if (!Types.ObjectId.isValid(id)) {
    throw new AppError("Invalid item id", 400);
  }

  const item = await Item.findOneAndDelete({ _id: id });
  if (!item) {
    throw new AppError("Item not found", 404);
  }

  await Category.updateMany({ items: id }, { $pull: { items: id } });

  return item;
}

export async function updateItemName(id, body) {
  if (!Types.ObjectId.isValid(id)) {
    throw new AppError("Invalid item id", 400);
  }

  const { name } = body;
  if (name === undefined || String(name).trim() === "") {
    throw new AppError("Name is required", 400);
  }

  const item = await Item.findById(id);
  if (!item) {
    throw new AppError("Item not found", 404);
  }

  item.name = String(name).trim();
  await item.save();
  return item;
}

export async function getItemAmazonPriceSuggestions(itemId) {
  if (!Types.ObjectId.isValid(itemId)) {
    throw new AppError("Invalid item id", 400);
  }

  const item = await Item.findById(itemId).lean();
  if (!item) {
    throw new AppError("Item not found", 404);
  }

  const products = await getAmazonProductSearchSuggestions(item.name, 3);
  const suggestions = products.map(({ title, price, image, url }) => ({
    title,
    price,
    image,
    url
  }));

  return {
    itemId: String(item._id),
    query: item.name,
    suggestions
  };
}
