// Test script sử dụng Appium Flutter Driver để kiểm tra chức năng đăng ký tài khoản
// Chạy bằng lệnh: node test/appium_test.js

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';
import 'package:flutter/material.dart';

void main() {
  group('Kiểm tra chức năng đăng ký', () {
    late FlutterDriver driver;

    // Kết nối với Flutter Driver trước khi chạy test
    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    // Đóng kết nối sau khi hoàn thành test
    tearDownAll(() async {
      await driver.close();
    });

    test('Đăng ký tài khoản thành công', () async {
      // Điều hướng đến màn hình đăng ký
      await driver.tap(find.byType('ElevatedButton'));

      // Điền thông tin đăng ký
      await driver.tap(find.byValueKey('email_field'));
      await driver.enterText('lva@gmail.com');

      await driver.tap(find.byValueKey('fullname_field'));
      await driver.enterText('Le Van A');

      await driver.tap(find.byValueKey('phone_field'));
      await driver.enterText('0797392641');

      // Chọn ngày sinh
      await driver.tap(find.byValueKey('birthdate_field'));
      await driver.tap(find.text('OK'));

      await driver.tap(find.byValueKey('password_field'));
      await driver.enterText('lva@123');

      // Nhấn nút đăng ký
      await driver.tap(find.byValueKey('signup_button'));

      // Kiểm tra kết quả
      await driver.waitFor(find.byValueKey('success_message'));
      expect(await driver.getText(find.byValueKey('success_message')),
          'Đăng ký thành công');
    });

    test('Đăng ký tài khoản (bỏ trống email)', () async {
      // Điều hướng đến màn hình đăng ký
      await driver.tap(find.byType('ElevatedButton'));

      // Bỏ qua email
      await driver.tap(find.byValueKey('fullname_field'));
      await driver.enterText('Le Van B');

      await driver.tap(find.byValueKey('phone_field'));
      await driver.enterText('0797392641');

      await driver.tap(find.byValueKey('birthdate_field'));
      await driver.tap(find.text('OK'));

      await driver.tap(find.byValueKey('password_field'));
      await driver.enterText('lvb@123');

      // Nhấn nút đăng ký
      await driver.tap(find.byValueKey('signup_button'));

      // Kiểm tra thông báo lỗi
      await driver.waitFor(find.byValueKey('email_error'));
      expect(await driver.getText(find.byValueKey('email_error')),
          'Please enter your email');
    });

    test('Đăng ký tài khoản (bỏ trống full name)', () async {
      // Điều hướng đến màn hình đăng ký
      await driver.tap(find.byType('ElevatedButton'));

      await driver.tap(find.byValueKey('email_field'));
      await driver.enterText('lvb@gmail.com');

      // Bỏ qua fullname
      await driver.tap(find.byValueKey('phone_field'));
      await driver.enterText('0797392641');

      await driver.tap(find.byValueKey('birthdate_field'));
      await driver.tap(find.text('OK'));

      await driver.tap(find.byValueKey('password_field'));
      await driver.enterText('lvb@123');

      // Nhấn nút đăng ký
      await driver.tap(find.byValueKey('signup_button'));

      // Kiểm tra thông báo lỗi
      await driver.waitFor(find.byValueKey('fullname_error'));
      expect(await driver.getText(find.byValueKey('fullname_error')),
          'Please enter your full name');
    });
  });
}
