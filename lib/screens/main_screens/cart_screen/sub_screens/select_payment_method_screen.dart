import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:booky/common/widgets/custom_button.dart';
import 'package:booky/constants.dart';
import 'package:booky/screens/main_screens/main_app_screen.dart';
import 'package:booky/screens/main_screens/cart_screen/sub_screens/enter_pin_for_order_confirmation_screen.dart';
import 'package:booky/utils/api_strings.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:booky/models/PlaceOrderItem.dart';

class SelectPaymentMethodScreen extends StatefulWidget {
  static const String routeName = 'select_payment_method';

  const SelectPaymentMethodScreen({super.key});

  @override
  State<SelectPaymentMethodScreen> createState() =>
      _SelectPaymentMethodScreenState();
}

class _SelectPaymentMethodScreenState extends State<SelectPaymentMethodScreen> {
  bool isResponseGenerating = false;
  String placeOrderFunction = '';
  String selectedPaymentMethod = 'COD';
  List<dynamic> orderItems = [];
  Map<String, dynamic> shippingAddress = {};
  int totalAmount = 0;

  @override
  void initState() {
    super.initState();
    loadOrderData();
  }

  Future<void> loadOrderData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? orderItemsJson = prefs.getString('current_order_items');
      String? shippingAddressJson = prefs.getString('current_shipping_address');
      int? amount = prefs.getInt('current_total_amount');

      print('Loading saved order items: $orderItemsJson'); // Debug log

      if (orderItemsJson != null &&
          shippingAddressJson != null &&
          amount != null) {
        setState(() {
          orderItems = jsonDecode(orderItemsJson);
          shippingAddress = jsonDecode(shippingAddressJson);
          totalAmount = amount;
        });

        print('Loaded order items: $orderItems'); // Debug log
        print('Items length: ${orderItems.length}'); // Debug log
      }
    } catch (e) {
      print('Error loading order data: $e');
    }
  }

  List<Map<String, String>> paymentMethod = [
    {
      'image': AppConstants.googleIcon,
      'name': 'Google Pay',
    },
    {
      'image': AppConstants.appleIcon,
      'name': 'Apple Pay',
    },
    {
      'image': AppConstants.paypalIcon,
      'name': 'Pay Pal',
    },
    {
      'image': AppConstants.masterCardIcon,
      'name': 'Master class',
    },
    {
      'image': AppConstants.walletIcon,
      'name': 'Wallet',
    },
  ];

  Future<String> placeOrderFunc() async {
    try {
      if (orderItems.isEmpty) {
        print('Order items is empty! Length: ${orderItems.length}');
        print('Current order items: $orderItems');
        return 'Không có sản phẩm trong giỏ hàng';
      }

      setState(() {
        isResponseGenerating = true;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      DateTime now = DateTime.now();
      String orderDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

      Map<String, dynamic> bodyData = {
        'order_date': orderDateTime,
        'total_amount': totalAmount,
        'status': 'Pending',
        'payment_method': selectedPaymentMethod,
        'payment_status': 'Pending',
        'shipping_address': jsonEncode(shippingAddress),
        'items': orderItems,
      };

      print('Request body: ${jsonEncode(bodyData)}'); // Debug log

      final response = await http.post(
        Uri.parse('${ApiStrings.hostNameUrl}/api/cart/place_order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(bodyData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      setState(() {
        isResponseGenerating = false;
      });

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        if (responseData['message'] == 'Đặt hàng thành công!') {
          Box box = Hive.box(AppConstants.appHiveBox);
          await box.put(AppConstants.cartProductHiveKey, []);

          if (!mounted) return '';

          Navigator.pushNamedAndRemoveUntil(
            context,
            MainAppScreen.routeName,
            (route) => false,
            arguments: 2,
          );

          return responseData['message'];
        }
      }
      return 'Đặt hàng không thành công';
    } catch (e) {
      print('Error in placeOrderFunc: $e');
      return 'Đặt hàng không thành công';
    }
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Payment Method'),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select the payment method you want to use.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: paymentMethod.length,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  return PaymentMethodWidget(
                    paymentMethod: paymentMethod[index],
                    isAvailabe: false,
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            PaymentMethodWidget(
              paymentMethod: const {
                'image': AppConstants.codIcon,
                'name': 'COD',
              },
              isAvailabe: true,
              onSelect: () {
                setState(() {
                  selectedPaymentMethod = 'COD';
                });
              },
            ),
            const Spacer(flex: 2),
            CustomButton(
              label: 'Continue',
              onPress: () async {
                try {
                  bool shouldProceed = false;

                  if (selectedPaymentMethod == 'COD') {
                    shouldProceed = true;
                  } else {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const EnterYourPinForOrderConfirmationScreen(),
                      ),
                    );
                    shouldProceed = result == true;
                  }

                  if (shouldProceed && mounted) {
                    try {
                      final orderResult = await placeOrderFunc();
                      print('Order result: $orderResult'); // Debug log

                      if (orderResult.contains('thành công')) {
                        Box box = Hive.box(AppConstants.appHiveBox);
                        await box.put(AppConstants.cartProductHiveKey, []);

                        if (!mounted) return;
                        await orderPlacedDialogBox(
                            context, MediaQuery.of(context).size.height);
                      } else {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Đặt hàng không thành công')),
                        );
                      }
                    } catch (e) {
                      print('Error placing order: $e');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Có lỗi xảy ra khi đặt hàng')),
                      );
                    }
                  }
                } catch (e) {
                  print('Navigation error: $e');
                }
              },
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

Future<void> orderPlacedDialogBox(
    BuildContext context, double screenHeight) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.white,
          child: SizedBox(
            height: screenHeight * 0.5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  SvgPicture.asset(
                    AppConstants.orderPlacedIcon,
                    height: 150,
                  ),
                  const Spacer(),
                  const Text(
                    'Order Successful!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'You have successfully placed order',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  CustomButton(
                    label: 'View Order',
                    onPress: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        MainAppScreen.routeName,
                        (route) => false,
                        arguments: 2,
                      );
                    },
                  ),
                  const Spacer(),
                  CustomButton(
                    label: 'Return to Home Screen',
                    buttonColor: AppConstants.kGrey2,
                    labelColor: Colors.black,
                    onPress: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        MainAppScreen.routeName,
                        (route) => false,
                      );
                    },
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class PaymentMethodWidget extends StatelessWidget {
  PaymentMethodWidget({
    super.key,
    required this.paymentMethod,
    this.isAvailabe,
    this.onSelect,
  });

  final Map<String, String> paymentMethod;
  bool? isAvailabe = false;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      // margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 0.6,
            blurRadius: 1,
            offset: Offset(0, 0.8),
          ),
        ],
      ),
      child: Row(
        // mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SvgPicture.asset(
            paymentMethod['image']!,
            height: 40,
            color: !isAvailabe! ? AppConstants.kGrey3 : null,
          ),
          const SizedBox(width: 10),
          Text(
            paymentMethod['name']!,
            style: TextStyle(
              color: !isAvailabe!
                  ? AppConstants.kGrey3
                  : AppConstants.kPrimaryColor1,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Icon(
            !isAvailabe!
                ? Icons.radio_button_unchecked_outlined
                : Icons.radio_button_checked_outlined,
            color: !isAvailabe!
                ? AppConstants.kGrey3
                : AppConstants.kPrimaryColor1,
          ),
        ],
      ),
    );
  }
}
