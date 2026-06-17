import { Router } from "express";
import { protectedRoutes } from "../../middleware/auth.js";
import { 
    createWithText, 
    getAllData,
    getTransaction,
    updateTransaction,
    deleteTransaction,
    getMyTransactions,
    getTransactionsByCategory,
    getTransactionsByDateRange
} from "./transactions.controller.js";

export const transactionsRouter = Router();

// Create transactions
transactionsRouter.post('/createWithText', protectedRoutes, createWithText);

// Read transactions
transactionsRouter.get('/', getAllData);
transactionsRouter.get('/my', protectedRoutes, getMyTransactions);
transactionsRouter.get('/category/:categoryId', protectedRoutes, getTransactionsByCategory);
transactionsRouter.get('/date-range', protectedRoutes, getTransactionsByDateRange);
transactionsRouter.get('/:id', protectedRoutes, getTransaction);

// Update & Delete
transactionsRouter.put('/:id', protectedRoutes, updateTransaction);
transactionsRouter.delete('/:id', protectedRoutes, deleteTransaction);
