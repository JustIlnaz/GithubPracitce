import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/product_sort_option.dart';
import '../services/product_service.dart';
import '../utils/error_handler.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService;

  ProductProvider({ProductService? productService})
    : _productService = productService ?? ProductService();

  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  bool _isCategoriesLoading = false;
  String? _error;
  String? _categoriesError;
  String? _selectedCategoryId;
  String? _shopId;
  String _searchQuery = '';
  double? _minPrice;
  double? _maxPrice;
  ProductSortOption _sortOption = ProductSortOption.defaultOrder;
  bool _hasLoadedProducts = false;
  int _latestProductsRequestId = 0;
  int _latestCategoriesRequestId = 0;

  List<Product> get products => List.unmodifiable(_products);
  List<Product> get customerProducts =>
      List.unmodifiable(_products.where((product) => product.stock > 0));
  List<Category> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  bool get isCategoriesLoading => _isCategoriesLoading;
  String? get error => _error;
  String? get categoriesError => _categoriesError;
  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  ProductSortOption get sortOption => _sortOption;
  bool get hasActiveFilters =>
      _selectedCategoryId != null ||
      _minPrice != null ||
      _maxPrice != null ||
      _sortOption != ProductSortOption.defaultOrder;

  int get activeFilterCount {
    var count = 0;
    if (_selectedCategoryId != null) count++;
    if (_minPrice != null || _maxPrice != null) count++;
    if (_sortOption != ProductSortOption.defaultOrder) count++;
    return count;
  }

  Future<void> fetchProducts({
    String? categoryId,
    String? shopId,
    String? search,
  }) async {
    if (categoryId != null) _selectedCategoryId = categoryId;
    if (shopId != null) _shopId = shopId;
    if (search != null) _searchQuery = search.trim();
    await _loadProducts();
  }

  Future<bool> applyFilters({
    required String? categoryId,
    required double? minPrice,
    required double? maxPrice,
    required ProductSortOption sortOption,
  }) async {
    final validationError = validatePriceRange(minPrice, maxPrice);
    if (validationError != null) {
      return false;
    }

    final didChange =
        _selectedCategoryId != categoryId ||
        _minPrice != minPrice ||
        _maxPrice != maxPrice ||
        _sortOption != sortOption;
    if (!didChange &&
        (_isLoading || (_error == null && _hasLoadedProducts))) {
      return true;
    }

    _selectedCategoryId = categoryId;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _sortOption = sortOption;
    await _loadProducts();
    return true;
  }

  Future<void> selectCategory(String? categoryId) async {
    if (_selectedCategoryId == categoryId &&
        (_isLoading || (_error == null && _hasLoadedProducts))) {
      return;
    }
    _selectedCategoryId = categoryId;
    await _loadProducts();
  }

  Future<void> updateSearch(String query) async {
    final normalizedQuery = query.trim();
    if (_searchQuery == normalizedQuery &&
        (_isLoading || (_error == null && _hasLoadedProducts))) {
      return;
    }
    _searchQuery = normalizedQuery;
    await _loadProducts();
  }

  Future<void> resetFilters({bool keepSearch = true}) async {
    final didChange = hasActiveFilters || (!keepSearch && _searchQuery.isNotEmpty);
    _selectedCategoryId = null;
    _minPrice = null;
    _maxPrice = null;
    _sortOption = ProductSortOption.defaultOrder;
    if (!keepSearch) _searchQuery = '';
    if (didChange || (_error != null && !_isLoading) || !_hasLoadedProducts) {
      await _loadProducts();
    }
  }

  String? validatePriceRange(double? minPrice, double? maxPrice) {
    if ((minPrice != null && !minPrice.isFinite) ||
        (maxPrice != null && !maxPrice.isFinite)) {
      return 'Введите корректную цену';
    }
    if ((minPrice != null && minPrice < 0) ||
        (maxPrice != null && maxPrice < 0)) {
      return 'Цена не может быть отрицательной';
    }
    if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
      return 'Минимальная цена не может быть больше максимальной';
    }
    return null;
  }

  Future<void> _loadProducts() async {
    final requestId = ++_latestProductsRequestId;
    _isLoading = true;
    _error = null;
    _products = [];
    notifyListeners();

    try {
      final products = await _productService.getProducts(
        categoryId: _selectedCategoryId,
        shopId: _shopId,
        search: _searchQuery,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        sortOption: _sortOption,
      );
      if (requestId != _latestProductsRequestId) return;
      _products = products;
      _hasLoadedProducts = true;
    } catch (e) {
      if (requestId != _latestProductsRequestId) return;
      _hasLoadedProducts = false;
      _error = ErrorHandler.getFriendlyErrorMessage(e);
    } finally {
      if (requestId == _latestProductsRequestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchCategories({bool force = false}) async {
    if (!force && (_isCategoriesLoading || _categories.isNotEmpty)) return;
    final requestId = ++_latestCategoriesRequestId;
    _isCategoriesLoading = true;
    _categoriesError = null;
    notifyListeners();

    try {
      final categories = await _productService.getCategories();
      if (requestId != _latestCategoriesRequestId) return;
      _categories = categories;
    } catch (e) {
      if (requestId != _latestCategoriesRequestId) return;
      _categoriesError = ErrorHandler.getFriendlyErrorMessage(e);
    } finally {
      if (requestId == _latestCategoriesRequestId) {
        _isCategoriesLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> searchProducts(String query) async {
    await updateSearch(query);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _error = null;
    notifyListeners();
  }

  Future<void> createProduct(Map<String, dynamic> productData) async {
    _setLoading(true);
    try {
      final product = await _productService.createProduct(productData);
      _products.add(product);
    } catch (e) {
      _error = ErrorHandler.getFriendlyErrorMessage(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteProduct(String id) async {
    _setLoading(true);
    try {
      await _productService.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
    } catch (e) {
      _error = ErrorHandler.getFriendlyErrorMessage(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProduct(String id, Map<String, dynamic> productData) async {
    _setLoading(true);
    try {
      final updated = await _productService.updateProduct(id, productData);
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        _products[index] = updated;
      }
    } catch (e) {
      _error = ErrorHandler.getFriendlyErrorMessage(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void decreaseStockLocally(String id, int quantity) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      final currentStock = _products[index].stock;
      final updatedStock = (currentStock - quantity) < 0 ? 0 : (currentStock - quantity);
      
      _products[index] = Product(
        id: _products[index].id,
        name: _products[index].name,
        description: _products[index].description,
        imageUrl: _products[index].imageUrl,
        shopName: _products[index].shopName,
        categoryName: _products[index].categoryName,
        price: _products[index].price,
        discountPrice: _products[index].discountPrice,
        shopId: _products[index].shopId,
        categoryId: _products[index].categoryId,
        stock: updatedStock,
        rating: _products[index].rating,
        reviewCount: _products[index].reviewCount,
      );
      notifyListeners();
    }
  }

  void increaseStockLocally(String id, int quantity) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      final currentStock = _products[index].stock;
      final updatedStock = currentStock + quantity;
      
      _products[index] = Product(
        id: _products[index].id,
        name: _products[index].name,
        description: _products[index].description,
        imageUrl: _products[index].imageUrl,
        shopName: _products[index].shopName,
        categoryName: _products[index].categoryName,
        price: _products[index].price,
        discountPrice: _products[index].discountPrice,
        shopId: _products[index].shopId,
        categoryId: _products[index].categoryId,
        stock: updatedStock,
        rating: _products[index].rating,
        reviewCount: _products[index].reviewCount,
      );
      notifyListeners();
    }
  }
}
