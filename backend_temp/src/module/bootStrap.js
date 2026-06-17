import { authRouter } from "./auth/auth.routes.js";
import { categoryRouter } from "./categorty/category.routes.js";
import { transactionsRouter } from "./transactions/transactions.routes.js";
import { itemsRouter } from "./items/items.routes.js";
import { analyticsRouter } from "./analytics/analytics.routes.js";
import { exportRouter } from "./export/export.routes.js";
import { offersRouter } from "./offers/offer.routes.js";
import { adminRouter } from "./admin/admin.routes.js";
import { notificationRouter } from "./notifications/notification.routes.js";
import { reminderRouter } from "./reminders/reminder.routes.js";

export const bootstrap = (app) => {
    // Auth routes
    app.use("/auth", authRouter);
    
    // Core routes
    app.use("/category", categoryRouter);
    app.use("/transactions", transactionsRouter);
    app.use("/items", itemsRouter);
    
    // Analytics & Export routes
    app.use("/analytics", analyticsRouter);
    app.use("/export", exportRouter);
    
    // Amazon deals (personalized by top spending category)
    app.use("/api/offers", offersRouter);

    // Admin dashboard
    app.use("/admin", adminRouter);

    // In-app notifications
    app.use("/notifications", notificationRouter);

    // Bill reminders
    app.use("/reminders", reminderRouter);
};
