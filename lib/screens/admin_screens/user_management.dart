import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/api_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserManagement extends StatefulWidget {
  static const routeName = '/admin/users';

  @override
  _UserManagementState createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  List<dynamic> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      print('Debug - Token being used: $token');

      final response = await http.get(
        Uri.parse('${ApiStrings.hostNameUrl}${ApiStrings.getUsersUrl}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('API Response - Status: ${response.statusCode}');
      print('API Response - Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Received users data:');
        (data['data'] as List).forEach((user) {
          print(
              'User ${user['email']} - ban_id: ${user['ban_id']} (${user['ban_id'].runtimeType})');
        });
        setState(() {
          users = data['data'] ?? [];
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        // Token hết hạn hoặc không hợp lệ
        final error = jsonDecode(response.body);
        if (error['message'].contains('hết hạn')) {
          // Chuyển về màn hình đăng nhập
          Navigator.of(context).pushReplacementNamed('/login');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại')),
          );
        } else {
          throw Exception('Lỗi xác thực: ${error['message']}');
        }
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching users: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải danh sách người dùng: $e')),
        );
      }
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> deleteUser(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse(
            '${ApiStrings.hostNameUrl}${ApiStrings.deleteUserUrl}/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getToken()}',
        },
      );

      print(
          'Delete API call: ${ApiStrings.hostNameUrl}${ApiStrings.deleteUserUrl}/$userId');
      print('Delete response status: ${response.statusCode}');
      print('Delete response body: ${response.body}');

      if (response.statusCode == 200) {
        await fetchUsers(); // Refresh list after deletion
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xóa người dùng thành công')),
          );
        }
      } else {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xóa người dùng: $e')),
        );
      }
    }
  }

  Future<void> banUser(String userId, int banStatus) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiStrings.hostNameUrl}/api/user/ban/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getToken()}',
        },
        body: jsonEncode({'ban_id': banStatus}),
      );

      print('Ban response status: ${response.statusCode}');
      print('Ban response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        await fetchUsers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message']),
              backgroundColor: banStatus == 1 ? Colors.red : Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to update user ban status');
      }
    } catch (e) {
      print('Error updating ban status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể cập nhật trạng thái khóa: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý Người dùng'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user['avatarUrl'] != null
                          ? NetworkImage(user['avatarUrl'])
                          : null,
                      child:
                          user['avatarUrl'] == null ? Icon(Icons.person) : null,
                    ),
                    title: Text(
                      user['fullName'] ?? 'N/A',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: ${user['email'] ?? 'N/A'}'),
                        Text('SĐT: ${user['phoneNumber'] ?? 'N/A'}'),
                        Text(
                            'Ngày sinh: ${user['birthDate'] != null ? user['birthDate'].toString().split('T')[0] : 'N/A'}'),
                        Text('Vai trò: ${_getRoleName(user['role_id'])}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 28,
                          ),
                          onPressed: () =>
                              banUser(user['user_id'].toString(), 2),
                          tooltip: 'Mở khóa tài khoản',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.cancel,
                            color: Colors.red,
                            size: 28,
                          ),
                          onPressed: () =>
                              banUser(user['user_id'].toString(), 1),
                          tooltip: 'Khóa tài khoản',
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Xác nhận xóa'),
                                content: Text(
                                    'Bạn có chắc muốn xóa người dùng này?'),
                                actions: [
                                  TextButton(
                                    child: Text('Hủy'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  TextButton(
                                    child: Text('Xóa'),
                                    onPressed: () {
                                      deleteUser(user['user_id'].toString());
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

  String _getRoleName(int? roleId) {
    switch (roleId) {
      case 1:
        return 'Admin';
      case 2:
        return 'User';
      default:
        return 'Unknown';
    }
  }
}
