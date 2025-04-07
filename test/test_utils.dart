import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../test/test_report.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Lớp hỗ trợ xuất kết quả kiểm thử
class TestExporter {
  /// Hàm này tạo báo cáo Excel và in ra thông tin cần thiết
  /// để copy file từ thiết bị vào thư mục project
  static Future<void> exportTestResults({
    String? testType,
    String? description,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePrefix = testType != null ? '${testType}_' : '';
    final fileName = '${filePrefix}test_report_$timestamp.xlsx';

    try {
      String? filePath;
      String? projectFilePath;

      // Thử lưu trực tiếp vào thư mục project trước
      try {
        if (!kIsWeb) {
          final String currentDir = Directory.current.path;
          final reportsDir = '$currentDir/reports';

          // Tạo thư mục reports nếu chưa tồn tại
          final dir = Directory(reportsDir);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }

          // Lưu file trực tiếp vào thư mục reports trong project
          projectFilePath = '$reportsDir/$fileName';

          // Tạo báo cáo Excel và lưu vào thư mục project
          final workbookBytes = await TestReport.generateExcelBytesOnly();
          final projectFile = File(projectFilePath);
          await projectFile.writeAsBytes(workbookBytes);
        }
      } catch (e) {
        print('Không thể lưu trực tiếp vào thư mục project: $e');
        projectFilePath = null;
      }

      // Lưu vào thư mục Documents trên thiết bị
      filePath = await TestReport.generateExcelReport(
        customFileName: fileName,
        deviceDirectory: true,
      );

      // In thông tin báo cáo
      print('\n========== BÁO CÁO KIỂM THỬ ==========');
      if (description != null) {
        print('Loại kiểm thử: $description');
      }
      print(
          'Thời gian: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}');
      print('Tổng số test: ${TestReport.getResults().length}');
      print(
          'Số test thành công: ${TestReport.getResults().where((r) => r.isPassed).length}');
      print(
          'Số test thất bại: ${TestReport.getResults().where((r) => !r.isPassed).length}');

      // Hiển thị đường dẫn file báo cáo
      print('\n========== THÔNG TIN FILE BÁO CÁO ==========');
      print('Đã lưu báo cáo kết quả vào: $filePath');

      // Hướng dẫn sao chép từ thiết bị di động
      if (projectFilePath == null) {
        print('\nĐể sao chép báo cáo vào máy tính:');
        if (Platform.isAndroid) {
          print('adb pull $filePath ${Directory.current.path}/reports/');
        } else if (Platform.isIOS) {
          print('\nĐối với iOS simulator, báo cáo được lưu tại:');
          print(
              '/path/to/simulator/data/Containers/Data/Application/<app-id>/Documents/$fileName');
        }
      }
      // Báo cáo nếu đã lưu thành công vào thư mục project
      else {
        print('\nĐã lưu báo cáo vào thư mục project tại:');
        print(projectFilePath);
      }

      print('=========================================');

      // Tạo báo cáo HTML
      await createHTMLSummary();
    } catch (e) {
      print('Lỗi khi xuất báo cáo kiểm thử: $e');
    }
  }

  /// Tạo HTML summary từ kết quả test
  static Future<String> createHTMLSummary() async {
    final results = TestReport.getResults();
    final passCount = results.where((r) => r.isPassed).length;
    final failCount = results.where((r) => !r.isPassed).length;
    final passRate = results.isEmpty
        ? 0
        : (passCount / results.length * 100).toStringAsFixed(2);

    final html = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Báo Cáo Kiểm Thử</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #2c3e50; }
        .summary { background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #4472C4; color: white; }
        tr.pass { background-color: #C6EFCE; }
        tr.fail { background-color: #FFC7CE; }
        .timestamp { color: #7f8c8d; font-size: 0.9em; }
      </style>
    </head>
    <body>
      <h1>Báo Cáo Kết Quả Kiểm Thử</h1>
      
      <div class="summary">
        <h2>Tổng Quan</h2>
        <p>Thời gian: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}</p>
        <p>Tổng số test: ${results.length}</p>
        <p>Số test thành công: $passCount</p>
        <p>Số test thất bại: $failCount</p>
        <p>Tỉ lệ thành công: $passRate%</p>
      </div>
      
      <h2>Chi Tiết Các Bài Kiểm Thử</h2>
      <table>
        <tr>
          <th>STT</th>
          <th>Tên Test</th>
          <th>Mô Tả</th>
          <th>Kết Quả</th>
          <th>Lỗi</th>
          <th>Thời Gian</th>
        </tr>
        ${_generateTableRows(results)}
      </table>
    </body>
    </html>
    ''';

    // Thử lưu file HTML vào thư mục project
    String htmlPath;
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final htmlFileName = 'test_summary_$timestamp.html';

    try {
      if (!kIsWeb) {
        final String currentDir = Directory.current.path;
        final reportsDir = '$currentDir/reports';

        // Tạo thư mục reports nếu chưa tồn tại
        final dir = Directory(reportsDir);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        // Lưu file HTML
        htmlPath = '$reportsDir/$htmlFileName';
        await File(htmlPath).writeAsString(html);
        print('Đã tạo báo cáo HTML tại: $htmlPath');

        return htmlPath;
      }
    } catch (e) {
      print('Không thể lưu HTML vào thư mục project: $e');
    }

    // Fallback: Lưu vào thư mục Documents
    final directory = await getApplicationDocumentsDirectory();
    htmlPath = '${directory.path}/$htmlFileName';
    await File(htmlPath).writeAsString(html);
    print('Đã tạo báo cáo HTML tại: $htmlPath');

    return htmlPath;
  }

  // Hàm helper để tạo các dòng trong bảng HTML
  static String _generateTableRows(List<TestResult> results) {
    String rows = '';
    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      rows += '''
      <tr class="${result.isPassed ? 'pass' : 'fail'}">
        <td>${i + 1}</td>
        <td>${result.testName}</td>
        <td>${result.testDescription}</td>
        <td>${result.isPassed ? 'PASS' : 'FAIL'}</td>
        <td>${result.errorMessage ?? ''}</td>
        <td class="timestamp">${DateFormat('dd/MM/yyyy HH:mm:ss').format(result.timestamp)}</td>
      </tr>
      ''';
    }
    return rows;
  }
}
