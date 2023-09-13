import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:safelattice/presentation/utils/app_colors.dart';

class SlAvatar extends StatefulWidget {
  final String? imageUrl;
  final double? dimensions;
  const SlAvatar({Key? key, this.imageUrl, this.dimensions}) : super(key: key);

  @override
  State<SlAvatar> createState() => _SlAvatarState();
}

class _SlAvatarState extends State<SlAvatar> {
  @override
  Widget build(BuildContext context) {
    return (widget.imageUrl != null &&
            widget.imageUrl!.isNotEmpty &&
            widget.imageUrl != "N/A")
        ? Stack(
            children: [
              Container(
                height: widget.dimensions ?? 100.0,
                width: widget.dimensions ?? 100.0,
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Image.network(
                  widget.imageUrl!,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                height: widget.dimensions ?? 100.0,
                width: widget.dimensions ?? 100.0,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.accentColor, width: 2.0),
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                ),
              ),
            ],
          )
        : SvgPicture.asset(
            "assets/icons/ic_person.crop.circle.svg",
            height: widget.dimensions ?? 100.0,
            width: widget.dimensions ?? 100.0,
          );
  }
}
