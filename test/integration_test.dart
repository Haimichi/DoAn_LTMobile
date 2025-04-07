import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide find;
import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test.dart';
import 'package:booky/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Kiểm tra chức năng đăng ký', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver.close();
    });

    test('Đăng ký tài khoản thành công', () async {
      // Chạy ứng dụng
      app.main();

      // Điều hướng đến màn hình đăng ký (giả định rằng có một nút đăng ký ở màn hình đầu tiên)
      await driver.tap(find.byValueKey('navigate_to_signup'));

      // Điền thông tin đăng ký
      await driver.tap(find.byValueKey('email_field'));
      await driver.enterText('lva@gmail.com');

      await driver.tap(find.byValueKey('fullname_field'));
      await driver.enterText('Le Van A');

      await driver.tap(find.byValueKey('phone_field'));
      await driver.enterText('0797392641');

      // Chọn ngày sinh
      await driver.tap(find.byValueKey('birthdate_field'));
      // Tương tác với Date Picker (giả định rằng đã chọn 16/1/2003)

      await driver.tap(find.byValueKey('password_field'));
      await driver.enterText('lva@123');

      // Nhấn nút đăng ký
      await driver.tap(find.byValueKey('signup_button'));

      // Xác minh kết quả
      expect(await driver.getText(find.byValueKey('success_message')),
          'Đăng ký thành công');
    });

    test('Đăng ký tài khoản (bỏ trống email)', () async {
      app.main();

      await driver.tap(find.byValueKey('navigate_to_signup'));

      // Bỏ qua email

      await driver.tap(find.byValueKey('fullname_field'));
      await driver.enterText('Le Van B');

      await driver.tap(find.byValueKey('phone_field'));
      await driver.enterText('0797392641');

      await driver.tap(find.byValueKey('birthdate_field'));
      // Tương tác với Date Picker

      await driver.tap(find.byValueKey('password_field'));
      await driver.enterText('lvb@123');

      await driver.tap(find.byValueKey('signup_button'));

      // Xác minh thông báo lỗi
      expect(await driver.getText(find.byValueKey('email_error')),
          'Please enter your email');
    });

    test('Đăng ký tài khoản (bỏ trống full name)', () async {
      app.main();

      await driver.tap(find.byValueKey('navigate_to_signup'));

      await driver.tap(find.byValueKey('email_field'));
      await driver.enterText('lvb@gmail.com');

      // Bỏ qua fullname

      await driver.tap(find.byValueKey('phone_field'));
      await driver.enterText('0797392641');

      await driver.tap(find.byValueKey('birthdate_field'));
      // Tương tác với Date Picker

      await driver.tap(find.byValueKey('password_field'));
      await driver.enterText('lvb@123');

      await driver.tap(find.byValueKey('signup_button'));

      // Xác minh thông báo lỗi
      expect(await driver.getText(find.byValueKey('fullname_error')),
          'Please enter your full name');
    });
  });
}
