import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

/// Lớp đại diện cho một kết quả kiểm thử
class TestEntry {
  final String testName;
  final String description;
  final bool passed;
  final String? error;
  final DateTime timestamp;

  TestEntry({
    required this.testName,
    required this.description,
    required this.passed,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory TestEntry.fromJson(Map<String, dynamic> json) {
    return TestEntry(
      testName: json['testName'] as String,
      description: json['description'] as String,
      passed: json['passed'] as bool,
      error: json['error'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'testName': testName,
      'description': description,
      'passed': passed,
      'error': error,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Lớp phụ trách tạo báo cáo Excel từ dữ liệu kiểm thử
class LocalTestReporter {
  /// Tạo báo cáo Excel từ file JSON
  static Future<String> generateReportFromJson(String jsonFilePath) async {
    final file = File(jsonFilePath);
    if (!await file.exists()) {
      throw Exception('File không tồn tại: $jsonFilePath');
    }

    final content = await file.readAsString();
    final List<dynamic> jsonList = json.decode(content) as List<dynamic>;
    final List<TestEntry> results = jsonList
        .map((item) => TestEntry.fromJson(item as Map<String, dynamic>))
        .toList();

    return generateExcelReport(results);
  }

  /// Tạo file Excel từ danh sách kết quả kiểm thử
  static Future<String> generateExcelReport(List<TestEntry> results) async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'Test Results';

    // Tạo style cho header
    final Style headerStyle = workbook.styles.add('HeaderStyle');
    headerStyle.backColor = '#4472C4';
    headerStyle.fontColor = '#FFFFFF';
    headerStyle.bold = true;
    headerStyle.hAlign = HAlignType.center;
    headerStyle.vAlign = VAlignType.center;

    // Tạo style cho dòng pass/fail
    final Style passStyle = workbook.styles.add('PassStyle');
    passStyle.backColor = '#C6EFCE';

    final Style failStyle = workbook.styles.add('FailStyle');
    failStyle.backColor = '#FFC7CE';

    // Thêm header
    sheet.getRangeByName('A1').setText('STT');
    sheet.getRangeByName('B1').setText('Tên Test');
    sheet.getRangeByName('C1').setText('Mô Tả');
    sheet.getRangeByName('D1').setText('Kết Quả');
    sheet.getRangeByName('E1').setText('Lỗi');
    sheet.getRangeByName('F1').setText('Thời Gian');
    sheet.getRangeByName('A1:F1').cellStyle = headerStyle;

    // Thêm dữ liệu
    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      final int row = i + 2; // Từ dòng 2

      // Áp dụng style theo kết quả
      final rowStyle = result.passed ? passStyle : failStyle;
      sheet.getRangeByName('A$row:F$row').cellStyle = rowStyle;

      // Thêm dữ liệu vào ô
      sheet.getRangeByName('A$row').setNumber(i + 1);
      sheet.getRangeByName('B$row').setText(result.testName);
      sheet.getRangeByName('C$row').setText(result.description);
      sheet.getRangeByName('D$row').setText(result.passed ? 'PASS' : 'FAIL');
      sheet.getRangeByName('E$row').setText(result.error ?? '');
      sheet
          .getRangeByName('F$row')
          .setText(DateFormat('dd/MM/yyyy HH:mm:ss').format(result.timestamp));
    }

    // Tự động điều chỉnh độ rộng cột
    sheet.autoFitColumn(1); // STT
    sheet.autoFitColumn(2); // Tên Test
    sheet.autoFitColumn(3); // Mô Tả
    sheet.autoFitColumn(4); // Kết Quả
    sheet.autoFitColumn(5); // Lỗi
    sheet.autoFitColumn(6); // Thời Gian

    // Lưu file
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    // Tạo thư mục reports nếu chưa tồn tại
    final reportsDir = Directory('reports');
    if (!await reportsDir.exists()) {
      await reportsDir.create();
    }

    // Tạo tên file với timestamp
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final String filePath = 'reports/test_report_$timestamp.xlsx';

    // Ghi file
    final File outputFile = File(filePath);
    await outputFile.writeAsBytes(bytes);

    return filePath;
  }

  /// Tạo file JSON từ dữ liệu kiểm thử để lưu trữ
  static Future<String> saveResultsToJson(List<TestEntry> results) async {
    final jsonList = results.map((result) => result.toJson()).toList();
    final jsonContent = json.encode(jsonList);

    // Tạo thư mục reports nếu chưa tồn tại
    final reportsDir = Directory('reports');
    if (!await reportsDir.exists()) {
      await reportsDir.create();
    }

    // Tạo tên file với timestamp
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final String filePath = 'reports/test_data_$timestamp.json';

    // Ghi file
    final File outputFile = File(filePath);
    await outputFile.writeAsString(jsonContent);

    return filePath;
  }
}

/// Chạy công cụ tạo báo cáo
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Cách sử dụng: dart local_test_reporter.dart <đường_dẫn_file_json>');
    return;
  }

  final jsonFilePath = args[0];
  try {
    final excelFilePath =
        await LocalTestReporter.generateReportFromJson(jsonFilePath);
    print('Đã tạo báo cáo Excel thành công: $excelFilePath');
  } catch (e) {
    print('Lỗi khi tạo báo cáo: $e');
  }
}
