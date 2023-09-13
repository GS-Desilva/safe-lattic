import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:safelattice/api/auth_manager/auth_manager.dart';
import 'package:safelattice/data/utils/global_data.dart';
import 'package:safelattice/presentation/screens/alert_screen.dart';
import 'package:safelattice/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<void> initHomeWidget() async {
    await HomeWidget.setAppGroupId("SafeLattice_GroupId");

    if (await HomeWidget.initiallyLaunchedFromHomeWidget() != null) {
      GlobalData().launchAlertScreenOnHome = true;
    }

    HomeWidget.widgetClicked.listen((event) {
      if (GlobalData().currentUser != null) {
        pushAlertScreen(context: GlobalData().navigatorKey.currentContext!);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    AuthManager().createAuthListener();
    initHomeWidget();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: GlobalData().navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)
              .copyWith(background: Colors.white)),
      home: const SplashScreen(),
    );
  }
}
