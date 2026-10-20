import 'package:flutter_test/flutter_test.dart';
import 'package:pawora/models/product.dart';
import 'package:pawora/providers/cart_provider.dart';

void main() {
  group('CartProvider', () {
    late CartProvider cartProvider;

    setUp(() {
      cartProvider = CartProvider();
    });

    test('starts empty with zero total and item count', () {
      expect(cartProvider.items, isEmpty);
      expect(cartProvider.totalAmount, 0);
      expect(cartProvider.itemCount, 0);
    });

    test('merges repeated products and uses the discounted price', () {
      final product = createProduct(
        id: 'food',
        price: 250,
        discountPrice: 200,
        stock: 3,
      );

      cartProvider.addToCart(product);
      cartProvider.addToCart(product);

      expect(cartProvider.items, hasLength(1));
      expect(cartProvider.items.single.quantity, 2);
      expect(cartProvider.items.single.unitPrice, 200);
      expect(cartProvider.items.single.totalPrice, 400);
      expect(cartProvider.totalAmount, 400);
      expect(cartProvider.itemCount, 2);
    });

    test('does not exceed available stock when adding or setting quantity', () {
      final product = createProduct(id: 'toy', price: 50, stock: 2);

      cartProvider.addToCart(product);
      cartProvider.addToCart(product);
      cartProvider.addToCart(product);
      cartProvider.updateQuantity(product.id, 3);

      expect(cartProvider.items.single.quantity, 2);
      expect(cartProvider.canIncreaseQuantity(product.id), isFalse);
      expect(cartProvider.totalAmount, 100);
    });

    test(
      'updates only the selected item and recalculates totals and counts',
      () {
        final food = createProduct(id: 'food', price: 10, stock: 5);
        final toy = createProduct(id: 'toy', price: 7, stock: 5);
        cartProvider.addToCart(food);
        cartProvider.addToCart(toy);

        cartProvider.updateQuantity(food.id, 3);

        expect(cartProvider.items.map((item) => item.quantity), [3, 1]);
        expect(cartProvider.items.first.totalPrice, 30);
        expect(cartProvider.totalAmount, 37);
        expect(cartProvider.itemCount, 4);
      },
    );

    test(
      'keeps quantity at one for zero or negative updates and notifies once per change',
      () {
        final product = createProduct(id: 'food', price: 10, stock: 5);
        var notifications = 0;
        cartProvider.addListener(() => notifications++);
        cartProvider.addToCart(product);
        notifications = 0;

        cartProvider.updateQuantity(product.id, 0);
        cartProvider.updateQuantity(product.id, -1);
        cartProvider.updateQuantity(product.id, 1);

        expect(cartProvider.items.single.quantity, 1);
        expect(cartProvider.items, hasLength(1));
        expect(notifications, 0);

        cartProvider.updateQuantity(product.id, 2);
        expect(notifications, 1);
        expect(cartProvider.totalAmount, 20);
      },
    );

    test(
      'removes one item and resets totals when the last item is removed',
      () {
        final food = createProduct(id: 'food', price: 10, stock: 5);
        final toy = createProduct(id: 'toy', price: 7, stock: 5);
        cartProvider.addToCart(food);
        cartProvider.addToCart(toy);

        cartProvider.removeFromCart(food.id);
        expect(cartProvider.items.map((item) => item.product.id), ['toy']);
        expect(cartProvider.totalAmount, 7);
        expect(cartProvider.itemCount, 1);

        cartProvider.removeFromCart(toy.id);
        expect(cartProvider.items, isEmpty);
        expect(cartProvider.totalAmount, 0);
        expect(cartProvider.itemCount, 0);
      },
    );

    test('does not add unavailable products or notify for missing items', () {
      var notifications = 0;
      cartProvider.addListener(() => notifications++);

      cartProvider.addToCart(
        createProduct(id: 'unavailable', price: 10, stock: 0),
      );
      cartProvider.removeFromCart('missing');
      cartProvider.updateQuantity('missing', 2);

      expect(cartProvider.items, isEmpty);
      expect(notifications, 0);
    });
  });
}

Product createProduct({
  required String id,
  required double price,
  double? discountPrice,
  required int stock,
}) {
  return Product(
    id: id,
    name: id,
    price: price,
    discountPrice: discountPrice,
    stock: stock,
    rating: 0,
    reviewCount: 0,
  );
}
