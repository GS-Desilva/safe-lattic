import 'package:flutter/material.dart';
import 'package:safelattice/presentation/utils/app_colors.dart';

class SecondaryButton extends StatelessWidget {
  final String? buttonText;
  final bool outline;
  final Function? callback;

  const SecondaryButton({
    this.buttonText,
    this.outline = false,
    this.callback,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (callback != null) callback!();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 5.0,
          horizontal: 12.0,
        ),
        decoration: BoxDecoration(
          color: outline ? Colors.white : AppColors.primaryColor,
          borderRadius: const BorderRadius.all(Radius.circular(13.0)),
          border: Border.all(
            color: AppColors.primaryColor,
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
              fontSize: 21.0,
              fontWeight: FontWeight.w500,
              color: outline ? AppColors.primaryColor : Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}
