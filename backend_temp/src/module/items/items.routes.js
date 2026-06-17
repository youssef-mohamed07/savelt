import { Router } from "express";
import { protectedRoutes } from "../../middleware/auth.js";
import {
    createItem,
    getMyItems,
    getItem,
    updateItem,
    deleteItem,
    addItemToCategory,
    removeItemFromCategory
} from "./items.controller.js";

export const itemsRouter = Router();

// CRUD operations
itemsRouter.post("/", protectedRoutes, createItem);
itemsRouter.get("/", protectedRoutes, getMyItems);
itemsRouter.get("/:id", protectedRoutes, getItem);
itemsRouter.put("/:id", protectedRoutes, updateItem);
itemsRouter.delete("/:id", protectedRoutes, deleteItem);

// Category operations
itemsRouter.post("/add-to-category", protectedRoutes, addItemToCategory);
itemsRouter.post("/remove-from-category", protectedRoutes, removeItemFromCategory);
