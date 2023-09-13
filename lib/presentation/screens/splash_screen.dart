import 'dart:async';
import 'package:flutter/material.dart';
import 'package:safelattice/api/database_manager/database_manager.dart';
import 'package:safelattice/data/utils/global_data.dart';
import 'package:safelattice/presentation/screens/home_screen.dart';
import 'package:safelattice/presentation/screens/staging_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future<void> redirect() async {
    Timer(const Duration(seconds: 2), () async {
      if (GlobalData().currentUser != null) {
        GlobalData().currentUser?.slUserId = await DatabaseManager()
            .getPropertyForUserId(
                userId: GlobalData().currentUser!.fbUserId!,
                property: "slUserId");
        GlobalData().currentUser?.biometrics = await DatabaseManager()
            .getPropertyForUserId(
                userId: GlobalData().currentUser!.fbUserId!,
                property: "biometrics");
        GlobalData().currentUser?.pin =
            await DatabaseManager().getPropertyForUserId(
          userId: GlobalData().currentUser!.fbUserId!,
          property: "pin",
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const StagingScreen(),
          ),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    redirect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          "assets/images/AppIcon.png",
          height: 85.0,
          width: 85.0,
        ),
      ),
    );
  }
}
