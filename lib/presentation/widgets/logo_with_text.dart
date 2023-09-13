import 'package:flutter/material.dart';
import 'package:safelattice/presentation/utils/app_colors.dart';

class LogoWithText extends StatelessWidget {
  const LogoWithText({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Image.asset(
          "assets/images/AppIcon.png",
          height: 100.0,
          width: 100.0,
        ),
        SizedBox(
          height: 65.0,
          width: 102.0,
          child: Stack(
            children: const [
              Text(
                "Safe",
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 29,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Positioned(
                top: 27.0,
                child: Text(
                  "Lattice",
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 29,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
