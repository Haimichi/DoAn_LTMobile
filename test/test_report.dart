import 'dart:io';
import 'dart:convert';
import 'dart:collection';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

/// Lớp TestResult lưu trữ kết quả của một bài kiểm thử.
class TestResult {
  final String testName;
  final String testDescription;
  final bool isPassed;
  final String? errorMessage;
  final DateTime timestamp;

  TestResult({
    required this.testName,
    required this.testDescription,
    required this.isPassed,
    this.errorMessage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'TestResult{testName: $testName, isPassed: $isPassed, errorMessage: $errorMessage, timestamp: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(timestamp)}}';
  }

  /// Chuyển đổi TestResult thành Map để dễ dàng chuyển đổi sang JSON
  Map<String, dynamic> toJson() {
    return {
      'testName': testName,
      'description': testDescription,
      'passed': isPassed,
      'error': errorMessage,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Tạo TestResult từ JSON
  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      testName: json['testName'] as String,
      testDescription: json['description'] as String,
      isPassed: json['passed'] as bool,
      errorMessage: json['error'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Lớp TestReport quản lý việc ghi nhận và xuất báo cáo kiểm thử.
class TestReport {
  static final List<TestResult> _results = [];

  /// Thêm một kết quả kiểm thử vào danh sách.
  static void addResult(TestResult result) {
    _results.add(result);
  }

  /// Chỉ tạo dữ liệu Excel và trả về bytes, không lưu file
  static Future<List<int>> generateExcelBytesOnly() async {
    // Tạo workbook và worksheet
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'Test Results';

    // Định dạng tiêu đề
    final Style headerStyle = workbook.styles.add('HeaderStyle');
    headerStyle.backColor = '#4472C4';
    headerStyle.fontColor = '#FFFFFF';
    headerStyle.bold = true;
    headerStyle.hAlign = HAlignType.center;
    headerStyle.vAlign = VAlignType.center;

    // Định dạng dòng đạt
    final Style passStyle = workbook.styles.add('PassStyle');
    passStyle.backColor = '#C6EFCE';

    // Định dạng dòng không đạt
    final Style failStyle = workbook.styles.add('FailStyle');
    failStyle.backColor = '#FFC7CE';

    // Thêm tiêu đề
    sheet.getRangeByName('A1').setText('STT');
    sheet.getRangeByName('B1').setText('Tên Test');
    sheet.getRangeByName('C1').setText('Mô tả');
    sheet.getRangeByName('D1').setText('Kết quả');
    sheet.getRangeByName('E1').setText('Lỗi');
    sheet.getRangeByName('F1').setText('Thời gian');

    // Áp dụng style cho tiêu đề
    sheet.getRangeByName('A1:F1').cellStyle = headerStyle;

    // Thêm kết quả test
    for (int i = 0; i < _results.length; i++) {
      final TestResult result = _results[i];
      final int row = i + 2; // Dòng 2 trở đi

      // Áp dụng style dựa trên kết quả
      final Style rowStyle = result.isPassed ? passStyle : failStyle;
      sheet.getRangeByName('A$row:F$row').cellStyle = rowStyle;

      // Thêm dữ liệu
      sheet.getRangeByName('A$row').setNumber(i + 1);
      sheet.getRangeByName('B$row').setText(result.testName);
      sheet.getRangeByName('C$row').setText(result.testDescription);
      sheet.getRangeByName('D$row').setText(result.isPassed ? 'PASS' : 'FAIL');
      sheet.getRangeByName('E$row').setText(result.errorMessage ?? '');
      sheet
          .getRangeByName('F$row')
          .setText(DateFormat('dd/MM/yyyy HH:mm:ss').format(result.timestamp));
    }

    // Tự động điều chỉnh độ rộng cột
    sheet.autoFitColumn(1); // STT
    sheet.autoFitColumn(2); // Tên Test
    sheet.autoFitColumn(3); // Mô tả
    sheet.autoFitColumn(4); // Kết quả
    sheet.autoFitColumn(5); // Lỗi
    sheet.autoFitColumn(6); // Thời gian

    // Lưu file và giải phóng workbook
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    return bytes;
  }

  /// Tạo báo cáo Excel từ các kết quả kiểm thử đã ghi nhận.
  ///
  /// [customFileName]: Tên file Excel mong muốn. Nếu không cung cấp, sẽ tạo tên mặc định.
  /// [deviceDirectory]: Nếu true, lưu vào thư mục Documents trên thiết bị.
  /// Nếu false, cố gắng lưu vào thư mục reports trong project (nếu chạy trên máy tính).
  static Future<String> generateExcelReport({
    String? customFileName,
    bool deviceDirectory = true,
  }) async {
    // Tạo dữ liệu Excel
    final List<int> bytes = await generateExcelBytesOnly();

    // Xác định tên file và thư mục
    String fileName = customFileName ??
        'test_results_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    String filePath;

    if (deviceDirectory) {
      // Lưu vào thư mục Documents trên thiết bị
      final Directory directory = await getApplicationDocumentsDirectory();
      filePath = '${directory.path}/$fileName';
    } else {
      // Cố gắng lưu vào thư mục reports trong project
      try {
        // Đường dẫn đến thư mục reports
        final String projectDir = Directory.current.path;
        final String reportsDir = '$projectDir/reports';

        // Tạo thư mục reports nếu chưa tồn tại
        final Directory reportsDirectory = Directory(reportsDir);
        if (!await reportsDirectory.exists()) {
          await reportsDirectory.create(recursive: true);
        }

        filePath = '$reportsDir/$fileName';
      } catch (e) {
        // Fallback: Lưu vào thư mục Documents nếu không thể lưu vào project
        print(
            'Không thể lưu vào thư mục project, fallback sang thư mục Documents: $e');
        final Directory directory = await getApplicationDocumentsDirectory();
        filePath = '${directory.path}/$fileName';
      }
    }

    // Ghi file
    final File file = File(filePath);
    await file.writeAsBytes(bytes);

    return filePath;
  }

  /// Xuất kết quả kiểm thử ra file JSON
  static Future<String> exportResultsToJson({
    String? customFileName,
    bool deviceDirectory = true,
  }) async {
    // Chuyển đổi danh sách kết quả thành định dạng JSON
    final List<Map<String, dynamic>> jsonList =
        _results.map((result) => result.toJson()).toList();
    final String jsonContent = json.encode(jsonList);

    // Xác định tên file và thư mục
    String fileName = customFileName ??
        'test_data_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
    String filePath;

    if (deviceDirectory) {
      // Lưu vào thư mục Documents trên thiết bị
      final Directory directory = await getApplicationDocumentsDirectory();
      filePath = '${directory.path}/$fileName';
    } else {
      // Cố gắng lưu vào thư mục reports trong project
      try {
        // Đường dẫn đến thư mục reports
        final String projectDir = Directory.current.path;
        final String reportsDir = '$projectDir/reports';

        // Tạo thư mục reports nếu chưa tồn tại
        final Directory reportsDirectory = Directory(reportsDir);
        if (!await reportsDirectory.exists()) {
          await reportsDirectory.create(recursive: true);
        }

        filePath = '$reportsDir/$fileName';
      } catch (e) {
        // Fallback: Lưu vào thư mục Documents nếu không thể lưu vào project
        print(
            'Không thể lưu vào thư mục project, fallback sang thư mục Documents: $e');
        final Directory directory = await getApplicationDocumentsDirectory();
        filePath = '${directory.path}/$fileName';
      }
    }

    // Ghi file
    final File file = File(filePath);
    await file.writeAsString(jsonContent);

    return filePath;
  }

  /// Xóa tất cả kết quả kiểm thử đã ghi nhận.
  static void clearResults() {
    _results.clear();
  }

  /// Trả về danh sách các kết quả kiểm thử (không thay đổi được).
  static UnmodifiableListView<TestResult> getResults() {
    return UnmodifiableListView(_results);
  }
}
