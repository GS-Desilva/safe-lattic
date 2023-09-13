import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'package:safelattice/api/database_manager/database_manager.dart';
import 'package:safelattice/api/notification_manager/notification_manager.dart';
import 'package:safelattice/data/models/user.dart';
import 'package:safelattice/data/utils/global_data.dart';
import 'package:safelattice/presentation/utils/sl_alerts.dart';

class AuthManager {
  static final AuthManager _instance = AuthManager.internal();
  final _fbAuth = FirebaseAuth.instance;
  final _localAuth = LocalAuthentication();

  factory AuthManager() => _instance;

  AuthManager.internal();

  void createAuthListener() async {
    _fbAuth.authStateChanges().listen((User? user) {
      if (user == null) {
        GlobalData().currentUser == null;
      } else {
        GlobalData().currentUser = SlUser(
          slUserId: "N/A",
          fbUserId: user.uid,
          username: user.displayName ?? "N/A",
          email: user.email ?? "N/A",
          imageUrl: user.photoURL,
        );
      }
    });
  }

  Future<bool> signUp(
      {required String email,
      required String password,
      required String userName}) async {
    SlAlert()
        .showLoadingDialog(context: GlobalData().navigatorKey.currentContext!);
    try {
      final credential = await _fbAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName(userName);
      GlobalData().currentUser?.username = userName;

      await DatabaseManager().createUser(userId: credential.user!.uid);

      SlAlert().hideLoadingDialog(
          context: GlobalData().navigatorKey.currentContext!);

      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Unknown error please, try again.";

      SlAlert().hideLoadingDialog(
          context: GlobalData().navigatorKey.currentContext!);

      if (e.code == 'email-already-in-use') {
        errorMessage = "Email already registered.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid email address.";
      } else if (e.code == 'operation-not-allowed') {
        errorMessage = "Operation not allowed.";
      } else if (e.code == 'weak-password') {
        errorMessage = "Weak password.";
      }

      SlAlert().showMessageDialog(
        context: GlobalData().navigatorKey.currentContext!,
        title: "Signup failed",
        message: errorMessage,
      );

      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    SlAlert()
        .showLoadingDialog(context: GlobalData().navigatorKey.currentContext!);
    try {
      await _fbAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      GlobalData().currentUser?.slUserId = await DatabaseManager()
          .getPropertyForUserId(
              userId: GlobalData().currentUser!.fbUserId!,
              property: "slUserId");
      GlobalData().currentUser?.biometrics = await DatabaseManager()
          .getPropertyForUserId(
              userId: GlobalData().currentUser!.fbUserId!,
              property: "biometrics");
      GlobalData().currentUser?.pin = await DatabaseManager()
          .getPropertyForUserId(
              userId: GlobalData().currentUser!.fbUserId!, property: "pin");

      SlAlert().hideLoadingDialog(
          context: GlobalData().navigatorKey.currentContext!);

      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Unknown error please, try again.";

      SlAlert().hideLoadingDialog(
          context: GlobalData().navigatorKey.currentContext!);

      if (e.code == 'user-not-found') {
        errorMessage = "User not found.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Invalid password.";
      } else if (e.code == 'user-disabled') {
        errorMessage = "User disabled.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid email.";
      }

      SlAlert().showMessageDialog(
        context: GlobalData().navigatorKey.currentContext!,
        title: "Login failed",
        message: errorMessage,
      );

      return false;
    }
  }

  Future<bool> signOut() async {
    SlAlert()
        .showLoadingDialog(context: GlobalData().navigatorKey.currentContext!);
    try {
      await _fbAuth.signOut();

      SlAlert().hideLoadingDialog(
          context: GlobalData().navigatorKey.currentContext!);

      return true;
    } on FirebaseAuthException catch (e) {
      SlAlert().hideLoadingDialog(
          context: GlobalData().navigatorKey.currentContext!);

      SlAlert().showMessageDialog(
        context: GlobalData().navigatorKey.currentContext!,
        title: "Logout failed",
        message: e.message ?? "Unknown error please try again.",
      );

      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    SlAlert().showLoadingDialog(
      context: GlobalData().navigatorKey.currentContext!,
      dismissible: false,
    );

    bool success = false;
    User user = _fbAuth.currentUser!;
    AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!, password: currentPassword);

    await _fbAuth.currentUser
        ?.reauthenticateWithCredential(credential)
        .then((value) async {
      await user.updatePassword(newPassword).then((value) {
        success = true;
      }).onError((error, stackTrace) {
        SlAlert().hideLoadingDialog(
            context: GlobalData().navigatorKey.currentContext!);

        SlAlert().showMessageDialog(
          context: GlobalData().navigatorKey.currentContext!,
          title: "Password update failed",
          message: "New password is weak.",
        );

        success = false;
      });
    }).onError((FirebaseAuthException e, stackTrace) {
      SlAlert().hideLoadingDialog(
          context: GlobalData().navigatorKey.currentContext!);

      SlAlert().showMessageDialog(
        context: GlobalData().navigatorKey.currentContext!,
        title: "Password update failed",
        message: "Current password provided is invalid.",
      );
      success = false;
    });

    SlAlert()
        .hideLoadingDialog(context: GlobalData().navigatorKey.currentContext!);
    return success;
  }

  Future<bool> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    SlAlert().showLoadingDialog(
      context: GlobalData().navigatorKey.currentContext!,
      dismissible: false,
    );

    bool success = false;
    User user = _fbAuth.currentUser!;
    AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!, password: currentPassword);

