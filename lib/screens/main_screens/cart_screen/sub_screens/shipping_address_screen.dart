import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:booky/common/widgets/custom_button.dart';
import 'package:booky/common/widgets/custom_circularprogressbar.dart';
import 'package:booky/constants.dart';
import 'package:booky/screens/main_screens/cart_screen/sub_screens/add_new_address_screen.dart';
import 'package:booky/screens/main_screens/cart_screen/sub_screens/select_payment_method_screen.dart';
import 'package:booky/utils/api_strings.dart';
import 'package:http/http.dart' as http;

class ShippingAddressScreen extends StatefulWidget {
  static const String routeName = 'shipping_address';

  const ShippingAddressScreen({super.key});

  @override
  State<ShippingAddressScreen> createState() => _ShippingAddressScreenState();
}

class _ShippingAddressScreenState extends State<ShippingAddressScreen> {
  bool isResponseGenerating = false;
  List addressesList = [];
  Map<String, dynamic>? selectedAddress;

  Future<void> getAddressesFunc() async {
    try {
      setState(() {
        isResponseGenerating = true;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString(AppConstants.spEmailKey);
      String token = prefs.getString(AppConstants.spTokenKey) ?? '';

      print('Getting addresses for email: $email');
      print('Token: $token');

      if (email == null || email.isEmpty) {
        throw Exception('Email không hợp lệ');
      }

      // Get user info
      final userResponse = await http.get(
        Uri.parse(
            '${ApiStrings.hostNameUrl}${ApiStrings.getUserInfoUrl}/$email'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('User Response: ${userResponse.body}');

      var userData = jsonDecode(userResponse.body);
      if (userData['status'] == 'success' && userData['user_id'] != null) {
        final userId = userData['user_id'];

        String apiUrl =
            '${ApiStrings.hostNameUrl}${ApiStrings.getAddressesUrl}?userId=$userId';
        print('Fetching addresses from: $apiUrl');

        final response = await http.get(
          Uri.parse(apiUrl),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
          },
        );

        print('Addresses Response: ${response.body}');

        var responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            addressesList = responseData['addresses'];
            var defaultAddress = addressesList.firstWhere(
              (address) => address['isDefault'] == true,
              orElse: () =>
                  addressesList.isNotEmpty ? addressesList.first : null,
            );

            if (defaultAddress != null) {
              selectedAddress = defaultAddress;
              prefs.setString(
                  AppConstants.spAddressKey, jsonEncode(defaultAddress));
            }
          });
        }
      }
    } catch (e) {
      print('getAddressesFunc error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi khi lấy danh sách địa chỉ: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        isResponseGenerating = false;
      });
    }
  }

  void selectAddress(Map<String, dynamic> address) async {
    setState(() {
      selectedAddress = address;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setString(AppConstants.spAddressKey, address.toString());
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    print('Shipping addresses screen!');

    getAddressesFunc();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.kGrey1,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.white,
        title: const Text('Shipping_address'),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: isResponseGenerating
          ? const Center(
              child: CustomCircularProgressBar(),
            )
          : SizedBox(
              child: ListView(
                children: [
                  SizedBox(
                    child: ListView.separated(
                      itemCount: addressesList.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 20),
                      itemBuilder: (context, index) {
                        return AddressWidget(
                          address: addressesList[index],
                          isSelected: addressesList[index] == selectedAddress,
                          onSelect: () async {
                            selectAddress(addressesList[index]);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: CustomButton(
                      label: 'Add New Address',
                      onPress: () async {
                        final result = await Navigator.of(context)
                            .pushNamed(AddNewAddressScreen.routeName);

                        if (result != null) {
                          // Cập nhật danh sách địa chỉ
                          await getAddressesFunc();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: CustomButton(
                      label: 'Apply',
                      onPress: () async {
                        if (selectedAddress == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng chọn địa chỉ giao hàng'),
                            ),
                          );
                          return;
                        }

                        try {
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          String? orderItemsJson =
                              prefs.getString('orderItems');
                          int totalAmount =
                              prefs.getInt(AppConstants.spTotalPrice) ?? 0;

                          print(
                              'Retrieved order items in shipping: $orderItemsJson'); // Debug log

                          if (orderItemsJson == null ||
                              orderItemsJson.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Không tìm thấy thông tin sản phẩm'),
                              ),
                            );
                            return;
                          }

                          List<dynamic> orderItems = jsonDecode(orderItemsJson);
                          print(
                              'Decoded order items: $orderItems'); // Debug log

                          if (!mounted) return;

                          // Lưu lại vào SharedPreferences để đảm bảo dữ liệu không bị mất
                          await prefs.setString(
                              'current_order_items', jsonEncode(orderItems));
                          await prefs.setString('current_shipping_address',
                              jsonEncode(selectedAddress));
                          await prefs.setInt(
                              'current_total_amount', totalAmount);

                          Navigator.pushNamed(
                            context,
                            SelectPaymentMethodScreen.routeName,
                          );
                        } catch (e) {
                          print('Error in shipping address: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Có lỗi xảy ra: $e'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

class AddressWidget extends StatelessWidget {
  const AddressWidget({
    super.key,
    required this.address,
    required this.isSelected,
    required this.onSelect,
  });

  final Map<String, dynamic> address;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final addressData = {
      'receiverName': address['receiver_name'] ?? '',
      'phone': address['phone'] ?? '',
      'houseNumber': address['house_number'] ?? '',
      'street': address['street'] ?? '',
      'ward': address['ward'] ?? '',
      'district': address['district'] ?? '',
      'province': address['province'] ?? '',
      'addressType': address['address_type'] ?? '',
      'isDefault': address['is_default'] ?? false,
    };

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 20),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  addressData['receiverName'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Text(addressData['phone']),
                const Spacer(),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_outlined
                      : Icons.radio_button_unchecked_outlined,
                  color: AppConstants.kPrimaryColor1,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${addressData['houseNumber']}, ${addressData['street']}, ${addressData['ward']}, ${addressData['district']}, ${addressData['province']}',
              style: const TextStyle(color: AppConstants.kGrey3),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.kGrey1,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    addressData['addressType'],
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                if (addressData['isDefault'])
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.kPrimaryColor1.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Mặc định',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppConstants.kPrimaryColor1,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
