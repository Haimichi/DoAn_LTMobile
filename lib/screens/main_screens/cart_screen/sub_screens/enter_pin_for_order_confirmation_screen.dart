import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pinput/pinput.dart';
import 'package:booky/common/widgets/custom_button.dart';
import 'package:booky/constants.dart';
import 'package:booky/utils/custom_num_pad.dart';

class EnterYourPinForOrderConfirmationScreen extends StatefulWidget {
  static const String routeName = 'enter_your_pin';

  const EnterYourPinForOrderConfirmationScreen({super.key});

  @override
  State<EnterYourPinForOrderConfirmationScreen> createState() =>
      _EnterYourPinForOrderConfirmationScreenState();
}

class _EnterYourPinForOrderConfirmationScreenState
    extends State<EnterYourPinForOrderConfirmationScreen> {
  @override
  void initState() {
    super.initState();
    // Tăng thời gian delay để đợi response
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Xác nhận đơn hàng'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Đang xử lý đơn hàng...'),
          ],
        ),
      ),
    );
  }
}
