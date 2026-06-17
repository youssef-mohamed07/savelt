import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Headers required by Amazon's image CDN.
const amazonImageHeaders = {
  'Referer': 'https://www.amazon.eg/',
  'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
  'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
};

String? normalizeAmazonImageUrl(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  if (s.isEmpty || s == 'null') return null;
  var url = s.startsWith('http://') ? s.replaceFirst('http://', 'https://') : s;
  url = url.replaceAll('._AC_UL960_QL65_.', '._AC_SX300_.');
  return url;
}

class AmazonProductImage extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final double? width;
  final BoxFit fit;
  final IconData fallbackIcon;

  const AmazonProductImage({
    super.key,
    required this.imageUrl,
    this.height = 78,
    this.width,
    this.fit = BoxFit.contain,
    this.fallbackIcon = Icons.shopping_bag_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final url = normalizeAmazonImageUrl(imageUrl);
    if (url == null) {
      return _fallback();
    }

    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders: amazonImageHeaders,
      fit: fit,
      width: width ?? double.infinity,
      height: height,
      placeholder: (_, __) => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      height: height,
      width: width ?? double.infinity,
      color: const Color(0xFFF8FAFC),
      child: Icon(fallbackIcon, size: height * 0.45, color: Colors.grey.shade400),
    );
  }
}
