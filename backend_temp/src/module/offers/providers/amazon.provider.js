import axios from "axios";
import puppeteer from "puppeteer";
import { BROWSER_HEADERS, formatPriceEgp } from "./shared.js";

let browserPromise = null;

function decodeHtml(text) {
  return String(text)
    .replace(/&quot;/g, '"')
    .replace(/&amp;/g, "&")
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">");
}

async function getBrowser() {
  if (!browserPromise) {
    browserPromise = puppeteer.launch({
      headless: "new",
      args: ["--no-sandbox", "--disable-setuid-sandbox"],
    });
  }
  return browserPromise;
}

async function fetchAmazonSearchHtml(query, { fast = false } = {}) {
  const url = `https://www.amazon.eg/s?k=${encodeURIComponent(query)}&language=en_AE`;

  try {
    const response = await axios.get("https://www.amazon.eg/s", {
      params: { k: query, language: "en_AE" },
      headers: {
        ...BROWSER_HEADERS,
        Accept: "text/html,application/xhtml+xml",
        Cookie: "i18n-prefs=EGP; lc-acbeg=en_AE",
      },
      timeout: fast ? 5000 : 12000,
      validateStatus: (status) => status >= 200 && status < 500,
    });

    const html = String(response.data);
    if (html.length > 50_000 && html.includes("s-search-result")) {
      return html;
    }
    if (html.includes("s-search-result") && html.length > 5000) {
      return html;
    }
  } catch {
    // fall through
  }

  if (fast) return "";

  const browser = await getBrowser();
  const page = await browser.newPage();
  try {
    await page.setUserAgent(BROWSER_HEADERS["User-Agent"]);
    await page.goto(url, { waitUntil: "domcontentloaded", timeout: 20000 });
    await page.waitForSelector('[data-component-type="s-search-result"]', {
      timeout: 8000,
    }).catch(() => {});
    return await page.content();
  } finally {
    await page.close();
  }
}

function parseAmazonHtml(html, limit, categoryName) {
  const chunks = html.split('data-component-type="s-search-result"').slice(1);
  const products = [];
  const seen = new Set();

  for (const chunk of chunks) {
    if (products.length >= limit) break;

    const asin = chunk.match(/data-asin="([A-Z0-9]{10})"/)?.[1];
    if (!asin || seen.has(asin)) continue;

    let title =
      chunk.match(/<h2[^>]*aria-label="([^"]+)"/)?.[1] ||
      chunk.match(/<span class="a-size-[^"]* a-color-base a-text-normal">([^<]+)/)?.[1] ||
      chunk.match(/<img[^>]+alt="([^"]+)"[^>]+src="https:\/\/m\.media-amazon/)?.[1];

    if (!title) continue;
    title = decodeHtml(title).replace(/^Sponsored Ad\s*[–-]\s*/i, "").trim();
    if (!title) continue;

    const priceWhole = chunk.match(/a-price-whole">([\d,.]+)/)?.[1];
    if (!priceWhole) continue;

    const priceFrac = chunk.match(/a-price-fraction">(\d+)/)?.[1] || "00";
    const priceNum = parseFloat(`${priceWhole.replace(/,/g, "")}.${priceFrac}`);
    if (!Number.isFinite(priceNum) || priceNum <= 0) continue;

    const image =
      chunk.match(/src="(https:\/\/m\.media-amazon\.com\/images\/I\/[^"]+)"/)?.[1] || null;

    const rating = chunk.match(/a-icon-alt">([\d.]+) out of/)?.[1] ?? null;

    seen.add(asin);
    products.push({
      title,
      displayTitle: title.slice(0, 90),
      price: formatPriceEgp(priceNum),
      original_price: null,
      discount: "",
      image,
      url: `https://www.amazon.eg/dp/${asin}`,
      rating,
      reviews: null,
      marketplace: "amazon",
      category: categoryName,
    });
  }

  return products;
}

/**
 * Amazon.eg — axios first; Puppeteer only when fast=false.
 */
export async function searchAmazonEg(query, limit = 8, categoryName = null, options = {}) {
  const q = String(query || "").trim();
  if (!q) return [];

  const fast = options.fast !== false;
  const html = await fetchAmazonSearchHtml(q, { fast });
  if (!html) return [];
  return parseAmazonHtml(html, limit, categoryName);
}

export async function closeAmazonBrowser() {
  if (browserPromise) {
    const browser = await browserPromise;
    browserPromise = null;
    await browser.close().catch(() => {});
  }
}
