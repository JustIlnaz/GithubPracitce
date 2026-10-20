import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawora/models/product.dart';
import 'package:pawora/providers/cart_provider.dart';
import 'package:pawora/screens/cart_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('updates line and cart totals and removes the last item', (
    tester,
  ) async {
    final cartProvider = CartProvider();
    cartProvider.addToCart(
      Product(
        id: 'food',
        name: 'Корм',
        price: 12.5,
        discountPrice: 10,
        stock: 5,
        rating: 0,
        reviewCount: 0,
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: cartProvider,
        child: const MaterialApp(home: CartScreen()),
      ),
    );

    expect(find.text('10.00 ₽ за шт.'), findsOneWidget);
    expect(find.text('Стоимость: 10.00 ₽'), findsOneWidget);
    expect(find.text('10.00 ₽'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byIcon(Icons.remove_circle_outline),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byTooltip('Увеличить количество'));
    await tester.pump();

    expect(find.text('Стоимость: 20.00 ₽'), findsOneWidget);
    expect(find.text('20.00 ₽'), findsOneWidget);
    expect(cartProvider.itemCount, 2);

    await tester.tap(find.byTooltip('Уменьшить количество'));
    await tester.pump();
    expect(find.text('Стоимость: 10.00 ₽'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();

    expect(find.text('Ваша корзина пуста'), findsOneWidget);
    expect(cartProvider.totalAmount, 0);
    expect(cartProvider.itemCount, 0);
  });
}
