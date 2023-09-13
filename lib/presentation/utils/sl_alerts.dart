import 'package:flutter/material.dart';
import 'package:safelattice/presentation/utils/app_colors.dart';
import 'package:safelattice/presentation/widgets/primary_card.dart';
import 'package:safelattice/presentation/widgets/secondary_button.dart';

class SlAlert {
  static final SlAlert _instance = SlAlert.internal();
  bool _loadingDialogOn = false;

  factory SlAlert() => _instance;

  SlAlert.internal();

  Future<void> showMessageDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
    Function? buttonCallback,
  }) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(29.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrimaryCard(
                shadowEnabled: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      message,
                      style: const TextStyle(
                        color: AppColors.primaryGray,
                        fontSize: 16.0,
                        fontWeight: FontWeight.normal,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 25.0),
                    Row(
                      children: [
                        const Spacer(),
                        SecondaryButton(
                          buttonText: buttonText ?? "Dismiss",
                          callback: () {
                            if (buttonCallback != null) {
                              buttonCallback();
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> showActionDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? button1Text,
    Function? button1Callback,
    String? button2Text,
    Function? button2Callback,
  }) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(29.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrimaryCard(
                shadowEnabled: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      message,
                      style: const TextStyle(
                        color: AppColors.primaryGray,
                        fontSize: 16.0,
                        fontWeight: FontWeight.normal,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 25.0),
                    Row(
                      children: [
                        const Spacer(),
                        SecondaryButton(
                          outline: true,
                          buttonText: button1Text ?? "Continue",
                          callback: () {
                            if (button1Callback != null) {
                              button1Callback();
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        ),
                        const SizedBox(width: 5.0),
                        SecondaryButton(
                          buttonText: button2Text ?? "Dismiss",
                          callback: () {
                            if (button2Callback != null) {
                              button2Callback();
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> showCustomDialog({
    required BuildContext context,
    required Widget content,
    bool? dismissible,
    EdgeInsets? padding,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: dismissible ?? true,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () => Future.value(dismissible ?? true),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            insetPadding: padding ?? EdgeInsets.zero,
            child: content,
          ),
        );
      },
    );
  }

  Future<void> showLoadingDialog({
    required BuildContext context,
    bool? dismissible = false,
  }) async {
    if (!_loadingDialogOn) {
      _loadingDialogOn = true;
      await showDialog(
        barrierDismissible: dismissible ?? true,
        context: context,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () => Future.value(dismissible ?? true),
            child: Dialog(
              backgroundColor: Colors.white.withOpacity(0.0),
              elevation: 0.0,
              insetPadding: const EdgeInsets.all(29.0),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accentColor,
                ),
              ),
            ),
          );
        },
      );
    }
  }

  Future<void> hideLoadingDialog({
    required BuildContext context,
  }) async {
    if (_loadingDialogOn) {
      _loadingDialogOn = false;
      Navigator.pop(context);
    }
  }
}
