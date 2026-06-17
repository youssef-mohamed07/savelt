/**
 * Seed starter notifications for all users who have none.
 * Usage: npm run seed:notifications
 */
import dotenv from "dotenv";
dotenv.config();

import { connectDatabase } from "../src/config/database.js";
import { seedAllUsersNotifications } from "../src/module/notifications/notification.service.js";

async function main() {
  await connectDatabase();
  const result = await seedAllUsersNotifications();
  console.log(
    `[seed-notifications] Done — ${result.seeded}/${result.users} users seeded`
  );
  process.exit(0);
}

main().catch((err) => {
  console.error("[seed-notifications] Failed:", err);
  process.exit(1);
});
