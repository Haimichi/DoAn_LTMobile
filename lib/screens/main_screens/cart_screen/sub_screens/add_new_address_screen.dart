import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:booky/common/widgets/custom_button.dart';
import 'package:booky/common/widgets/custom_circularprogressbar.dart';
import 'package:booky/common/widgets/custom_textfield.dart';
import 'package:booky/constants.dart';
import 'package:booky/utils/api_strings.dart';
import 'package:http/http.dart' as http;
import 'package:booky/utils/helper_method.dart';

class AddNewAddressScreen extends StatefulWidget {
  static const String routeName = 'add_new_address';

  AddNewAddressScreen({super.key});

  @override
  State<AddNewAddressScreen> createState() => _AddNewAddressScreenState();
}

class _AddNewAddressScreenState extends State<AddNewAddressScreen> {
  final TextEditingController receiverNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController houseNumberController = TextEditingController();
  String selectedAddressType = 'Nhà riêng';
  bool isDefaultAddress = false;
  bool isResponseGenerating = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> fetchUserInfo() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString(AppConstants.spTokenKey) ?? '';
      String email = prefs.getString(AppConstants.spEmailKey) ?? '';

      if (email.isEmpty) {
        print('Email không hợp lệ');
        return;
      }

      final userResponse = await http.get(
        Uri.parse(
            '${ApiStrings.hostNameUrl}${ApiStrings.getUserInfoUrl}/$email'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('User Response status: ${userResponse.statusCode}');
      print('User Response body: ${userResponse.body}');

      var userData = jsonDecode(userResponse.body);
      if (userData['status'] == 'success') {
        setState(() {
          receiverNameController.text = userData['fullName'];
          phoneController.text = userData['phoneNumber'];
        });
      } else {
        throw Exception(userData['message']);
      }
    } catch (e) {
      print('Error fetching user info: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Lỗi khi lấy thông tin người dùng: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> addAddressFunc() async {
    try {
      setState(() {
        isResponseGenerating = true;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString(AppConstants.spTokenKey) ?? '';
      String email = prefs.getString(AppConstants.spEmailKey) ?? '';

      print('Adding address for email: $email');

      if (email.isEmpty) {
        throw Exception('Email không hợp lệ');
      }

      // Lấy userId từ API getUserInfo
      final userResponse = await http.get(
        Uri.parse(
            '${ApiStrings.hostNameUrl}${ApiStrings.getUserInfoUrl}/$email'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      var userData = jsonDecode(userResponse.body);
      if (userData['status'] != 'success' || userData['user_id'] == null) {
        throw Exception('Không thể lấy thông tin người dùng');
      }

      // Phân tích địa chỉ
      List<String> addressParts =
          addressController.text.split(',').map((e) => e.trim()).toList();
      if (addressParts.length < 3) {
        throw Exception('Vui lòng nhập đầy đủ thông tin địa chỉ');
      }

      Map<String, dynamic> addressData = {
        'userId': userData['user_id'], // Thêm userId vào request
        'email': email,
        'receiverName': receiverNameController.text,
        'phone': phoneController.text,
        'province': addressParts[2],
        'district': addressParts[1],
        'ward': addressParts[0],
        'street': streetController.text,
        'houseNumber': houseNumberController.text,
        'addressType': selectedAddressType,
        'isDefault': isDefaultAddress,
      };

      print('Sending address data: $addressData');

      final response = await http.post(
        Uri.parse('${ApiStrings.hostNameUrl}${ApiStrings.addAddressUrl}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(addressData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      var responseData = jsonDecode(response.body);
      if (responseData['status'] == 'success') {
        if (isDefaultAddress) {
          await prefs.setString(
              AppConstants.spAddressKey, jsonEncode(addressData));
        }

        if (!context.mounted) return;
        Navigator.pop(context, true);
      } else {
        throw Exception(responseData['message']);
      }
    } catch (e) {
      print('addAddressFunc error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        isResponseGenerating = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchUserInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('Thêm địa chỉ mới'),
        surfaceTintColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Họ tên người nhận',
                  textEditingController: receiverNameController,
                  validator: (value) {
                    if (value.isEmpty) return 'Vui lòng nhập họ tên người nhận';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Số điện thoại',
                  textEditingController: phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value.isEmpty) return 'Vui lòng nhập số điện thoại';
                    if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                      return 'Số điện thoại không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Phường/Xã, Quận/Huyện, Tỉnh/Thành phố',
                  textEditingController: addressController,
                  validator: (value) {
                    if (value.isEmpty) return 'Vui lòng nhập địa chỉ đầy đủ';
                    if (!value.contains(',')) {
                      return 'Vui lòng nhập đúng định dạng: Phường/Xã, Quận/Huyện, Tỉnh/Thành phố';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Tên đường',
                  textEditingController: streetController,
                  validator: (value) {
                    if (value.isEmpty) return 'Vui lòng nhập tên đường';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Số nhà',
                  textEditingController: houseNumberController,
                  validator: (value) {
                    if (value.isEmpty) return 'Vui lòng nhập số nhà';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedAddressType,
                  decoration: const InputDecoration(
                    labelText: 'Loại địa chỉ',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'Nhà riêng', child: Text('Nhà riêng')),
                    DropdownMenuItem(
                        value: 'Văn phòng', child: Text('Văn phòng')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedAddressType = value!;
                    });
                  },
                ),
                const SizedBox(height: 20),
                CheckboxListTile(
                  title: const Text('Đặt làm địa chỉ mặc định'),
                  value: isDefaultAddress,
                  onChanged: (bool? value) {
                    setState(() {
                      isDefaultAddress = value!;
                    });
                  },
                ),
                const SizedBox(height: 40),
                isResponseGenerating
                    ? const CustomCircularProgressBar()
                    : CustomButton(
                        label: 'Thêm địa chỉ',
                        onPress: () async {
                          if (_formKey.currentState!.validate()) {
                            await addAddressFunc();
                          }
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
