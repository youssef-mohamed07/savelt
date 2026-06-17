import { Router } from "express";
import { protectedRoutes } from "../../middleware/auth.js";
import { uploadLimiter } from "../../middleware/rateLimiter.js";
import { handleUpload, uploadTransactionMedia } from "../../middleware/upload.js";
import {
  createWithText,
  createWithMedia,
  attachMedia,
  getAllData,
  getTransaction,
  updateTransaction,
  deleteTransaction,
  getMyTransactions,
  getTransactionsByCategory,
  getTransactionsByDateRange,
} from "./transactions.controller.js";

export const transactionsRouter = Router();

// Create transactions
transactionsRouter.post("/createWithText", protectedRoutes, createWithText);
transactionsRouter.post(
  "/createWithMedia",
  protectedRoutes,
  uploadLimiter,
  handleUpload(uploadTransactionMedia),
  createWithMedia,
);
transactionsRouter.post(
  "/:id/media",
  protectedRoutes,
  uploadLimiter,
  handleUpload(uploadTransactionMedia),
  attachMedia,
);

// Read transactions
transactionsRouter.get("/", getAllData);
transactionsRouter.get("/my", protectedRoutes, getMyTransactions);
transactionsRouter.get("/category/:categoryId", protectedRoutes, getTransactionsByCategory);
transactionsRouter.get("/date-range", protectedRoutes, getTransactionsByDateRange);
transactionsRouter.get("/:id", protectedRoutes, getTransaction);

// Update & Delete
transactionsRouter.put("/:id", protectedRoutes, updateTransaction);
transactionsRouter.delete("/:id", protectedRoutes, deleteTransaction);
