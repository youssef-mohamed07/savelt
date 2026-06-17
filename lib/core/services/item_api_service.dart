import 'api_service.dart';
import '../models/item_model.dart';

class ItemApiService {
  static final ItemApiService instance = ItemApiService._internal();
  ItemApiService._internal();
  factory ItemApiService() => instance;

  final ApiService _api = ApiService();

  Future<ItemListResult> getItems({
    int page = 1,
    int limit = 10,
    String? search,
    String? categoryId,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'category': categoryId,
    };

    final response = await _api.get('/items', queryParams: queryParams);

    if (response.isSuccess) {
      final dataList = response.getData<List>('data') ?? [];
      final meta = response.getData<Map<String, dynamic>>('meta');
      final count = response.getData<int>('count') ?? 0;

      final items = dataList
          .map((item) => ItemModel.fromMap(item as Map<String, dynamic>))
          .toList();

      return ItemListResult.success(
        items: items,
        totalCount: count,
        currentPage: meta?['page'] ?? page,
        totalPages: meta?['totalPages'] ?? 1,
      );
    }

    return ItemListResult.failure(message: response.message ?? 'Failed to get items');
  }

  Future<ItemApiResult> createItem({
    required String name,
    required String categoryId,
    double? price,
    String? description,
  }) async {
    final response = await _api.post('/items', body: {
      'name': name,
      if (categoryId != null) 'categoryId': categoryId,
      if (price != null) 'price': price,
      if (description != null) 'description': description,
    });

    if (response.isSuccess) {
      final data = response.getData<Map<String, dynamic>>('data');
      if (data != null) {
        return ItemApiResult.success(
          item: ItemModel.fromMap(data),
          message: 'Item created',
        );
      }
    }

    return ItemApiResult.failure(message: response.message ?? 'Failed to create item');
  }

  Future<ItemApiResult> updateItem({
    required String id,
    String? name,
    String? categoryId,
    double? price,
    String? description,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (categoryId != null) body['category'] = categoryId;
    if (price != null) body['price'] = price;
    if (description != null) body['description'] = description;

    final response = await _api.put('/items/$id', body: body);

    if (response.isSuccess) {
      final data = response.getData<Map<String, dynamic>>('data');
      if (data != null) {
        return ItemApiResult.success(
          item: ItemModel.fromMap(data),
          message: 'Item updated',
        );
      }
    }

    return ItemApiResult.failure(message: response.message ?? 'Failed to update item');
  }

  Future<ItemApiResult> deleteItem(String id) async {
    final response = await _api.delete('/items/$id');

    if (response.isSuccess) {
      return ItemApiResult.success(message: 'Item deleted');
    }

    return ItemApiResult.failure(message: response.message ?? 'Failed to delete item');
  }

  Future<ItemApiResult> getItem(String id) async {
    final response = await _api.get('/items/$id');

    if (response.isSuccess) {
      final data = response.getData<Map<String, dynamic>>('data') ?? response.data;
      if (data != null) {
        return ItemApiResult.success(item: ItemModel.fromMap(data));
      }
    }

    return ItemApiResult.failure(message: response.message ?? 'Item not found');
  }
}

class ItemApiResult {
  final bool isSuccess;
  final ItemModel? item;
  final String? message;

  ItemApiResult._({
    required this.isSuccess,
    this.item,
    this.message,
  });

  factory ItemApiResult.success({
    ItemModel? item,
    String? message,
  }) {
    return ItemApiResult._(
      isSuccess: true,
      item: item,
      message: message,
    );
  }

  factory ItemApiResult.failure({required String message}) {
    return ItemApiResult._(
      isSuccess: false,
      message: message,
    );
  }
}

class ItemListResult {
  final bool isSuccess;
  final List<ItemModel> items;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final String? message;

  ItemListResult._({
    required this.isSuccess,
    this.items = const [],
    this.totalCount = 0,
    this.currentPage = 1,
    this.totalPages = 1,
    this.message,
  });

  factory ItemListResult.success({
    required List<ItemModel> items,
    required int totalCount,
    required int currentPage,
    required int totalPages,
  }) {
    return ItemListResult._(
      isSuccess: true,
      items: items,
      totalCount: totalCount,
      currentPage: currentPage,
      totalPages: totalPages,
    );
  }

  factory ItemListResult.failure({required String message}) {
    return ItemListResult._(
      isSuccess: false,
      message: message,
    );
  }
}