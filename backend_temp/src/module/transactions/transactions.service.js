import { Category } from '../../DB/models/category.model.js';
import { Item } from '../../DB/models/item.model.js';
import { Transactions } from '../../DB/models/transactions.model.js';
import { AppError } from '../../utils/AppError.js';
import { publicUploadUrl, deleteUploadFile } from '../../middleware/upload.js';
import { broadcastAnalysis } from '../analysis/wsServer.js';
import { getHomeAnalytics } from '../analytics/analytics.service.js';
import { createUserNotification } from '../notifications/notification.service.js';

export function normalizeItems(rawItems) {
  if (!rawItems) return [];
  if (Array.isArray(rawItems)) return rawItems.filter(Boolean);
  if (typeof rawItems === 'string') {
    try {
      const parsed = JSON.parse(rawItems);
      return Array.isArray(parsed) ? parsed.filter(Boolean) : [];
    } catch {
      return rawItems ? [rawItems] : [];
    }
  }
  if (typeof rawItems === 'object') return Object.values(rawItems).filter(Boolean);
  return [];
}

export async function resolveCategoryForUser(userId, { categoryId, items = [] }) {
  let category = null;

  if (categoryId) {
    category = await Category.findOne({ _id: categoryId, user: userId });
  }

  if (!category && items.length > 0) {
    const firstItemId = items[0];
    if (firstItemId) {
      category = await Category.findOne({
        user: userId,
        items: firstItemId,
      });

      if (!category) {
        const item = await Item.findOne({ _id: firstItemId, user: userId });
        if (item?.category) {
          category = await Category.findById(item.category);
        }
      }
    }
  }

  if (!category) {
    category = await Category.findOne({ user: userId });
  }

  return category;
}

export async function createTransactionForUser(userId, payload) {
  const {
    text,
    price,
    quantity = 1,
    items = [],
    transactionDate,
    voice_path,
    OCR_path,
    type = 'expense',
    notes,
    categoryId,
  } = payload;

  if (!text?.trim()) {
    throw new AppError('Text is required', 400);
  }

  const normalizedItems = normalizeItems(items);
  const category = await resolveCategoryForUser(userId, {
    categoryId,
    items: normalizedItems,
  });

  if (!category) {
    throw new AppError('No category found. Please create a category first.', 404);
  }

  const transaction = await Transactions.create({
    text: text.trim(),
    category: category._id,
    price: price ?? 0,
    quantity,
    user: userId,
    items: normalizedItems,
    voice_path: voice_path || undefined,
    OCR_path: OCR_path || undefined,
    type,
    notes,
    transactionDate: transactionDate ? new Date(transactionDate) : new Date(),
  });

  await notifyAndBroadcast(userId, transaction);

  const data = transaction.toObject();
  if (data.voice_path) data.voice_url = publicUploadUrl(data.voice_path);
  if (data.OCR_path) data.receipt_url = publicUploadUrl(data.OCR_path);

  return data;
}

async function notifyAndBroadcast(userId, transaction) {
  try {
    await createUserNotification(userId, {
      title: 'Expense recorded',
      body: `${transaction.text}${transaction.price != null ? ` — ${transaction.price} EGP` : ''}`,
      type: 'transaction',
      referenceId: transaction._id.toString(),
    });
  } catch (err) {
    console.error('[NOTIFICATION] failed to create:', err.message);
  }

  (async () => {
    try {
      const payload = await getHomeAnalytics(userId);
      broadcastAnalysis(payload, userId);
    } catch (err) {
      console.error('[ANALYSIS] error computing home analytics', err.message || err);
    }
  })();
}

export function enrichTransactionMedia(transaction) {
  const doc = transaction?.toObject ? transaction.toObject() : { ...transaction };
  if (doc.voice_path) doc.voice_url = publicUploadUrl(doc.voice_path);
  if (doc.OCR_path) doc.receipt_url = publicUploadUrl(doc.OCR_path);
  return doc;
}

export function cleanupUploadedFiles(...relativePaths) {
  for (const relativePath of relativePaths) {
    deleteUploadFile(relativePath);
  }
}
