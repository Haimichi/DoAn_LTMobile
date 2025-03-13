import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/api_strings.dart';

class AddEditVoucherScreen extends StatefulWidget {
  final Map<String, dynamic>? voucher;

  AddEditVoucherScreen({this.voucher});

  @override
  _AddEditVoucherScreenState createState() => _AddEditVoucherScreenState();
}

class _AddEditVoucherScreenState extends State<AddEditVoucherScreen> {
  final _formKey = GlobalKey<FormState>();
  final codeController = TextEditingController();
  final discountController = TextEditingController();
  final quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.voucher != null) {
      codeController.text = widget.voucher!['code'];
      discountController.text = widget.voucher!['discount'];
      quantityController.text = widget.voucher!['voucher_quantity'].toString();
    }
  }

  Future<void> saveVoucher() async {
    if (!_formKey.currentState!.validate()) return;

    final voucherData = {
      'code': codeController.text,
      'discount': discountController.text,
      'voucher_quantity': int.parse(quantityController.text),
    };

    try {
      final response = widget.voucher == null
          ? await http.post(
              Uri.parse('${ApiStrings.hostNameUrl}/api/vouchers'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(voucherData),
            )
          : await http.put(
              Uri.parse(
                  '${ApiStrings.hostNameUrl}/api/vouchers/${widget.voucher!['voucher_id']}'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(voucherData),
            );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.voucher == null
                  ? 'Thêm voucher thành công'
                  : 'Cập nhật voucher thành công')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Có lỗi xảy ra')),
        );
      }
    } catch (e) {
      print('Error saving voucher: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra khi kết nối với server')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.voucher == null ? 'Thêm Voucher' : 'Sửa Voucher'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: codeController,
                decoration: InputDecoration(labelText: 'Mã voucher'),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập mã voucher';
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: discountController,
                decoration: InputDecoration(labelText: 'Giảm giá'),
                validator: (value) {
                  if (value?.isEmpty ?? true)
                    return 'Vui lòng nhập giá trị giảm giá';
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: quantityController,
                decoration: InputDecoration(labelText: 'Số lượng'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập số lượng';
                  if (int.tryParse(value!) == null)
                    return 'Số lượng không hợp lệ';
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveVoucher,
                child: Text(widget.voucher == null ? 'Thêm' : 'Cập nhật'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
