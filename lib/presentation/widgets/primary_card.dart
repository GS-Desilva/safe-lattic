import 'package:flutter/material.dart';
import 'package:safelattice/presentation/utils/app_colors.dart';

class PrimaryCard extends StatelessWidget {
  final Widget? child;
  final double? height;
  final double? width;
  final double? maxWidth;
  final double? minWidth;
  final double? maxHeight;
  final double? minHeight;
  final bool shadowEnabled;

  const PrimaryCard({
    this.child,
    this.height,
    this.width,
    this.maxHeight,
    this.maxWidth,
    this.minHeight,
    this.minWidth,
    this.shadowEnabled = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minWidth ?? 0.0,
        minHeight: minHeight ?? 0.0,
        maxHeight: maxHeight ?? double.infinity,
        maxWidth: maxWidth ?? double.infinity,
      ),
      child: Container(
        height: height,
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 23.5, vertical: 15.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.accentColor, width: 2.0),
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
                color:
                    shadowEnabled ? AppColors.accentColor : Colors.transparent,
                offset: const Offset(0.0, 6.0),
                blurRadius: 12.0),
          ],
        ),
        child: AnimatedSize(
          curve: Curves.linear,
          duration: const Duration(milliseconds: 500),
          child: child,
        ),
      ),
    );
  }
}
