import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:booky/common/widgets/custom_button.dart';
import 'package:booky/common/widgets/custom_circularprogressbar.dart';
import 'package:booky/common/widgets/custom_textfield.dart';
import 'package:booky/constants.dart';
import 'package:booky/screens/authentication_screens/components/app_logo.dart';
import 'package:booky/screens/authentication_screens/components/custom_divider.dart';
import 'package:booky/screens/authentication_screens/components/have_account.dart';
import 'package:booky/screens/authentication_screens/components/login_with_socials.dart';
import 'package:booky/screens/authentication_screens/fill_your_profile_screen.dart';
import 'package:booky/screens/authentication_screens/sign_in_screen.dart';
import 'package:booky/utils/api_strings.dart';
import 'package:http/http.dart' as http;
import 'package:booky/utils/app_state.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  static const String routeName = '/signup';

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController birthDateController = TextEditingController();
  DateTime? selectedDate;
  bool isResponseGenerating = false;
  var signUpFunction;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        birthDateController.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<bool> signUpFunc() async {
    try {
      setState(() {
        isResponseGenerating = true;
      });

      String apiUrl = '${ApiStrings.hostNameUrl}${ApiStrings.signUpUrl}';

      var bodyData = {
        'email': emailController.text,
        'fullName': fullNameController.text,
        'password': passwordController.text,
        'phoneNumber': phoneNumberController.text,
        'birthDate': selectedDate?.toIso8601String(),
      };

      http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(bodyData),
      );

      var responseData = jsonDecode(response.body);
      print('signUpFunc() response.body -----------------> ${response.body}');

      setState(() {
        isResponseGenerating = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thành công'),
            backgroundColor: Colors.green,
          ),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Đăng ký thất bại'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      print('signUpFunc() Error--------------------------> $e');
      setState(() {
        isResponseGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có lỗi xảy ra khi đăng ký'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    print('signUpFunction ----------------------> $signUpFunction');

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Center(
            child: Padding(
              padding: AppConstants.defaultHorizontalPadding,
              child: SizedBox(
                height: size.height * 0.83,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),
                    const AppLogo(),
                    const Spacer(),
                    const Text(
                      'Create Your Account',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    CustomTextField(
                      textEditingController: emailController,
                      label: 'Email',
                      prefixIcon: const Icon(
                        Icons.mail_rounded,
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your email';
                        } else if (!isValidEmail(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    if (signUpFunction == 'That email is already registered')
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            signUpFunction,
                            style: TextStyle(
                                color: Colors.red.shade900, fontSize: 12),
                          ),
                        ),
                      ),
                    const Spacer(),
                    CustomTextField(
                      textEditingController: fullNameController,
                      label: 'Full Name',
                      prefixIcon: const Icon(
                        Icons.person_rounded,
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      textEditingController: phoneNumberController,
                      label: 'Phone Number',
                      prefixIcon: const Icon(
                        Icons.phone_rounded,
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      textEditingController: birthDateController,
                      label: 'Birth Date',
                      prefixIcon: const Icon(
                        Icons.calendar_today_rounded,
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please select your birth date';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      textEditingController: passwordController,
                      label: 'Password',
                      prefixIcon: const Icon(
                        Icons.lock_rounded,
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const Spacer(),
                    isResponseGenerating
                        ? const CustomCircularProgressBar()
                        : CustomButton(
                            label: 'Sign up',
                            onPress: () async {
                              if (_formKey.currentState!.validate()) {
                                bool success = await signUpFunc();
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Đăng ký thành công! Vui lòng đăng nhập'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );

                                  await Future.delayed(
                                      const Duration(seconds: 2));

                                  if (mounted) {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      SignInScreen.routeName,
                                      (route) => false,
                                    );
                                  }
                                }
                              }
                            },
                          ),
                    const Spacer(),
                    CustomDivider(label: 'or continue with'),
                    const Spacer(),
                    const LoginWithSocials(),
                    const Spacer(),
                    HaveAnAccount(
                      label: 'Already have an account?',
                      buttonLabel: 'Sign in',
                      onPress: () {
                        Navigator.of(context).pushNamed(SignInScreen.routeName);
                      },
                    ),
                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
