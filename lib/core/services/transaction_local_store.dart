import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/transactions/models/transaction_model.dart' as ui;
import '../models/transaction_model.dart' as core;

/// Shared local cache for the Transactions tab.
class TransactionLocalStore {
  static const String key = 'local_transactions';

  static ui.TransactionModel fromCore(core.TransactionModel t) {
    return ui.TransactionModel(
      id: t.id,
      title: t.displayText,
      description: t.categoryName ?? '',
      amount: t.price,
      category: t.categoryName ?? t.categoryId ?? '',
      type: 'expense',
      date: t.createdAt,
      createdAt: t.createdAt,
      updatedAt: t.updatedAt ?? t.createdAt,
    );
  }

  static const _knownCategories = {
    'shopping', 'food', 'transport', 'entertainment', 'health',
    'education', 'bills', 'groceries', 'other', 'travel', 'utilities',
    'rent', 'salary', 'income', 'personal', 'gifts', 'subscriptions',
  };

  static List<ui.TransactionModel> dedupe(List<ui.TransactionModel> items) {
    final sorted = List<ui.TransactionModel>.from(items)
      ..sort((a, b) => b.date.compareTo(a.date));

    final byFingerprint = <String, ui.TransactionModel>{};

    for (final t in sorted) {
      final fp = _fingerprint(t);
      final existing = byFingerprint[fp];
      if (existing == null) {
        byFingerprint[fp] = t;
        continue;
      }
      byFingerprint[fp] = _pickBetter(existing, t);
    }

    return byFingerprint.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static bool _isBackendId(String id) =>
      RegExp(r'^[a-f0-9]{24}$').hasMatch(id);

  static int _qualityScore(ui.TransactionModel t) {
    var score = 0;
    if (_isBackendId(t.id)) score += 10;
    if (_knownCategories.contains(t.category.trim().toLowerCase())) score += 5;
    return score;
  }

  static ui.TransactionModel _pickBetter(
    ui.TransactionModel a,
    ui.TransactionModel b,
  ) {
    return _qualityScore(a) >= _qualityScore(b) ? a : b;
  }

  static String _fingerprint(ui.TransactionModel t) {
    final day = '${t.date.year}-${t.date.month}-${t.date.day}';
    return '${t.title.trim().toLowerCase()}|${t.amount.toStringAsFixed(2)}|$day';
  }

  static Future<List<ui.TransactionModel>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(key);
      if (json == null) return [];
      final list = jsonDecode(json) as List;
      return dedupe(
        list.map((e) => ui.TransactionModel.fromMap(e as Map<String, dynamic>)).toList(),
      );
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<ui.TransactionModel> transactions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        key,
        jsonEncode(dedupe(transactions).map((t) => t.toMap()).toList()),
      );
    } catch (_) {}
  }

  static Future<void> saveFromCore(List<core.TransactionModel> transactions) async {
    await save(transactions.map(fromCore).toList());
  }

  /// Upsert one row — avoids duplicate rows when mirroring new expenses locally.
  static Future<void> upsert(ui.TransactionModel transaction) async {
    final current = await load();
    final fp = _fingerprint(transaction);
    final updated = [
      transaction,
      ...current.where((t) {
        if (t.id.isNotEmpty && t.id == transaction.id) return false;
        return _fingerprint(t) != fp;
      }),
    ];
    await save(updated);
  }

  static Future<void> removeById(String id) async {
    final updated = (await load()).where((t) => t.id != id).toList();
    await save(updated);
  }
}
