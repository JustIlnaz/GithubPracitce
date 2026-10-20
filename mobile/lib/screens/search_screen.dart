import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import '../widgets/loading_state.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/catalog_filters.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      _searchController.text = provider.searchQuery;
      provider.fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    Provider.of<ProductProvider>(
      context,
      listen: false,
    ).updateSearch(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Поиск товаров...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
            filled: false,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _onSearch();
              },
            ),
          ),
          onSubmitted: (_) => _onSearch(),
        ),
        actions: [
          CatalogFilterButton(
            activeFilterCount: provider.activeFilterCount,
            compact: true,
            onPressed: () => CatalogFilterSheet.show(context),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                _buildFilterChip(
                  'Все',
                  null,
                  provider.selectedCategoryId == null,
                ),
                if (provider.categories.isNotEmpty)
                  ...provider.categories.map((cat) {
                    return _buildFilterChip(
                      cat.displayName,
                      cat.id,
                      provider.selectedCategoryId == cat.id,
                    );
                  }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ActiveCatalogFilters(provider: provider),
            ),
          ),
          Expanded(
            child: _buildContent(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? categoryId, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          Provider.of<ProductProvider>(
            context,
            listen: false,
          ).selectCategory(categoryId);
        },
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        selectedColor: Theme.of(context).colorScheme.primaryContainer,
        labelStyle: TextStyle(color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurface),
      ),
    );
  }

  Widget _buildContent(ProductProvider provider) {
    if (provider.isLoading) {
      return const LoadingState();
    } else if (provider.error != null) {
      return ErrorState(message: provider.error!, onRetry: () => _onSearch());
    } else if (provider.customerProducts.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        message: 'По выбранным условиям товары не найдены',
        actionLabel: provider.hasActiveFilters ? 'Сбросить фильтры' : null,
        onAction: provider.hasActiveFilters ? provider.resetFilters : null,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: provider.customerProducts.length,
      itemBuilder: (context, index) {
        final product = provider.customerProducts[index];
        return ProductCard(
          product: product,
          onTap: () => Navigator.pushNamed(context, '/product', arguments: product),
        );
      },
    );
  }
}
