import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'ocr_service.dart';
import 'auth_api_service.dart';

/// Picks a receipt image and sends it to the unified AI OCR endpoint.
class OcrScannerService {
  static final OcrScannerService instance = OcrScannerService._internal();
  OcrScannerService._internal();
  factory OcrScannerService() => instance;

  final ImagePicker _picker = ImagePicker();

  /// Pick a receipt image without scanning.
  Future<File?> pickReceipt({required bool fromCamera}) async {
    final picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2000,
      maxHeight: 2000,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Scan an already-picked receipt file.
  Future<OcrResult> scanReceiptFile(File imageFile, {double price = 0}) async {
    try {
      final isLoggedIn = await AuthApiService.instance.isAuthenticated();
      if (!isLoggedIn) {
        return OcrResult.failure(message: 'Please log in to scan receipts');
      }

      final ocrResult = await OcrService.instance.scanReceipt(imageFile);

      if (!ocrResult.isSuccess || ocrResult.invoice == null) {
        return OcrResult.failure(
          message: ocrResult.message ?? 'OCR failed. Run ./start.sh to start the server.',
        );
      }

      final invoice = ocrResult.invoice!;
      final amount = invoice.total ?? price;
      final category = invoice.mappedCategory;
      final description = invoice.items.isNotEmpty
          ? invoice.items.map((i) => i.name).take(3).join(', ')
          : 'Receipt scan — $category';

      return OcrResult.success(
        transactionId: 'ocr_${DateTime.now().millisecondsSinceEpoch}',
        text: description,
        amount: amount,
        category: category,
        itemCount: invoice.items.length,
        invoice: invoice,
      );
    } catch (e) {
      return OcrResult.failure(message: 'Error: $e');
    }
  }

  /// Pick from camera and scan
  Future<OcrResult> scanFromCamera({double price = 0}) async {
    return _pickAndScan(ImageSource.camera, price: price);
  }

  /// Pick from gallery and scan
  Future<OcrResult> scanFromGallery({double price = 0}) async {
    return _pickAndScan(ImageSource.gallery, price: price);
  }

  Future<OcrResult> _pickAndScan(ImageSource source, {double price = 0}) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2000,
        maxHeight: 2000,
      );

      if (picked == null) return OcrResult.cancelled();

      return scanReceiptFile(File(picked.path), price: price);
    } catch (e) {
      return OcrResult.failure(message: 'Error: $e');
    }
  }
}

class OcrResult {
  final OcrStatus status;
  final String? transactionId;
  final String? text;
  final double? amount;
  final String? category;
  final String? message;
  final int itemCount;
  final OcrInvoice? invoice; // full invoice for showing dialog

  OcrResult._({
    required this.status,
    this.transactionId,
    this.text,
    this.amount,
    this.category,
    this.message,
    this.itemCount = 0,
    this.invoice,
  });

  factory OcrResult.success({
    required String transactionId,
    required String text,
    required double amount,
    String? category,
    int itemCount = 0,
    OcrInvoice? invoice,
  }) {
    return OcrResult._(
      status: OcrStatus.success,
      transactionId: transactionId,
      text: text,
      amount: amount,
      category: category,
      itemCount: itemCount,
      invoice: invoice,
    );
  }

  factory OcrResult.failure({required String message}) {
    return OcrResult._(status: OcrStatus.failure, message: message);
  }

  factory OcrResult.cancelled() {
    return OcrResult._(status: OcrStatus.cancelled);
  }

  bool get isSuccess => status == OcrStatus.success;
  bool get isCancelled => status == OcrStatus.cancelled;
}

enum OcrStatus { success, failure, cancelled }
