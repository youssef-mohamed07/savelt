import axios from "axios";
import { BROWSER_HEADERS, formatPriceEgp } from "./shared.js";

const JUMIA_CATALOG = "https://www.jumia.com.eg/catalog/";
const JUMIA_BASE = "https://www.jumia.com.eg";

/**
 * Jumia Egypt — catalog JSON endpoint (Accept: application/json).
 */
export async function searchJumiaEg(query, limit = 8, categoryName = null) {
  const q = String(query || "").trim();
  if (!q) return [];

  const response = await axios.get(JUMIA_CATALOG, {
    params: { q },
    headers: {
      ...BROWSER_HEADERS,
      Accept: "application/json",
      Referer: JUMIA_BASE,
    },
    timeout: 25000,
    validateStatus: (status) => status >= 200 && status < 500,
  });

  if (response.status === 503) {
    throw new Error("Jumia temporarily unavailable (503)");
  }
  if (response.status !== 200) {
    throw new Error(`Jumia search returned ${response.status}`);
  }

  const products = response.data?.viewData?.products;
  if (!Array.isArray(products) || !products.length) return [];

  const results = [];
  for (const hit of products) {
    if (results.length >= limit) break;
    if (!hit?.name || !hit?.prices?.rawPrice) continue;

    const priceNum = parseFloat(String(hit.prices.rawPrice).replace(/,/g, ""));
    if (!Number.isFinite(priceNum) || priceNum <= 0) continue;

    const path = String(hit.url || "").trim();
    const productUrl = path.startsWith("http")
      ? path
      : `${JUMIA_BASE}${path.startsWith("/") ? path : `/${path}`}`;

    const title = String(hit.displayName || hit.name).trim();
    results.push({
      title,
      displayTitle: hit.brand ? `${hit.brand} — ${title}`.slice(0, 90) : title.slice(0, 90),
      price: formatPriceEgp(priceNum),
      original_price: null,
      discount: "",
      image: hit.image || null,
      url: productUrl,
      rating: hit.rating?.average > 0 ? hit.rating.average : null,
      reviews: hit.rating?.totalRatings ?? null,
      marketplace: "jumia",
      category: categoryName,
    });
  }

  return results;
}
