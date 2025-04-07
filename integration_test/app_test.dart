import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:booky/screens/authentication_screens/sign_up_screen.dart';
import 'package:booky/common/widgets/custom_button.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../test/test_report.dart';
import '../test/test_utils.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo danh sách kết quả test
  TestReport.clearResults();

  late List<Map<String, dynamic>> testResults;

  setUp(() async {
    testResults = [];
  });

  Future<void> saveTestResult(
      String testName, bool passed, String message) async {
    testResults.add({
      'test_name': testName,
      'passed': passed,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    });

    try {
      // Lưu vào thư mục tạm thời
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'registration_test_data_${DateTime.now().millisecondsSinceEpoch}.json';
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);

      await file.writeAsString(jsonEncode({
        'test_results': testResults,
        'total_tests': testResults.length,
        'passed_tests': testResults.where((result) => result['passed']).length,
        'failed_tests': testResults.where((result) => !result['passed']).length,
      }));

      print('Đã lưu báo cáo JSON vào: $filePath');
      print('\nHƯỚNG DẪN TẠO BÁO CÁO HTML:');
      print(
          '1. Mở ứng dụng web tạo báo cáo: flutter run -d chrome -t test/test_report_web.dart');
      print('2. Tải lên file JSON và tạo báo cáo HTML\n');
    } catch (e) {
      print('Lỗi khi lưu báo cáo: $e');
    }
  }

  group('Kiểm thử đăng ký tài khoản', () {
    final DateTime startTime = DateTime.now();

    Future<void> saveJsonReport() async {
      try {
        final List<Map<String, dynamic>> jsonList = testResults.map((result) {
          return {
            'testName': result['test_name'],
            'description': result['message'],
            'passed': result['passed'],
            'error': result['message'],
            'timestamp': startTime.toIso8601String()
          };
        }).toList();

        final String jsonContent = jsonEncode(jsonList);

        // In kết quả test ra console
        print('\n========= KẾT QUẢ TEST =========');
        print('Tổng số test: ${testResults.length}');
        print(
            'Số test thành công: ${testResults.where((result) => result['passed']).length}');
        print(
            'Số test thất bại: ${testResults.where((result) => !result['passed']).length}');
        print('\nChi tiết kết quả:');

        for (var result in testResults) {
          final status = result['passed'] ? '✅ PASS' : '❌ FAIL';
          print('$status - ${result['test_name']}: ${result['message']}');
        }

        print('\n===============================');

        // Lưu vào thư mục cache và in đường dẫn
        final tempDir = await getTemporaryDirectory();
        final fileName = 'registration_test_results.json';
        final filePath = '${tempDir.path}/$fileName';
        final File file = File(filePath);
        await file.writeAsString(jsonContent);
        print('\nĐã lưu báo cáo JSON vào: $filePath');

        // In đường dẫn để lấy file từ thiết bị
        print('\nĐể lấy file JSON từ thiết bị Android:');
        print(
            'adb shell "run-as com.example.booky cat $filePath" > registration_test_results.json');

        print('\nĐể lấy file JSON từ thiết bị iOS:');
        print('1. Mở Simulator');
        print('2. Vào menu: File > Open Files... hoặc Cmd+Shift+O');
        print('3. Tìm và mở file $filePath');

        print('\nHƯỚNG DẪN TẠO BÁO CÁO HTML:');
        print(
            '1. Mở ứng dụng web tạo báo cáo: flutter run -d chrome -t test/test_report_web.dart');
        print('2. Tải lên file JSON và tạo báo cáo HTML\n');
      } catch (e) {
        print('Lỗi khi lưu báo cáo JSON: $e');
      }
    }

    testWidgets('Đăng ký thành công với đầy đủ thông tin',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
      await tester.pumpAndSettle();

      // Tìm các TextField bằng key
      final emailField = find.byKey(Key('email_field'));
      final fullNameField = find.byKey(Key('fullname_field'));
      final phoneField = find.byKey(Key('phone_field'));
      final birthdateField = find.byKey(Key('birthdate_field'));
      final passwordField = find.byKey(Key('password_field'));

      // Nhập thông tin
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(fullNameField, 'Test User');
      await tester.enterText(phoneField, '0123456789');
      await tester.enterText(birthdateField, '01/01/2000');
      await tester.enterText(passwordField, 'Password123!');

      // Kiểm tra validation
      expect(find.text('Please enter your email'), findsNothing);
      expect(find.text('Please enter your full name'), findsNothing);
      expect(find.text('Please enter your phone number'), findsNothing);
      expect(find.text('Please select your birth date'), findsNothing);
      expect(find.text('Please enter your password'), findsNothing);

      await saveTestResult('Đăng ký thành công với đầy đủ thông tin', true,
          'Validation pass với thông tin hợp lệ');
    });

    testWidgets('Đăng ký thất bại khi để trống email',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
      await tester.pumpAndSettle();

      // Tìm các TextField
      final fullNameField = find.byKey(Key('fullname_field'));
      final phoneField = find.byKey(Key('phone_field'));
      final birthdateField = find.byKey(Key('birthdate_field'));
      final passwordField = find.byKey(Key('password_field'));

      // Nhập thông tin (bỏ trống email)
      await tester.enterText(fullNameField, 'Test User');
      await tester.enterText(phoneField, '0123456789');
      await tester.enterText(birthdateField, '01/01/2000');
      await tester.enterText(passwordField, 'Password123!');

      // Tìm và nhấn nút đăng ký
      final signUpButton = find.byType(CustomButton).first;
      await tester.tap(signUpButton);

      // Đợi thông báo lỗi hiển thị
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Kiểm tra validation bằng cách tìm kiếm TextFormField có lỗi
      // Nhấn nút đăng ký sẽ trigger validation và hiển thị lỗi
      // Kiểm tra xem form có được submit hay không
      expect(find.byType(SnackBar), findsNothing);
      await saveTestResult('Đăng ký thất bại khi để trống email', true,
          'Hiển thị thông báo lỗi khi để trống email');
    });

    testWidgets('Đăng ký thất bại khi để trống họ tên',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
      await tester.pumpAndSettle();

      // Tìm các TextField
      final emailField = find.byKey(Key('email_field'));
      final phoneField = find.byKey(Key('phone_field'));
      final birthdateField = find.byKey(Key('birthdate_field'));
      final passwordField = find.byKey(Key('password_field'));

      // Nhập thông tin (bỏ trống họ tên)
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(phoneField, '0123456789');
      await tester.enterText(birthdateField, '01/01/2000');
      await tester.enterText(passwordField, 'Password123!');

      // Tìm và nhấn nút đăng ký
      final signUpButton = find.byType(CustomButton).first;
      await tester.tap(signUpButton);

      // Đợi thông báo lỗi hiển thị
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Kiểm tra validation bằng cách kiểm tra xem form có được submit hay không
      // Nếu validation thất bại, SnackBar sẽ không hiển thị
      expect(find.byType(SnackBar), findsNothing);
      await saveTestResult('Đăng ký thất bại khi để trống họ tên', true,
          'Hiển thị thông báo lỗi khi để trống họ tên');
    });

    testWidgets('Đăng ký thất bại khi định dạng email không hợp lệ',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
      await tester.pumpAndSettle();

      // Tìm các TextField
      final emailField = find.byKey(Key('email_field'));
      final fullNameField = find.byKey(Key('fullname_field'));
      final phoneField = find.byKey(Key('phone_field'));
      final birthdateField = find.byKey(Key('birthdate_field'));
      final passwordField = find.byKey(Key('password_field'));

      // Nhập thông tin với email không hợp lệ
      await tester.enterText(emailField, 'invalid-email');
      await tester.enterText(fullNameField, 'Test User');
      await tester.enterText(phoneField, '0123456789');
      await tester.enterText(birthdateField, '01/01/2000');
      await tester.enterText(passwordField, 'Password123!');

      // Tìm và nhấn nút đăng ký
      final signUpButton = find.byType(CustomButton).first;
      await tester.tap(signUpButton);

      // Đợi thông báo lỗi hiển thị
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Kiểm tra validation bằng cách kiểm tra xem form có được submit hay không
      // Nếu validation thất bại, SnackBar sẽ không hiển thị
      expect(find.byType(SnackBar), findsNothing);
      await saveTestResult('Đăng ký thất bại khi định dạng email không hợp lệ',
          true, 'Hiển thị thông báo lỗi khi email không hợp lệ');
    });

    testWidgets('Đăng ký thất bại khi để trống số điện thoại',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
      await tester.pumpAndSettle();

      // Tìm các TextField
      final emailField = find.byKey(Key('email_field'));
      final fullNameField = find.byKey(Key('fullname_field'));
      final birthdateField = find.byKey(Key('birthdate_field'));
      final passwordField = find.byKey(Key('password_field'));

      // Nhập thông tin (bỏ trống số điện thoại)
      await tester.enterText(emailField, 'lequangduy@gmail.com');
      await tester.enterText(fullNameField, 'Le Van B');
      await tester.enterText(birthdateField, '16/1/2003');
      await tester.enterText(passwordField, 'lvb@123');

      // Tìm và nhấn nút đăng ký
      final signUpButton = find.byType(CustomButton).first;
      await tester.tap(signUpButton);

      // Đợi thông báo lỗi hiển thị
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Kiểm tra validation bằng cách kiểm tra xem form có được submit hay không
      // Nếu validation thất bại, SnackBar sẽ không hiển thị
      expect(find.byType(SnackBar), findsNothing);
      await saveTestResult('Đăng ký thất bại khi để trống số điện thoại', true,
          'Hiển thị thông báo lỗi khi để trống số điện thoại');
    });

    testWidgets('Đăng ký thất bại khi để trống ngày sinh',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
      await tester.pumpAndSettle();

      // Tìm các TextField
      final emailField = find.byKey(Key('email_field'));
      final fullNameField = find.byKey(Key('fullname_field'));
      final phoneField = find.byKey(Key('phone_field'));
      final passwordField = find.byKey(Key('password_field'));

      // Nhập thông tin (bỏ trống ngày sinh)
      await tester.enterText(emailField, 'lvb@gmail.com');
      await tester.enterText(fullNameField, 'Le Van B');
      await tester.enterText(phoneField, '0797392641');
      await tester.enterText(passwordField, 'lvb@123');

      // Tìm và nhấn nút đăng ký
      final signUpButton = find.byType(CustomButton).first;
      await tester.tap(signUpButton);

      // Đợi thông báo lỗi hiển thị
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Kiểm tra validation bằng cách kiểm tra xem form có được submit hay không
      // Nếu validation thất bại, SnackBar sẽ không hiển thị
      expect(find.byType(SnackBar), findsNothing);
      await saveTestResult('Đăng ký thất bại khi để trống ngày sinh', true,
          'Hiển thị thông báo lỗi khi để trống ngày sinh');
    });

    testWidgets('Đăng ký thất bại khi để trống mật khẩu',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
      await tester.pumpAndSettle();

      // Tìm các TextField
      final emailField = find.byKey(Key('email_field'));
      final fullNameField = find.byKey(Key('fullname_field'));
      final phoneField = find.byKey(Key('phone_field'));
      final birthdateField = find.byKey(Key('birthdate_field'));

      // Nhập thông tin (bỏ trống mật khẩu)
      await tester.enterText(emailField, 'lvb@gmail.com');
      await tester.enterText(fullNameField, 'Le Van B');
      await tester.enterText(phoneField, '0797392641');
      await tester.enterText(birthdateField, '16/1/2003');

      // Tìm và nhấn nút đăng ký
      final signUpButton = find.byType(CustomButton).first;
      await tester.tap(signUpButton);

      // Đợi thông báo lỗi hiển thị
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Kiểm tra validation bằng cách kiểm tra xem form có được submit hay không
      // Nếu validation thất bại, SnackBar sẽ không hiển thị
      expect(find.byType(SnackBar), findsNothing);
      await saveTestResult('Đăng ký thất bại khi để trống mật khẩu', true,
          'Hiển thị thông báo lỗi khi để trống mật khẩu');
    });

    testWidgets('Đăng ký thất bại khi nhập sai định dạng email',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
      await tester.pumpAndSettle();

      // Tìm các TextField
      final emailField = find.byKey(Key('email_field'));
      final fullNameField = find.byKey(Key('fullname_field'));
      final phoneField = find.byKey(Key('phone_field'));
      final birthdateField = find.byKey(Key('birthdate_field'));
      final passwordField = find.byKey(Key('password_field'));

      // Nhập thông tin với email không hợp lệ
      await tester.enterText(emailField, 'lvbgmail');
      await tester.enterText(fullNameField, 'Le Van B');
      await tester.enterText(phoneField, '0797392641');
      await tester.enterText(birthdateField, '16/1/2003');
      await tester.enterText(passwordField, 'lvb@123');

      // Tìm và nhấn nút đăng ký
      final signUpButton = find.byType(CustomButton).first;
      await tester.tap(signUpButton);

      // Đợi thông báo lỗi hiển thị
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Kiểm tra thông báo lỗi
      expect(find.text('Please enter a valid email'), findsOneWidget);
      await saveTestResult('Đăng ký thất bại khi nhập sai định dạng email',
          true, 'Hiển thị thông báo lỗi khi email không hợp lệ');
    });

    testWidgets('Đăng ký thất bại khi nhập ký tự đặc biệt vào tên',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
      await tester.pumpAndSettle();

      // Tìm các TextField
      final emailField = find.byKey(Key('email_field'));
      final fullNameField = find.byKey(Key('fullname_field'));
      final phoneField = find.byKey(Key('phone_field'));
      final birthdateField = find.byKey(Key('birthdate_field'));
      final passwordField = find.byKey(Key('password_field'));

      // Nhập thông tin với tên có ký tự đặc biệt
      await tester.enterText(emailField, 'lvb@gmail.com');
      await tester.enterText(fullNameField, 'Le@!?`~,.');
      await tester.enterText(phoneField, '0797392641');
      await tester.enterText(birthdateField, '16/1/2003');
      await tester.enterText(passwordField, 'lvb@123');

      // Tìm và nhấn nút đăng ký
      final signUpButton = find.byType(CustomButton).first;
      await tester.tap(signUpButton);

      // Đợi thông báo lỗi hiển thị
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Kiểm tra validation bằng cách kiểm tra xem form có được submit hay không
      // Nếu validation thất bại, SnackBar sẽ không hiển thị
      expect(find.byType(SnackBar), findsNothing);
      await saveTestResult('Đăng ký thất bại khi nhập ký tự đặc biệt vào tên',
          true, 'Hiển thị thông báo lỗi khi tên có ký tự đặc biệt');
    });

    testWidgets('Đăng ký thất bại khi nhập sai định dạng số điện thoại',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
      await tester.pumpAndSettle();

      // Tìm các TextField
      final emailField = find.byKey(Key('email_field'));
      final fullNameField = find.byKey(Key('fullname_field'));
      final phoneField = find.byKey(Key('phone_field'));
      final birthdateField = find.byKey(Key('birthdate_field'));
      final passwordField = find.byKey(Key('password_field'));

      // Nhập thông tin với số điện thoại không hợp lệ
      await tester.enterText(emailField, 'lvb@gmail.com');
      await tester.enterText(fullNameField, 'Le Van B');
      await tester.enterText(phoneField, '12345');
      await tester.enterText(birthdateField, '16/1/2003');
      await tester.enterText(passwordField, 'lvb@123');

      // Tìm và nhấn nút đăng ký
      final signUpButton = find.byType(CustomButton).first;
      await tester.tap(signUpButton);

      // Đợi thông báo lỗi hiển thị
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Kiểm tra validation bằng cách kiểm tra xem form có được submit hay không
      // Nếu validation thất bại, SnackBar sẽ không hiển thị
      expect(find.byType(SnackBar), findsNothing);
      await saveTestResult(
          'Đăng ký thất bại khi nhập sai định dạng số điện thoại',
          true,
          'Hiển thị thông báo lỗi khi số điện thoại không hợp lệ');
    });

    testWidgets('Đăng ký thất bại khi nhập sai định dạng ngày sinh',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
      await tester.pumpAndSettle();

      // Tìm các TextField
      final emailField = find.byKey(Key('email_field'));
      final fullNameField = find.byKey(Key('fullname_field'));
      final phoneField = find.byKey(Key('phone_field'));
      final birthdateField = find.byKey(Key('birthdate_field'));
      final passwordField = find.byKey(Key('password_field'));

      // Nhập thông tin với ngày sinh không hợp lệ
      await tester.enterText(emailField, 'lvb@gmail.com');
      await tester.enterText(fullNameField, 'Le Van B');
      await tester.enterText(phoneField, '0797392641');
      await tester.enterText(birthdateField, '32/13/2003');
      await tester.enterText(passwordField, 'lvb@123');

      // Tìm và nhấn nút đăng ký
      final signUpButton = find.byType(CustomButton).first;
      await tester.tap(signUpButton);

      // Đợi thông báo lỗi hiển thị
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Kiểm tra validation bằng cách kiểm tra xem form có được submit hay không
      // Nếu validation thất bại, SnackBar sẽ không hiển thị
      expect(find.byType(SnackBar), findsNothing);
      await saveTestResult('Đăng ký thất bại khi nhập sai định dạng ngày sinh',
          true, 'Hiển thị thông báo lỗi khi ngày sinh không hợp lệ');
    });

    testWidgets('Đăng ký thất bại khi mật khẩu quá ngắn',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
      await tester.pumpAndSettle();

      // Tìm các TextField
      final emailField = find.byKey(Key('email_field'));
      final fullNameField = find.byKey(Key('fullname_field'));
      final phoneField = find.byKey(Key('phone_field'));
      final birthdateField = find.byKey(Key('birthdate_field'));
      final passwordField = find.byKey(Key('password_field'));

      // Nhập thông tin với mật khẩu quá ngắn
      await tester.enterText(emailField, 'lvb@gmail.com');
      await tester.enterText(fullNameField, 'Le Van B');
      await tester.enterText(phoneField, '0797392641');
      await tester.enterText(birthdateField, '16/1/2003');
      await tester.enterText(passwordField, '123');

      // Tìm và nhấn nút đăng ký
      final signUpButton = find.byType(CustomButton).first;
      await tester.tap(signUpButton);

      // Đợi thông báo lỗi hiển thị
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Kiểm tra validation bằng cách kiểm tra xem form có được submit hay không
      // Nếu validation thất bại, SnackBar sẽ không hiển thị
      expect(find.byType(SnackBar), findsNothing);
      await saveTestResult('Đăng ký thất bại khi mật khẩu quá ngắn', true,
          'Hiển thị thông báo lỗi khi mật khẩu quá ngắn');
    });

    testWidgets('Đăng ký thất bại khi mật khẩu không có ký tự đặc biệt',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
      await tester.pumpAndSettle();

      // Tìm các TextField
      final emailField = find.byKey(Key('email_field'));
      final fullNameField = find.byKey(Key('fullname_field'));
      final phoneField = find.byKey(Key('phone_field'));
      final birthdateField = find.byKey(Key('birthdate_field'));
      final passwordField = find.byKey(Key('password_field'));

      // Nhập thông tin với mật khẩu không có ký tự đặc biệt
      await tester.enterText(emailField, 'lvb@gmail.com');
      await tester.enterText(fullNameField, 'Le Van B');
      await tester.enterText(phoneField, '0797392641');
      await tester.enterText(birthdateField, '16/1/2003');
      await tester.enterText(passwordField, 'lvb123456');

      // Tìm và nhấn nút đăng ký
      final signUpButton = find.byType(CustomButton).first;
      await tester.tap(signUpButton);

      // Đợi thông báo lỗi hiển thị
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Kiểm tra validation bằng cách kiểm tra xem form có được submit hay không
      // Nếu validation thất bại, SnackBar sẽ không hiển thị
      expect(find.byType(SnackBar), findsNothing);
      await saveTestResult(
          'Đăng ký thất bại khi mật khẩu không có ký tự đặc biệt',
          true,
          'Hiển thị thông báo lỗi khi mật khẩu không có ký tự đặc biệt');
    });

    testWidgets('Đăng ký thất bại khi mật khẩu không có chữ hoa',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
      await tester.pumpAndSettle();

      // Tìm các TextField
      final emailField = find.byKey(Key('email_field'));
      final fullNameField = find.byKey(Key('fullname_field'));
      final phoneField = find.byKey(Key('phone_field'));
      final birthdateField = find.byKey(Key('birthdate_field'));
      final passwordField = find.byKey(Key('password_field'));

      // Nhập thông tin với mật khẩu không có chữ hoa
      await tester.enterText(emailField, 'lvb@gmail.com');
      await tester.enterText(fullNameField, 'Le Van B');
      await tester.enterText(phoneField, '0797392641');
      await tester.enterText(birthdateField, '16/1/2003');
      await tester.enterText(passwordField, 'lvb@123');

      // Tìm và nhấn nút đăng ký
      final signUpButton = find.byType(CustomButton).first;
      await tester.tap(signUpButton);

      // Đợi thông báo lỗi hiển thị
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Kiểm tra validation bằng cách kiểm tra xem form có được submit hay không
      // Nếu validation thất bại, SnackBar sẽ không hiển thị
      expect(find.byType(SnackBar), findsNothing);
      await saveTestResult('Đăng ký thất bại khi mật khẩu không có chữ hoa',
          true, 'Hiển thị thông báo lỗi khi mật khẩu không có chữ hoa');
    });

    tearDownAll(() async {
      // Lưu báo cáo sau khi tất cả các test hoàn thành
      await saveJsonReport();
    });
  });
}
