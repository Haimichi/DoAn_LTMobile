// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart'; // Màn hình chính

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Booky App',
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(), // Màn hình đăng nhập
        '/register': (context) => RegisterScreen(), // Màn hình đăng ký
        '/home': (context) => HomeScreen(), // Màn hình chính
      },
    );
  }
}
