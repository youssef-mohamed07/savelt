import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/marketplace_badge.dart';

/// Normalize product URLs from marketplace providers.
String normalizeMarketplaceProductUrl(String? url, String marketplace) {
  final store = MarketplaceBadge.normalize(marketplace);
  var raw = (url ?? '').trim();
  if (raw.isEmpty) return marketplaceDefaultUrl(store);

  if (!raw.startsWith('http')) {
    raw = raw.replaceFirst(RegExp(r'^/+'), '');
    switch (store) {
      case 'noon':
        raw = raw.replaceFirst(RegExp(r'^egypt-en/+'), '');
        if (raw.endsWith('/p') || raw.endsWith('/p/')) {
          raw = raw.replaceFirst(RegExp(r'/p/?$'), '');
        }
        return 'https://www.noon.com/egypt-en/$raw/p/';
      case 'jumia':
        return raw.startsWith('/')
            ? 'https://www.jumia.com.eg$raw'
            : 'https://www.jumia.com.eg/$raw';
      default:
        if (raw.startsWith('dp/') || RegExp(r'^[A-Z0-9]{10}').hasMatch(raw)) {
          final asin = raw.replaceFirst('dp/', '').split('/').first;
          return 'https://www.amazon.eg/dp/$asin';
        }
        return marketplaceDefaultUrl(store);
    }
  }

  if (store == 'amazon' && raw.contains('amazon.com') && !raw.contains('amazon.eg')) {
    raw = raw.replaceAll('amazon.com', 'amazon.eg');
  }

  return raw;
}

/// Open a product page in the device browser; shows feedback on failure.
Future<void> openMarketplaceProduct(
  BuildContext context, {
  String? url,
  required String marketplace,
}) async {
  final target = normalizeMarketplaceProductUrl(url, marketplace);
  final uri = Uri.tryParse(target);
  if (uri == null || !uri.hasScheme) {
    if (context.mounted) {
      _showOpenError(context, 'Invalid product link');
    }
    return;
  }

  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      _showOpenError(context, 'Could not open store link');
    }
  } catch (_) {
    if (context.mounted) {
      _showOpenError(context, 'Could not open store link');
    }
  }
}

void _showOpenError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: GoogleFonts.inter(fontSize: 14)),
      backgroundColor: const Color(0xFFEF4444),
      duration: const Duration(seconds: 3),
    ),
  );
}
