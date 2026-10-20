enum ProductSortOption {
  defaultOrder,
  priceAscending,
  priceDescending,
  ratingDescending,
}

extension ProductSortOptionDetails on ProductSortOption {
  String? get apiValue {
    switch (this) {
      case ProductSortOption.defaultOrder:
        return null;
      case ProductSortOption.priceAscending:
        return 'price_asc';
      case ProductSortOption.priceDescending:
        return 'price_desc';
      case ProductSortOption.ratingDescending:
        return 'rating';
    }
  }

  String get label {
    switch (this) {
      case ProductSortOption.defaultOrder:
        return 'По умолчанию';
      case ProductSortOption.priceAscending:
        return 'Сначала дешёвые';
      case ProductSortOption.priceDescending:
        return 'Сначала дорогие';
      case ProductSortOption.ratingDescending:
        return 'По рейтингу';
    }
  }
}