    await _fbAuth.currentUser
        ?.reauthenticateWithCredential(credential)
        .then((value) async {
      await user.updateEmail(newEmail).then((value) {
        success = true;
      }).onError((FirebaseAuthException e, stackTrace) {
        String errorMessage = "Unknown error please, try again.";

        SlAlert().hideLoadingDialog(
            context: GlobalData().navigatorKey.currentContext!);

        if (e.code == 'invalid-email') {
          errorMessage = "Entered email is invalid";
        } else if (e.code == 'email-already-in-use') {
          errorMessage =
              "Entered email is already registered with Safe Lattice.";
        }

        SlAlert().showMessageDialog(
          context: GlobalData().navigatorKey.currentContext!,
          title: "Email update failed",
          message: errorMessage,
        );

        success = false;
      });
    }).onError((FirebaseAuthException e, stackTrace) {
      SlAlert().hideLoadingDialog(
          context: GlobalData().navigatorKey.currentContext!);

      SlAlert().showMessageDialog(
        context: GlobalData().navigatorKey.currentContext!,
        title: "Email update failed",
        message: "Current password provided is invalid.",
      );
      success = false;
    });

    SlAlert()
        .hideLoadingDialog(context: GlobalData().navigatorKey.currentContext!);
    return success;
  }

  Future<bool> updateUsername({required String newUsername}) async {
    bool success = false;

    SlAlert().showLoadingDialog(
        context: GlobalData().navigatorKey.currentContext!, dismissible: false);

    await _fbAuth.currentUser!.updateDisplayName(newUsername).then((value) {
      SlAlert().hideLoadingDialog(
          context: GlobalData().navigatorKey.currentContext!);
      success = true;
    }).onError((error, stackTrace) {
      SlAlert().hideLoadingDialog(
          context: GlobalData().navigatorKey.currentContext!);

      SlAlert().showMessageDialog(
          context: GlobalData().navigatorKey.currentContext!,
          title: "Unexpected Error",
          message: error.toString());
    });

    return success;
  }

  Future<bool> updatePhotoUrl({required String imageUrl}) async {
    bool success = false;

    SlAlert().showLoadingDialog(
        context: GlobalData().navigatorKey.currentContext!, dismissible: false);

    await _fbAuth.currentUser!.updatePhotoURL(imageUrl).then((value) {
      SlAlert().hideLoadingDialog(
          context: GlobalData().navigatorKey.currentContext!);
      success = true;
    }).onError((error, stackTrace) {
      SlAlert().hideLoadingDialog(
          context: GlobalData().navigatorKey.currentContext!);

      SlAlert().showMessageDialog(
          context: GlobalData().navigatorKey.currentContext!,
          title: "Unexpected Error",
          message: error.toString());
    });

    return success;
  }

  Future<bool> sendPasswordResetLink({required String email}) async {
    SlAlert()
        .showLoadingDialog(context: GlobalData().navigatorKey.currentContext!);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      SlAlert().hideLoadingDialog(
          context: GlobalData().navigatorKey.currentContext!);

      return true;
    } on FirebaseAuthException catch (e) {
      SlAlert().hideLoadingDialog(
          context: GlobalData().navigatorKey.currentContext!);

      SlAlert().showMessageDialog(
        context: GlobalData().navigatorKey.currentContext!,
        title: "Password reset failed",
        message: "Invalid email.",
      );

      return false;
    }
  }

  Future<bool> isBiometricsAvailable() async {
    return await _localAuth.isDeviceSupported();
  }

  Future<bool> authBiometric() async {
    return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to cancel alert.');
  }
}
