import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:booky/constants.dart';
import 'package:booky/screens/main_screens/components/order_widget.dart';

class ViewOrderScreen extends StatefulWidget {
  static const String routeName = 'view_order';

  const ViewOrderScreen({
    super.key,
    required this.orderData,
  });

  final Map<String, dynamic> orderData;

  @override
  State<ViewOrderScreen> createState() => _ViewOrderScreenState();
}

class _ViewOrderScreenState extends State<ViewOrderScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng'),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        surfaceTintColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mã đơn hàng: ${widget.orderData['order_id']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Ngày đặt: ${widget.orderData['order_date']}'),
                Text('Trạng thái: ${widget.orderData['status']}'),
                Text(
                    'Phương thức thanh toán: ${widget.orderData['payment_method']}'),
                Text(
                  'Tổng tiền: ${widget.orderData['total_amount']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: widget.orderData['items'].length,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final item = widget.orderData['items'][index];
                return Column(
                  children: [
                    OrderWidget(
                      isActive: true,
                      mainButton: Container(),
                      label: item['book_name'],
                      retail: item['price'].toString(),
                      quantity: item['quantity'].toString(),
                      productImage: item['image_url'],
                      retailerId: '',
                      isInViewOrder: true,
                      wholeProduct: {},
                      deleteFunc: () {},
                    ),
                    if (item['quantity'] <= 5)
                      Text(
                        'Còn ${item['quantity']} sản phẩm',
                        style: TextStyle(color: Colors.red),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
