import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/marketplace_url.dart';
import '../../../widgets/amazon_product_image.dart';
import '../../../widgets/marketplace_badge.dart';

class OfferProductCard extends StatelessWidget {
  final Map<String, dynamic> offer;

  static const _navy = Color(0xFF0D5DB8);

  const OfferProductCard({
    super.key,
    required this.offer,
  });

  @override
  Widget build(BuildContext context) {
    final name = offer['name']?.toString() ?? 'Product';
    final price = offer['price']?.toString() ?? '';
    final oldPrice = offer['oldPrice']?.toString() ?? '';
    final discount = offer['discount']?.toString() ?? '';
    final rating = offer['rating']?.toString() ?? '4.0';
    final reviews = offer['reviews']?.toString() ?? '';
    final imageUrl = offer['imageUrl'] as String?;
    final marketplace = offer['marketplace']?.toString() ?? 'amazon';
    final showOldPrice = oldPrice.isNotEmpty && oldPrice != price;
    final showDiscount = discount.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => openMarketplaceProduct(
          context,
          url: offer['url']?.toString(),
          marketplace: marketplace,
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EDF5)),
            boxShadow: [
              BoxShadow(
                color: _navy.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageSection(
                imageUrl: imageUrl,
                marketplace: marketplace,
                showDiscount: showDiscount,
                discount: discount,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: const Color(0xFF111827),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      _buildPriceRow(price, showOldPrice ? oldPrice : null),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _RatingChip(rating: rating, reviews: reviews),
                          const Spacer(),
                          MarketplaceBadge(
                            marketplace: marketplace,
                            height: 20,
                            compact: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection({
    required String? imageUrl,
    required String marketplace,
    required bool showDiscount,
    required String discount,
  }) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.all(10),
          height: 108,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: AmazonProductImage(
                imageUrl: imageUrl,
                height: 88,
                fit: BoxFit.contain,
                marketplace: marketplace,
              ),
            ),
          ),
        ),
        if (showDiscount)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFEE4444)],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEE4444).withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                discount,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 14,
          left: 14,
          child: MarketplaceBadge(marketplace: marketplace, height: 18, compact: true),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String price, String? oldPrice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          price,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _navy,
            letterSpacing: -0.3,
          ),
        ),
        if (oldPrice != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              oldPrice,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: const Color(0xFF94A3B8),
                decoration: TextDecoration.lineThrough,
                decorationColor: const Color(0xFFCBD5E1),
              ),
            ),
          ),
      ],
    );
  }
}

class _RatingChip extends StatelessWidget {
  final String rating;
  final String reviews;

  const _RatingChip({required this.rating, required this.reviews});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A).withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
          const SizedBox(width: 3),
          Text(
            rating,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF92400E),
            ),
          ),
          if (reviews.isNotEmpty && reviews != '0') ...[
            Text(
              ' · $reviews',
              style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFFB45309)),
            ),
          ],
        ],
      ),
    );
  }
}
