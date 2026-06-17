import axios from "axios";
import { BROWSER_HEADERS, formatDiscount, formatPriceEgp } from "./shared.js";

const NOON_SEARCH = "https://www.noon.com/_svc/catalog/api/v3/u/search/";

function noonProductUrl(hit) {
  const raw = String(hit.url || hit.share_url || "").trim();
  if (raw.startsWith("http")) return raw;

  let slug = raw.replace(/^\/+/, "").replace(/^egypt-en\//, "");
  if (!slug) return "https://www.noon.com/egypt-en/";
  slug = slug.replace(/\/p\/?$/, "");
  return `https://www.noon.com/egypt-en/${slug}/p/`;
}

/**
 * Noon Egypt — public catalog search API used by the website (no API key).
 */
export async function searchNoonEg(query, limit = 8, categoryName = null) {
  const q = String(query || "").trim();
  if (!q) return [];

  const response = await axios.get(NOON_SEARCH, {
    params: { q, limit: Math.min(limit, 20) },
    headers: {
      ...BROWSER_HEADERS,
      Accept: "application/json",
      "x-locale": "en-eg",
      "x-mp": "noon",
    },
    timeout: 25000,
    validateStatus: (status) => status >= 200 && status < 500,
  });

  if (response.status !== 200) {
    throw new Error(`Noon search returned ${response.status}`);
  }

  const hits = Array.isArray(response.data?.hits) ? response.data.hits : [];
  const products = [];

  for (const hit of hits) {
    if (products.length >= limit) break;
    if (!hit?.name || !hit?.price) continue;

    const salePrice = hit.sale_price != null ? Number(hit.sale_price) : null;
    const listPrice = Number(hit.price);
    const current = salePrice && salePrice > 0 ? salePrice : listPrice;
    if (!Number.isFinite(current) || current <= 0) continue;

    const price = formatPriceEgp(current);
    const original =
      salePrice && listPrice > salePrice ? formatPriceEgp(listPrice) : null;

    products.push({
      title: hit.name,
      displayTitle: hit.brand ? `${hit.brand} ${hit.name}`.trim() : hit.name,
      price,
      original_price: original,
      discount: formatDiscount(price, original),
      image: hit.image_url || hit.image_urls?.[0] || null,
      url: noonProductUrl(hit),
      rating: hit.product_rating?.value ?? hit.product_rating?.best_rating ?? null,
      reviews: hit.product_rating?.count ?? null,
      marketplace: "noon",
      category: categoryName,
    });
  }

  return products;
}
