import { Notification } from "../../DB/models/notification.model.js";

const SEED_NOTIFICATIONS = [
  {
    title: "Welcome to Smart Finance",
    body: "Track expenses, set reminders, and get personalized offers — all in one place.",
    type: "system",
    isRead: false,
    daysAgo: 0,
  },
  {
    title: "Voice & OCR are ready",
    body: "Tap + on the home screen to add expenses by voice or by scanning a receipt.",
    type: "system",
    isRead: false,
    daysAgo: 0,
  },
  {
    title: "Weekly spending summary",
    body: "Open Analysis to see how your spending changed compared to last week.",
    type: "system",
    isRead: true,
    daysAgo: 1,
  },
  {
    title: "New deals matched for you",
    body: "We found Amazon offers based on your recent Shopping activity.",
    type: "offer",
    isRead: false,
    daysAgo: 2,
  },
  {
    title: "Don't miss bill payments",
    body: "Open Reminders to schedule upcoming bills and get alerts before they're due.",
    type: "reminder",
    isRead: true,
    daysAgo: 3,
  },
  {
    title: "Transaction saved",
    body: "Your latest expense was recorded and categorized automatically.",
    type: "transaction",
    isRead: true,
    daysAgo: 4,
  },
];

export async function createUserNotification(
  userId,
  { title, body, type = "system", referenceId = null }
) {
  return Notification.create({
    user: userId,
    title,
    body,
    type,
    referenceId,
  });
}

export async function getUnreadCount(userId) {
  return Notification.countDocuments({ user: userId, isRead: false });
}

/** Insert starter notifications when a user has none yet. */
export async function seedNotificationsIfEmpty(userId) {
  const existing = await Notification.countDocuments({ user: userId });
  if (existing > 0) return false;

  const now = Date.now();
  const docs = SEED_NOTIFICATIONS.map((item, index) => {
    const createdAt = new Date(
      now - (item.daysAgo ?? 0) * 86_400_000 - index * 60_000
    );
    return {
      user: userId,
      title: item.title,
      body: item.body,
      type: item.type,
      isRead: item.isRead,
      referenceId: null,
      createdAt,
      updatedAt: createdAt,
    };
  });

  await Notification.insertMany(docs);
  console.log(
    `[NOTIFICATIONS] Seeded ${docs.length} notifications for user ${userId}`
  );
  return true;
}

/** Force seed for all users (skips users who already have notifications). */
export async function seedAllUsersNotifications() {
  const { User } = await import("../../DB/models/user.model.js");
  const users = await User.find({ isDeleted: { $ne: true } }).select("_id");
  let seeded = 0;

  for (const user of users) {
    if (await seedNotificationsIfEmpty(user._id)) seeded++;
  }

  return { users: users.length, seeded };
}
