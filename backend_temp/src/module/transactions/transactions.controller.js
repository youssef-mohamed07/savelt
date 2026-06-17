import { Transactions } from "../../DB/models/transactions.model.js";
import { ApiFeature } from "../../utils/API.Feature.js";
import { AppError } from "../../utils/AppError.js";
import { catchError } from "../../utils/catchError.js";
import {
  toRelativeUploadPath,
  deleteUploadFile,
} from "../../middleware/upload.js";
import {
  createTransactionForUser,
  enrichTransactionMedia,
  normalizeItems,
} from "./transactions.service.js";

// Create a transaction with text (optional voice_path / OCR_path if already uploaded)
export const createWithText = catchError(async (req, res, next) => {
  console.log("Received data:", req.body);

  const { text, price, categoryId, transactionDate, voice_path, OCR_path, type, notes, quantity } =
    req.body;
  const items = normalizeItems(req.body.items);

  try {
    const data = await createTransactionForUser(req.user._id, {
      text,
      price,
      categoryId,
      items,
      transactionDate,
      voice_path,
      OCR_path,
      type,
      notes,
      quantity,
    });

    console.log(
      `[TX] ✅ Saved | id=${data._id} | user=${req.user._id} | voice=${!!data.voice_path} | receipt=${!!data.OCR_path}`,
    );

    res.status(201).json({ message: "Transaction created successfully", data });
  } catch (err) {
    if (err instanceof AppError) return next(err);
    throw err;
  }
});

// Create transaction with voice or receipt file upload (multipart)
export const createWithMedia = catchError(async (req, res, next) => {
  const voiceFile = req.files?.voice?.[0];
  const receiptFile = req.files?.receipt?.[0];

  if (!voiceFile && !receiptFile) {
    return next(new AppError("Upload a voice file or receipt image", 400));
  }
  if (voiceFile && receiptFile) {
    return next(new AppError("Send either voice or receipt, not both", 400));
  }

  const { text, price, categoryId, transactionDate, type, notes, quantity } = req.body;
  const items = normalizeItems(req.body.items);

  if (!text?.trim()) {
    if (voiceFile) deleteUploadFile(toRelativeUploadPath(voiceFile.path));
    if (receiptFile) deleteUploadFile(toRelativeUploadPath(receiptFile.path));
    return next(new AppError("Text is required", 400));
  }

  const voice_path = voiceFile ? toRelativeUploadPath(voiceFile.path) : undefined;
  const OCR_path = receiptFile ? toRelativeUploadPath(receiptFile.path) : undefined;

  try {
    const data = await createTransactionForUser(req.user._id, {
      text,
      price: price != null && price !== '' ? Number(price) : 0,
      categoryId,
      items,
      transactionDate,
      voice_path,
      OCR_path,
      type,
      notes,
      quantity: quantity != null && quantity !== '' ? Number(quantity) : 1,
    });

    console.log(
      `[TX] ✅ Saved with media | id=${data._id} | voice=${!!voice_path} | receipt=${!!OCR_path}`,
    );

    res.status(201).json({
      message: voice_path
        ? "Voice transaction created successfully"
        : "Receipt transaction created successfully",
      data,
    });
  } catch (err) {
    deleteUploadFile(voice_path);
    deleteUploadFile(OCR_path);
    if (err instanceof AppError) return next(err);
    throw err;
  }
});

// Attach media to an existing transaction
export const attachMedia = catchError(async (req, res, next) => {
  const voiceFile = req.files?.voice?.[0];
  const receiptFile = req.files?.receipt?.[0];

  if (!voiceFile && !receiptFile) {
    return next(new AppError("Upload a voice file or receipt image", 400));
  }
  if (voiceFile && receiptFile) {
    return next(new AppError("Send either voice or receipt, not both", 400));
  }

  const transaction = await Transactions.findOne({
    _id: req.params.id,
    user: req.user._id,
    isDeleted: { $ne: true },
  });

  if (!transaction) {
    if (voiceFile) deleteUploadFile(toRelativeUploadPath(voiceFile.path));
    if (receiptFile) deleteUploadFile(toRelativeUploadPath(receiptFile.path));
    return next(new AppError("Transaction not found", 404));
  }

  const newVoicePath = voiceFile ? toRelativeUploadPath(voiceFile.path) : null;
  const newReceiptPath = receiptFile ? toRelativeUploadPath(receiptFile.path) : null;

  if (newVoicePath) {
    deleteUploadFile(transaction.voice_path);
    transaction.voice_path = newVoicePath;
  }
  if (newReceiptPath) {
    deleteUploadFile(transaction.OCR_path);
    transaction.OCR_path = newReceiptPath;
  }

  await transaction.save();

  res.status(200).json({
    message: "Media attached successfully",
    data: enrichTransactionMedia(transaction),
  });
});

