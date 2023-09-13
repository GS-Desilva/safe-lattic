import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:safelattice/presentation/utils/app_colors.dart';

class CustomNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Function? onTapBack;

  const CustomNavbar({Key? key, this.title, this.onTapBack}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(86.0);

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(MediaQuery.of(context).size.height * 0.9),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 0.0),
          child: SizedBox(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                const SizedBox(width: 29.0),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        if (onTapBack != null) {
                          onTapBack!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: SvgPicture.asset(
                          "assets/icons/ic_chevron.backward.svg")),
                ),
                const SizedBox(width: 13.4),
                Text(
                  title ?? "Title",
                  style: const TextStyle(
                    height: 0.0,
                    fontSize: 53.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
