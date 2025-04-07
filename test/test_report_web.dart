import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Report Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TestReportScreen(),
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
  const TestReportScreen({Key? key}) : super(key: key);

  @override
  State<TestReportScreen> createState() => _TestReportScreenState();
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
      // Tạo input element để chọn file
      final uploadInput = html.FileUploadInputElement();
      uploadInput.accept = '.json';
      uploadInput.click();

      await uploadInput.onChange.first;
      if (uploadInput.files!.isEmpty) {
        setState(() {
          _statusMessage = 'Không có file nào được chọn';
          _isLoading = false;
        });
        return;
      }

      final file = uploadInput.files![0];
      final reader = html.FileReader();
      reader.readAsText(file);

      await reader.onLoad.first;
      final content = reader.result as String;
      final jsonData = json.decode(content) as List<dynamic>;

      setState(() {
        _results = jsonData
            .map((item) => TestResult.fromJson(item as Map<String, dynamic>))
            .toList();
        _statusMessage = 'Đã tải ${_results.length} kết quả kiểm thử';
      });
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

  void _generateHtmlReport() {
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
        final timestamp =
            '${result.timestamp.day}/${result.timestamp.month}/${result.timestamp.year} ${result.timestamp.hour}:${result.timestamp.minute}:${result.timestamp.second}';

        tableRows += '''
        <tr class="${result.passed ? 'pass' : 'fail'}">
          <td>${i + 1}</td>
          <td>${result.testName}</td>
          <td>${result.description}</td>
          <td>${result.passed ? 'PASS' : 'FAIL'}</td>
          <td>${result.error ?? ''}</td>
          <td>${timestamp}</td>
        </tr>
        ''';
      }

      final now = DateTime.now();
      final currentTime =
          '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}:${now.second}';

      final htmlContent = '''
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
          <p>Thời gian: ${currentTime}</p>
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

      // Tạo tên file với timestamp
      final fileName = 'test_report_${now.millisecondsSinceEpoch}.html';

      // Tạo Blob và tải xuống file
      final blob = html.Blob([htmlContent.codeUnits], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..style.display = 'none';
      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

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
        title: const Text('Test Report Generator'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Tạo báo cáo kiểm thử từ file JSON',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                _statusMessage,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _pickJsonFile,
                      child: const Text('Tải lên file JSON'),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: _results.isEmpty ? null : _generateHtmlReport,
                      child: const Text('Tạo báo cáo HTML'),
                    ),
                  ],
                ),
              const SizedBox(height: 30),
              if (_results.isNotEmpty) ...[
                const Text(
                  'Tóm tắt kết quả kiểm thử',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
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
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
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
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(result.description),
                              if (result.error != null &&
                                  result.error!.isNotEmpty)
                                Text(
                                  'Lỗi: ${result.error}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              Text(
                                'Thời gian: ${result.timestamp.day}/${result.timestamp.month}/${result.timestamp.year} ${result.timestamp.hour}:${result.timestamp.minute}:${result.timestamp.second}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
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
