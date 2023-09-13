import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:safelattice/presentation/utils/app_colors.dart';
import 'package:shimmer/shimmer.dart';

class SlSliderButton extends StatefulWidget {
  final String? labelText;
  final Function? callBack;

  const SlSliderButton({
    Key? key,
    this.labelText,
    this.callBack,
  }) : super(key: key);

  @override
  _SlSliderButtonState createState() => _SlSliderButtonState();
}

class _SlSliderButtonState extends State<SlSliderButton> {
  double sliderValue = 0.0;
  final GlobalKey sliderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  Size getWidgetSize() {
    final RenderBox renderBox =
        sliderKey.currentContext?.findRenderObject() as RenderBox;

    return renderBox.size;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: sliderKey,
      decoration: BoxDecoration(
          color: AppColors.tertiaryGray,
          borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.all(3.0),
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 30.0),
              child: Shimmer.fromColors(
                baseColor: AppColors.primaryRed,
                highlightColor: Colors.white,
                child: Text(
                  widget.labelText ?? "",
                  style: const TextStyle(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: (DragUpdateDetails details) {
              if ((getWidgetSize().width - 58) >= details.localPosition.dx &&
                  details.localPosition.dx >= 0) {
                setState(() {
                  sliderValue = details.localPosition.dx;
                });
              }
            },
            onHorizontalDragEnd: (DragEndDetails details) {
              if ((getWidgetSize().width - 100) <= sliderValue &&
                  widget.callBack != null) {
                widget.callBack!();
              }
              setState(() {
                sliderValue = 0.0;
              });
            },
            child: Transform.translate(
              offset: Offset(sliderValue, 0),
              child: Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(9.0),
                child: SvgPicture.asset(
                  "assets/icons/ic_x.circle.svg",
                  height: 35.0,
                  width: 35.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
