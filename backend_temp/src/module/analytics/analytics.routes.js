import { Router } from "express";
import { protectedRoutes } from "../../middleware/auth.js";
import {
    getSummary,
    getByCategory,
    getByDate,
    getTopCategories,
    getTrends
} from "./analytics.controller.js";

export const analyticsRouter = Router();

// All routes require authentication
analyticsRouter.use(protectedRoutes);

// Analytics endpoints
analyticsRouter.get("/summary", getSummary);
analyticsRouter.get("/by-category", getByCategory);
analyticsRouter.get("/by-date", getByDate);
analyticsRouter.get("/top-categories", getTopCategories);
analyticsRouter.get("/trends", getTrends);
