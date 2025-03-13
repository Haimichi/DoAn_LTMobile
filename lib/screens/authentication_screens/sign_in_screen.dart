/*
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:booky/common/widgets/custom_button.dart';
import 'package:booky/common/widgets/custom_circularprogressbar.dart';
import 'package:booky/common/widgets/custom_textfield.dart';
import 'package:booky/constants.dart';
import 'package:booky/screens/authentication_screens/components/app_logo.dart';
import 'package:booky/screens/authentication_screens/components/custom_divider.dart';
import 'package:booky/screens/authentication_screens/components/forgot_password.dart';
import 'package:booky/screens/authentication_screens/components/have_account.dart';
import 'package:booky/screens/authentication_screens/components/login_with_socials.dart';
import 'package:booky/screens/authentication_screens/forgot_password_screen/forgot_password_screen.dart';
import 'package:booky/screens/authentication_screens/sign_up_screen.dart';
import 'package:booky/screens/main_screens/main_app_screen.dart';
import 'package:booky/utils/api_strings.dart';
import 'package:booky/utils/app_state.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  static const String routeName = '/signin';

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isResponseGenerating = false;

  var signInFunction;

  Future<bool> signInFunc() async {
    try {
      setState(() {
        isResponseGenerating = true;
      });

      String apiUrl = '${ApiStrings.hostNameUrl}${ApiStrings.signInUrl}';
      print('Login API call to: $apiUrl');

      http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final prefs = await SharedPreferences.getInstance();
        await prefs.clear(); // Clear old data

        // Save with consistent keys
        await prefs.setString(
            AppConstants.spEmailKey, emailController.text.trim());
        await prefs.setString(AppConstants.spTokenKey, responseData['token']);

        print('Saved login data:');
        print('Email: ${emailController.text.trim()}');
        print('Token: ${responseData['token']}');

        setState(() {
          isResponseGenerating = false;
        });

        return true;
      }

      setState(() {
        isResponseGenerating = false;
        signInFunction = 'Đăng nhập thất bại';
      });
      return false;
    } catch (e) {
      print('SignIn Error: $e');
      setState(() {
        isResponseGenerating = false;
        signInFunction = 'Có lỗi xảy ra';
      });
      return false;
    }
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');
    return emailRegex.hasMatch(email);
  }

  Future<void> signInUser() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiStrings.hostNameUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text,
        }),
      );

      print('Login response: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Lưu token VÀ email vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', responseData['token']);
        await prefs.setString(
            'email', emailController.text.trim()); // Thêm dòng này

        print('Saved email: ${emailController.text.trim()}'); // Debug log
        print('Saved token: ${responseData['token']}'); // Debug log

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/main');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng nhập thất bại')),
          );
        }
      }
    } catch (e) {
      print('Sign in error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Center(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: AppConstants.defaultHorizontalPadding,
              child: SizedBox(
                height: size.height * 0.85,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 4),
                    const AppLogo(),
                    const Spacer(),
                    const Text(
                      'Login to your Account',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'Email',
                      textEditingController: emailController,
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
                    if (signInFunction == 'That email is not registered')
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            signInFunction,
                            style: TextStyle(
                                color: Colors.red.shade900, fontSize: 12),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'Password',
                      isObscured: true,
                      textEditingController: passwordController,
                      prefixIcon: const Icon(
                        Icons.lock_rounded,
                      ),
                      suffixIcon: const Icon(
                        Icons.visibility_off_rounded,
                        color: AppConstants.kGrey3,
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value!.length < 6) {
                          return 'Enter your 6 digits password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    if (signInFunction == 'Entered password is incorrect')
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: 2.1,
                          child: Text(
                            signInFunction,
                            style: TextStyle(
                                color: Colors.red.shade900, fontSize: 12),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    isResponseGenerating
                        ? const CustomCircularProgressBar()
                        : CustomButton(
                            label: 'Sign in',
                            onPress: () async {
                              setState(() {
                                signInFunction = '';
                              });
                              if (_formKey.currentState!.validate()) {
                                bool success = await signInFunc();
                                if (success) {
                                  AppStateManger.setAppState(3);
                                  if (mounted) {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      MainAppScreen.routeName,
                                      (route) => false,
                                    );
                                  }
                                }
                              }
                            },
                          ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ForgotPassword(
                        onTap: () {
                          Navigator.of(context)
                              .pushNamed(ForgotPasswordScreen.routeName);
                        },
                      ),
                    ),
                    const Spacer(flex: 2),
                    CustomDivider(label: 'or continue with'),
                    const Spacer(),
                    const LoginWithSocials(),
                    const Spacer(),
                    HaveAnAccount(
                      label: 'Don\'t have an account? ',
                      buttonLabel: 'Sign up',
                      onPress: () {
                        Navigator.of(context).pushNamed(SignUpScreen.routeName);
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
*/

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:booky/common/widgets/custom_button.dart';
import 'package:booky/common/widgets/custom_circularprogressbar.dart';
import 'package:booky/common/widgets/custom_textfield.dart';
import 'package:booky/constants.dart';
import 'package:booky/screens/authentication_screens/components/app_logo.dart';
import 'package:booky/screens/authentication_screens/components/custom_divider.dart';
import 'package:booky/screens/authentication_screens/components/forgot_password.dart';
import 'package:booky/screens/authentication_screens/components/have_account.dart';
import 'package:booky/screens/authentication_screens/components/login_with_socials.dart';
import 'package:booky/screens/authentication_screens/forgot_password_screen/forgot_password_screen.dart';
import 'package:booky/screens/authentication_screens/sign_up_screen.dart';
import 'package:booky/screens/main_screens/main_app_screen.dart';
import 'package:booky/utils/api_strings.dart';
import 'package:booky/utils/app_state.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  static const String routeName = '/signin';

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isResponseGenerating = false;

  var signInFunction;

  Future<bool> signInFunc() async {
    try {
      setState(() {
        isResponseGenerating = true;
      });

      String apiUrl = '${ApiStrings.hostNameUrl}${ApiStrings.signInUrl}';
      print('Login API call to: $apiUrl');

      http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final prefs = await SharedPreferences.getInstance();
        await prefs.clear(); // Clear old data

        // Save with consistent keys
        await prefs.setString(
            AppConstants.spEmailKey, emailController.text.trim());
        await prefs.setString(AppConstants.spTokenKey, responseData['token']);

        print('Saved login data:');
        print('Email: ${emailController.text.trim()}');
        print('Token: ${responseData['token']}');

        setState(() {
          isResponseGenerating = false;
        });

        return true;
      } else if (response.statusCode == 403) {
        setState(() {
          isResponseGenerating = false;
          signInFunction = 'Tài khoản của bạn đã bị khóa';
        });

        // Hiển thị dialog thông báo
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Thông báo'),
              content: Text('Tài khoản của bạn đã bị khóa'),
              actions: <Widget>[
                TextButton(
                  child: Text('Đóng'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
        return false;
      }

      setState(() {
        isResponseGenerating = false;
        signInFunction = 'Đăng nhập thất bại';
      });
      return false;
    } catch (e) {
      print('SignIn Error: $e');
      setState(() {
        isResponseGenerating = false;
        signInFunction = 'Có lỗi xảy ra';
      });
      return false;
    }
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');
    return emailRegex.hasMatch(email);
  }

  Future<void> signInUser() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiStrings.hostNameUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 403) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tài khoản của bạn đã bị khóa'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      print('Login response: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Lưu token VÀ email vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', responseData['token']);
        await prefs.setString(
            'email', emailController.text.trim()); // Thêm dòng này

        print('Saved email: ${emailController.text.trim()}'); // Debug log
        print('Saved token: ${responseData['token']}'); // Debug log

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/main');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng nhập thất bại')),
          );
        }
      }
    } catch (e) {
      print('Sign in error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Center(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: AppConstants.defaultHorizontalPadding,
              child: SizedBox(
                height: size.height * 0.85,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 4),
                    const AppLogo(),
                    const Spacer(),
                    const Text(
                      'Login to your Account',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'Email',
                      textEditingController: emailController,
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
                    if (signInFunction == 'That email is not registered')
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            signInFunction,
                            style: TextStyle(
                                color: Colors.red.shade900, fontSize: 12),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'Password',
                      isObscured: true,
                      textEditingController: passwordController,
                      prefixIcon: const Icon(
                        Icons.lock_rounded,
                      ),
                      suffixIcon: const Icon(
                        Icons.visibility_off_rounded,
                        color: AppConstants.kGrey3,
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value!.length < 6) {
                          return 'Enter your 6 digits password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    if (signInFunction == 'Entered password is incorrect')
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: 2.1,
                          child: Text(
                            signInFunction,
                            style: TextStyle(
                                color: Colors.red.shade900, fontSize: 12),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    isResponseGenerating
                        ? const CustomCircularProgressBar()
                        : CustomButton(
                            label: 'Sign in',
                            onPress: () async {
                              setState(() {
                                signInFunction = '';
                              });
                              if (_formKey.currentState!.validate()) {
                                bool success = await signInFunc();
                                if (success) {
                                  AppStateManger.setAppState(3);
                                  if (mounted) {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      MainAppScreen.routeName,
                                      (route) => false,
                                    );
                                  }
                                }
                              }
                            },
                          ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ForgotPassword(
                        onTap: () {
                          Navigator.of(context)
                              .pushNamed(ForgotPasswordScreen.routeName);
                        },
                      ),
                    ),
                    const Spacer(flex: 2),
                    CustomDivider(label: 'or continue with'),
                    const Spacer(),
                    const LoginWithSocials(),
                    const Spacer(),
                    HaveAnAccount(
                      label: 'Don\'t have an account? ',
                      buttonLabel: 'Sign up',
                      onPress: () {
                        Navigator.of(context).pushNamed(SignUpScreen.routeName);
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
