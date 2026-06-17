import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import '../../../core/storage/simple_storage.dart';
import '../../../core/services/category_api_service.dart';
import '../../../core/services/auth_api_service.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class CategoryEvent {}

class LoadCategories extends CategoryEvent {}

class AddCategory extends CategoryEvent {
  final String name;
  final IconData icon;
  AddCategory({required this.name, required this.icon});
}

class DeleteCategory extends CategoryEvent {
  final String name;
  final String? backendId; // backend _id if available
  DeleteCategory(this.name, {this.backendId});
}

// ─── State ────────────────────────────────────────────────────────────────────

class CategoryState {
  final List<Map<String, dynamic>> customCategories;

  CategoryState({this.customCategories = const []});

  CategoryState copyWith({List<Map<String, dynamic>>? customCategories}) {
    return CategoryState(
      customCategories: customCategories ?? this.customCategories,
    );
  }
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  static const String _storageKey = 'custom_categories';
  final SimpleStorage _storage = SimpleStorage();
  final CategoryApiService _api = CategoryApiService.instance;

  CategoryBloc() : super(CategoryState()) {
    on<LoadCategories>(_onLoad);
    on<AddCategory>(_onAdd);
    on<DeleteCategory>(_onDelete);

    add(LoadCategories());
  }

  // ─── Icon persistence map ──────────────────────────────────────────────────

  static final Map<int, IconData> _iconMap = {
    Icons.restaurant.codePoint: Icons.restaurant,
    Icons.shopping_bag.codePoint: Icons.shopping_bag,
    Icons.receipt.codePoint: Icons.receipt,
    Icons.favorite.codePoint: Icons.favorite,
    Icons.directions_car.codePoint: Icons.directions_car,
    Icons.movie.codePoint: Icons.movie,
    Icons.school.codePoint: Icons.school,
    Icons.sports_esports.codePoint: Icons.sports_esports,
    Icons.pets.codePoint: Icons.pets,
    Icons.flight.codePoint: Icons.flight,
    Icons.home.codePoint: Icons.home,
    Icons.work.codePoint: Icons.work,
    Icons.fitness_center.codePoint: Icons.fitness_center,
    Icons.music_note.codePoint: Icons.music_note,
    Icons.book.codePoint: Icons.book,
    Icons.coffee.codePoint: Icons.coffee,
    Icons.local_gas_station.codePoint: Icons.local_gas_station,
    Icons.phone_android.codePoint: Icons.phone_android,
    Icons.wifi.codePoint: Icons.wifi,
    Icons.category.codePoint: Icons.category,
  };

  // ─── Local persistence ─────────────────────────────────────────────────────

  Future<void> _saveLocal(List<Map<String, dynamic>> categories) async {
    final jsonList = categories.map((cat) => {
          'name': cat['name'],
          'iconCode': (cat['icon'] as IconData).codePoint,
          'isDefault': cat['isDefault'] ?? false,
          'backendId': cat['backendId'], // persist backend _id
        }).toList();
    await _storage.write(_storageKey, jsonEncode(jsonList));
  }

  Future<List<Map<String, dynamic>>> _loadLocal() async {
    final jsonString = await _storage.read(_storageKey);
    if (jsonString == null || jsonString.isEmpty) return [];
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((item) {
      final iconCode = item['iconCode'] as int;
      return {
        'name': item['name'],
        'icon': _iconMap[iconCode] ?? Icons.category,
        'isDefault': item['isDefault'] ?? false,
        'backendId': item['backendId'],
      };
    }).toList();
  }

  // ─── Handlers ─────────────────────────────────────────────────────────────

  Future<void> _onLoad(
      LoadCategories event, Emitter<CategoryState> emit) async {
    final isLoggedIn = await AuthApiService.instance.isAuthenticated();

    if (isLoggedIn) {
      try {
        final result = await _api.getCategories();
        if (result.isSuccess) {
          final categories = result.categories
              .map((c) => {
                    'name': c.name,
                    'icon': _iconFromBackend(c.icon) ?? _iconForName(c.name),
                    'isDefault': c.isDefault,
                    'backendId': c.id,
                  })
              .toList();

          emit(state.copyWith(customCategories: categories));
          await _saveLocal(categories);
          print('✅ Loaded ${categories.length} categories from backend');
          return;
        }
      } catch (e) {
        print('⚠️ Backend category load failed, using local: $e');
      }
    }

    // Fallback to local
    final local = await _loadLocal();
    emit(state.copyWith(customCategories: local));
  }

  Future<void> _onAdd(AddCategory event, Emitter<CategoryState> emit) async {
    String? backendId;

    // Try to create on backend
    final isLoggedIn = await AuthApiService.instance.isAuthenticated();
    if (isLoggedIn) {
      try {
        final result = await _api.createCategory(
          name: event.name,
          icon: event.icon.codePoint.toString(),
          color: '#1976D2',
        );
        if (result.isSuccess && result.category != null) {
          backendId = result.category!.id;
          print('✅ Category created on backend: ${event.name} (id: $backendId)');
        } else {
          print('⚠️ Backend category create failed: ${result.message}');
        }
      } catch (e) {
        print('⚠️ Backend category create error: $e');
      }
    }

    final newCategory = {
      'name': event.name,
      'icon': event.icon,
      'isDefault': false,
      'backendId': backendId,
    };

    final updated = [...state.customCategories, newCategory];
    emit(state.copyWith(customCategories: updated));
    await _saveLocal(updated);
  }

  Future<void> _onDelete(
      DeleteCategory event, Emitter<CategoryState> emit) async {
    // Find the category to get its backendId
    final category = state.customCategories
        .where((c) => c['name'] == event.name)
        .firstOrNull;

    final backendId = event.backendId ?? category?['backendId'] as String?;

    // Delete from backend if we have an ID
    final isLoggedIn = await AuthApiService.instance.isAuthenticated();
    if (isLoggedIn && backendId != null) {
      try {
        final result = await _api.deleteCategory(backendId);
        if (result.isSuccess) {
          print('✅ Category deleted from backend: ${event.name}');
        } else {
          print('⚠️ Backend category delete failed: ${result.message}');
        }
      } catch (e) {
        print('⚠️ Backend category delete error: $e');
      }
    }

    final updated =
        state.customCategories.where((c) => c['name'] != event.name).toList();
    emit(state.copyWith(customCategories: updated));
    await _saveLocal(updated);
  }

  // ─── Helper ───────────────────────────────────────────────────────────────

  IconData? _iconFromBackend(String icon) {
    final code = int.tryParse(icon);
    if (code != null) return _iconMap[code];
    return null;
  }

  IconData _iconForName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('food') || lower.contains('طعام') || lower.contains('restaurant')) {
      return Icons.restaurant;
    }
    if (lower.contains('shop') || lower.contains('تسوق')) return Icons.shopping_bag;
    if (lower.contains('bill') || lower.contains('فواتير')) return Icons.receipt;
    if (lower.contains('health') || lower.contains('صحة')) return Icons.favorite;
    if (lower.contains('transport') || lower.contains('مواصلات')) {
      return Icons.directions_car;
    }
    if (lower.contains('entertain') || lower.contains('ترفيه')) return Icons.movie;
    if (lower.contains('school') || lower.contains('تعليم')) return Icons.school;
    if (lower.contains('travel') || lower.contains('سفر')) return Icons.flight;
    if (lower.contains('home') || lower.contains('منزل')) return Icons.home;
    if (lower.contains('work') || lower.contains('عمل')) return Icons.work;
    return Icons.category;
  }
}
