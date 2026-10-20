import 'api_client.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/product_sort_option.dart';

class ProductService {
  final ApiClient _apiClient;

  ProductService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<Product>> getProducts({
    String? search,
    String? categoryId,
    String? shopId,
    double? minPrice,
    double? maxPrice,
    ProductSortOption sortOption = ProductSortOption.defaultOrder,
    int? skip,
    int? take,
  }) async {
    final Map<String, dynamic> queryParams = {};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (categoryId != null) queryParams['categoryId'] = categoryId;
    if (shopId != null) queryParams['shopId'] = shopId;
    if (minPrice != null) queryParams['minPrice'] = minPrice;
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice;
    if (sortOption.apiValue != null) {
      queryParams['sortBy'] = sortOption.apiValue;
    }
    if (skip != null) queryParams['skip'] = skip;
    if (take != null) queryParams['take'] = take;

    final response = await _apiClient.dio.get(
      '/products',
      queryParameters: queryParams,
    );
    return (response.data['data'] as List)
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Product> getProductById(String id) async {
    final response = await _apiClient.dio.get('/products/$id');
    return Product.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<Category>> getCategories() async {
    final response = await _apiClient.dio.get('/categories');
    return (response.data['data'] as List)
        .map((json) => Category.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Product> createProduct(Map<String, dynamic> productData) async {
    final response = await _apiClient.dio.post('/products', data: productData);
    return Product.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Product> updateProduct(String id, Map<String, dynamic> productData) async {
    final response = await _apiClient.dio.put('/products/$id', data: productData);
    return Product.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteProduct(String id) async {
    await _apiClient.dio.delete('/products/$id');
  }
}
