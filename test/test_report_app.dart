import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart' hide Row, Column;
import 'package:flutter/material.dart' as material show Row, Column;
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Report Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TestReportScreen(),
    );
  }
}

class TestResult {
  final String testName;
  final String description;
  final bool passed;
  final String? error;
  final DateTime timestamp;

  TestResult({
    required this.testName,
    required this.description,
    required this.passed,
    this.error,
    required this.timestamp,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      testName: json['testName'] as String,
      description: json['description'] as String,
      passed: json['passed'] as bool,
      error: json['error'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class TestReportScreen extends StatefulWidget {
  @override
  _TestReportScreenState createState() => _TestReportScreenState();
}

class _TestReportScreenState extends State<TestReportScreen> {
  List<TestResult> _results = [];
  bool _isLoading = false;
  String _statusMessage = 'Vui lòng tải lên file JSON kết quả kiểm thử';

  Future<void> _pickJsonFile() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Đang xử lý...';
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final fileBytes = result.files.first.bytes!;
        final content = utf8.decode(fileBytes);
        final jsonData = json.decode(content) as List<dynamic>;

        setState(() {
          _results = jsonData
              .map((item) => TestResult.fromJson(item as Map<String, dynamic>))
              .toList();
          _statusMessage = 'Đã tải ${_results.length} kết quả kiểm thử';
        });
      } else {
        setState(() {
          _statusMessage = 'Không có file nào được chọn';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi xử lý file: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateExcel() async {
    if (_results.isEmpty) {
      setState(() {
        _statusMessage = 'Không có dữ liệu để tạo báo cáo';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Đang tạo báo cáo Excel...';
    });

    try {
      // Tạo một workbook Excel mới
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
        final rowStyle = result.passed ? passStyle : failStyle;
        sheet.getRangeByName('A$row:F$row').cellStyle = rowStyle;

        // Thêm dữ liệu
        sheet.getRangeByName('A$row').setNumber(i + 1);
        sheet.getRangeByName('B$row').setText(result.testName);
        sheet.getRangeByName('C$row').setText(result.description);
        sheet.getRangeByName('D$row').setText(result.passed ? 'PASS' : 'FAIL');
        sheet.getRangeByName('E$row').setText(result.error ?? '');
        sheet.getRangeByName('F$row').setText(
            DateFormat('dd/MM/yyyy HH:mm:ss').format(result.timestamp));
      }

      // Tự động điều chỉnh độ rộng cột
      sheet.autoFitColumn(1); // STT
      sheet.autoFitColumn(2); // Tên Test
      sheet.autoFitColumn(3); // Mô tả
      sheet.autoFitColumn(4); // Kết quả
      sheet.autoFitColumn(5); // Lỗi
      sheet.autoFitColumn(6); // Thời gian

      // Chuyển đổi workbook thành mảng bytes
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      // Tạo tên file với timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'test_report_$timestamp.xlsx';

      // Tạo Blob và tải xuống file
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..style.display = 'none';
      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      setState(() {
        _statusMessage = 'Đã tạo báo cáo Excel thành công';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi khi tạo báo cáo Excel: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateHtmlReport() async {
    if (_results.isEmpty) {
      setState(() {
        _statusMessage = 'Không có dữ liệu để tạo báo cáo';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Đang tạo báo cáo HTML...';
    });

    try {
      final passCount = _results.where((r) => r.passed).length;
      final failCount = _results.where((r) => !r.passed).length;
      final passRate = _results.isEmpty
          ? 0
          : (passCount / _results.length * 100).toStringAsFixed(2);

      String tableRows = '';
      for (int i = 0; i < _results.length; i++) {
        final result = _results[i];
        tableRows += '''
        <tr class="${result.passed ? 'pass' : 'fail'}">
          <td>${i + 1}</td>
          <td>${result.testName}</td>
          <td>${result.description}</td>
          <td>${result.passed ? 'PASS' : 'FAIL'}</td>
          <td>${result.error ?? ''}</td>
          <td>${DateFormat('dd/MM/yyyy HH:mm:ss').format(result.timestamp)}</td>
        </tr>
        ''';
      }

      final html.DivElement reportDiv = html.DivElement()
        ..id = 'report'
        ..style.display = 'none'
        ..innerHtml = '''
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
            <p>Tổng số test: ${_results.length}</p>
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
            $tableRows
          </table>
        </body>
        </html>
        ''';

      html.document.body!.children.add(reportDiv);

      // Tạo tên file với timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'test_report_$timestamp.html';

      // Tạo Blob và tải xuống file
      final blob = html.Blob([reportDiv.innerHtml!.codeUnits], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..style.display = 'none';
      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
      html.document.body!.children.remove(reportDiv);

      setState(() {
        _statusMessage = 'Đã tạo báo cáo HTML thành công';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi khi tạo báo cáo HTML: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Report Generator'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: material.Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Tạo báo cáo kiểm thử từ file JSON',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text(
                _statusMessage,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              if (_isLoading)
                CircularProgressIndicator()
              else
                material.Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.upload_file),
                      label: Text('Tải lên file JSON'),
                      onPressed: _pickJsonFile,
                    ),
                    SizedBox(width: 20),
                    ElevatedButton.icon(
                      icon: Icon(Icons.table_chart),
                      label: Text('Tạo báo cáo Excel'),
                      onPressed: _results.isEmpty ? null : _generateExcel,
                    ),
                    SizedBox(width: 20),
                    ElevatedButton.icon(
                      icon: Icon(Icons.code),
                      label: Text('Tạo báo cáo HTML'),
                      onPressed: _results.isEmpty ? null : _generateHtmlReport,
                    ),
                  ],
                ),
              SizedBox(height: 30),
              if (_results.isNotEmpty) ...[
                Text(
                  'Tóm tắt kết quả kiểm thử',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 10),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: material.Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tổng số test: ${_results.length}'),
                        Text(
                            'Số test thành công: ${_results.where((r) => r.passed).length}'),
                        Text(
                            'Số test thất bại: ${_results.where((r) => !r.passed).length}'),
                        Text(
                            'Tỉ lệ thành công: ${_results.isEmpty ? 0 : ((_results.where((r) => r.passed).length / _results.length) * 100).toStringAsFixed(2)}%'),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        color: result.passed
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                result.passed ? Colors.green : Colors.red,
                            child: Icon(
                              result.passed ? Icons.check : Icons.close,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(result.testName),
                          subtitle: material.Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(result.description),
                              if (result.error != null &&
                                  result.error!.isNotEmpty)
                                Text(
                                  'Lỗi: ${result.error}',
                                  style: TextStyle(color: Colors.red),
                                ),
                              Text(
                                'Thời gian: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(result.timestamp)}',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
