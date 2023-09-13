import 'package:flutter/material.dart';
import 'package:safelattice/presentation/utils/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String? buttonText;
  final bool outline;
  final Function? callback;
  final double? width;
  final double? height;

  const PrimaryButton({
    this.buttonText,
    this.outline = false,
    this.callback,
    this.width,
    this.height,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (callback != null) callback!();
      },
      child: Container(
        height: height,
        width: width,
        padding: const EdgeInsets.symmetric(
          vertical: 14.0,
          horizontal: 12.0,
        ),
        decoration: BoxDecoration(
          color: outline ? Colors.white : AppColors.primaryColor,
          borderRadius: const BorderRadius.all(Radius.circular(20.0)),
          border: Border.all(
            color: outline ? AppColors.primaryColor : Colors.transparent,
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  outline ? Colors.transparent : AppColors.primaryShadowColor,
              offset: const Offset(0.0, 3.0),
              blurRadius: 6.0,
            )
          ],
        ),
        child: Center(
          child: Text(
            buttonText ?? "Text",
            style: TextStyle(
              fontSize: 29.0,
              fontWeight: FontWeight.w500,
              color: outline ? AppColors.primaryColor : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
