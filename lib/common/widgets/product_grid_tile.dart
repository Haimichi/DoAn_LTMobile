import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:booky/constants.dart';
import 'package:intl/intl.dart';

class ProductGridTile extends StatefulWidget {
  const ProductGridTile({
    super.key,
    required this.product,
  });

  final Map<dynamic, dynamic> product;

  @override
  State<ProductGridTile> createState() => _ProductGridTileState();
}

class _ProductGridTileState extends State<ProductGridTile> {
  bool isFavouriteProduct = false;

  // Tạo formatter cho tiền VND
  final currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ', // Thay đổi symbol thành 'đ'
    decimalDigits: 0,
  );

  String formatPrice(dynamic price) {
    if (price == null) return '0 đ';

    // Chuyển đổi price thành double
    double numericPrice;
    if (price is String) {
      // Loại bỏ các ký tự không phải số
      String cleanPrice = price.replaceAll(RegExp(r'[^\d]'), '');
      numericPrice = double.tryParse(cleanPrice) ?? 0;
    } else {
      numericPrice = price.toDouble();
    }

    return currencyFormatter.format(numericPrice);
  }

  isAFavouriteProduct() {
    Box box = Hive.box(AppConstants.appHiveBox);

    List favProductsList = box.get(AppConstants.favProductsHiveKey) ?? [];

    isFavouriteProduct = favProductsList.any(
        (favProduct) => favProduct['productId'] == widget.product['productId']);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isAFavouriteProduct();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.grey,
            blurRadius: 0.2,
            offset: Offset(0, 0.3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 150,
                  width: double.maxFinite,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: NetworkImage(widget.product['productImages'][0]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    onPressed: () async {
                      Box box = Hive.box(AppConstants.appHiveBox);

                      List favProductsList =
                          box.get(AppConstants.favProductsHiveKey) ?? [];

                      bool isAlreadyFavorited = favProductsList.any(
                          (favProduct) =>
                              favProduct['productId'] ==
                              widget.product['productId']);

                      if (!isAlreadyFavorited) {
                        favProductsList.add(widget.product);

                        box.put(
                            AppConstants.favProductsHiveKey, favProductsList);
                      } else {
                        favProductsList.removeWhere((favProduct) =>
                            favProduct['productId'] ==
                            widget.product['productId']);
                        box.put(
                            AppConstants.favProductsHiveKey, favProductsList);
                      }

                      setState(() {
                        isFavouriteProduct = !isFavouriteProduct;
                      });
                    },
                    icon: isFavouriteProduct
                        ? const Icon(
                            Icons.favorite_rounded,
                            color: Colors.pink,
                          )
                        : const Icon(Icons.favorite_outline_rounded),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              widget.product['productName'],
              maxLines: 1,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              formatPrice(widget.product['productRetail']),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
