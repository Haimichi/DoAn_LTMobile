import 'package:flutter/material.dart';

class CartScreen extends StatelessWidget {
  final List cartItems;

  CartScreen({required this.cartItems});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cart')),
      body: ListView.builder(
        itemCount: cartItems.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(cartItems[index]['title']),
            subtitle: Text(cartItems[index]['price']),
          );
        },
      ),
    );
  }
}
