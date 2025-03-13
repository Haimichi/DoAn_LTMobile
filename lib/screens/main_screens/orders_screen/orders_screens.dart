import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:booky/common/widgets/custom_button.dart';
import 'package:booky/common/widgets/custom_circularprogressbar.dart';
import 'package:booky/constants.dart';
import 'package:booky/screens/authentication_screens/components/app_logo.dart';
import 'package:booky/screens/main_screens/components/order_widget.dart';
import 'package:booky/screens/main_screens/orders_screen/sub_screens/view_order_screen.dart';
import 'package:booky/utils/api_strings.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with AutomaticKeepAliveClientMixin {
  List ordersList = [];
  bool isResponseGenerating = false;

  final currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  String formatCurrency(dynamic price) {
    if (price == null) return '0 đ';

    double numericPrice;
    if (price is String) {
      String cleanPrice = price.replaceAll(RegExp(r'[^\d]'), '');
      numericPrice = double.tryParse(cleanPrice) ?? 0;
    } else {
      numericPrice = price.toDouble();
    }

    return currencyFormatter.format(numericPrice);
  }

  Future<String> getMyOrdersFunc() async {
    try {
      setState(() {
        isResponseGenerating = true;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('token') ?? '';

      String apiUrl = '${ApiStrings.hostNameUrl}/api/orders/my-orders';

      http.Response response = await http.get(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get orders response: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        setState(() {
          ordersList = List.from(responseData['orders']).reversed.toList();
          isResponseGenerating = false;
        });
      }
    } catch (e) {
      setState(() {
        isResponseGenerating = false;
      });
      print('getMyOrdersFunc() ERROR: $e');
    }
    return '';
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Fetch orders khi vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshOrders();
    });
  }

  Future<void> refreshOrders() async {
    if (!mounted) return;

    try {
      setState(() {
        isResponseGenerating = true;
      });

      await getMyOrdersFunc();
    } catch (e) {
      print('Error refreshing orders: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải danh sách đơn hàng')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isResponseGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    Size size = MediaQuery.of(context).size;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: const Padding(
            padding: EdgeInsets.only(left: 20),
            child: AppLogo(),
          ),
          title: const Text(
            'My Orders',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_horiz),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: refreshOrders,
          child: isResponseGenerating
              ? const Center(child: CustomCircularProgressBar())
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ordersList.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                ViewOrderScreen.routeName,
                                arguments: {
                                  'order_id': ordersList[index]['order_id'],
                                  'order_date': ordersList[index]['order_date'],
                                  'status': ordersList[index]['status'],
                                  'payment_method': ordersList[index]
                                      ['payment_method'],
                                  'total_amount': ordersList[index]
                                      ['total_amount'],
                                  'items': ordersList[index]['items'],
                                },
                              );
                            },
                            child: ViewOrderWidget(
                              ordersList: ordersList,
                              index: index,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class ViewOrderWidget extends StatelessWidget {
  const ViewOrderWidget({
    super.key,
    required this.ordersList,
    required this.index,
  });

  final List ordersList;
  final int index;

  String formatCurrency(dynamic price) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    if (price == null) return '0 đ';

    double numericPrice;
    if (price is String) {
      String cleanPrice = price.replaceAll(RegExp(r'[^\d]'), '');
      numericPrice = double.tryParse(cleanPrice) ?? 0;
    } else {
      numericPrice = price.toDouble();
    }

    return formatter.format(numericPrice);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      margin: AppConstants.defaultHorizontalPadding,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 15,
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${ordersList[index]['items'].length} items orders',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'on ${ordersList[index]['order_date']}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.separated(
              itemCount: ordersList[index]['items'].length,
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index2) {
                return Container(
                  width: 70,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.kGrey1,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.grey,
                        blurRadius: 0.2,
                        offset: Offset(0, 0.3),
                      ),
                    ],
                    image: DecorationImage(
                      image: NetworkImage(
                        ordersList[index]['items'][index2]['image_url'],
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total Cost: ${formatCurrency(ordersList[index]['total_amount'])}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          CustomButton(label: 'View Order'),
        ],
      ),
    );
  }
}
