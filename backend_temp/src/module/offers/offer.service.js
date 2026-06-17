/**
 * Amazon product offers via RapidAPI Real-Time Amazon Data.
 * Top spending category from transactions → Amazon browse node → cached HTTP fetch.
 */
import axios from "axios";
import NodeCache from "node-cache";
import { Types } from "mongoose";
import { Transactions } from "../../DB/models/transactions.model.js";

const RAPIDAPI_HOST = "real-time-amazon-data.p.rapidapi.com";
const RAPIDAPI_BASE = `https://${RAPIDAPI_HOST}`;

/** Category name (case-insensitive) → Amazon browse node id */
const CATEGORY_TO_AMAZON_ID = {
  electronics: "172282",
  fashion: "7141123011",
  food: "16310101",
  books: "283155",
  sports: "3375251",
  beauty: "11059031"
};

const AMAZON_CATEGORIES = Object.entries(CATEGORY_TO_AMAZON_ID).map(([name, id]) => ({
  name,
  id
}));

const offersCache = new NodeCache({ stdTTL: 86400, checkperiod: 3600 }); // 24 hours cache

const activeMatch = { isDeleted: { $ne: true } };

/** English search terms per category — amazon.eg browse often returns Arabic titles */
const CATEGORY_EN_QUERY = {
  electronics: "electronics gadgets english",
  fashion: "fashion clothing english",
  food: "grocery food milk english",
  books: "books reading english",
  sports: "sports fitness english",
  beauty: "beauty skincare english"
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

/** Longest phrases first — Arabic → English product title hints */
const AR_EN_PHRASES = [
  ["حليب كامل الدسم من المراعي", "Almarai Full Cream Milk 1L"],
  ["حليب كامل الدسم من جهينة", "Juhayna Full Cream Milk 1L"],
  ["حليب كرتون كامل الدسم من جهينة", "Juhayna Full Cream UHT Milk 6-Pack"],
  ["حليب المراعي كامل الدسم", "Almarai Full Cream Milk 1L"],
  ["أداة خفق اللبن قابلة لإعادة الشحن", "Rechargeable Milk Frother 3-Speed"],
  ["مجموعة أعواد قطنية من البامبو", "Eco Bamboo Cotton Swabs 100-Pack"],
  ["مناديل وجه برستيج من فاين", "Fine Prestige Facial Tissues 500"],
  ["مناديل وجه", "Facial Tissues"],
  ["حليب كامل الدسم", "Full Cream Milk"],
  ["حليب المراعي", "Almarai Milk"],
  ["حليب جهينة", "Juhayna Milk"],
  ["حليب", "Milk"],
  ["مناديل", "Tissues"],
  ["قطنية", "Cotton"],
  ["بامبو", "Bamboo"],
  ["قهوة", "Coffee"],
  ["سماعات", "Headphones"],
  ["ساعة", "Smart Watch"],
  ["شاحن", "Charger"],
  ["حقيبة", "Backpack"],
];

function normalizeCategoryName(categoryName) {
  if (!categoryName) return "Deals";
  const key = categoryName.trim().toLowerCase();
  if (CATEGORY_NAME_EN[key]) return CATEGORY_NAME_EN[key];
  if (isEnglishDominant(categoryName)) {
    return categoryName.trim().replace(/\b\w/g, (c) => c.toUpperCase());
  }
  for (const [k, v] of Object.entries(CATEGORY_NAME_EN)) {
    if (key.includes(k)) return v;
  }
  return "Deals";
}

function toEnglishTitle(title, categoryName = null) {
  const raw = String(title || "").trim();
  if (!raw) return "Amazon Deal";
  if (isEnglishDominant(raw)) {
    return raw.replace(/\s+/g, " ").slice(0, 90);
  }

  let result = raw;
  for (const [ar, en] of AR_EN_PHRASES) {
    if (result.includes(ar)) result = result.replaceAll(ar, en);
  }
  result = result
    .replace(/[\u0600-\u06FF]+/g, " ")
    .replace(/[^\w\s\-&',.()]/g, " ")
    .replace(/\s+/g, " ")
    .trim();

  if (isEnglishDominant(result) && result.length > 8) {
    return result.slice(0, 90);
  }

  const cat = normalizeCategoryName(categoryName);
  const priceHint = raw.match(/\d+\s*(لتر|عبوات|قطعة|pack|L)/i);
  if (priceHint) return `${cat} — ${priceHint[0]}`.slice(0, 90);
  return `${cat} Deal on Amazon`.slice(0, 90);
}

function isEnglishDominant(text) {
  const t = String(text || "").trim();
  if (!t) return false;
  const en = (t.match(/[a-zA-Z]/g) || []).length;
  const ar = (t.match(/[\u0600-\u06FF]/g) || []).length;
  return en > ar;
}

function normalizePriceEg(raw) {
  if (raw == null) return null;
  const s = String(raw).trim();
  if (!s || s === "null") return null;
  const num = parseFloat(s.replace(/[^0-9.,]/g, "").replace(/,/g, ""));
  if (!Number.isNaN(num) && num > 0) return `EGP ${num.toFixed(2)}`;
  const cleaned = s
    .replace(/جنيه/g, "EGP")
    .replace(/ج\.م/g, "EGP")
    .replace(/\$/g, "EGP ");
  return cleaned.includes("EGP") ? cleaned : `EGP ${cleaned}`;
}

function normalizeDiscount(raw, price, originalPrice) {
  if (raw != null && String(raw).trim()) {
    const d = String(raw).trim();
    if (d.startsWith("-") || d.toUpperCase().includes("SAVE") || d.includes("%")) return d;
  }
  const priceNum = parseFloat(String(price || "").replace(/[^0-9.]/g, ""));
  const originalNum = parseFloat(String(originalPrice || "").replace(/[^0-9.]/g, ""));
  if (originalNum > priceNum && priceNum > 0) {
    return `-${Math.round(((originalNum - priceNum) / originalNum) * 100)}%`;
  }
  return "";
}

function englishQueryForCategory(categoryName, amazonCategoryId) {
  if (categoryName) {
    const key = categoryName.trim().toLowerCase();
    if (CATEGORY_EN_QUERY[key]) return CATEGORY_EN_QUERY[key];
  }
  const entry = Object.entries(CATEGORY_TO_AMAZON_ID).find(([, id]) => id === amazonCategoryId);
  return entry ? CATEGORY_EN_QUERY[entry[0]] : "today deals";
}

function dedupeByTitle(products) {
  const seen = new Set();
  return products.filter((p) => {
    const key = String(p.title || "").trim().toLowerCase();
    if (!key || seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

function sortEnglishFirst(products) {
  return [...products].sort((a, b) => {
    const aEn = isEnglishDominant(a.title) ? 1 : 0;
    const bEn = isEnglishDominant(b.title) ? 1 : 0;
    return bEn - aEn;
  });
}

function userExpenseMatch(userId) {
  return {
    user: userId,
    ...activeMatch,
    // Don't filter by type — not all transactions have it set
    category: { $exists: true, $ne: null }
  };
}

/**
 * Find the user's top spending category name (expenses only) via aggregation.
 * @param {import("mongoose").Types.ObjectId} userId
 * @returns {Promise<string|null>} Category name or null if no data
 */
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
        as: "cat"
      }
    },
    { $unwind: { path: "$cat", preserveNullAndEmptyArrays: true } },
    {
      $project: {
        name: { $ifNull: ["$cat.name", null] }
      }
    }
  ];

  const rows = await Transactions.aggregate(pipeline);
  const name = rows[0]?.name;
  return typeof name === "string" && name.trim() ? name.trim() : null;
}

/**
 * Pick random category (used when user has no expenses yet).
 */
export function pickRandomAmazonCategory() {
  const randomIndex = Math.floor(Math.random() * AMAZON_CATEGORIES.length);
  return AMAZON_CATEGORIES[randomIndex];
}

/**
 * Map app category name to Amazon id; unknown category → random known category id.
 * @param {string|null} categoryName
 */
export function resolveAmazonCategoryId(categoryName) {
  if (!categoryName) return pickRandomAmazonCategory().id;
  const key = categoryName.trim().toLowerCase();
  return CATEGORY_TO_AMAZON_ID[key] ?? pickRandomAmazonCategory().id;
}

export function resolveDisplayCategoryName(categoryName, amazonId) {
  if (categoryName) return categoryName;
  const entry = Object.entries(CATEGORY_TO_AMAZON_ID).find(([, id]) => id === amazonId);
  if (entry) return entry[0].replace(/^./, (c) => c.toUpperCase());
  return pickRandomAmazonCategory().name.replace(/^./, (c) => c.toUpperCase());
}

function extractProducts(payload) {
  const root = payload?.data ?? payload;
  const nested = root?.data;
  const list =
    root?.products ??
    nested?.products ??
    root?.product_list ??
    root?.items;
  if (Array.isArray(list)) return list;
  return [];
}

function mapProduct(raw, categoryName = null) {
  // Try all known field names from RapidAPI Real-Time Amazon Data
  const title =
    raw.product_title ??
    raw.title ??
    raw.name ??
    '';

  const priceRaw =
    raw.product_price ??
    raw.price ??
    raw.sale_price ??
    null;

  const originalPriceRaw =
    raw.product_original_price ??
    raw.original_price ??
    raw.was_price ??
    raw.list_price ??
    null;

  const price = normalizePriceEg(priceRaw);
  const original_price = normalizePriceEg(originalPriceRaw);

  const imageRaw =
    raw.product_photo ??
    raw.product_main_image_url ??
    raw.image ??
    raw.product_image ??
    raw.thumbnail ??
    raw.main_image ??
    null;

  let image = imageRaw ? String(imageRaw).trim() : null;
  if (image && image.startsWith("http://")) image = image.replace("http://", "https://");
  if (image && image.includes("._AC_UL960_QL65_.")) {
    image = image.replace("._AC_UL960_QL65_.", "._AC_SX300_.");
  }

  const url =
    raw.product_url ??
    raw.url ??
    raw.link ??
    raw.detail_url ??
    null;

  const rating =
    raw.product_star_rating ??
    raw.rating ??
    raw.stars ??
    raw.average_rating ??
    null;

  const reviews =
    raw.product_num_ratings ??
    raw.num_ratings ??
    raw.reviews_count ??
    raw.review_count ??
    null;

  // Calculate discount
  let discount = raw.product_discounted_price ?? raw.savings_percent ?? null;
  discount = normalizeDiscount(discount, price, original_price);

  const displayTitle = toEnglishTitle(title, categoryName);
  const categoryEn = normalizeCategoryName(categoryName);

  return {
    title: String(title).trim(),
    displayTitle,
    price,
    original_price,
    discount,
    image,
    url,
    rating,
    reviews,
    category: categoryName,
    categoryEn,
  };
}

/**
 * @param {string} amazonCategoryId
 * @returns {Promise<{ products: ReturnType<typeof mapProduct>[], fromCache: boolean }>}
 */
export async function getOffersForAmazonCategory(amazonCategoryId, categoryName = null, maxPerCategory = 8) {
  const cacheKey = `amazon-offers-v3:${amazonCategoryId}:${categoryName || "any"}`;
  const hit = offersCache.get(cacheKey);
  if (hit) {
    const limited = hit.slice(0, maxPerCategory).map((p) => ({ ...p, category: categoryName }));
    return { products: limited, fromCache: true };
  }

  const key = process.env.RAPIDAPI_KEY;
  if (!key) {
    const err = new Error("RAPIDAPI_KEY is not configured");
    err.statusCode = 503;
    throw err;
  }

  const enQuery = englishQueryForCategory(categoryName, amazonCategoryId);
  let merged = [];

  // Prefer English titles via keyword search (still EGP / amazon.eg)
  try {
    const searched = await getAmazonProductSearchSuggestions(enQuery, 16);
    merged.push(...searched);
  } catch (e) {
    console.log("[AMAZON] English search fallback skipped:", e.message);
  }

  let response;
  try {
    response = await axios.get(`${RAPIDAPI_BASE}/products-by-category`, {
      params: {
        category_id: amazonCategoryId,
        deals_and_discounts: "TODAYS_DEALS",
        country: "EG",
        page: 1
      },
      headers: {
        "X-RapidAPI-Key": key,
        "X-RapidAPI-Host": RAPIDAPI_HOST
      },
      timeout: 25000,
      validateStatus: () => true
    });
  } catch (e) {
    if (!merged.length) {
      const err = new Error(e.message || "Failed to reach Amazon data API");
      err.statusCode = 502;
      err.cause = e;
      throw err;
    }
  }

  if (response && response.status >= 200 && response.status < 300) {
    const rawList = extractProducts(response.data);
    merged.push(...rawList.slice(0, 10).map((raw) => mapProduct(raw, null)));
  }

  merged = dedupeByTitle(sortEnglishFirst(merged.map((p) => ({
    ...p,
    displayTitle: p.displayTitle || toEnglishTitle(p.title, categoryName),
    categoryEn: normalizeCategoryName(categoryName),
  })))).filter((p) => p.image && String(p.image).trim().length > 0);
  const baseProducts = merged.slice(0, Math.max(maxPerCategory, 12));

  offersCache.set(cacheKey, baseProducts);
  const products = baseProducts.slice(0, maxPerCategory).map((p) => ({ ...p, category: categoryName }));
  return { products, fromCache: false };
}

/**
 * Keyword product search (admin item price suggestions).
 * Uses GET /product-search on Real-Time Amazon Data (RapidAPI).
 * @param {string} searchQuery
 * @param {number} [limit=3]
 * @returns {Promise<ReturnType<typeof mapProduct>[]>}
 */
export async function getAmazonProductSearchSuggestions(searchQuery, limit = 3) {
  const q = typeof searchQuery === "string" ? searchQuery.trim() : "";
  if (!q) {
    const err = new Error("Search query is required");
    err.statusCode = 400;
    throw err;
  }

  const key = process.env.RAPIDAPI_KEY;
  if (!key) {
    const err = new Error("RAPIDAPI_KEY is not configured");
    err.statusCode = 503;
    throw err;
  }

  let response;
  try {
    response = await axios.get(`${RAPIDAPI_BASE}/product-search`, {
      params: {
        query: q,
        country: "EG",
        page: 1
      },
      headers: {
        "X-RapidAPI-Key": key,
        "X-RapidAPI-Host": RAPIDAPI_HOST
      },
      timeout: 25000,
      validateStatus: () => true
    });
  } catch (e) {
    const err = new Error(e.message || "Failed to reach Amazon data API");
    err.statusCode = 502;
    err.cause = e;
    throw err;
  }

  if (response.status < 200 || response.status >= 300) {
    console.log("[AMAZON API ERROR] product-search status:", response.status);
    console.log("[AMAZON API ERROR] product-search data:", JSON.stringify(response.data));
    const msg =
      response.data?.message ||
      response.data?.error ||
      `Amazon data API returned status ${response.status}`;
    const err = new Error(msg);
    err.statusCode = 502;
    throw err;
  }

  const rawList = extractProducts(response.data);
  const max = Math.min(Math.max(Number(limit) || 3, 1), 10);
  return rawList.slice(0, max).map(mapProduct);
}

/**
 * @param {string} userIdHex
 */
export async function getPersonalizedOffers(userIdHex) {
  const userId = new Types.ObjectId(userIdHex);
  const categories = await getUserCategoriesBySpending(userId, 4);

  if (!categories.length) {
    const defaults = AMAZON_CATEGORIES.slice(0, 4);
    const perCategory = await Promise.all(
      defaults.map(async (cat) => {
        const name = cat.name.replace(/^./, (c) => c.toUpperCase());
        const fetched = await getOffersForAmazonCategory(cat.id, name, 8);
        return {
          category: name,
          categoryEn: normalizeCategoryName(name),
          amazonCategoryId: cat.id,
          total: 0,
          fromCache: fetched.fromCache,
          products: fetched.products,
        };
      })
    );
    const products = perCategory.flatMap((entry) => entry.products);
    return {
      categories: perCategory.map(({ category, categoryEn, amazonCategoryId, total }) => ({
        category,
        categoryEn,
        amazonCategoryId,
        total,
      })),
      defaultedCategory: true,
      cached: perCategory.every((e) => e.fromCache),
      products,
      byCategory: perCategory.map(({ category, categoryEn, amazonCategoryId, total, fromCache, products: scopedProducts }) => ({
        category,
        categoryEn,
        amazonCategoryId,
        total,
        cached: fromCache,
        products: scopedProducts,
      })),
    };
  }

  const perCategory = await Promise.all(
    categories.map(async (cat) => {
      const fetched = await getOffersForAmazonCategory(cat.amazonCategoryId, cat.category, 8);
      return {
        ...cat,
        categoryEn: normalizeCategoryName(cat.category),
        fromCache: fetched.fromCache,
        products: fetched.products,
      };
    })
  );

  const products = perCategory.flatMap((entry) => entry.products);
  const cached = perCategory.every((entry) => entry.fromCache);
  return {
    categories: perCategory.map(({ category, categoryEn, amazonCategoryId, total }) => ({
      category,
      categoryEn,
      amazonCategoryId,
      total,
    })),
    defaultedCategory: false,
    cached,
    products,
    byCategory: perCategory.map(({ category, categoryEn, amazonCategoryId, total, fromCache, products: scopedProducts }) => ({
      category,
      categoryEn,
      amazonCategoryId,
      total,
      cached: fromCache,
      products: scopedProducts,
    })),
  };
}

export async function getOffersPreview(userIdHex) {
  const userId = new Types.ObjectId(userIdHex);
  const categories = await getUserCategoriesBySpending(userId, 3);

  if (!categories.length) {
    return { products: [], categories: [], defaultedCategory: true, cached: true };
  }

  const picked = await Promise.all(
    categories.map(async (cat) => {
      const { products, fromCache } = await getOffersForAmazonCategory(cat.amazonCategoryId, cat.category, 5);
      return {
        category: cat.category,
        amazonCategoryId: cat.amazonCategoryId,
        total: cat.total,
        cached: fromCache,
        product: products[0] || null
      };
    })
  );

  const products = picked.filter((x) => x.product).map((x) => x.product).slice(0, 3);
  return {
    products,
    categories: picked.map(({ category, amazonCategoryId, total }) => ({ category, amazonCategoryId, total })),
    defaultedCategory: false,
    cached: picked.every((x) => x.cached)
  };
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
        as: "cat"
      }
    },
    { $unwind: { path: "$cat", preserveNullAndEmptyArrays: true } },
    {
      $project: {
        _id: 0,
        total: 1,
        category: { $ifNull: ["$cat.name", null] }
      }
    }
  ];

  if (Number.isInteger(limit) && limit > 0) {
    pipeline.push({ $limit: limit });
  }

  const rows = await Transactions.aggregate(pipeline);
  return rows.map((row) => {
    const category = typeof row.category === "string" && row.category.trim()
      ? row.category.trim()
      : resolveDisplayCategoryName(null, resolveAmazonCategoryId(null));
    const amazonCategoryId = resolveAmazonCategoryId(category);
    return {
      category,
      amazonCategoryId,
      total: row.total ?? 0
    };
  });
}

export function isValidUserId(userId) {
  return typeof userId === "string" && Types.ObjectId.isValid(userId);
}

/**
 * Admin: snapshot of cached Amazon offer payloads (in-memory NodeCache).
 * @returns {{ entries: Array<{ cacheKey: string, amazonCategoryId: string | null, productCount: number, products: ReturnType<typeof mapProduct>[] }>, stats: ReturnType<NodeCache["getStats"]> }}
 */
export function getOffersCacheAdminSnapshot() {
  const keys = offersCache.keys();
  const entries = keys.map((k) => {
    const products = offersCache.get(k) || [];
    const amazonCategoryId = k.startsWith("amazon-offers:") ? k.slice("amazon-offers:".length) : null;
    return {
      cacheKey: k,
      amazonCategoryId,
      productCount: Array.isArray(products) ? products.length : 0,
      products: Array.isArray(products) ? products : []
    };
  });
  return {
    entries,
    stats: offersCache.getStats()
  };
}
