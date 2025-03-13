import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:booky/common/widgets/product_grid_tile.dart';
import 'package:booky/constants.dart';
import 'package:booky/screens/main_screens/home_screen/sub_screens/add_to_cart_screen.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:booky/utils/api_strings.dart';

class ProductsByCategoryScreen extends StatefulWidget {
  static const String routeName = '/products_by_category';

  ProductsByCategoryScreen({super.key});

  @override
  State<ProductsByCategoryScreen> createState() =>
      _ProductsByCategoryScreenState();
}

class _ProductsByCategoryScreenState extends State<ProductsByCategoryScreen> {
  List products = [];
  bool isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final category =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (category != null) {
      fetchProducts(category['category_id']);
    }
  }

  Future<void> fetchProducts(dynamic categoryId) async {
    try {
      print('Fetching products for category ID: $categoryId');

      final response = await http.get(
        Uri.parse('${ApiStrings.hostNameUrl}/api/books/category/$categoryId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('API Response - Status: ${response.statusCode}');
      print('API Response - Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            products = (data['data'] as List)
                .map((book) => {
                      'productId': book['book_id']?.toString() ?? 'unknown_id',
                      'book_id': book['book_id']?.toString() ?? 'unknown_id',
                      'productName': book['title'] ?? 'Unknown Title',
                      'productDescription':
                          book['description'] ?? 'No description available',
                      'productRetail': formatCurrency(book['price']),
                      'numericPrice':
                          double.tryParse(book['price']?.toString() ?? '0') ??
                              0.0,
                      'productImages': [
                        book['image_url'] ??
                            'https://via.placeholder.com/128x196'
                      ],
                      'productCompany': 'Book Store',
                      'productCategory':
                          book['category_id']?.toString() ?? 'General',
                      'retailerName': book['author'] ?? 'Unknown Author',
                      'productSizes': 'Standard',
                      'productColors': 'Default',
                      'quantity': book['quantity']?.toString() ?? '1',
                      'preview_images': book['preview_images'] ?? [],
                      'retailerId': book['author_id']?.toString() ?? 'unknown',
                      'averageRating': book['average_rating'] ?? 0.0,
                      'totalReviews': book['total_reviews'] ?? 0,
                      'ratings': book['ratings'] ?? {},
                    })
                .toList();
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching products: $e');
      setState(() => isLoading = false);
    }
  }

  String formatCurrency(dynamic price) {
    if (price == null) return '0 đ';

    double numericPrice;
    if (price is String) {
      numericPrice = double.tryParse(price) ?? 0;
    } else {
      numericPrice = price.toDouble();
    }

    int roundedPrice = numericPrice.round();
    String result = roundedPrice.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );

    return '$result đ';
  }

  @override
  Widget build(BuildContext context) {
    final category =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(category?['name'] ?? 'Danh mục')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(category?['name'] ?? 'Danh mục')),
      body: products.isEmpty
          ? Center(child: Text('Không có sản phẩm trong danh mục này'))
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 20,
                childAspectRatio: 2 / 2.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: products.length,
              itemBuilder: (context, index) {
                var product = products[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AddToCartScreen.routeName,
                      arguments: product,
                    );
                  },
                  child: ProductGridTile(product: product),
                );
              },
            ),
    );
  }
}
