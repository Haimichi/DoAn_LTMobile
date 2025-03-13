import 'package:flutter/material.dart';
import 'user_management.dart';
import 'product_management.dart';
import 'category_management.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'voucher_management.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    final prefs = await SharedPreferences.getInstance();
    final roleId = prefs.getInt('role_id'); // Lấy role_id từ SharedPreferences

    if (roleId != 1) {
      // Nếu không phải admin, quay lại trang trước đó
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Bạn không có quyền truy cập vào trang này.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Dashboard',
            style: TextStyle(
                color: Colors.white, fontSize: 27, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.home, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.book, color: Colors.white),
            onPressed: () {
              // Hành động khi nhấn vào biểu tượng sách
            },
          ),
        ],
        toolbarHeight: 80,
      ),
      body: Container(
        color: Colors.grey[200], // Màu nền
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 16), // Khoảng cách giữa AppBar và các nút
              GestureDetector(
                onTap: () {
                  Navigator.of(context)
                      .push(_createPageRoute(UserManagement()));
                },
                child: Container(
                  color: Colors.grey[800], // Màu nền tối cho hàng đầu tiên
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Center(
                    child: Text(
                      'Quản lý Người dùng',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.of(context)
                      .push(_createPageRoute(ProductManagement()));
                },
                child: Container(
                  color: Colors.grey[700], // Màu nền tối cho hàng thứ hai
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Center(
                    child: Text(
                      'Quản lý Sản phẩm',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.of(context)
                      .push(_createPageRoute(CategoryManagement()));
                },
                child: Container(
                  color: Colors.grey[600], // Màu nền tối cho hàng thứ ba
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Center(
                    child: Text(
                      'Quản lý Thể loại',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () {},
                child: Container(
                  color: Colors.grey[500],
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Center(
                    child: Text(
                      'Quản lý Đơn hàng',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    _createPageRoute(VoucherManagement()),
                  );
                },
                child: Container(
                  color: Colors.grey[400],
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Center(
                    child: Text(
                      'Quản lý Voucher',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Route _createPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Bắt đầu từ bên phải
        const end = Offset.zero; // Kết thúc ở vị trí ban đầu
        const curve = Curves.easeInOut;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }
}
