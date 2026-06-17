import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../utils/marketplace_url.dart';
import 'auth_api_service.dart';
import '../../widgets/amazon_product_image.dart';

/// Fast offers loading with in-memory cache + lighter preview endpoint for Home.
class OffersApiService {
  OffersApiService._();
  static final OffersApiService instance = OffersApiService._();

  List<Map<String, dynamic>>? _previewCache;
  List<Map<String, dynamic>>? _fullCache;
  DateTime? _previewCacheAt;
  DateTime? _fullCacheAt;

  static const _cacheTtl = Duration(minutes: 30);

  Dio _client({required Duration receiveTimeout}) {
    return Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: receiveTimeout,
    ));
  }

  Future<Dio> _authedDio({required Duration receiveTimeout}) async {
    final dio = _client(receiveTimeout: receiveTimeout);
    final token = await AuthApiService.instance.getToken();
    if (token != null) dio.options.headers['token'] = token;
    return dio;
  }

  /// Home carousel — single top category, max 8 products.
  Future<List<Map<String, dynamic>>> fetchPreview({bool force = false}) async {
    if (!force &&
        _previewCache != null &&
        _previewCacheAt != null &&
        DateTime.now().difference(_previewCacheAt!) < _cacheTtl) {
      return _previewCache!;
    }

    final userId = AuthApiService.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) return [];

    final dio = await _authedDio(receiveTimeout: const Duration(seconds: 12));
    final response = await dio.get(
      '/api/offers/preview',
      queryParameters: {'userId': userId},
    );

    final data = response.data;
    if (data is! Map || data['success'] != true) return [];

    final raw = List<Map<String, dynamic>>.from(data['products'] ?? []);
    final products = _dedupeAndMap(raw).take(8).toList();

    if (products.isNotEmpty) {
      _previewCache = products;
      _previewCacheAt = DateTime.now();
    }

    return products;
  }

  /// Full offers page — top 2 spending categories.
  Future<List<Map<String, dynamic>>> fetchAll({bool force = false}) async {
    if (!force &&
        _fullCache != null &&
        _fullCacheAt != null &&
        DateTime.now().difference(_fullCacheAt!) < _cacheTtl) {
      return _fullCache!;
    }

    final userId = AuthApiService.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) return [];

    final dio = await _authedDio(receiveTimeout: const Duration(seconds: 25));
    final response = await dio.get(
      '/api/offers',
      queryParameters: {'userId': userId},
    );

    final data = response.data;
    if (data is! Map || data['success'] != true) return [];

    final byCategory = data['byCategory'] as List<dynamic>?;
    final raw = byCategory != null && byCategory.isNotEmpty
        ? byCategory
            .expand((c) => List<Map<String, dynamic>>.from(c['products'] ?? []))
            .toList()
        : List<Map<String, dynamic>>.from(data['products'] ?? []);

    final products = _dedupeAndMap(raw);

    if (products.isNotEmpty) {
      _fullCache = products;
      _fullCacheAt = DateTime.now();
    }

    return products;
  }

  List<Map<String, dynamic>> _dedupeAndMap(List<Map<String, dynamic>> raw) {
    final seen = <String>{};
    return raw
        .map((p) => _mapProduct(Map<String, dynamic>.from(p)))
        .where((p) {
          final url = p['url']?.toString() ?? '';
          final image = p['imageUrl']?.toString() ?? '';
          if (url.isEmpty || image.isEmpty) return false;
          final key =
              '${p['marketplace']}:${(p['name'] ?? '').toString().trim().toLowerCase()}';
          if (seen.contains(key)) return false;
          seen.add(key);
          return true;
        })
        .toList();
  }

  Map<String, dynamic> _mapProduct(Map<String, dynamic> p) {
    final title =
        (p['displayTitle'] ?? p['title'] ?? p['name'] ?? 'Product').toString();
    final price = _formatPrice(p['price']);
    final oldPrice =
        _formatPrice(p['original_price'] ?? p['oldPrice'] ?? p['originalPrice']);

    return {
      'name': title,
      'price': price,
      'oldPrice': oldPrice != price ? oldPrice : '',
      'discount': _formatDiscount(p['discount']?.toString(), price, oldPrice),
      'rating': _formatRating(p['rating']),
      'reviews': _formatReviews(p['reviews'] ?? p['num_ratings']),
      'imageUrl': normalizeAmazonImageUrl(p['image']),
      'url': normalizeMarketplaceProductUrl(
        p['url']?.toString(),
        (p['marketplace'] ?? 'amazon').toString(),
      ),
      'marketplace': (p['marketplace'] ?? 'amazon').toString(),
    };
  }

  String _formatPrice(dynamic val) {
    if (val == null) return '';
    final s = val.toString().trim();
    if (s.isEmpty || s == 'null') return '';
    final num = double.tryParse(s.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (num != null && num > 0) return 'EGP ${num.toStringAsFixed(2)}';
    if (s.toUpperCase().contains('EGP')) return s;
    return 'EGP $s'.replaceAll('جنيه', '').replaceAll('ج.م', '').trim();
  }

  String _formatDiscount(String? raw, String price, String oldPrice) {
    if (raw != null && raw.trim().isNotEmpty) {
      final d = raw.trim();
      if (d.startsWith('-') || d.toUpperCase().contains('SAVE') || d.contains('%')) {
        return d;
      }
    }
    final p = double.tryParse(price.replaceAll(RegExp(r'[^0-9.]'), ''));
    final o = double.tryParse(oldPrice.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (p != null && o != null && o > p && p > 0) {
      return '-${(((o - p) / o) * 100).round()}%';
    }
    return '';
  }

  String _formatRating(dynamic val) {
    final n = double.tryParse(val?.toString() ?? '');
    return (n ?? 4.0).toStringAsFixed(1);
  }

  String _formatReviews(dynamic val) {
    final n = int.tryParse(val?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '');
    if (n == null) return '0';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  void clearCache() {
    _previewCache = null;
    _fullCache = null;
    _previewCacheAt = null;
    _fullCacheAt = null;
  }

  List<Map<String, dynamic>>? get cachedPreview => _previewCache;
  List<Map<String, dynamic>>? get cachedFull => _fullCache;
}
