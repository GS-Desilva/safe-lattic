import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safelattice/api/auth_manager/auth_manager.dart';
import 'package:safelattice/api/database_manager/database_manager.dart';
import 'package:safelattice/api/notification_manager/notification_manager.dart';
import 'package:safelattice/data/models/event.dart';
import 'package:safelattice/data/utils/global_data.dart';
import 'package:safelattice/presentation/utils/app_colors.dart';
import 'package:safelattice/presentation/utils/sl_alerts.dart';
import 'package:safelattice/presentation/utils/sl_bottomsheet.dart';
import 'package:safelattice/presentation/widgets/primary_textfiled.dart';
import 'package:safelattice/presentation/widgets/sl_camera.dart';
import 'package:safelattice/presentation/widgets/sl_numpad.dart';
import 'package:safelattice/presentation/widgets/sl_slider_button.dart';
import 'package:uuid/uuid.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({Key? key}) : super(key: key);

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  int countDown = 10;
  bool numpadVisible = false;
  late Timer timer;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      setState(() {
        countDown = countDown - 1;
      });

      if (countDown <= 4 && countDown != 0) HapticFeedback.vibrate();

      if (countDown == 0) {
        timer.cancel();
        if (numpadVisible) {
          Navigator.pop(context);
        }

        SlAlert().showLoadingDialog(
            context: GlobalData().navigatorKey.currentContext!,
            dismissible: false);
        Position? currentPosition = await getPosition();

        Event newEvent = Event(
          eventId: const Uuid().v4(),
          latitude: currentPosition?.latitude ?? 0.0,
          longitude: currentPosition?.longitude ?? 0.0,
          dateTime: DateTime.now(),
          initiatedUser: GlobalData().currentUser!,
        );

        bool? success;
        if (GlobalData().emergencyContacts != null &&
            GlobalData().emergencyContacts!.isNotEmpty &&
            await NotificationManager().notifyUsers(
                users: GlobalData().emergencyContacts!, event: newEvent)) {
          success = await DatabaseManager().createEvent(
              users: GlobalData().emergencyContacts ?? [], event: newEvent);
        }
        SlAlert().hideLoadingDialog(
          context: GlobalData().navigatorKey.currentContext!,
        );
        Navigator.pop(context, success);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
  }

  Future<Position?> getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> onSlideCancel() async {
    if (await AuthManager().isBiometricsAvailable() &&
        (GlobalData().currentUser!.biometrics ?? false)) {
      if (await AuthManager().authBiometric()) {
        Navigator.pop(context, false);
      }
    } else if (GlobalData().currentUser!.pin != null) {
      numpadVisible = true;
      TextEditingController pinController = TextEditingController();

      SlBottomSheet().showCustomSheet(
        context: context,
        onDismissed: () => numpadVisible = false,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PrimaryTextField(
              labelText: "Pin",
              controller: pinController,
              isPassword: true,
              isEnabled: false,
            ),
            const SizedBox(height: 22.0),
            SlNumpad(
              callBack: (value) {
                pinController.text = value;
              },
              onTapDone: () {
                if (pinController.text.isNotEmpty) {
                  String newPin = sha256
                      .convert(utf8.encode(pinController.text))
                      .toString();

                  if (newPin == GlobalData().currentUser!.pin!) {
                    Navigator.pop(context, false);
                  } else {
                    pinController.text = "";
                  }
                }
              },
            ),
            const SizedBox(height: 22.0),
          ],
        ),
      );
    } else {
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: AppColors.secondaryColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 74.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: onSlideCancel,
                  child: Column(
                    children: const [
                      Text(
                        "Notifying",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 44.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 0.0),
                      ),
                      FittedBox(
                        child: Text(
                          "Emergency",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 44.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 0.0),
                        ),
                      ),
                      Text(
                        "Contacts",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 44.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 0.0),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 264.0,
                  child: FittedBox(
                    child: Text(
                      countDown.toString(),
                      key: UniqueKey(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 200.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 0.0),
                    ),
                  ),
                ),
                SlSliderButton(
                  labelText: "Slide to cancel!",
                  callBack: onSlideCancel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> pushAlertScreen({required BuildContext context}) async {
  bool? performHaptics = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const AlertScreen(),
    ),
  );
  if (performHaptics != null && performHaptics) {
    Timer(const Duration(milliseconds: 500), () {
      HapticFeedback.heavyImpact();
      Timer(const Duration(milliseconds: 100), () {
        SlAlert().showMessageDialog(
            context: context,
            title: "Success!",
            message: "Emergency contacts successfully notified.");
        HapticFeedback.heavyImpact();
      });
    });
  }

  if (performHaptics == null || performHaptics) {
    bool? videoSuccess = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SlCamera(),
      ),
    );

    if (videoSuccess ?? false) {
      SlAlert().showMessageDialog(
        context: context,
        title: "Video saved!",
        message:
            "Video recorded during the event successfully saved to gallery",
      );
    }
  }
}
