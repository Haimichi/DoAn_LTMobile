import 'package:flutter/material.dart';
import 'package:booky/constants.dart';
import 'package:booky/screens/main_screens/cart_screen/cart_screen.dart';
import 'package:booky/screens/main_screens/home_screen/home_screen.dart';
import 'package:booky/screens/main_screens/orders_screen/orders_screens.dart';
import 'package:booky/screens/main_screens/profile_screen.dart';

class MainAppScreen extends StatefulWidget {
  static const String routeName = '/main';
  final int initialTabIndex;

  const MainAppScreen({
    Key? key,
    this.initialTabIndex = 0,
  }) : super(key: key);

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  List<Widget> tabsBody = const [
    HomeScreen(),
    CartScreen(),
    OrdersScreen(),
    // WalletScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: tabsBody[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppConstants.kGrey1,
        selectedItemColor: AppConstants.kPrimaryColor1,
        unselectedItemColor: AppConstants.kGrey3,
        showUnselectedLabels: true,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            label: 'Home',
            icon: Icon(Icons.home_rounded),
          ),
          BottomNavigationBarItem(
            label: 'Cart',
            icon: Icon(Icons.shopping_bag_outlined),
          ),
          BottomNavigationBarItem(
            label: 'Orders',
            icon: Icon(Icons.shopping_cart_outlined),
          ),
          // BottomNavigationBarItem(
          //   label: 'Wallet',
          //   icon: Icon(Icons.wallet),
          // ),
          BottomNavigationBarItem(
            label: 'Profile',
            icon: Icon(Icons.person_rounded),
          ),
        ],
      ),
    );
  }
}
