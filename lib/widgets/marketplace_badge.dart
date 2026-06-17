import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Store badge with official-style logos for Amazon, Noon, and Jumia.
class MarketplaceBadge extends StatelessWidget {
  final String marketplace;
  final double height;
  final bool compact;

  const MarketplaceBadge({
    super.key,
    required this.marketplace,
    this.height = 22,
    this.compact = false,
  });

  static String normalize(String? value) {
    final v = (value ?? 'amazon').toLowerCase().trim();
    if (v == 'noon' || v == 'jumia' || v == 'amazon') return v;
    return 'amazon';
  }

  @override
  Widget build(BuildContext context) {
    final store = normalize(marketplace);

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: _bg(store),
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        border: Border.all(color: _border(store)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _logo(store),
          if (!compact) ...[
            const SizedBox(width: 4),
            Icon(Icons.arrow_outward_rounded, size: height * 0.5, color: _accent(store)),
          ],
        ],
      ),
    );
  }

  Widget _logo(String store) {
    switch (store) {
      case 'noon':
        return _NoonWordmark(height: height - (compact ? 6 : 8));
      case 'jumia':
        return Image.asset(
          'assets/images/marketplaces/jumia.png',
          height: height - (compact ? 6 : 8),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _textFallback('Jumia', const Color(0xFFF68B1E)),
        );
      case 'amazon':
      default:
        return Image.asset(
          'assets/images/marketplaces/amazon.png',
          height: height - (compact ? 6 : 8),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _textFallback('Amazon', const Color(0xFF0D5DB8)),
        );
    }
  }

  Widget _textFallback(String label, Color color) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: height * 0.42,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    );
  }

  Color _bg(String store) {
    switch (store) {
      case 'noon':
        return Colors.black;
      case 'jumia':
        return const Color(0xFFFFF7ED);
      default:
        return const Color(0xFFEFF6FF);
    }
  }

  Color _border(String store) {
    switch (store) {
      case 'noon':
        return Colors.black;
      case 'jumia':
        return const Color(0xFFFED7AA);
      default:
        return const Color(0xFFBFDBFE);
    }
  }

  Color _accent(String store) {
    switch (store) {
      case 'noon':
        return const Color(0xFFFEEE00);
      case 'jumia':
        return const Color(0xFFF68B1E);
      default:
        return const Color(0xFF0D5DB8);
    }
  }
}

class MarketplaceLogoStrip extends StatelessWidget {
  final double height;

  const MarketplaceLogoStrip({super.key, this.height = 22});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MarketplaceBadge(marketplace: 'amazon', height: height, compact: true),
        const SizedBox(width: 6),
        MarketplaceBadge(marketplace: 'noon', height: height, compact: true),
        const SizedBox(width: 6),
        MarketplaceBadge(marketplace: 'jumia', height: height, compact: true),
      ],
    );
  }
}

class _NoonWordmark extends StatelessWidget {
  final double height;

  const _NoonWordmark({required this.height});

  @override
  Widget build(BuildContext context) {
    return Text(
      'noon',
      style: GoogleFonts.inter(
        fontSize: height * 0.72,
        fontWeight: FontWeight.w800,
        color: const Color(0xFFFEEE00),
        letterSpacing: -0.5,
        height: 1,
      ),
    );
  }
}

String marketplaceDefaultUrl(String marketplace) {
  switch (MarketplaceBadge.normalize(marketplace)) {
    case 'noon':
      return 'https://www.noon.com/egypt-en/';
    case 'jumia':
      return 'https://www.jumia.com.eg/';
    default:
      return 'https://www.amazon.eg/';
  }
}

ImageHeaders imageHeadersForMarketplace(String? imageUrl, String marketplace) {
  if (imageUrl != null && imageUrl.contains('nooncdn.com')) {
    return const ImageHeaders({
      'User-Agent': 'Mozilla/5.0',
      'Accept': 'image/webp,image/*,*/*;q=0.8',
    });
  }
  if (imageUrl != null && imageUrl.contains('jumia.is')) {
    return const ImageHeaders({
      'User-Agent': 'Mozilla/5.0',
      'Referer': 'https://www.jumia.com.eg/',
      'Accept': 'image/*',
    });
  }
  return const ImageHeaders({
    'Referer': 'https://www.amazon.eg/',
    'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
    'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
  });
}

class ImageHeaders {
  final Map<String, String> headers;
  const ImageHeaders(this.headers);
}
