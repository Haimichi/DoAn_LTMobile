import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:booky/screens/authentication_screens/sign_up_screen.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_driver/driver_extension.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  enableFlutterDriverExtension();

  group('Đăng ký tài khoản', () {
    testWidgets('Đăng ký tài khoản thành công', (WidgetTester tester) async {
      // Khởi tạo app và điều hướng đến màn hình đăng ký
      await tester.pumpWidget(MaterialApp(home: SignUpScreen()));

      // Điền thông tin đăng ký
      await tester.enterText(find.byType(TextField).at(0), 'lva@gmail.com');
      await tester.enterText(find.byType(TextField).at(1), 'Le Van A');
      await tester.enterText(find.byType(TextField).at(2), '0797392641');

      // Chọn ngày sinh (do cần tương tác với DatePicker, sẽ mô phỏng)
      await tester.tap(find.byType(TextField).at(3));
      await tester.pumpAndSettle();
      // Giả lập chọn ngày tháng trong DatePicker
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Điền mật khẩu
      await tester.enterText(find.byType(TextField).at(4), 'lva@123');

      // Nhấn nút đăng ký
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      // Kiểm tra thông báo đăng ký thành công
      expect(find.text('Đăng ký thành công'), findsOneWidget);
    });

    testWidgets('Đăng ký tài khoản (bỏ trống email)',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SignUpScreen()));

      // Bỏ qua email, chỉ điền các trường khác
      await tester.enterText(find.byType(TextField).at(1), 'Le Van B');
      await tester.enterText(find.byType(TextField).at(2), '0797392641');

      // Chọn ngày sinh
      await tester.tap(find.byType(TextField).at(3));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Điền mật khẩu
      await tester.enterText(find.byType(TextField).at(4), 'lvb@123');

      // Nhấn nút đăng ký
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      // Kiểm tra thông báo lỗi "Please enter your email"
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('Đăng ký tài khoản (bỏ trống full name)',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SignUpScreen()));

      // Điền email nhưng bỏ trống full name
      await tester.enterText(find.byType(TextField).at(0), 'lvb@gmail.com');
      await tester.enterText(find.byType(TextField).at(2), '0797392641');

      // Chọn ngày sinh
      await tester.tap(find.byType(TextField).at(3));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Điền mật khẩu
      await tester.enterText(find.byType(TextField).at(4), 'lvb@123');

      // Nhấn nút đăng ký
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      // Kiểm tra thông báo lỗi "Please enter your full name"
      expect(find.text('Please enter your full name'), findsOneWidget);
    });
  });
}
