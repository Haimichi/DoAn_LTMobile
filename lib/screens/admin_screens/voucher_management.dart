import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/api_strings.dart';
import 'add_edit_voucher_screen.dart';

class VoucherManagement extends StatefulWidget {
  @override
  _VoucherManagementState createState() => _VoucherManagementState();
}

class _VoucherManagementState extends State<VoucherManagement> {
  List<dynamic> vouchers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVouchers();
  }

  Future<void> fetchVouchers() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiStrings.hostNameUrl}/api/vouchers'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          vouchers = json.decode(response.body)['data'];
          isLoading = false;
        });
      } else {
        print(
            'Error fetching vouchers: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching vouchers: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteVoucher(String voucherId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiStrings.hostNameUrl}/api/vouchers/$voucherId'),
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(responseData['message'] ?? 'Xóa voucher thành công')),
        );
        await fetchVouchers();
      } else {
        print(
            'Error deleting voucher: ${response.statusCode} - ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(responseData['message'] ?? 'Không thể xóa voucher')),
        );
      }
    } catch (e) {
      print('Error deleting voucher: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra khi kết nối với server')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý Voucher'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddEditVoucherScreen()),
              );
              if (result == true) {
                await fetchVouchers();
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: vouchers.length,
              itemBuilder: (context, index) {
                final voucher = vouchers[index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text('Mã: ${voucher['code']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Phần trăm giảm giá: ${voucher['discount']}'),
                        Text('Số lượng: ${voucher['voucher_quantity']}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEditVoucherScreen(
                                  voucher: voucher,
                                ),
                              ),
                            );
                            if (result == true) {
                              await fetchVouchers();
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Xác nhận xóa'),
                                content:
                                    Text('Bạn có chắc muốn xóa voucher này?'),
                                actions: [
                                  TextButton(
                                    child: Text('Hủy'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  TextButton(
                                    child: Text('Xóa'),
                                    onPressed: () {
                                      deleteVoucher(
                                          voucher['voucher_id'].toString());
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
