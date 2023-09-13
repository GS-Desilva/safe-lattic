import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:safelattice/data/utils/global_data.dart';
import 'package:safelattice/presentation/utils/sl_alerts.dart';

class StorageManager {
  static final StorageManager _instance = StorageManager.internal();
  final _fbStorage = FirebaseStorage.instance;

  factory StorageManager() => _instance;

  StorageManager.internal();

  Future<String?> uploadProfilePic({required File file}) async {
    final profilePicRef = _fbStorage
        .ref()
        .child("profile-pics/${GlobalData().currentUser!.fbUserId}/pic.jpg");

    SlAlert().showLoadingDialog(
      context: GlobalData().navigatorKey.currentContext!,
      dismissible: false,
    );

    try {
      await profilePicRef.putFile(file);
      String downloadUrl = await profilePicRef.getDownloadURL();

      SlAlert().hideLoadingDialog(
        context: GlobalData().navigatorKey.currentContext!,
      );

      return downloadUrl;
    } on FirebaseException catch (e) {
      SlAlert().hideLoadingDialog(
        context: GlobalData().navigatorKey.currentContext!,
      );

      SlAlert().showMessageDialog(
          context: GlobalData().navigatorKey.currentContext!,
          title: "Unexpected Error",
          message:
              "An unexpected error occurred while uploading your profile picture. Please try again.");
    }
  }
}
