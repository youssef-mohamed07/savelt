import 'dart:io';
import 'package:dio/dio.dart';
import '../config/api_config.dart';

import 'ocr_category_classifier.dart';

/// OCR Receipt scanning service.
/// Talks to the unified AI server (voice + OCR on port 8000).
class OcrService {
  static final OcrService instance = OcrService._internal();
  OcrService._internal();
  factory OcrService() => instance;

  String get _baseUrl => ApiConfig.ocrBaseUrl;

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 60), // OCR can take time
  ));

  /// Scan a receipt image and return structured invoice data.
  Future<OcrResult> scanReceipt(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '$_baseUrl/ocr/scan',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        return OcrResult.success(invoice: OcrInvoice.fromJson(data));
      }

      return OcrResult.failure(
        message: response.data['message'] ?? 'OCR failed',
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        return OcrResult.failure(
          message: 'Cannot reach OCR service. Run ./start.sh from the project root.',
        );
      }
      if (e.type == DioExceptionType.receiveTimeout) {
        return OcrResult.failure(message: 'OCR timed out — try a clearer photo.');
      }
      final serverMsg = _extractServerMessage(e.response?.data);
      if (e.response?.statusCode == 503) {
        return OcrResult.failure(
          message: serverMsg ??
              'OCR service unavailable. Restart with ./start.sh and check ocr_service/.env',
        );
      }
      if (e.response?.statusCode == 500) {
        return OcrResult.failure(
          message: serverMsg ??
              'OCR scan failed on server. Restart with ./start.sh --no-app',
        );
      }
      return OcrResult.failure(message: serverMsg ?? e.message ?? 'Network error');
    } catch (e) {
      return OcrResult.failure(message: e.toString());
    }
  }

  String? _extractServerMessage(dynamic data) {
    if (data is! Map) return null;
    final err = data['error'];
    if (err is Map && err['message'] != null) {
      return err['message'].toString();
    }
    if (data['detail'] != null) return data['detail'].toString();
    if (data['message'] != null) return data['message'].toString();
    return null;
  }

  /// Check if the OCR service is running.
  Future<bool> isAvailable() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/health',
        options: Options(receiveTimeout: const Duration(seconds: 3)),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

// ── Models ────────────────────────────────────────────────────────────────────

class OcrInvoice {
  final String? date;
  final String? time;
  final double? total;
  final String? category;
  final String? storeName;
  final String? place;
  final String? details;
  final List<OcrLineItem> items;

  const OcrInvoice({
    this.date,
    this.time,
    this.total,
    this.category,
    this.storeName,
    this.place,
    this.details,
    required this.items,
  });

  factory OcrInvoice.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return OcrInvoice(
      date: json['date']?.toString(),
      time: json['time']?.toString(),
      total: (json['total'] as num?)?.toDouble(),
      category: json['category']?.toString(),
      storeName: json['store_name']?.toString(),
      place: json['place']?.toString(),
      details: json['details']?.toString(),
      items: rawItems
          .map((e) => OcrLineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Map OCR invoice category to app category name.
  String get mappedCategory => OcrCategoryClassifier.mapOcrCategory(category);

  /// Best app category for a line item (uses item name + invoice fallback).
  String categoryForItem(String itemName) =>
      OcrCategoryClassifier.classifyItem(itemName, invoiceCategory: category);
}

class OcrLineItem {
  final String name;
  final double? quantity;
  final double? unitPrice;
  final double? totalPrice;

  const OcrLineItem({
    required this.name,
    this.quantity,
    this.unitPrice,
    this.totalPrice,
  });

  factory OcrLineItem.fromJson(Map<String, dynamic> json) {
    return OcrLineItem(
      name: json['name']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble(),
      unitPrice: (json['unit_price'] as num?)?.toDouble(),
      totalPrice: (json['total_price'] as num?)?.toDouble(),
    );
  }
}

class OcrResult {
  final bool isSuccess;
  final OcrInvoice? invoice;
  final String? message;

  const OcrResult._({
    required this.isSuccess,
    this.invoice,
    this.message,
  });

  factory OcrResult.success({required OcrInvoice invoice}) {
    return OcrResult._(isSuccess: true, invoice: invoice);
  }

  factory OcrResult.failure({required String message}) {
    return OcrResult._(isSuccess: false, message: message);
  }
}
