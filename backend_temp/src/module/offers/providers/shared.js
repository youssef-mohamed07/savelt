/** Shared product formatting for marketplace providers */

export function formatPriceEgp(amount) {
  const num = Number(amount);
  if (!Number.isFinite(num) || num <= 0) return null;
  return `EGP ${num.toFixed(2)}`;
}

export function formatDiscount(price, originalPrice) {
  const priceNum = parseFloat(String(price || "").replace(/[^0-9.]/g, ""));
  const originalNum = parseFloat(String(originalPrice || "").replace(/[^0-9.]/g, ""));
  if (originalNum > priceNum && priceNum > 0) {
    return `-${Math.round(((originalNum - priceNum) / originalNum) * 100)}%`;
  }
  return "";
}

export const BROWSER_HEADERS = {
  "User-Agent":
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
  "Accept-Language": "en-EG,en;q=0.9,ar;q=0.8",
};

export function interleaveProducts(...lists) {
  const merged = [];
  const maxLen = Math.max(...lists.map((l) => l.length), 0);
  for (let i = 0; i < maxLen; i++) {
    for (const list of lists) {
      if (list[i]) merged.push(list[i]);
    }
  }
  return merged;
}

/** Reject if promise does not settle within ms. */
export function withTimeout(promise, ms, label = "operation") {
  return Promise.race([
    promise,
    new Promise((_, reject) => {
      setTimeout(() => reject(new Error(`${label} timed out after ${ms}ms`)), ms);
    }),
  ]);
}
