import { Router } from "express";
import { protectedRoutes } from "../../middleware/auth.js";
import { exportToPDF, exportToCSV, exportToJSON } from "./export.controller.js";

export const exportRouter = Router();

// All routes require authentication
exportRouter.use(protectedRoutes);

// Export endpoints
exportRouter.get("/pdf", exportToPDF);
exportRouter.get("/csv", exportToCSV);
exportRouter.get("/json", exportToJSON);
