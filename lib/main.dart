import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:booky/models/PlaceOrderItem.dart';
import 'package:booky/constants.dart';
import 'package:booky/route_generator.dart';
import 'package:booky/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Hive
  await Hive.initFlutter();

  // Đăng ký adapter
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(PlaceOrderItemAdapter());
  }

  // Mở các box cần thiết
  await Hive.openBox<PlaceOrderItem>(AppConstants.cartProductHiveKey);
  await Hive.openBox(AppConstants.appHiveBox);

  print('Hive initialized successfully');
  print('Cart box opened: ${Hive.isBoxOpen(AppConstants.cartProductHiveKey)}');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shoea',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppConstants.kPrimaryColor1,
      ),
      initialRoute: SplashScreen.routeName,
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
