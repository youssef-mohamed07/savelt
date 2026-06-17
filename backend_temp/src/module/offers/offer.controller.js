import { catchError } from "../../utils/catchError.js";
import { getOffersPreview, getPersonalizedOffers, isValidUserId } from "./offer.service.js";

/**
 * GET /api/offers?userId=...
 * Personalized Amazon deals based on top spending category (or Electronics).
 */
async function getOffers(req, res, next) {
  try {
    const userId = req.query.userId;
    if (userId === undefined || userId === null || String(userId).trim() === "") {
      return res.status(400).json({
        success: false,
        message: "userId query parameter is required"
      });
    }
    if (!isValidUserId(String(userId))) {
      return res.status(400).json({
        success: false,
        message: "userId must be a valid MongoDB ObjectId"
      });
    }

    const result = await getPersonalizedOffers(String(userId));
    return res.status(200).json({
      success: true,
      source: result.source ?? "amazon+noon+jumia",
      categories: result.categories,
      defaultedCategory: result.defaultedCategory,
      cached: result.cached,
      products: result.products,
      byCategory: result.byCategory
    });
  } catch (err) {
    console.error('[OFFERS ERROR]', err);
    const code = Number(err.statusCode) || 500;
    if (code >= 500 || code === 503) {
      return res.status(code).json({
        success: false,
        message: err.message || "Unable to load product offers. Please try again later.",
        code: err.code || undefined,
      });
    }
    return next(err);
  }
}

export const getOffersHandler = catchError(getOffers);

/**
 * GET /api/offers/preview?userId=...
 * Home-screen preview offers: max 3 products from top 3 categories.
 */
async function getOffersPreviewController(req, res, next) {
  try {
    const userId = req.query.userId;
    if (userId === undefined || userId === null || String(userId).trim() === "") {
      return res.status(400).json({
        success: false,
        message: "userId query parameter is required"
      });
    }
    if (!isValidUserId(String(userId))) {
      return res.status(400).json({
        success: false,
        message: "userId must be a valid MongoDB ObjectId"
      });
    }

    const result = await getOffersPreview(String(userId));
    return res.status(200).json({
      success: true,
      cached: result.cached,
      defaultedCategory: result.defaultedCategory,
      categories: result.categories,
      products: result.products
    });
  } catch (err) {
    console.error("[OFFERS PREVIEW ERROR]", err);
    const code = Number(err.statusCode) || 500;
    if (code >= 500) {
      return res.status(code).json({
        success: false,
        message: err.message || "Unable to load preview offers. Please try again later."
      });
    }
    return next(err);
  }
}

export const getOffersPreviewHandler = catchError(getOffersPreviewController);

