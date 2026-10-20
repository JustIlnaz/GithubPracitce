enum ProductSortOption {
  defaultOrder,
  priceAscending,
  priceDescending,
  ratingDescending,
  popularityDescending,
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
      case ProductSortOption.popularityDescending:
        return 'popularity';
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
      case ProductSortOption.popularityDescending:
        return 'По популярности';
    }
  }
}
