/**
 * Personalized deals — Amazon.eg + Noon (direct fetch, no RapidAPI).
 */
import NodeCache from "node-cache";
import { Types } from "mongoose";
import { Transactions } from "../../DB/models/transactions.model.js";
import { searchAllMarketplaces, searchAmazonEg } from "./providers/index.js";

const WARM_CATEGORIES = ["Shopping", "Food & Drink", "Electronics"];

const offersCache = new NodeCache({ stdTTL: 3600, checkperiod: 600 }); // 1 hour

const activeMatch = { isDeleted: { $ne: true } };

const CATEGORY_EN_QUERY = {
  electronics: "electronics headphones laptop",
  fashion: "clothing fashion shoes",
  food: "grocery food milk",
  books: "books stationery",
  sports: "sports fitness",
  beauty: "beauty skincare",
  shopping: "home essentials",
  grocery: "supermarket grocery",
  "food & grocery": "grocery food",
  "food & drink": "grocery drinks",
  health: "health vitamins",
  education: "books stationery",
  transport: "car accessories",
  entertainment: "games toys",
  bills: "home essentials",
  other: "best sellers",
  طعام: "grocery food milk",
  تسوق: "shopping deals",
  صحة: "health wellness",
  تعليم: "books stationery",
  مواصلات: "car accessories",
  أخرى: "best sellers",
};

const CATEGORY_NAME_EN = {
  electronics: "Electronics",
  fashion: "Fashion",
  food: "Food & Grocery",
  books: "Books",
  sports: "Sports",
  beauty: "Beauty",
  طعام: "Food & Grocery",
  "food & drink": "Food & Drink",
  health: "Health",
  education: "Education",
  bills: "Bills",
  shopping: "Shopping",
  transport: "Transport",
  entertainment: "Entertainment",
  other: "Other",
  أخرى: "Other",
  صحة: "Health",
  تعليم: "Education",
  تسوق: "Shopping",
  مواصلات: "Transport",
};

function normalizeCategoryName(categoryName) {
  if (!categoryName) return "Deals";
  const key = categoryName.trim().toLowerCase();
  if (CATEGORY_NAME_EN[key]) return CATEGORY_NAME_EN[key];
  for (const [k, v] of Object.entries(CATEGORY_NAME_EN)) {
    if (key.includes(k)) return v;
  }
  return categoryName.trim();
}

function searchQueryForCategory(categoryName) {
  if (!categoryName) return "best sellers deals";
  const key = categoryName.trim().toLowerCase();
  if (CATEGORY_EN_QUERY[key]) return CATEGORY_EN_QUERY[key];
  for (const [name, query] of Object.entries(CATEGORY_EN_QUERY)) {
    if (key.includes(name)) return query;
  }
  return `${categoryName} deals`;
}

function dedupeProducts(products) {
  const seen = new Set();
  return products.filter((p) => {
    const key = `${p.marketplace}:${String(p.title || "").trim().toLowerCase()}`;
    if (!p.title || seen.has(key)) return false;
    seen.add(key);
    return p.image && String(p.image).trim().length > 0;
  });
}

function enrichProducts(products, categoryName) {
  const categoryEn = normalizeCategoryName(categoryName);
  return products.map((p) => ({
    ...p,
    category: categoryName,
    categoryEn,
    displayTitle: p.displayTitle || p.title,
  }));
}

function userExpenseMatch(userId) {
  return {
    user: userId,
    ...activeMatch,
    category: { $exists: true, $ne: null },
  };
}

export async function getTopSpendingCategoryName(userId) {
  const pipeline = [
    { $match: userExpenseMatch(userId) },
    { $group: { _id: "$category", total: { $sum: "$price" } } },
    { $sort: { total: -1 } },
    { $limit: 1 },
    {
      $lookup: {
        from: "categories",
        localField: "_id",
        foreignField: "_id",
        as: "cat",
      },
    },
    { $unwind: { path: "$cat", preserveNullAndEmptyArrays: true } },
    { $project: { name: { $ifNull: ["$cat.name", null] } } },
  ];

  const rows = await Transactions.aggregate(pipeline);
  const name = rows[0]?.name;
  return typeof name === "string" && name.trim() ? name.trim() : null;
}

/**
 * Fetch Amazon + Noon products for a spending category.
 */
export async function getOffersForCategory(categoryName, maxProducts = 12) {
  const cacheKey = `marketplace-v2:${categoryName || "default"}`;
  const hit = offersCache.get(cacheKey);
  if (hit) {
    return { products: hit.slice(0, maxProducts), fromCache: true };
  }

  const query = searchQueryForCategory(categoryName);
  const perStore = Math.max(2, Math.ceil(maxProducts / 3));
  const raw = await searchAllMarketplaces(query, perStore, categoryName);
  const products = dedupeProducts(enrichProducts(raw, categoryName)).slice(0, maxProducts);

  if (products.length) {
    offersCache.set(cacheKey, products);
  }

  return { products, fromCache: false };
}

