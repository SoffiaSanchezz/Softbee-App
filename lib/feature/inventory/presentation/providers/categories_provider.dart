import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/category_local_datasource.dart';
import '../../domain/entities/inventory_category.dart';

/// Estado de las categorías de inventario.
class CategoriesState {
  final List<InventoryCategory> categories;
  final bool isLoading;

  const CategoriesState({this.categories = const [], this.isLoading = true});

  CategoriesState copyWith({
    List<InventoryCategory>? categories,
    bool? isLoading,
  }) {
    return CategoriesState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Busca una categoría por nombre (case-insensitive).
  InventoryCategory? findByName(String? name) {
    if (name == null) return null;
    final target = name.trim().toLowerCase();
    for (final c in categories) {
      if (c.name.trim().toLowerCase() == target) return c;
    }
    return null;
  }
}

class CategoriesController extends StateNotifier<CategoriesState> {
  final CategoryLocalDataSource _dataSource;

  CategoriesController(this._dataSource) : super(const CategoriesState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final categories = await _dataSource.getCategories();
    state = state.copyWith(categories: categories, isLoading: false);
  }

  Future<void> addCategory({
    required String name,
    required String iconKey,
    required int colorValue,
  }) async {
    final category = InventoryCategory(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      iconKey: iconKey,
      colorValue: colorValue,
    );
    final updated = [...state.categories, category];
    await _persist(updated);
  }

  Future<void> updateCategory(InventoryCategory category) async {
    final updated = state.categories
        .map((c) => c.id == category.id ? category : c)
        .toList();
    await _persist(updated);
  }

  Future<void> deleteCategory(String id) async {
    final updated = state.categories.where((c) => c.id != id).toList();
    await _persist(updated);
  }

  Future<void> _persist(List<InventoryCategory> categories) async {
    state = state.copyWith(categories: categories);
    await _dataSource.saveCategories(categories);
  }

  /// Resuelve el icono de una categoría por su nombre (para tarjetas/listados).
  IconData iconForName(String? name) =>
      state.findByName(name)?.icon ?? CategoryIcons.fallback;

  /// Resuelve el color de una categoría por su nombre.
  Color colorForName(String? name, {Color fallback = const Color(0xFFF5A623)}) =>
      state.findByName(name)?.color ?? fallback;
}

final categoryLocalDataSourceProvider = Provider<CategoryLocalDataSource>(
  (ref) => CategoryLocalDataSource(),
);

final categoriesProvider =
    StateNotifierProvider<CategoriesController, CategoriesState>((ref) {
  return CategoriesController(ref.read(categoryLocalDataSourceProvider));
});
