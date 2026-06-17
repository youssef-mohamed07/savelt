import 'package:flutter/material.dart';
import 'sync_service.dart';

// مثال: إزاي تستخدمي الـ Sync في التطبيق

class SyncExample {
  // 1️⃣ في main.dart، ابدأي الـ Sync Service
  static void initSync() {
    final syncService = SyncService();
    syncService.startListening(); // يبدأ يراقب النت
    debugPrint('✅ Sync service started');
  }

  // 2️⃣ لو عايزة تعملي sync يدوي (زرار Sync مثلاً)
  static Future<void> manualSync(BuildContext context) async {
    final syncService = SyncService();

    // عرض loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // عمل sync
    await syncService.manualSync();

    // إخفاء loading
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Sync completed!')));
    }
  }

  // 3️⃣ فحص حالة النت
  static Future<bool> checkInternet() async {
    final syncService = SyncService();
    return await syncService.hasInternet();
  }
}

// مثال استخدام في Widget:
class SyncButton extends StatelessWidget {
  const SyncButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.sync),
      onPressed: () => SyncExample.manualSync(context),
      tooltip: 'Sync with server',
    );
  }
}


