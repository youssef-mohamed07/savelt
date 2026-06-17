import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/services/auth_api_service.dart';
import '../../widgets/amazon_product_image.dart';
import 'widgets/offer_product_card.dart';

class OffersPage extends StatefulWidget {
  const OffersPage({super.key});

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  static const _navy = Color(0xFF0D5DB8);
  static const _navyDark = Color(0xFF0A4A94);

  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  final Map<int, bool> _saved = {};

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() => _isLoading = true);
    try {
      final userId = AuthApiService.instance.currentUser?.uid;
      if (userId == null || userId.isEmpty) {
        setState(() { _products = []; _isLoading = false; });
        return;
      }
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
      ));
      final token = await AuthApiService.instance.getToken();
      if (token != null) dio.options.headers['token'] = token;

      final response = await dio.get('/api/offers', queryParameters: {'userId': userId});
      if (response.data['success'] == true) {
        final byCategory = response.data['byCategory'] as List<dynamic>?;
        final rawProducts = byCategory != null && byCategory.isNotEmpty
            ? byCategory.expand((c) => List<Map<String, dynamic>>.from(c['products'] ?? [])).toList()
            : List<Map<String, dynamic>>.from(response.data['products'] ?? []);

        final products = _dedupeAndFilter(rawProducts.map(_mapProduct).toList());
        setState(() {
          _products = products;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('❌ [Offers] Error: $e');
    }
    setState(() { _products = []; _isLoading = false; });
  }

  List<Map<String, dynamic>> _dedupeAndFilter(List<Map<String, dynamic>> items) {
    final seen = <String>{};
    return items.where((p) {
      final url = p['imageUrl'] as String?;
      if (url == null || url.isEmpty) return false;
      final key = (p['name'] ?? '').toString().trim().toLowerCase();
      if (key.isEmpty || seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();
  }

  Map<String, dynamic> _mapProduct(Map<String, dynamic> p) {
    final title = (p['displayTitle'] ?? p['title'] ?? p['name'] ?? 'Product').toString();
    final price = _formatPrice(p['price']);
    final oldPrice = _formatPrice(p['original_price'] ?? p['oldPrice'] ?? p['originalPrice']);

    return {
      'name': title,
      'price': price,
      'oldPrice': oldPrice != price ? oldPrice : '',
      'discount': _formatDiscount(p['discount']?.toString(), price, oldPrice),
      'rating': _formatRating(p['rating']),
      'reviews': _formatReviews(p['reviews'] ?? p['num_ratings']),
      'imageUrl': normalizeAmazonImageUrl(p['image']),
      'url': _fixUrl(p['url']),
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
      if (d.startsWith('-') || d.toUpperCase().contains('SAVE') || d.contains('%')) return d;
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

  String _fixUrl(dynamic val) {
    if (val == null || val.toString().isEmpty) return 'https://www.amazon.eg';
    return val.toString()
        .replaceAll('amazon.com', 'amazon.eg')
        .replaceAll('amazon.co.uk', 'amazon.eg');
  }

  int get _dealCount => _products.where((p) => (p['discount'] ?? '').toString().isNotEmpty).length;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4FA),
        body: SafeArea(
          bottom: false,
          child: _isLoading ? _buildLoadingView() : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(dealCount: null)),
        SliverToBoxAdapter(child: _buildBannerSkeleton()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.66,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, __) => _buildCardSkeleton(),
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadOffers,
      color: _navy,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(dealCount: _products.length)),
          if (_products.isNotEmpty) ...[
            SliverToBoxAdapter(child: _buildFeaturedDeal(_products.first)),
            SliverToBoxAdapter(child: _buildInsightBanner()),
            if (_products.length > 1)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                  child: Text(
                    'More for you',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
          ],
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: _products.isEmpty
                ? SliverToBoxAdapter(child: _buildEmptyState())
                : SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.66,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final productIndex = _products.length > 1 ? index + 1 : index;
                        if (productIndex >= _products.length) return const SizedBox.shrink();
                        final saved = _saved[productIndex] ?? false;
                        return OfferProductCard(
                          offer: _products[productIndex],
                          saved: saved,
                          onSaveToggle: () => setState(() => _saved[productIndex] = !saved),
                        );
                      },
                      childCount: _products.length > 1 ? _products.length - 1 : _products.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({required int? dealCount}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _navy.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'FOR YOU',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: _navy,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Smart Offers',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.8,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dealCount == null
                      ? 'Curating deals from Amazon.eg…'
                      : '$dealCount picks · ${_dealCount > 0 ? '$_dealCount on sale' : 'based on your spending'}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: _navy.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.notifications_none_rounded, color: _navy, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedDeal(Map<String, dynamic> offer) {
    final discount = offer['discount']?.toString() ?? '';
    final hasDiscount = discount.isNotEmpty;
    final url = offer['url']?.toString() ?? 'https://www.amazon.eg';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_navy, _navyDark],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: _navy.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasDiscount)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B6B),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Top deal $discount',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            if (hasDiscount) const SizedBox(height: 10),
                            Text(
                              'Deal of the day',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.75),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              offer['name']?.toString() ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              offer['price']?.toString() ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 88,
                        height: 88,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: AmazonProductImage(
                          imageUrl: offer['imageUrl'] as String?,
                          height: 72,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsightBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF818CF8).withValues(alpha: 0.2),
                    const Color(0xFF6366F1).withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFF6366F1)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Matched to your recent purchases on Amazon.eg',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFF475569),
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.local_offer_outlined, size: 32, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            'No offers right now',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Pull down to refresh when new deals are available.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSkeleton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: _ShimmerBox(height: 120, borderRadius: 22),
    );
  }

  Widget _buildCardSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: _ShimmerBox(height: 108, borderRadius: 14),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(height: 12, borderRadius: 6, width: double.infinity),
                const SizedBox(height: 6),
                _ShimmerBox(height: 12, borderRadius: 6, width: 100),
                const SizedBox(height: 14),
                _ShimmerBox(height: 16, borderRadius: 6, width: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const _ShimmerBox({
    required this.height,
    this.width,
    this.borderRadius = 8,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: Color.lerp(
              const Color(0xFFE2E8F0),
              const Color(0xFFF1F5F9),
              _controller.value,
            ),
          ),
        );
      },
    );
  }
}
