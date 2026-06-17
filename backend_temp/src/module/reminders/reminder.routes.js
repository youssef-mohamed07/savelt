import { Router } from "express";
import { protectedRoutes } from "../../middleware/auth.js";
import {
  getMyReminders,
  createReminder,
  updateReminder,
  toggleReminder,
  deleteReminder,
  deleteMultipleReminders,
} from "./reminder.controller.js";

export const reminderRouter = Router();

reminderRouter.get("/my", protectedRoutes, getMyReminders);
reminderRouter.post("/", protectedRoutes, createReminder);
reminderRouter.put("/:id", protectedRoutes, updateReminder);
reminderRouter.patch("/:id/toggle", protectedRoutes, toggleReminder);
reminderRouter.delete("/bulk", protectedRoutes, deleteMultipleReminders);
reminderRouter.delete("/:id", protectedRoutes, deleteReminder);
