import 'product.dart';

class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, required this.quantity});

  double get unitPrice => product.discountPrice ?? product.price;

  double get totalPrice => unitPrice * quantity;

  Map<String, dynamic> toJson() {
    return {'productId': product.id, 'quantity': quantity};
  }
}
