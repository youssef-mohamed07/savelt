import { Router } from "express";
import { protectedRoutes } from "../../middleware/auth.js";
import {
  getMyNotifications,
  getUnreadCountHandler,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  clearAllNotifications,
  createNotification,
} from "./notification.controller.js";

export const notificationRouter = Router();

notificationRouter.get("/my", protectedRoutes, getMyNotifications);
notificationRouter.get("/unread-count", protectedRoutes, getUnreadCountHandler);
notificationRouter.post("/", protectedRoutes, createNotification);
notificationRouter.patch("/read-all", protectedRoutes, markAllAsRead);
notificationRouter.patch("/:id/read", protectedRoutes, markAsRead);
notificationRouter.delete("/clear-all", protectedRoutes, clearAllNotifications);
notificationRouter.delete("/:id", protectedRoutes, deleteNotification);