// Get all transactions with API features
export const getAllData = catchError(async (req, res, next) => {
  const apiFeature = new ApiFeature(Transactions.find(), req.query);

  apiFeature.filter().search().sort().select().pagination();

  const transactions = await apiFeature.mongooseQuery;
  const totalCount = await Transactions.countDocuments();
  const responseDetails = await apiFeature.getResponseDetails();

  res.status(200).json({
    message: "Data retrieved successfully",
    meta: responseDetails,
    count: totalCount,
    data: transactions.map(enrichTransactionMedia),
  });
});

// Get single transaction
export const getTransaction = catchError(async (req, res, next) => {
  const transaction = await Transactions.findOne({
    _id: req.params.id,
    user: req.user._id,
  }).populate("category");

  if (!transaction) {
    return next(new AppError("Transaction not found", 404));
  }

  res.status(200).json({
    message: "Transaction retrieved successfully",
    data: enrichTransactionMedia(transaction),
  });
});

// Get my transactions
export const getMyTransactions = catchError(async (req, res, next) => {
  console.log("REQ USER:", req.user._id);

  const apiFeature = new ApiFeature(
    Transactions.find({ user: req.user._id }).populate("category"),
    req.query,
  );

  apiFeature.filter().search().sort().select().pagination();

  const transactions = await apiFeature.mongooseQuery;
  const totalCount = await Transactions.countDocuments({ user: req.user._id });

  console.log("FOUND:", transactions.length, "total:", totalCount);

  const responseDetails = await apiFeature.getResponseDetails();

  res.status(200).json({
    message: "Transactions retrieved successfully",
    meta: responseDetails,
    count: totalCount,
    data: transactions.map(enrichTransactionMedia),
  });
});

// Get transactions by category
export const getTransactionsByCategory = catchError(async (req, res, next) => {
  const { categoryId } = req.params;

  const transactions = await Transactions.find({
    user: req.user._id,
    category: categoryId,
  })
    .populate("category")
    .sort("-createdAt");

  res.status(200).json({
    message: "Transactions retrieved successfully",
    count: transactions.length,
    data: transactions.map(enrichTransactionMedia),
  });
});

// Get transactions by date range
export const getTransactionsByDateRange = catchError(async (req, res, next) => {
  const { startDate, endDate } = req.query;

  if (!startDate || !endDate) {
    return next(new AppError("Start date and end date are required", 400));
  }

  const transactions = await Transactions.find({
    user: req.user._id,
    createdAt: {
      $gte: new Date(startDate),
      $lte: new Date(endDate),
    },
  })
    .populate("category")
    .sort("-createdAt");

  const totalAmount = transactions.reduce((sum, t) => sum + (t.price || 0), 0);

  res.status(200).json({
    message: "Transactions retrieved successfully",
    count: transactions.length,
    totalAmount,
    data: transactions.map(enrichTransactionMedia),
  });
});

// Update transaction
export const updateTransaction = catchError(async (req, res, next) => {
  const { text, price, category } = req.body;

  const transaction = await Transactions.findOneAndUpdate(
    { _id: req.params.id, user: req.user._id },
    { text, price, category },
    { new: true },
  ).populate("category");

  if (!transaction) {
    return next(new AppError("Transaction not found", 404));
  }

  res.status(200).json({
    message: "Transaction updated successfully",
    data: enrichTransactionMedia(transaction),
  });
});

// Delete transaction (and associated media files)
export const deleteTransaction = catchError(async (req, res, next) => {
  const transaction = await Transactions.findOneAndDelete({
    _id: req.params.id,
    user: req.user._id,
  });

  if (!transaction) {
    return next(new AppError("Transaction not found", 404));
  }

  deleteUploadFile(transaction.voice_path);
  deleteUploadFile(transaction.OCR_path);

  res.status(200).json({ message: "Transaction deleted successfully", data: transaction });
});
