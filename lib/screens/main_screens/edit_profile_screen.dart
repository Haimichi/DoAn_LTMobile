import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:booky/common/widgets/custom_button.dart';
import 'package:booky/common/widgets/custom_textfield.dart';
import 'package:booky/constants.dart';
import 'package:booky/utils/api_strings.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  static const String routeName = 'edit_profile';

  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  DateTime? selectedDate;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      setState(() => isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString(AppConstants.spEmailKey);
      String token = prefs.getString(AppConstants.spTokenKey) ?? '';

      print('Loading profile for email: $email');
      print('Token: $token');

      if (email == null || email.isEmpty) {
        throw Exception('Email not found');
      }

      final response = await http.get(
        Uri.parse(
            '${ApiStrings.hostNameUrl}${ApiStrings.getUserInfoUrl}/$email'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          fullNameController.text = data['fullName'] ?? '';
          phoneController.text = data['phoneNumber'] ?? '';
          if (data['birthDate'] != null) {
            selectedDate = DateTime.parse(data['birthDate']);
          }
        });
      } else {
        throw Exception('Failed to load user info');
      }
    } catch (e) {
      print('Load user info error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải thông tin: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    try {
      if (!_formKey.currentState!.validate()) return;

      setState(() => isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString(AppConstants.spEmailKey);
      String token = prefs.getString(AppConstants.spTokenKey) ?? '';

      if (email == null) throw Exception('Email not found');

      print('Updating profile for email: $email');
      print('API URL: ${ApiStrings.hostNameUrl}${ApiStrings.updateProfileUrl}');

      final response = await http.put(
        Uri.parse('${ApiStrings.hostNameUrl}${ApiStrings.updateProfileUrl}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'email': email,
          'fullName': fullNameController.text,
          'phoneNumber': phoneController.text,
          'birthDate': selectedDate?.toIso8601String(),
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật thông tin thành công')),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(
            jsonDecode(response.body)['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cập nhật: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa thông tin'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'Họ và tên',
                      textEditingController: fullNameController,
                      validator: (value) {
                        if (value.isEmpty) return 'Vui lòng nhập họ tên';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Ngày sinh'),
                      subtitle: Text(
                        selectedDate != null
                            ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                            : 'Chưa chọn ngày sinh',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      label: 'Cập nhật',
                      onPress: _updateProfile,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
