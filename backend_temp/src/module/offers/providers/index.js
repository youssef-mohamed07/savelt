import { searchAmazonEg } from "./amazon.provider.js";
import { searchNoonEg } from "./noon.provider.js";
import { searchJumiaEg } from "./jumia.provider.js";
import { interleaveProducts, withTimeout } from "./shared.js";

const STORE_TIMEOUT_MS = {
  amazon: 7000,
  noon: 8000,
  jumia: 8000,
};

/**
 * Fetch products from Amazon.eg + Noon + Jumia in parallel and merge (round-robin).
 * Uses fast mode (no Puppeteer) and per-store timeouts so the API responds quickly.
 */
export async function searchAllMarketplaces(query, limitPerStore = 4, categoryName = null) {
  const perStore = Math.max(1, Math.min(limitPerStore, 10));

  const [amazonSettled, noonSettled, jumiaSettled] = await Promise.allSettled([
    withTimeout(
      searchAmazonEg(query, perStore, categoryName, { fast: true }),
      STORE_TIMEOUT_MS.amazon,
      "Amazon",
    ),
    withTimeout(searchNoonEg(query, perStore, categoryName), STORE_TIMEOUT_MS.noon, "Noon"),
    withTimeout(searchJumiaEg(query, perStore, categoryName), STORE_TIMEOUT_MS.jumia, "Jumia"),
  ]);

  const amazon = amazonSettled.status === "fulfilled" ? amazonSettled.value : [];
  const noon = noonSettled.status === "fulfilled" ? noonSettled.value : [];
  const jumia = jumiaSettled.status === "fulfilled" ? jumiaSettled.value : [];

  for (const [name, settled] of [
    ["Amazon", amazonSettled],
    ["Noon", noonSettled],
    ["Jumia", jumiaSettled],
  ]) {
    if (settled.status === "rejected") {
      console.warn(`[OFFERS] ${name} fetch failed:`, settled.reason?.message);
    }
  }

  if (!amazon.length && !noon.length && !jumia.length) {
    const reason = amazonSettled.reason || noonSettled.reason || jumiaSettled.reason;
    throw reason instanceof Error
      ? reason
      : new Error("Could not fetch products from Amazon, Noon, or Jumia");
  }

  return interleaveProducts(amazon, noon, jumia);
}

export { searchAmazonEg, searchNoonEg, searchJumiaEg };
