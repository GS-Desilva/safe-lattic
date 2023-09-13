import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:safelattice/presentation/utils/app_colors.dart';

class PrimaryTextField extends StatefulWidget {
  final String? labelText;
  final String? value;
  final bool isPassword;
  final bool isEnabled;
  final Function? callback;
  final TextEditingController? controller;
  final Widget? prefixContent;
  final TextInputType? keyboardType;
  final int? maxLength;

  const PrimaryTextField({
    this.labelText,
    this.value,
    this.callback,
    this.isPassword = false,
    this.isEnabled = true,
    this.prefixContent,
    this.controller,
    this.keyboardType,
    this.maxLength,
    Key? key,
  }) : super(key: key);

  @override
  State<PrimaryTextField> createState() => _PrimaryTextFieldState();
}

class _PrimaryTextFieldState extends State<PrimaryTextField> {
  bool obscureText = false;
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? TextEditingController();
    obscureText = widget.isPassword;
    controller.text = widget.value ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: widget.keyboardType,
      enabled: widget.isEnabled,
      controller: controller,
      obscureText: obscureText,
      maxLength: widget.maxLength,
      onChanged: (value) {
        if (widget.callback != null) {
          widget.callback!(value);
        }
      },
      style: const TextStyle(
          color: AppColors.primaryColor,
          fontSize: 19.0,
          decoration: TextDecoration.none),
      decoration: InputDecoration(
        counterText: "",
        prefix: widget.prefixContent,
        suffix: widget.isPassword
            ? GestureDetector(
                onTap: () => setState(() => obscureText = !obscureText),
                child: SvgPicture.asset(
                  "assets/icons/ic_eye.slash.svg",
                ),
              )
            : const SizedBox.shrink(),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
        labelText: widget.labelText ?? "",
        labelStyle: const TextStyle(
          color: AppColors.primaryGray,
          fontSize: 19.0,
        ),
        border: InputBorder.none,
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.accentColor,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.accentColor,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.accentColor,
            width: 1.0,
          ),
        ),
      ),
    );
  }
}
