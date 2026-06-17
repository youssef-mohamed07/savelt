import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/ocr_service.dart';
import '../../core/services/ocr_category_classifier.dart';
import '../../core/models/expense.dart';
import '../../features/home/bloc/expense_bloc.dart';
import '../../features/home/bloc/expense_event.dart';
import '../../features/categories/bloc/category_bloc.dart';
import '../../features/categories/category_data_store.dart';
import '../../features/transactions/bloc/transaction_bloc.dart';
import '../../features/transactions/bloc/transaction_event.dart';

class OcrResultsDialog extends StatefulWidget {
  final OcrInvoice invoice;
  final ExpenseBloc expenseBloc;
  final CategoryBloc categoryBloc;

  const OcrResultsDialog({
    super.key,
    required this.invoice,
    required this.expenseBloc,
    required this.categoryBloc,
  });

  @override
  State<OcrResultsDialog> createState() => _OcrResultsDialogState();
}

class _OcrResultsDialogState extends State<OcrResultsDialog> {
  static const _navy = Color(0xFF0D5DB8);
  static const _bg = Color(0xFFF0F4FA);
  static const _border = Color(0xFFE8EDF5);

  late List<Map<String, dynamic>> _items;
  late final TextEditingController _receiptNoteController;
  final List<TextEditingController> _descriptionControllers = [];

  @override
  void initState() {
    super.initState();
    _items = _buildItemsFromInvoice();
    _receiptNoteController = TextEditingController(text: _receiptSummary());
    _initItemControllers();
  }

  @override
  void dispose() {
    _receiptNoteController.dispose();
    for (final c in _descriptionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  String _receiptSummary() {
    final inv = widget.invoice;
    final parts = <String>[];
    if (inv.mappedCategory.isNotEmpty && inv.mappedCategory != 'Other') {
      parts.add(inv.mappedCategory);
    }
    if (inv.date != null && inv.date!.trim().isNotEmpty) {
      parts.add(inv.date!.trim());
    }
    if (inv.time != null && inv.time!.trim().isNotEmpty) {
      parts.add(inv.time!.trim());
    }
    if (parts.isEmpty) return 'Receipt scan';
    return parts.join(' · ');
  }

  void _initItemControllers() {
    for (final c in _descriptionControllers) {
      c.dispose();
    }
    _descriptionControllers.clear();
    for (final item in _items) {
      _descriptionControllers.add(
        TextEditingController(text: item['description'] as String),
      );
    }
  }

  List<Map<String, dynamic>> _buildItemsFromInvoice() {
    final inv = widget.invoice;

    if (inv.items.isNotEmpty) {
      return inv.items
          .map((item) => {
                'description': item.name,
                'amount': item.totalPrice ?? item.unitPrice ?? 0.0,
                'category': inv.categoryForItem(item.name),
              })
          .toList();
    }

    return [
      {
        'description': 'Receipt — ${inv.mappedCategory}',
        'amount': inv.total ?? 0.0,
        'category': inv.mappedCategory,
      }
    ];
  }

  List<String> _categoryOptions(CategoryBloc bloc) {
    const extras = [
      'Food & Drink',
      'Shopping',
      'Bills',
      'Health',
      'Transport',
      'Entertainment',
      'Education',
    ];
    final seen = <String>{};
    final names = <String>[];

    for (final c in bloc.state.customCategories) {
      final name = (c['name'] as String?)?.trim();
      if (name != null && name.isNotEmpty && seen.add(name)) {
        names.add(name);
      }
    }
    for (final c in CategoryDataStore().allCategories) {
      if (seen.add(c.name)) names.add(c.name);
    }
    for (final e in extras) {
      if (seen.add(e)) names.add(e);
    }
    return names;
  }

  String _resolveDropdownValue(String current, List<String> options) {
    if (options.contains(current)) return current;
    final mapped = OcrCategoryClassifier.mapOcrCategory(current);
    if (options.contains(mapped)) return mapped;
    for (final opt in options) {
      if (opt.toLowerCase() == current.toLowerCase()) return opt;
    }
    return options.isNotEmpty ? options.first : current;
  }

  IconData _getCategoryIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains('food') || c.contains('drink')) return Icons.restaurant;
    if (c.contains('transport') || c.contains('fuel')) return Icons.directions_car;
    if (c.contains('shop')) return Icons.shopping_bag;
    if (c.contains('health') || c.contains('pharmacy')) return Icons.medical_services;
    if (c.contains('education')) return Icons.school;
    if (c.contains('entertain')) return Icons.movie;
    if (c.contains('bill')) return Icons.receipt;
    return Icons.category;
  }

