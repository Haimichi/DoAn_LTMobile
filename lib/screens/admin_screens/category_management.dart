import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/api_strings.dart';
import 'add_edit_category.dart';

class CategoryManagement extends StatefulWidget {
  @override
  _CategoryManagementState createState() => _CategoryManagementState();
}

class _CategoryManagementState extends State<CategoryManagement> {
  List<dynamic> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiStrings.hostNameUrl}/api/categories'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          categories = data['data'];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiStrings.hostNameUrl}/api/categories/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        fetchCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xóa thể loại thành công')),
        );
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['message'] ?? 'Không thể xóa thể loại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể xóa thể loại: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý Thể Loại'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddEditCategory()),
              );
              if (result == true) {
                fetchCategories();
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    child: category['category_image']?.isNotEmpty == true
                        ? Image.network(
                            '${ApiStrings.hostNameUrl}${category['category_image']}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading image: $error');
                              return Container(
                                color: Colors.grey[300],
                                child: Icon(Icons.image_not_supported),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.category),
                          ),
                  ),
                  title: Text(category['name'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddEditCategory(category: category),
                            ),
                          );
                          if (result == true) {
                            fetchCategories();
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
                                  Text('Bạn có chắc muốn xóa thể loại này?'),
                              actions: [
                                TextButton(
                                  child: Text('Hủy'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                TextButton(
                                  child: Text('Xóa'),
                                  onPressed: () {
                                    deleteCategory(
                                        category['category_id'].toString());
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
                );
              },
            ),
    );
  }
}
