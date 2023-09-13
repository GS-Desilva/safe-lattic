import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:safelattice/presentation/screens/alert_screen.dart';
import 'package:safelattice/presentation/utils/app_colors.dart';

class SlFloatingActionButton extends StatelessWidget {
  const SlFloatingActionButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await pushAlertScreen(context: context);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 15.0, right: 10.0),
        child: Container(
          width: 70,
          height: 70,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.secondaryColor,
            boxShadow: [
              BoxShadow(
                color: const Color(0xffF3800A).withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 0),
              )
            ],
          ),
          child:
              SvgPicture.asset("assets/icons/ic_exclamationmark.octagon.svg"),
        ),
      ),
    );
  }
}
