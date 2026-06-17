import { Reminder } from "../../DB/models/reminder.model.js";
import { AppError } from "../../utils/AppError.js";
import { catchError } from "../../utils/catchError.js";

export const getMyReminders = catchError(async (req, res) => {
  const reminders = await Reminder.find({ user: req.user._id })
    .sort({ date: 1 })
    .lean();

  res.status(200).json({
    message: "Reminders retrieved successfully",
    count: reminders.length,
    data: reminders,
  });
});

export const createReminder = catchError(async (req, res, next) => {
  const { title, amount, date, repeat, enabled, iconCode, sound } = req.body;

  if (!title || !date) {
    return next(new AppError("Title and date are required", 400));
  }

  const reminder = await Reminder.create({
    user: req.user._id,
    title,
    amount: amount ?? null,
    date: new Date(date),
    repeat: repeat || "Once",
    enabled: enabled !== false,
    iconCode: iconCode ?? 0xe7f4,
    sound: sound || "defaultSound",
  });

  res.status(201).json({ message: "Reminder created", data: reminder });
});

export const updateReminder = catchError(async (req, res, next) => {
  const { title, amount, date, repeat, enabled, iconCode, sound } = req.body;

  const reminder = await Reminder.findOneAndUpdate(
    { _id: req.params.id, user: req.user._id },
    {
      ...(title != null && { title }),
      ...(amount !== undefined && { amount }),
      ...(date != null && { date: new Date(date) }),
      ...(repeat != null && { repeat }),
      ...(enabled !== undefined && { enabled }),
      ...(iconCode != null && { iconCode }),
      ...(sound != null && { sound }),
    },
    { new: true }
  );

  if (!reminder) {
    return next(new AppError("Reminder not found", 404));
  }

  res.status(200).json({ message: "Reminder updated", data: reminder });
});

export const toggleReminder = catchError(async (req, res, next) => {
  const existing = await Reminder.findOne({
    _id: req.params.id,
    user: req.user._id,
  });

  if (!existing) {
    return next(new AppError("Reminder not found", 404));
  }

  existing.enabled = !existing.enabled;
  await existing.save();

  res.status(200).json({ message: "Reminder toggled", data: existing });
});

export const deleteReminder = catchError(async (req, res, next) => {
  const reminder = await Reminder.findOneAndDelete({
    _id: req.params.id,
    user: req.user._id,
  });

  if (!reminder) {
    return next(new AppError("Reminder not found", 404));
  }

  res.status(200).json({ message: "Reminder deleted" });
});

export const deleteMultipleReminders = catchError(async (req, res) => {
  const ids = req.body?.ids;
  if (!Array.isArray(ids) || ids.length === 0) {
    return res.status(400).json({ message: "ids array is required" });
  }

  const result = await Reminder.deleteMany({
    _id: { $in: ids },
    user: req.user._id,
  });

  res.status(200).json({
    message: "Reminders deleted",
    deletedCount: result.deletedCount,
  });
});
