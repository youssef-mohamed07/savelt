import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../widgets/amazon_product_image.dart';

class OfferProductCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  final bool saved;
  final VoidCallback onSaveToggle;

  static const _navy = Color(0xFF0D5DB8);

  const OfferProductCard({
    super.key,
    required this.offer,
    required this.saved,
    required this.onSaveToggle,
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
    final showOldPrice = oldPrice.isNotEmpty && oldPrice != price;
    final showDiscount = discount.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openAmazon(offer['url']?.toString()),
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
                showDiscount: showDiscount,
                discount: discount,
                saved: saved,
                onSaveToggle: onSaveToggle,
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
                          _AmazonBadge(),
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
    required bool showDiscount,
    required String discount,
    required bool saved,
    required VoidCallback onSaveToggle,
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
          top: 14,
          right: 14,
          child: GestureDetector(
            onTap: onSaveToggle,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: saved
                    ? const Color(0xFFFEE2E2)
                    : Colors.white.withValues(alpha: 0.95),
                shape: BoxShape.circle,
                border: Border.all(
                  color: saved ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 16,
                color: saved ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
              ),
            ),
          ),
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

  Future<void> _openAmazon(String? url) async {
    final target = (url == null || url.isEmpty) ? 'https://www.amazon.eg' : url;
    await launchUrl(Uri.parse(target), mode: LaunchMode.externalApplication);
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
          if (reviews.isNotEmpty) ...[
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

class _AmazonBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Amazon',
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0D5DB8),
            ),
          ),
          const SizedBox(width: 2),
          Icon(Icons.arrow_outward_rounded, size: 11, color: Colors.grey.shade600),
        ],
      ),
    );
  }
}
