import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pawora/models/category.dart';
import 'package:pawora/models/product.dart';
import 'package:pawora/models/product_sort_option.dart';
import 'package:pawora/providers/product_provider.dart';
import 'package:pawora/services/product_service.dart';

void main() {
  group('ProductProvider filters', () {
    test('passes category filter to the service', () async {
      final service = FakeProductService();
      final provider = ProductProvider(productService: service);

      await provider.selectCategory('food-id');

      expect(provider.selectedCategoryId, 'food-id');
      expect(service.requests.single.categoryId, 'food-id');
    });

    test('passes minimum price to the service', () async {
      final service = FakeProductService();
      final provider = ProductProvider(productService: service);

      await provider.applyFilters(
        categoryId: null,
        minPrice: 100,
        maxPrice: null,
        sortOption: ProductSortOption.defaultOrder,
      );

      expect(service.requests.single.minPrice, 100);
      expect(service.requests.single.maxPrice, isNull);
    });

    test('passes maximum price to the service', () async {
      final service = FakeProductService();
      final provider = ProductProvider(productService: service);

      await provider.applyFilters(
        categoryId: null,
        minPrice: null,
        maxPrice: 500,
        sortOption: ProductSortOption.defaultOrder,
      );

      expect(service.requests.single.minPrice, isNull);
      expect(service.requests.single.maxPrice, 500);
    });

    test('combines filters, sorting and existing search', () async {
      final service = FakeProductService();
      final provider = ProductProvider(productService: service);
      await provider.updateSearch('корм');

      await provider.applyFilters(
        categoryId: 'food-id',
        minPrice: 100,
        maxPrice: 500,
        sortOption: ProductSortOption.priceAscending,
      );

      final request = service.requests.last;
      expect(request.search, 'корм');
      expect(request.categoryId, 'food-id');
      expect(request.minPrice, 100);
      expect(request.maxPrice, 500);
      expect(request.sortOption, ProductSortOption.priceAscending);
    });

    test('forwards every supported sort option', () async {
      final service = FakeProductService();
      final provider = ProductProvider(productService: service);

      for (final option in ProductSortOption.values.skip(1)) {
        await provider.applyFilters(
          categoryId: null,
          minPrice: null,
          maxPrice: null,
          sortOption: option,
        );
        expect(service.requests.last.sortOption, option);
      }
    });

    test('reset keeps search and clears all catalog filters', () async {
      final service = FakeProductService();
      final provider = ProductProvider(productService: service);
      await provider.updateSearch('игрушка');
      await provider.applyFilters(
        categoryId: 'toys-id',
        minPrice: 10,
        maxPrice: 20,
        sortOption: ProductSortOption.ratingDescending,
      );

      await provider.resetFilters();

      expect(provider.searchQuery, 'игрушка');
      expect(provider.selectedCategoryId, isNull);
      expect(provider.minPrice, isNull);
      expect(provider.maxPrice, isNull);
      expect(provider.sortOption, ProductSortOption.defaultOrder);
      expect(service.requests.last.search, 'игрушка');
    });

    test('rejects invalid range without changing state or loading', () async {
      final service = FakeProductService();
      final provider = ProductProvider(productService: service);

      final wasApplied = await provider.applyFilters(
        categoryId: 'food-id',
        minPrice: 200,
        maxPrice: 100,
        sortOption: ProductSortOption.priceDescending,
      );

      expect(wasApplied, isFalse);
      expect(provider.hasActiveFilters, isFalse);
      expect(service.requests, isEmpty);
      expect(
        provider.validatePriceRange(-1, null),
        'Цена не может быть отрицательной',
      );
    });

    test('does not repeat an identical request after an empty result', () async {
      final service = FakeProductService();
      final provider = ProductProvider(productService: service);

      await provider.applyFilters(
        categoryId: 'empty-category',
        minPrice: null,
        maxPrice: null,
        sortOption: ProductSortOption.defaultOrder,
      );
      await provider.applyFilters(
        categoryId: 'empty-category',
        minPrice: null,
        maxPrice: null,
        sortOption: ProductSortOption.defaultOrder,
      );

      expect(provider.products, isEmpty);
      expect(service.requests, hasLength(1));
    });

    test('exposes a loading error and clears loading state', () async {
      final service = FakeProductService()..error = StateError('load failed');
      final provider = ProductProvider(productService: service);

      await provider.fetchProducts();

      expect(provider.isLoading, isFalse);
      expect(provider.error, contains('load failed'));
      expect(provider.products, isEmpty);
    });

    test('ignores a stale response from an older request', () async {
      final service = FakeProductService()..useCompleters = true;
      final provider = ProductProvider(productService: service);

      final oldRequest = provider.updateSearch('old');
      final newRequest = provider.updateSearch('new');
      service.completers[1].complete([product('new-product')]);
      await newRequest;
      service.completers[0].complete([product('old-product')]);
      await oldRequest;

      expect(provider.products.single.id, 'new-product');
      expect(provider.searchQuery, 'new');
    });
  });
}

Product product(String id) {
  return Product(
    id: id,
    name: id,
    price: 100,
    stock: 1,
    rating: 4,
    reviewCount: 1,
  );
}

class ProductRequest {
  final String? search;
  final String? categoryId;
  final double? minPrice;
  final double? maxPrice;
  final ProductSortOption sortOption;

  ProductRequest({
    required this.search,
    required this.categoryId,
    required this.minPrice,
    required this.maxPrice,
    required this.sortOption,
  });
}

class FakeProductService extends ProductService {
  final List<ProductRequest> requests = [];
  final List<Completer<List<Product>>> completers = [];
  List<Product> response = [];
  Object? error;
  bool useCompleters = false;

  @override
  Future<List<Product>> getProducts({
    String? search,
    String? categoryId,
    String? shopId,
    double? minPrice,
    double? maxPrice,
    ProductSortOption sortOption = ProductSortOption.defaultOrder,
    int? skip,
    int? take,
  }) {
    requests.add(
      ProductRequest(
        search: search,
        categoryId: categoryId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        sortOption: sortOption,
      ),
    );
    if (error != null) return Future.error(error!);
    if (useCompleters) {
      final completer = Completer<List<Product>>();
      completers.add(completer);
      return completer.future;
    }
    return Future.value(response);
  }

  @override
  Future<List<Category>> getCategories() async => [];
}
