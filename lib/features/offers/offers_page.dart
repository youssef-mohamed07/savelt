import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/services/offers_api_service.dart';
import '../../core/utils/marketplace_url.dart';
import '../../widgets/amazon_product_image.dart';
import '../../widgets/marketplace_badge.dart';
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

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers({bool force = false}) async {
    setState(() => _isLoading = true);

    final userId = AuthApiService.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      setState(() { _products = []; _isLoading = false; });
      return;
    }

    final api = OffersApiService.instance;
    final stale = api.cachedFull ?? api.cachedPreview;
    if (stale != null && stale.isNotEmpty) {
      setState(() {
        _products = stale;
        _isLoading = false;
      });
    }

    try {
      final products = await api.fetchAll(force: force);
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } on DioException catch (e) {
      debugPrint('❌ [Offers] Error: ${e.message}');
      if (mounted && _products.isEmpty) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ [Offers] Error: $e');
      if (mounted && _products.isEmpty) {
        setState(() => _isLoading = false);
      }
    }
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
      onRefresh: () => _loadOffers(force: true),
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
                        return OfferProductCard(offer: _products[productIndex]);
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
                      ? 'Curating deals from Amazon, Noon & Jumia…'
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
        ],
      ),
    );
  }

  Widget _buildFeaturedDeal(Map<String, dynamic> offer) {
    final discount = offer['discount']?.toString() ?? '';
    final hasDiscount = discount.isNotEmpty;
    final marketplace = offer['marketplace']?.toString() ?? 'amazon';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => openMarketplaceProduct(
            context,
            url: offer['url']?.toString(),
            marketplace: marketplace,
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Deals from top stores',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF334155),
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _StoreLogoButton(store: 'amazon'),
            const SizedBox(width: 6),
            _StoreLogoButton(store: 'noon'),
            const SizedBox(width: 6),
            _StoreLogoButton(store: 'jumia'),
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

class _StoreLogoButton extends StatelessWidget {
  final String store;

  const _StoreLogoButton({required this.store});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openMarketplaceProduct(context, marketplace: store),
        borderRadius: BorderRadius.circular(8),
        child: MarketplaceBadge(marketplace: store, height: 24, compact: true),
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
