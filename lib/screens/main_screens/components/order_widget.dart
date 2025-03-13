import 'package:flutter/material.dart';
import 'package:booky/constants.dart';
import 'package:booky/utils/helper_method.dart';
import 'package:intl/intl.dart';

class OrderWidget extends StatelessWidget {
  final String label;
  final String retail;
  final String quantity;
  final String productImage;
  final Map<dynamic, dynamic> wholeProduct;
  final bool isActive;
  final Widget mainButton;
  final Function()? deleteFunc;
  final Function()? onTapFunc;
  final bool isInViewOrder;
  final String retailerId;
  final Widget? addWidget;
  final Widget? status;

  // Tạo formatter cho tiền VND
  final currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  OrderWidget({
    super.key,
    required this.label,
    required this.retail,
    required this.quantity,
    required this.productImage,
    required this.wholeProduct,
    required this.isActive,
    required this.mainButton,
    this.deleteFunc,
    this.onTapFunc,
    this.isInViewOrder = false,
    this.retailerId = '',
    this.addWidget,
    this.status,
  });

  String formatPrice(String price) {
    if (price.isEmpty) return '0 đ';

    // Loại bỏ các ký tự không phải số
    String cleanPrice = price.replaceAll(RegExp(r'[^\d]'), '');
    double numericPrice = double.tryParse(cleanPrice) ?? 0;

    return currencyFormatter.format(numericPrice);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTapFunc,
      child: Container(
        height: 150,
        width: double.maxFinite,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.grey,
              blurRadius: 0.2,
              offset: Offset(0, 0.3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product Image
            Container(
              height: double.maxFinite,
              width: 120,
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: NetworkImage(productImage),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Product Details
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name and Delete Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!isActive && deleteFunc != null)
                        IconButton(
                          onPressed: deleteFunc,
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                    ],
                  ),

                  // Quantity
                  if (isInViewOrder)
                    Text(
                      'Số lượng: $quantity',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),

                  const SizedBox(height: 6),
                  status ?? const SizedBox.shrink(),

                  // Price and Action Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatPrice(retail),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      mainButton,
                    ],
                  ),

                  // Retailer Info
                  if (isInViewOrder)
                    Text(
                      'Retailer\'s contact: $retailerId',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
