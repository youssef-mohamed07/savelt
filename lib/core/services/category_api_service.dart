import 'api_service.dart';
import '../models/category_model.dart';

class CategoryApiService {
  static final CategoryApiService instance = CategoryApiService._internal();
  CategoryApiService._internal();
  factory CategoryApiService() => instance;

  final ApiService _api = ApiService();

  Future<CategoryListResult> getCategories() async {
    final response = await _api.get('/category');

    if (response.isSuccess) {
      final dataList = response.getData<List>('data') ?? [];
      final categories = dataList
          .map((item) => CategoryModel.fromMap(item as Map<String, dynamic>))
          .toList();

      return CategoryListResult.success(categories: categories);
    }

    return CategoryListResult.failure(message: response.message ?? 'Failed to get categories');
  }

  Future<CategoryApiResult> createCategory({
    required String name,
    required String icon,
    required String color,
  }) async {
    final response = await _api.post('/category', body: {
      'name': name,
      'icon': icon,
      'color': color,
    });

    if (response.isSuccess) {
      final data = response.getData<Map<String, dynamic>>('data');
      if (data != null) {
        return CategoryApiResult.success(
          category: CategoryModel.fromMap(data),
          message: 'Category created',
        );
      }
    }

    return CategoryApiResult.failure(message: response.message ?? 'Failed to create category');
  }

  Future<CategoryApiResult> updateCategory({
    required String id,
    String? name,
    String? icon,
    String? color,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (icon != null) body['icon'] = icon;
    if (color != null) body['color'] = color;

    final response = await _api.put('/category/$id', body: body);

    if (response.isSuccess) {
      final data = response.getData<Map<String, dynamic>>('data');
      if (data != null) {
        return CategoryApiResult.success(
          category: CategoryModel.fromMap(data),
          message: 'Category updated',
        );
      }
    }

    return CategoryApiResult.failure(message: response.message ?? 'Failed to update category');
  }

  Future<CategoryApiResult> deleteCategory(String id) async {
    final response = await _api.delete('/category/$id');

    if (response.isSuccess) {
      return CategoryApiResult.success(message: 'Category deleted');
    }

    return CategoryApiResult.failure(message: response.message ?? 'Failed to delete category');
  }
}

class CategoryApiResult {
  final bool isSuccess;
  final CategoryModel? category;
  final String? message;

  CategoryApiResult._({
    required this.isSuccess,
    this.category,
    this.message,
  });

  factory CategoryApiResult.success({
    CategoryModel? category,
    String? message,
  }) {
    return CategoryApiResult._(
      isSuccess: true,
      category: category,
      message: message,
    );
  }

  factory CategoryApiResult.failure({required String message}) {
    return CategoryApiResult._(
      isSuccess: false,
      message: message,
    );
  }
}

class CategoryListResult {
  final bool isSuccess;
  final List<CategoryModel> categories;
  final String? message;

  CategoryListResult._({
    required this.isSuccess,
    this.categories = const [],
    this.message,
  });

  factory CategoryListResult.success({required List<CategoryModel> categories}) {
    return CategoryListResult._(
      isSuccess: true,
      categories: categories,
    );
  }

  factory CategoryListResult.failure({required String message}) {
    return CategoryListResult._(
      isSuccess: false,
      message: message,
    );
  }
}