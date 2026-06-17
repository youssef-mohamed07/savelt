import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Item Model for persistence
class CategoryItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final DateTime date;
  final String source; // 'manual', 'voice', 'ocr'

  CategoryItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.date,
    this.source = 'manual',
  });

  double get totalPrice => quantity * unitPrice;
}

/// Category Model for persistence
class CategoryData {
  final String name;
  final IconData icon;
  final Color color;
  double totalAmount;
  final List<CategoryItem> items;
  final bool isMain;

  CategoryData({
    required this.name,
    required this.icon,
    this.color = const Color(0xFF1976D2),
    this.totalAmount = 0,
    List<CategoryItem>? items,
    this.isMain = false,
  }) : items = items ?? [];

  void addItem(CategoryItem item) {
    items.add(item);
    totalAmount += item.totalPrice;
  }

  void removeItem(int index) {
    if (index >= 0 && index < items.length) {
      totalAmount -= items[index].totalPrice;
      items.removeAt(index);
    }
  }

  void recalculateTotal() {
    totalAmount = items.fold(0, (sum, item) => sum + item.totalPrice);
  }
}

/// Singleton data store for category persistence
class CategoryDataStore {
  static final CategoryDataStore _instance = CategoryDataStore._internal();
  factory CategoryDataStore() => _instance;
  
  bool _initialized = false;
  bool get isInitialized => _initialized;
  
  CategoryDataStore._internal() {
    _loadData().then((_) => _initialized = true);
  }

  Future<void> ensureInitialized() async {
    if (!_initialized) {
      await _loadData();
      _initialized = true;
    }
  }

  final List<CategoryData> _mainCategories = [];
  final List<CategoryData> _customCategories = [];

  List<CategoryData> get mainCategories => _mainCategories;
  List<CategoryData> get customCategories => _customCategories;
  List<CategoryData> get allCategories => [..._mainCategories, ..._customCategories];

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load main categories
    final mainCatsJson = prefs.getString('main_categories');
    if (mainCatsJson != null) {
      final List<dynamic> decoded = jsonDecode(mainCatsJson);
      _mainCategories.clear();
      for (var catData in decoded) {
        _mainCategories.add(_categoryFromJson(catData));
      }
    }
    // No hardcoded defaults — categories come from backend via CategoryBloc / expenses
    
    // Load custom categories
    final customCatsJson = prefs.getString('custom_categories');
    if (customCatsJson != null) {
      final List<dynamic> decoded = jsonDecode(customCatsJson);
      _customCategories.clear();
      for (var catData in decoded) {
        _customCategories.add(_categoryFromJson(catData));
      }
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save main categories
    final mainCatsJson = jsonEncode(_mainCategories.map((c) => _categoryToJson(c)).toList());
    await prefs.setString('main_categories', mainCatsJson);
    
    // Save custom categories
    final customCatsJson = jsonEncode(_customCategories.map((c) => _categoryToJson(c)).toList());
    await prefs.setString('custom_categories', customCatsJson);
  }

  Map<String, dynamic> _categoryToJson(CategoryData cat) {
    return {
      'name': cat.name,
      'icon': cat.icon.codePoint,
      'color': cat.color.value,
      'totalAmount': cat.totalAmount,
      'isMain': cat.isMain,
      'items': cat.items.map((item) => {
        'name': item.name,
        'quantity': item.quantity,
        'unitPrice': item.unitPrice,
        'date': item.date.toIso8601String(),
        'source': item.source,
      }).toList(),
    };
  }

  CategoryData _categoryFromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List?)?.map((itemData) {
      return CategoryItem(
        name: itemData['name'],
        quantity: itemData['quantity'],
        unitPrice: itemData['unitPrice'],
        date: DateTime.parse(itemData['date']),
        source: itemData['source'] ?? 'manual',
      );
    }).toList() ?? [];
    
    return CategoryData(
      name: json['name'],
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      color: Color(json['color']),
      totalAmount: json['totalAmount'] ?? 0,
      items: items,
      isMain: json['isMain'] ?? false,
    );
  }

  void addCustomCategory(CategoryData category) {
    _customCategories.add(category);
    _saveData();
  }

  void removeCustomCategory(int index) {
    if (index >= 0 && index < _customCategories.length) {
      _customCategories.removeAt(index);
      _saveData();
    }
  }

  CategoryData? findCategory(String name) {
    for (var cat in _mainCategories) {
      if (cat.name == name) return cat;
    }
    for (var cat in _customCategories) {
      if (cat.name == name) return cat;
    }
    return null;
  }

  void addItemToCategory(String categoryName, CategoryItem item) {
    final category = findCategory(categoryName);
    category?.addItem(item);
    _saveData();
  }

  void removeItemFromCategory(String categoryName, int itemIndex) {
    final category = findCategory(categoryName);
    category?.removeItem(itemIndex);
    _saveData();
  }
}
