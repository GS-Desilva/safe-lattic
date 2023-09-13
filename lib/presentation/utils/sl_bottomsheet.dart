import 'package:flutter/material.dart';
import 'package:safelattice/presentation/utils/app_colors.dart';

class SlBottomSheet {
  static final SlBottomSheet _instance = SlBottomSheet._internal();

  factory SlBottomSheet() {
    return _instance;
  }

  SlBottomSheet._internal();

  Future<void> showCustomSheet(
      {required BuildContext context,
      Widget? content,
      Function? onDismissed}) async {
    await showModalBottomSheet(
        backgroundColor: Colors.transparent,
        elevation: 0,
        isScrollControlled: true,
        context: context,
        builder: (BuildContext context) {
          return Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: Wrap(
              children: [
                Container(
                  margin: const EdgeInsets.only(
                      left: 10.0, right: 10.0, bottom: 20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40.0),
                    border: Border.all(
                      color: AppColors.accentColor,
                      width: 2.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: Container(
                          height: 5.0,
                          width: 101.0,
                          decoration: const BoxDecoration(
                              color: AppColors.accentColor,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(11.0))),
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: content ?? const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).then((value) {
      if (onDismissed != null) {
        onDismissed();
      }
    });
  }
}