/** Admin / item price hints — Amazon + Noon */
export async function getAmazonProductSearchSuggestions(searchQuery, limit = 3) {
  const q = String(searchQuery || "").trim();
  if (!q) {
    const err = new Error("Search query is required");
    err.statusCode = 400;
    throw err;
  }

  const perStore = Math.max(1, Math.ceil(limit / 2));
  const products = await searchAllMarketplaces(q, perStore);
  return products.slice(0, limit);
}

export async function getPersonalizedOffers(userIdHex) {
  const userCacheKey = `user-v3:${userIdHex}`;
  const userHit = offersCache.get(userCacheKey);
  if (userHit) {
    return { ...userHit, cached: true };
  }

  const userId = new Types.ObjectId(userIdHex);
  const categories = await getUserCategoriesBySpending(userId, 2);

  const toFetch = categories.length
    ? categories
    : [{ category: "Shopping", total: 0 }];

  const perCategory = await Promise.all(
    toFetch.map(async (cat) => {
      const fetched = await getOffersForCategory(cat.category, 8);
      return {
        category: cat.category,
        categoryEn: normalizeCategoryName(cat.category),
        total: cat.total,
        fromCache: fetched.fromCache,
        products: fetched.products,
      };
    }),
  );

  const products = perCategory.flatMap((e) => e.products);
  const result = buildOffersResponse(
    perCategory,
    products,
    !categories.length,
  );

  if (products.length) {
    offersCache.set(userCacheKey, result);
  }

  return result;
}

function buildOffersResponse(perCategory, products, defaultedCategory) {
  return {
    source: "amazon+noon+jumia",
    categories: perCategory.map(({ category, categoryEn, total }) => ({
      category,
      categoryEn,
      total,
    })),
    defaultedCategory,
    cached: perCategory.every((e) => e.fromCache),
    products,
    byCategory: perCategory.map(
      ({ category, categoryEn, total, fromCache, products: scopedProducts }) => ({
        category,
        categoryEn,
        total,
        cached: fromCache,
        products: scopedProducts,
      }),
    ),
  };
}

export async function getOffersPreview(userIdHex) {
  const previewKey = `preview-v3:${userIdHex}`;
  const previewHit = offersCache.get(previewKey);
  if (previewHit) {
    return { ...previewHit, cached: true };
  }

  const userId = new Types.ObjectId(userIdHex);
  const categories = await getUserCategoriesBySpending(userId, 1);
  const primary = categories[0] || { category: "Shopping", total: 0 };

  const { products, fromCache } = await getOffersForCategory(primary.category, 8);

  const result = {
    source: "amazon+noon+jumia",
    products: products.slice(0, 8),
    categories: [{ category: primary.category, total: primary.total ?? 0 }],
    defaultedCategory: !categories.length,
    cached: fromCache,
  };

  if (result.products.length) {
    offersCache.set(previewKey, result);
  }

  return result;
}

async function getUserCategoriesBySpending(userId, limit = null) {
  const pipeline = [
    { $match: userExpenseMatch(userId) },
    { $group: { _id: "$category", total: { $sum: "$price" } } },
    { $sort: { total: -1 } },
    {
      $lookup: {
        from: "categories",
        localField: "_id",
        foreignField: "_id",
        as: "cat",
      },
    },
    { $unwind: { path: "$cat", preserveNullAndEmptyArrays: true } },
    {
      $project: {
        _id: 0,
        total: 1,
        category: { $ifNull: ["$cat.name", null] },
      },
    },
  ];

  if (Number.isInteger(limit) && limit > 0) {
    pipeline.push({ $limit: limit });
  }

  const rows = await Transactions.aggregate(pipeline);
  return rows
    .filter((row) => typeof row.category === "string" && row.category.trim())
    .map((row) => ({
      category: row.category.trim(),
      total: row.total ?? 0,
    }));
}

export function isValidUserId(userId) {
  return typeof userId === "string" && Types.ObjectId.isValid(userId);
}

export function getOffersCacheAdminSnapshot() {
  const keys = offersCache.keys();
  const entries = keys.map((cacheKey) => {
    const products = offersCache.get(cacheKey) || [];
    return {
      cacheKey,
      productCount: Array.isArray(products) ? products.length : 0,
      products: Array.isArray(products) ? products : [],
    };
  });
  return { entries, stats: offersCache.getStats() };
}

// Legacy export for admin — Amazon-only quick search
export { searchAmazonEg };

/** Pre-warm category caches in background after server start. */
export function warmOffersCache() {
  setImmediate(async () => {
    console.log("[OFFERS] Warming cache…");
    await Promise.allSettled(
      WARM_CATEGORIES.map(async (category) => {
        try {
          await getOffersForCategory(category, 10);
          console.log(`[OFFERS] Cache ready: ${category}`);
        } catch (err) {
          console.warn(`[OFFERS] Warm skipped ${category}:`, err.message);
        }
      }),
    );
  });
}
