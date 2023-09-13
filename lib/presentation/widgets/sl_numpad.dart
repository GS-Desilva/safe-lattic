import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:safelattice/presentation/utils/app_colors.dart';

class SlNumpad extends StatelessWidget {
  final ValueSetter<String> callBack;
  final VoidCallback onTapDone;

  const SlNumpad({
    Key? key,
    required this.callBack,
    required this.onTapDone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String _pin = "";

    Widget numPadItem(int value) {
      return GestureDetector(
        onTap: () {
          _pin += value.toString();
          callBack(_pin);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 27.0, vertical: 19.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: AppColors.primaryColor,
            ),
            shape: BoxShape.circle,
          ),
          child: Text(
            value.toString(),
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontSize: 27,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            numPadItem(1),
            numPadItem(2),
            numPadItem(3),
          ],
        ),
        const SizedBox(height: 20.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            numPadItem(4),
            numPadItem(5),
            numPadItem(6),
          ],
        ),
        const SizedBox(height: 20.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            numPadItem(7),
            numPadItem(8),
            numPadItem(9),
          ],
        ),
        const SizedBox(height: 20.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
                onTap: () {
                  _pin = "";
                  callBack(_pin);
                },
                child: SvgPicture.asset("assets/icons/ic_xmark.circle.svg")),
            numPadItem(0),
            GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onTapDone();
                },
                child: SvgPicture.asset(
                    "assets/icons/ic_checkmark.circle.fill.svg")),
          ],
        ),
      ],
    );
  }
}
