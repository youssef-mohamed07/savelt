import { Router } from "express";
import { allowedTo, protectedRoutes } from "../../middleware/auth.js";
import {
  blockUser,
  deleteCategory,
  deleteItem,
  editUser,
  getItemAmazonPrice,
  getStats,
  getUser,
  getUsers,
  listCategories,
  listItems,
  listOffers,
  listTransactions,
  removeUser,
  updateCategory,
  updateItem
} from "./admin.controller.js";

export const adminRouter = Router();

const adminGuard = [protectedRoutes, allowedTo("admin")];

adminRouter.get("/stats", ...adminGuard, getStats);
adminRouter.get("/users", ...adminGuard, getUsers);
adminRouter.get("/users/:id", ...adminGuard, getUser);
adminRouter.put("/users/:id/block", ...adminGuard, blockUser);
adminRouter.put("/users/:id", ...adminGuard, editUser);
adminRouter.delete("/users/:id", ...adminGuard, removeUser);
adminRouter.get("/categories", ...adminGuard, listCategories);
adminRouter.put("/categories/:id", ...adminGuard, updateCategory);
adminRouter.delete("/categories/:id", ...adminGuard, deleteCategory);
adminRouter.get("/items", ...adminGuard, listItems);
adminRouter.get("/items/:id/amazon-price", ...adminGuard, getItemAmazonPrice);
adminRouter.put("/items/:id", ...adminGuard, updateItem);
adminRouter.delete("/items/:id", ...adminGuard, deleteItem);
adminRouter.get("/transactions", ...adminGuard, listTransactions);
adminRouter.get("/offers", ...adminGuard, listOffers);
