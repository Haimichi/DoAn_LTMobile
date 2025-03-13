import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:booky/constants.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      AppConstants.logo,
      height: 60,
    );
  }
}
