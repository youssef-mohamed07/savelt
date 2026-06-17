import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { v4 as uuidv4 } from 'uuid';
import { AppError } from '../utils/AppError.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
export const UPLOAD_ROOT = path.resolve(__dirname, '../uploads');

const VOICE_EXTENSIONS = new Set(['.m4a', '.mp3', '.wav', '.webm', '.ogg', '.flac', '.mp4', '.aac']);
const RECEIPT_EXTENSIONS = new Set(['.jpg', '.jpeg', '.png', '.webp', '.heic', '.heif', '.gif']);

export function ensureUploadDirs() {
  fs.mkdirSync(UPLOAD_ROOT, { recursive: true });
}

function userSubfolder(req, subfolder) {
  const userId = req.user?._id?.toString();
  if (!userId) {
    throw new AppError('Authentication required for upload', 401);
  }
  const dir = path.join(UPLOAD_ROOT, 'users', userId, subfolder);
  fs.mkdirSync(dir, { recursive: true });
  return dir;
}

const mediaStorage = multer.diskStorage({
  destination(req, file, cb) {
    try {
      const subfolder = file.fieldname === 'voice' ? 'voice' : 'receipts';
      cb(null, userSubfolder(req, subfolder));
    } catch (err) {
      cb(err);
    }
  },
  filename(_req, file, cb) {
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, `${uuidv4()}${ext}`);
  },
});

function voiceFilter(_req, file, cb) {
  const ext = path.extname(file.originalname).toLowerCase();
  if (VOICE_EXTENSIONS.has(ext) || file.mimetype.startsWith('audio/')) {
    cb(null, true);
    return;
  }
  cb(new AppError(`Invalid voice file. Allowed: ${[...VOICE_EXTENSIONS].join(', ')}`, 400));
}

function receiptFilter(_req, file, cb) {
  const ext = path.extname(file.originalname).toLowerCase();
  if (RECEIPT_EXTENSIONS.has(ext) || file.mimetype.startsWith('image/')) {
    cb(null, true);
    return;
  }
  cb(new AppError(`Invalid receipt image. Allowed: ${[...RECEIPT_EXTENSIONS].join(', ')}`, 400));
}

const mediaUpload = multer({
  storage: mediaStorage,
  limits: { fileSize: 15 * 1024 * 1024 },
  fileFilter(req, file, cb) {
    if (file.fieldname === 'voice') return voiceFilter(req, file, cb);
    if (file.fieldname === 'receipt') return receiptFilter(req, file, cb);
    cb(new AppError(`Unexpected field: ${file.fieldname}`, 400));
  },
});

export const uploadTransactionMedia = mediaUpload.fields([
  { name: 'voice', maxCount: 1 },
  { name: 'receipt', maxCount: 1 },
]);

export function handleUpload(middleware) {
  return (req, res, next) => {
    middleware(req, res, (err) => {
      if (err instanceof multer.MulterError) {
        const message =
          err.code === 'LIMIT_FILE_SIZE'
            ? 'File too large (max 15MB)'
            : err.message;
        return next(new AppError(message, 400));
      }
      if (err) return next(err);
      return next();
    });
  };
}

/** Relative path stored in MongoDB (served at /uploads/...) */
export function toRelativeUploadPath(absolutePath) {
  return path.relative(UPLOAD_ROOT, absolutePath).replace(/\\/g, '/');
}

export function resolveUploadAbsolutePath(relativePath) {
  if (!relativePath) return null;
  const normalized = relativePath.replace(/^\/+/, '');
  const absolute = path.resolve(UPLOAD_ROOT, normalized);
  if (!absolute.startsWith(UPLOAD_ROOT)) return null;
  return absolute;
}

export function deleteUploadFile(relativePath) {
  const absolute = resolveUploadAbsolutePath(relativePath);
  if (!absolute || !fs.existsSync(absolute)) return;
  try {
    fs.unlinkSync(absolute);
  } catch (err) {
    console.warn('[UPLOAD] Failed to delete file:', relativePath, err.message);
  }
}

export function publicUploadUrl(relativePath) {
  if (!relativePath) return null;
  const base = process.env.BASE_URL || 'http://localhost:3001/uploads/';
  return `${base.replace(/\/+$/, '')}/${relativePath.replace(/^\/+/, '')}`;
}
