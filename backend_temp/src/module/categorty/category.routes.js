import { Router } from "express";
import { protectedRoutes } from "../../middleware/auth.js";
import { 
    createCategory, 
    deleteCategory, 
    getMyCategory,
    getCategory,
    updateCategory,
    addItemsToCategory,
    removeItemsFromCategory,
    getCategoryWithItems
} from "./category.controller.js";

export const categoryRouter = Router();

// CRUD operations
categoryRouter.post('/', protectedRoutes, createCategory);
categoryRouter.get('/', protectedRoutes, getMyCategory);
categoryRouter.get('/:id', protectedRoutes, getCategory);
categoryRouter.get('/:id/items', protectedRoutes, getCategoryWithItems);
categoryRouter.put('/:id', protectedRoutes, updateCategory);
categoryRouter.delete('/:id', protectedRoutes, deleteCategory);

// Item operations
categoryRouter.post('/:id/items', protectedRoutes, addItemsToCategory);
categoryRouter.delete('/:id/items', protectedRoutes, removeItemsFromCategory);
