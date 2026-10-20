import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  int get itemCount {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  bool canIncreaseQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    return index >= 0 && _items[index].quantity < _items[index].product.stock;
  }

  double get deliveryFee => 5.99;

  void addToCart(Product product) {
    if (product.stock < 1) return;

    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      final item = _items[index];
      if (item.quantity >= product.stock) return;
      _items[index] = CartItem(product: product, quantity: item.quantity + 1);
    } else {
      _items.add(CartItem(product: product, quantity: 1));
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    final originalLength = _items.length;
    _items.removeWhere((item) => item.product.id == productId);
    if (_items.length == originalLength) return;
    notifyListeners();
  }

  void updateQuantity(String productId, int qty) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index < 0 || qty < 1) return;

    final item = _items[index];
    if (qty == item.quantity || qty > item.product.stock) return;

    _items[index] = CartItem(product: item.product, quantity: qty);
    notifyListeners();
  }

  void clearCart() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }
}
