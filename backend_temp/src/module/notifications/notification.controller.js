import { Notification } from "../../DB/models/notification.model.js";
import { AppError } from "../../utils/AppError.js";
import { catchError } from "../../utils/catchError.js";
import { createUserNotification, getUnreadCount } from "./notification.service.js";

export const getMyNotifications = catchError(async (req, res) => {
  const limit = Math.min(parseInt(req.query.limit, 10) || 50, 100);
  const notifications = await Notification.find({ user: req.user._id })
    .sort({ createdAt: -1 })
    .limit(limit)
    .lean();

  const unread = await getUnreadCount(req.user._id);

  res.status(200).json({
    message: "Notifications retrieved successfully",
    unreadCount: unread,
    count: notifications.length,
    data: notifications,
  });
});

export const getUnreadCountHandler = catchError(async (req, res) => {
  const unread = await getUnreadCount(req.user._id);
  res.status(200).json({ message: "OK", unreadCount: unread });
});

export const markAsRead = catchError(async (req, res, next) => {
  const notification = await Notification.findOneAndUpdate(
    { _id: req.params.id, user: req.user._id },
    { isRead: true },
    { new: true }
  );

  if (!notification) {
    return next(new AppError("Notification not found", 404));
  }

  res.status(200).json({ message: "Marked as read", data: notification });
});

export const markAllAsRead = catchError(async (req, res) => {
  const result = await Notification.updateMany(
    { user: req.user._id, isRead: false },
    { isRead: true }
  );

  res.status(200).json({
    message: "All notifications marked as read",
    modifiedCount: result.modifiedCount,
  });
});

export const deleteNotification = catchError(async (req, res, next) => {
  const notification = await Notification.findOneAndDelete({
    _id: req.params.id,
    user: req.user._id,
  });

  if (!notification) {
    return next(new AppError("Notification not found", 404));
  }

  res.status(200).json({ message: "Notification deleted" });
});

export const clearAllNotifications = catchError(async (req, res) => {
  const result = await Notification.deleteMany({ user: req.user._id });

  res.status(200).json({
    message: "All notifications cleared",
    deletedCount: result.deletedCount,
  });
});

export const createNotification = catchError(async (req, res) => {
  const { title, body, type, referenceId } = req.body;

  if (!title || !body) {
    return res.status(400).json({ message: "Title and body are required" });
  }

  const notification = await createUserNotification(req.user._id, {
    title,
    body,
    type: type || "system",
    referenceId: referenceId || null,
  });

  res.status(201).json({ message: "Notification created", data: notification });
});
