import 'package:flutter/material.dart';
import 'package:safelattice/data/models/user.dart';

class GlobalData {
  static final GlobalData _instance = GlobalData._internal();

  factory GlobalData() {
    return _instance;
  }

  GlobalData._internal();

  SlUser? currentUser;
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  List<SlUser>? emergencyContacts;
  bool launchAlertScreenOnHome = false;
}
