import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/api_strings.dart';
import 'add_edit_book_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductManagement extends StatefulWidget {
  static const routeName = '/admin/products';

  @override
  _ProductManagementState createState() => _ProductManagementState();
}

class _ProductManagementState extends State<ProductManagement> {
  List<dynamic> books = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }

  Future<void> fetchBooks() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiStrings.hostNameUrl}/api/books'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          books = data['data'];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching books: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteBook(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiStrings.hostNameUrl}/api/books/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('books_updated', true);

        await fetchBooks();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xóa sách thành công')),
        );
      }
    } catch (e) {
      print('Error deleting book: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra khi xóa sách')),
      );
    }
  }

  void navigateToAddEdit(Map<String, dynamic>? book) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditBookScreen(book: book),
      ),
    );

    if (result == true) {
      // Refresh danh sách sách
      await fetchBooks();

      // Gửi thông báo để home_screen cập nhật
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Danh sách sách đã được cập nhật'),
            action: SnackBarAction(
              label: 'Làm mới',
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/', // Route của HomeScreen
                  (route) => false,
                );
              },
            ),
          ),
        );
      }
    }
  }

  String formatCurrency(dynamic price) {
    if (price == null) return '0 đ';

    double numericPrice;
    if (price is String) {
      numericPrice = double.tryParse(price) ?? 0;
    } else {
      numericPrice = price.toDouble();
    }

    int roundedPrice = numericPrice.round();
    String result = roundedPrice.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );

    return '$result đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => navigateToAddEdit(null),
        child: Icon(Icons.add),
      ),
      appBar: AppBar(
        title: Text('Quản lý Sách'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddEditBookScreen()),
              );
              if (result == true) {
                // Nếu có thay đổi thì refresh lại danh sách
                await fetchBooks();
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return ListTile(
                  leading: Image.network(
                    book['image_url']?.toString() ??
                        'https://via.placeholder.com/50',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.network(
                        'https://via.placeholder.com/50',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                  title: Text(book['title']?.toString() ?? 'Không có tiêu đề'),
                  subtitle: Text(
                      '${book['author']?.toString() ?? 'Không có tác giả'} - ${formatCurrency(book['price'])} - Số lượng: ${book['quantity']?.toString() ?? '0'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddEditBookScreen(book: book),
                            ),
                          ).then((_) => fetchBooks());
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Xác nhận xóa'),
                              content: Text('Bạn có chắc muốn xóa sách này?'),
                              actions: [
                                TextButton(
                                  child: Text('Hủy'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                TextButton(
                                  child: Text('Xóa'),
                                  onPressed: () {
                                    deleteBook(book['book_id'].toString());
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