  String _mapCategory(String raw) {
    return OcrCategoryClassifier.mapOcrCategory(raw);
  }

  String? _findMatchingCategory(String name) {
    final dataStore = CategoryDataStore();
    final normalized = name.toLowerCase().replaceAll(RegExp(r'[&\-_\s]+'), ' ').trim();
    for (var cat in dataStore.allCategories) {
      final n = cat.name.toLowerCase().replaceAll(RegExp(r'[&\-_\s]+'), ' ').trim();
      if (n == normalized || n.contains(normalized) || normalized.contains(n)) {
        return cat.name;
      }
    }
    return null;
  }

  Future<void> _ensureCategoryExists(String categoryName) async {
    final dataStore = CategoryDataStore();
    if (_findMatchingCategory(categoryName) != null) return;
    if (dataStore.findCategory(categoryName) != null) return;

    final icon = _getCategoryIcon(categoryName);
    widget.categoryBloc.add(AddCategory(name: categoryName, icon: icon));
    dataStore.addCustomCategory(CategoryData(
      name: categoryName,
      icon: icon,
      color: _navy,
      isMain: false,
    ));
  }

  Future<void> _saveAll() async {
    if (_items.isEmpty) return;

    HapticFeedback.lightImpact();
    final dataStore = CategoryDataStore();
    final expenseBloc = widget.expenseBloc;
    final transactionBloc = context.read<TransactionBloc>();

    for (int i = 0; i < _items.length; i++) {
      _items[i]['description'] = _descriptionControllers[i].text.trim();
      final item = _items[i];
      final rawCategory = item['category'] as String;
      final mappedCategory = _mapCategory(rawCategory);
      final finalCategory = _findMatchingCategory(mappedCategory) ?? mappedCategory;

      await _ensureCategoryExists(finalCategory);

      final amount = (item['amount'] as num).toDouble();
      final description = item['description'] as String;

      expenseBloc.add(AddExpense(Expense(
        id: '${DateTime.now().millisecondsSinceEpoch}_ocr_$i',
        amount: amount,
        category: finalCategory,
        title: description,
        date: DateTime.now(),
        isVoiceInput: false,
      )));

      dataStore.addItemToCategory(
        finalCategory,
        CategoryItem(
          name: description,
          quantity: 1,
          unitPrice: amount,
          date: DateTime.now(),
          source: 'ocr',
        ),
      );
    }

    // Refresh transactions after backend sync (AddExpense handles persistence)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) transactionBloc.add(const LoadTransactions());
    });

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Saved ${_items.length} item${_items.length > 1 ? 's' : ''} from receipt',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  double get _grandTotal =>
      _items.fold(0, (sum, item) => sum + (item['amount'] as num).toDouble());

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            _buildHeader(context),
            Flexible(child: _buildResultsView(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _navy.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.document_scanner_outlined, color: _navy, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review & save',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  '${_items.length} item${_items.length == 1 ? '' : 's'} from receipt',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, categoryState) {
        final categoryOptions = _categoryOptions(context.read<CategoryBloc>());

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Receipt details',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _receiptNoteController,
                maxLines: 2,
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _bg,
                  hintText: 'Store or receipt note…',
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _navy, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _navy.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _navy.withValues(alpha: 0.12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '${_grandTotal.toStringAsFixed(2)} EGP',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Items',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _buildItemCard(index, categoryOptions),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: _border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saveAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Save all',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemCard(int index, List<String> categoryOptions) {
    final item = _items[index];
    final category = item['category'] as String;
    final dropdownValue = _resolveDropdownValue(category, categoryOptions);

    if (_items[index]['category'] != dropdownValue) {
      _items[index]['category'] = dropdownValue;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _navy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getCategoryIcon(dropdownValue),
                  color: _navy,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: dropdownValue,
                  isExpanded: true,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: _bg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
                  items: categoryOptions
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _items[index]['category'] = v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(item['amount'] as num).toStringAsFixed(2)} EGP',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionControllers[index],
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155)),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: _bg,
              hintText: 'Item description',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => _items[index]['description'] = v,
          ),
        ],
      ),
    );
  }
}

Future<void> showOcrResultsDialog(
  BuildContext context, {
  required OcrInvoice invoice,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) => OcrResultsDialog(
      invoice: invoice,
      expenseBloc: context.read<ExpenseBloc>(),
      categoryBloc: context.read<CategoryBloc>(),
    ),
  );
}
