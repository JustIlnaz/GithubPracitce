import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_sort_option.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';

class CatalogFilterButton extends StatelessWidget {
  final int activeFilterCount;
  final VoidCallback onPressed;
  final bool compact;

  const CatalogFilterButton({
    super.key,
    required this.activeFilterCount,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.tune),
        if (activeFilterCount > 0)
          Positioned(
            top: -7,
            right: -9,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(
                '$activeFilterCount',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onError,
                  fontSize: 10,
                ),
              ),
            ),
          ),
      ],
    );

    if (compact) {
      return IconButton(
        tooltip: 'Фильтры и сортировка',
        onPressed: onPressed,
        icon: icon,
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: const Text('Фильтры'),
    );
  }
}

class ActiveCatalogFilters extends StatelessWidget {
  final ProductProvider provider;

  const ActiveCatalogFilters({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (!provider.hasActiveFilters) return const SizedBox.shrink();

    final matchingCategories = provider.categories.where(
      (category) => category.id == provider.selectedCategoryId,
    );
    final selectedCategory = matchingCategories.isEmpty
        ? null
        : matchingCategories.first;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          if (selectedCategory != null)
            InputChip(
              label: Text(selectedCategory.displayName),
              onDeleted: () => provider.selectCategory(null),
            ),
          if (provider.minPrice != null || provider.maxPrice != null)
            InputChip(
              label: Text(_priceLabel(provider.minPrice, provider.maxPrice)),
              onDeleted: () => provider.applyFilters(
                categoryId: provider.selectedCategoryId,
                minPrice: null,
                maxPrice: null,
                sortOption: provider.sortOption,
              ),
            ),
          if (provider.sortOption != ProductSortOption.defaultOrder)
            InputChip(
              label: Text(provider.sortOption.label),
              onDeleted: () => provider.applyFilters(
                categoryId: provider.selectedCategoryId,
                minPrice: provider.minPrice,
                maxPrice: provider.maxPrice,
                sortOption: ProductSortOption.defaultOrder,
              ),
            ),
        ],
      ),
    );
  }

  String _priceLabel(double? minPrice, double? maxPrice) {
    if (minPrice != null && maxPrice != null) {
      return '${_formatPrice(minPrice)}–${_formatPrice(maxPrice)} ₽';
    }
    if (minPrice != null) return 'От ${_formatPrice(minPrice)} ₽';
    return 'До ${_formatPrice(maxPrice!)} ₽';
  }

  String _formatPrice(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }
}

class CatalogFilterSheet extends StatefulWidget {
  const CatalogFilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const CatalogFilterSheet(),
    );
  }

  @override
  State<CatalogFilterSheet> createState() => _CatalogFilterSheetState();
}

class _CatalogFilterSheetState extends State<CatalogFilterSheet> {
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;
  String? _selectedCategoryId;
  late ProductSortOption _sortOption;
  String? _minPriceError;
  String? _maxPriceError;
  String? _rangeError;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ProductProvider>();
    _selectedCategoryId = provider.selectedCategoryId;
    _sortOption = provider.sortOption;
    _minPriceController = TextEditingController(
      text: _formatInitialPrice(provider.minPrice),
    );
    _maxPriceController = TextEditingController(
      text: _formatInitialPrice(provider.maxPrice),
    );
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Фильтры и сортировка',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Закрыть',
                  onPressed: _isApplying
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (provider.categoriesError != null) ...[
              Text(
                provider.categoriesError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: provider.isCategoriesLoading
                      ? null
                      : () => provider.fetchCategories(force: true),
                  child: const Text('Повторить загрузку категорий'),
                ),
              ),
            ] else
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Категория'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Все категории'),
                  ),
                  ...provider.categories.map(
                    (category) => DropdownMenuItem<String>(
                      value: category.id,
                      child: Text(category.displayName),
                    ),
                  ),
                ],
                onChanged: _isApplying
                    ? null
                    : (value) => setState(() => _selectedCategoryId = value),
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceController,
                    enabled: !_isApplying,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Цена от',
                      suffixText: '₽',
                      errorText: _minPriceError,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _maxPriceController,
                    enabled: !_isApplying,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Цена до',
                      suffixText: '₽',
                      errorText: _maxPriceError,
                    ),
                  ),
                ),
              ],
            ),
            if (_rangeError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _rangeError!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<ProductSortOption>(
              initialValue: _sortOption,
              decoration: const InputDecoration(labelText: 'Сортировка'),
              items: ProductSortOption.values
                  .map(
                    (option) => DropdownMenuItem<ProductSortOption>(
                      value: option,
                      child: Text(option.label),
                    ),
                  )
                  .toList(),
              onChanged: _isApplying
                  ? null
                  : (value) {
                      if (value != null) setState(() => _sortOption = value);
                    },
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _isApplying ? null : _apply,
              child: _isApplying
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Применить'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: _isApplying ? null : _reset,
              child: const Text('Сбросить фильтры'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _apply() async {
    final minPrice = _parsePrice(_minPriceController.text);
    final maxPrice = _parsePrice(_maxPriceController.text);
    final minError = _priceError(_minPriceController.text, minPrice);
    final maxError = _priceError(_maxPriceController.text, maxPrice);
    final rangeError = minError == null && maxError == null
        ? context.read<ProductProvider>().validatePriceRange(minPrice, maxPrice)
        : null;

    setState(() {
      _minPriceError = minError;
      _maxPriceError = maxError;
      _rangeError = rangeError;
    });
    if (minError != null || maxError != null || rangeError != null) return;

    setState(() => _isApplying = true);
    await context.read<ProductProvider>().applyFilters(
      categoryId: _selectedCategoryId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      sortOption: _sortOption,
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _reset() async {
    setState(() => _isApplying = true);
    await context.read<ProductProvider>().resetFilters();
    if (mounted) Navigator.of(context).pop();
  }

  double? _parsePrice(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  String? _priceError(String source, double? value) {
    if (source.trim().isEmpty) return null;
    if (value == null || !value.isFinite) return 'Введите число';
    if (value < 0) return 'Не меньше 0';
    return null;
  }

  String _formatInitialPrice(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }
}
