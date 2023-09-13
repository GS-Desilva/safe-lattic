import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safelattice/api/auth_manager/auth_manager.dart';
import 'package:safelattice/api/database_manager/database_manager.dart';
import 'package:safelattice/data/models/user.dart';
import 'package:safelattice/data/utils/global_data.dart';
import 'package:safelattice/presentation/screens/staging_screen.dart';
import 'package:safelattice/presentation/utils/app_colors.dart';
import 'package:safelattice/presentation/utils/sl_alerts.dart';
import 'package:safelattice/presentation/utils/sl_bottomsheet.dart';
import 'package:safelattice/presentation/widgets/custom_navbar.dart';
import 'package:safelattice/presentation/widgets/primary_card.dart';
import 'package:safelattice/presentation/widgets/primary_textfiled.dart';
import 'package:safelattice/presentation/widgets/secondary_button.dart';
import 'package:safelattice/presentation/widgets/sl_avatar.dart';
import 'package:safelattice/presentation/widgets/sl_floating_action_button.dart';
import 'package:safelattice/presentation/widgets/sl_image_picker.dart';
import 'package:safelattice/presentation/widgets/sl_numpad.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  StreamSubscription? listedOnSubscription;
  StreamSubscription? listRequestSubscription;
  List<SlUser>? listedOn;
  List<SlUser> listRequests = [];
  bool preciseLocationPermission = false;
  bool notificationPermission = false;
  bool cameraPermission = false;
  bool galleryPermission = false;
  bool biometricsPermission = false;
  bool pinPermission = false;
  bool showBiometricsPermission = false;
  String? currentPassword;
  String? newPassword;
  String? newConfirmedPassword;
  String? newEmail;
  String? newUsername;
  TextEditingController pinController = TextEditingController();
  TextEditingController newPinController = TextEditingController();

  Future<void> fetchData() async {
    listedOnSubscription =
        GlobalData().currentUser?.listedOnStream().listen((event) async {
      listedOn ??= [];
      if (event.docChanges.isNotEmpty) {
        for (var change in event.docChanges) {
          switch (change.type) {
            case DocumentChangeType.added:
              SlUser? newUser = await SlUser.getUserFromDocRef(
                  doc: ((change.doc.data() as Map<String, dynamic>)["user"]
                      as DocumentReference));
              if (newUser != null) listedOn?.add(newUser);
              break;
            case DocumentChangeType.removed:
              listedOn
                  ?.removeWhere((element) => change.doc.id == element.slUserId);
              break;
            default:
              break;
          }
        }
      }
      setState(() {});
    });

    listRequestSubscription =
        GlobalData().currentUser?.listRequestStream().listen((event) async {
      listRequests ??= [];
      if (event.docChanges.isNotEmpty) {
        for (var change in event.docChanges) {
          switch (change.type) {
            case DocumentChangeType.added:
              SlUser? newUser = await SlUser.getUserFromDocRef(
                  doc: ((change.doc.data() as Map<String, dynamic>)["user"]
                      as DocumentReference));

              if (newUser != null) {
                listRequests.add(newUser);
                listedOn?.add(newUser);
              }

              break;
            case DocumentChangeType.removed:
              listRequests
                  .removeWhere((element) => change.doc.id == element.slUserId);
              listedOn
                  ?.removeWhere((element) => change.doc.id == element.slUserId);
              break;
            default:
              break;
          }
        }
      }

      setState(() {});
    });

    listedOnSubscription?.onError(
      (error) => SlAlert().showMessageDialog(
        context: context,
        title: "Unexpected error",
        message: "Restart app and try again.",
      ),
    );

    listRequestSubscription?.onError(
      (error) => SlAlert().showMessageDialog(
        context: context,
        title: "Unexpected error",
        message: "Restart app and try again.",
      ),
    );
  }

  Future<void> checkPermission() async {
    showBiometricsPermission = await AuthManager().isBiometricsAvailable();
    preciseLocationPermission = await Permission.location.isGranted;
    notificationPermission = await Permission.notification.isGranted;
    cameraPermission = await Permission.camera.isGranted;
    if (Platform.isAndroid) {
      final androidVersion = await DeviceInfoPlugin()
          .androidInfo
          .then((value) => value.version.sdkInt);
      galleryPermission = androidVersion <= 32
          ? await Permission.storage.isGranted
          : await Permission.photos.isGranted;
    } else {
      galleryPermission = await Permission.photos.isGranted;
    }

    biometricsPermission = GlobalData().currentUser?.biometrics ?? false;
    pinPermission = GlobalData().currentUser?.pin != null ? true : false;

    setState(() {});
  }

  Future<void> togglePermission({required int permissionType}) async {
    switch (permissionType) {
      /// PreciseLocation
      case 0:
        if (preciseLocationPermission) {
          await openAppSettings();
        } else {
          PermissionStatus status =
              await Permission.locationWhenInUse.request();

          if (status == PermissionStatus.permanentlyDenied) {
            await openAppSettings();
          } else {
            setState(() {
              preciseLocationPermission = true;
            });
          }
        }
        break;

      /// Notifications
      case 1:
        if (notificationPermission) {
          await openAppSettings();
        } else {
          PermissionStatus status = await Permission.notification.request();

          if (status == PermissionStatus.permanentlyDenied) {
            await openAppSettings();
          } else {
            setState(() {
              notificationPermission = true;
            });
          }
        }
        break;

      /// Camera
      case 2:
        if (cameraPermission) {
          await openAppSettings();
        } else {
          PermissionStatus status = await Permission.camera.request();

          if (status == PermissionStatus.permanentlyDenied) {
            await openAppSettings();
          } else {
            setState(() {
              cameraPermission = true;
            });
          }
        }
        break;

      /// Gallery
      case 3:
        if (galleryPermission) {
          await openAppSettings();
        } else {
          PermissionStatus status;

          if (Platform.isAndroid) {
            final androidVersion = await DeviceInfoPlugin()
                .androidInfo
                .then((value) => value.version.sdkInt);
            status = androidVersion <= 32
                ? await Permission.storage.request()
                : await Permission.photos.request();
          } else {
            status = await Permission.photos.request();
          }

          if (status == PermissionStatus.permanentlyDenied) {
            await openAppSettings();
          } else {
            setState(() {
              galleryPermission = true;
            });
          }
        }
        break;

      /// Biometrics
      case 4:
        if (biometricsPermission) {
          if (await DatabaseManager().updateBiometric(
              fbId: GlobalData().currentUser!.fbUserId!, status: false)) {
            GlobalData().currentUser!.biometrics = false;
            setState(() {
              biometricsPermission = false;
            });
          }
        } else {
          if (pinPermission) {
            if (await DatabaseManager().updateBiometric(
                fbId: GlobalData().currentUser!.fbUserId!, status: true)) {
              GlobalData().currentUser!.biometrics = true;
              setState(() {
                biometricsPermission = true;
              });
            }
          } else {
            SlAlert().showMessageDialog(
              context: context,
              title: "Enable pin",
              message:
                  "You need to enable the pin first in order to use biometrics.",
            );
          }
        }

        break;

      /// Pin
      case 5:
        if (pinPermission) {
          SlBottomSheet().showCustomSheet(
            context: context,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrimaryTextField(
                  labelText: "Current Pin",
                  controller: pinController,
                  isPassword: true,
                  isEnabled: false,
                ),
                const SizedBox(height: 22.0),
                SlNumpad(
                  callBack: (value) {
                    pinController.text = value;
                  },
                  onTapDone: () async {
                    if (pinController.text.isNotEmpty) {
                      String newPin = sha256
                          .convert(utf8.encode(pinController.text))
                          .toString();

                      pinController.text = "";

                      if (newPin == GlobalData().currentUser!.pin!) {
                        if (await DatabaseManager().updatePin(
                              fbId: GlobalData().currentUser!.fbUserId!,
                              pin: null,
                            ) &&
                            await DatabaseManager().updateBiometric(
                              fbId: GlobalData().currentUser!.fbUserId!,
                              status: false,
                            )) {
                          GlobalData().currentUser!.pin = null;
                          GlobalData().currentUser!.biometrics = false;
                          setState(() {
                            pinPermission = false;
                            biometricsPermission = false;
                          });
                        }
                      } else {
                        SlAlert().showMessageDialog(
                            context: context,
                            title: "Invalid Pin",
                            message:
                                "The pin you've entered is incorrect, please try again.");
                      }
                    }
                  },
                ),
                const SizedBox(height: 22.0),
              ],
            ),
          );
        } else {
          SlBottomSheet().showCustomSheet(
            context: context,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrimaryTextField(
                  labelText: "New pin",
                  controller: pinController,
                  isPassword: true,
                  isEnabled: false,
                ),
                const SizedBox(height: 22.0),
                SlNumpad(
                  callBack: (value) {
                    pinController.text = value;
                  },
                  onTapDone: () async {
                    if (pinController.text.isNotEmpty) {
                      String newPin = sha256
                          .convert(utf8.encode(pinController.text))
                          .toString();
                      pinController.text = "";
                      if (await DatabaseManager().updatePin(
                        fbId: GlobalData().currentUser!.fbUserId!,
                        pin: newPin,
                      )) {
                        GlobalData().currentUser!.pin = newPin;
                        setState(() {
                          pinPermission = true;
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 22.0),
              ],
            ),
          );
        }
        break;

      default:
        break;
    }
  }

  Future<void> onTapPasswordChange() async {
    String? message;

    if (currentPassword == null ||
        newPassword == null ||
        newConfirmedPassword == null) {
      message = "Please enter valid passwords.";
    } else if (!RegExp(
            r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{7,}$')
        .hasMatch(newPassword ?? "")) {
      message =
          "New password should be more than 6 characters long and it should contain at least a single uppercase letter, lowercase letter, a number and a special character.";
    } else if (newPassword != newConfirmedPassword) {
      message = "New passwords entered do not match.";
    }

    if (message != null) {
      SlAlert().showMessageDialog(
        context: context,
        title: "Invalid input",
        message: message,
      );
      return;
    } else {
      Navigator.pop(context);

      bool updateSuccess = await AuthManager().changePassword(
          currentPassword: currentPassword!, newPassword: newPassword!);

      if (updateSuccess && await AuthManager().signOut()) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const StagingScreen()),
          (Route<dynamic> route) => false,
        );

        SlAlert().showMessageDialog(
          context: context,
          title: "Success",
          message:
              "New password successfully updated. Please login with new credentials.",
        );
      }
    }
  }

  Future<void> onTapEmailChange() async {
    String? message;

    if (newEmail == null ||
        !RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
            .hasMatch(newEmail ?? "")) {
      message = "Please enter valid email address.";
    } else if (newEmail == GlobalData().currentUser!.email) {
      message = "Please enter new email address.";
    }

    if (message != null) {
      SlAlert().showMessageDialog(
        context: context,
        title: "Invalid input",
        message: message,
      );
      return;
    } else {
      Navigator.pop(context);

      bool updateSuccess = await AuthManager().changeEmail(
          currentPassword: currentPassword ?? "", newEmail: newEmail!);

      if (updateSuccess && await AuthManager().signOut()) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const StagingScreen()),
          (Route<dynamic> route) => false,
        );

        SlAlert().showMessageDialog(
          context: context,
          title: "Success",
          message:
              "New email successfully updated. Please login with new credentials.",
        );
      }
    }
  }

  Future<void> onTapUsernameChange() async {
    String? message;

    if (newUsername == null ||
        newUsername!.isEmpty ||
        newUsername == GlobalData().currentUser!.username) {
      message = "Please enter new username.";
    } else if (!RegExp(r'^[A-Za-z ]+$').hasMatch(newUsername ?? "")) {
      message = "Please enter a valid username.";
    }

    if (message != null) {
      SlAlert().showMessageDialog(
        context: context,
        title: "Invalid input",
        message: message,
      );
      return;
    }

    Navigator.pop(context);

    if (await AuthManager().updateUsername(newUsername: newUsername!)) {
      if (await DatabaseManager().updateUsername(
          fbId: GlobalData().currentUser!.fbUserId!,
          newUsername: newUsername!)) {
        setState(() {
          GlobalData().currentUser?.username = newUsername!;
        });

        SlAlert().showMessageDialog(
          context: context,
          title: "Success",
          message: "Username successfully updated.",
        );
      }
    }
  }

  void onTapPicChange() async {
    await SlBottomSheet().showCustomSheet(
      context: context,
      content: const SlImagePicker(),
    );
    setState(() {});
  }

  Widget getListedOnAction(SlUser user) {
    if (listRequests.contains(user)) {
      return Row(
        children: [
          GestureDetector(
            onTap: () async {
              await DatabaseManager()
                  .respondRequest(userID: user.slUserId, acceptRequest: true);
            },
            child: SvgPicture.asset("assets/icons/ic_checkmark.circle.svg"),
          ),
          const SizedBox(width: 14.8),
          GestureDetector(
            onTap: () async {
              await DatabaseManager()
                  .respondRequest(userID: user.slUserId, acceptRequest: false);
            },
            child: SvgPicture.asset("assets/icons/ic_x.circle.svg"),
          ),
        ],
      );
    } else {
      return GestureDetector(
        onTap: () {
          SlAlert().showActionDialog(
            context: context,
            title: "Delete Contact?",
            message:
                "Are you sure you want to delete this contact from your listed contacts?",
            button1Callback: () async {
              Navigator.pop(context);
              bool? removeUser = await DatabaseManager()
                  .deleteContact(userID: user.slUserId, deleteFromListed: true);

              if (removeUser ?? false) {
                setState(() {
                  listedOn?.removeWhere(
                      (listUser) => listUser.slUserId == user.slUserId);
                });
              }
            },
          );
        },
        child: SvgPicture.asset("assets/icons/ic_minus.circle.svg"),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    checkPermission();
    fetchData();
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    listedOnSubscription?.cancel();
    listRequestSubscription?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        checkPermission();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const SlFloatingActionButton(),
      appBar: const CustomNavbar(
        title: "Profile",
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 29.0),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40.0),
              Center(
                child: GestureDetector(
                  onTap: onTapPicChange,
                  child: SlAvatar(
                    imageUrl: GlobalData().currentUser?.imageUrl,
                    dimensions: 107.0,
                  ),
                ),
              ),
              const SizedBox(height: 15.0),
              Text(
                GlobalData().currentUser!.username,
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: true,
                style: const TextStyle(
                  overflow: TextOverflow.clip,
                  fontSize: 39.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              Text(
                "SL ${GlobalData().currentUser!.slUserId}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17.0,
                  fontWeight: FontWeight.w300,
                  color: AppColors.primaryGray,
                ),
              ),
              const SizedBox(height: 5.0),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 75.0),
                child: Divider(
                  color: AppColors.accentColor,
                  thickness: 2,
                ),
              ),
              const SizedBox(height: 25.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 14.0),
                    child: Text(
                      "General",
                      style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 21.0,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  PrimaryCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 10.0),
                                  child: Text(
                                    GlobalData().currentUser?.username ?? "",
                                    style: const TextStyle(
                                      overflow: TextOverflow.ellipsis,
                                      fontSize: 16.0,
                                      color: AppColors.primaryGray,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  newUsername = newUsername;

                                  SlAlert().showCustomDialog(
                                    context: context,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        PrimaryCard(
                                          shadowEnabled: false,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "Update Username",
                                                style: TextStyle(
                                                  fontSize: 24.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primaryColor,
                                                ),
                                              ),
                                              const SizedBox(height: 10.0),
                                              PrimaryTextField(
                                                labelText: "Username",
                                                value: GlobalData()
                                                        .currentUser
                                                        ?.username ??
                                                    "",
                                                callback: (value) =>
                                                    newUsername = value,
                                              ),
                                              const SizedBox(height: 16.0),
                                              Row(
                                                children: [
                                                  const Spacer(),
                                                  SecondaryButton(
                                                    buttonText: "Update",
                                                    outline: true,
                                                    callback:
                                                        onTapUsernameChange,
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
                                child: SvgPicture.asset(
                                    "assets/icons/ic_square.and.pencil.svg"),
                              ),
                            ],
                          ),
                          Divider(
                            thickness: 1.0,
                            height: 35.0,
                            color: AppColors.primaryGray.withOpacity(0.25),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 10.0),
                                  child: Text(
                                    GlobalData().currentUser?.email ?? "",
                                    style: const TextStyle(
                                      overflow: TextOverflow.ellipsis,
                                      fontSize: 16.0,
                                      color: AppColors.primaryGray,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  newEmail = GlobalData().currentUser!.email;
                                  currentPassword = null;

                                  SlAlert().showCustomDialog(
                                    context: context,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        PrimaryCard(
                                          shadowEnabled: false,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "Update Email",
                                                style: TextStyle(
                                                  fontSize: 24.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primaryColor,
                                                ),
                                              ),
                                              const SizedBox(height: 10.0),
                                              PrimaryTextField(
                                                labelText: "Email",
                                                keyboardType:
                                                    TextInputType.emailAddress,
                                                value: GlobalData()
                                                        .currentUser
                                                        ?.email ??
                                                    "",
                                                callback: (value) =>
                                                    newEmail = value,
                                              ),
                                              const SizedBox(height: 10.0),
                                              PrimaryTextField(
                                                labelText: "Password",
                                                isPassword: true,
                                                callback: (value) =>
                                                    currentPassword = value,
                                              ),
                                              const SizedBox(height: 16.0),
                                              Row(
                                                children: [
                                                  const Spacer(),
                                                  SecondaryButton(
                                                    buttonText: "Update",
                                                    outline: true,
                                                    callback: onTapEmailChange,
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
                                child: SvgPicture.asset(
                                    "assets/icons/ic_square.and.pencil.svg"),
                              ),
                            ],
                          ),
                          Divider(
                            thickness: 1.0,
                            height: 35.0,
                            color: AppColors.primaryGray.withOpacity(0.25),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: 10.0),
                                  child: Text(
                                    "Password",
                                    style: TextStyle(
                                      overflow: TextOverflow.ellipsis,
                                      fontSize: 16.0,
                                      color: AppColors.primaryGray,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  currentPassword = null;
                                  newPassword = null;
                                  newConfirmedPassword = null;

                                  SlAlert().showCustomDialog(
                                    context: context,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        PrimaryCard(
                                          shadowEnabled: false,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "Update Password",
                                                style: TextStyle(
                                                  fontSize: 24.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primaryColor,
                                                ),
                                              ),
                                              const SizedBox(height: 10.0),
                                              PrimaryTextField(
                                                labelText: "Current Password",
                                                isPassword: true,
                                                callback: (value) =>
                                                    currentPassword = value,
                                              ),
                                              const SizedBox(height: 10.0),
                                              PrimaryTextField(
                                                labelText: "New Password",
                                                isPassword: true,
                                                callback: (value) =>
                                                    newPassword = value,
                                              ),
                                              const SizedBox(height: 10.0),
                                              PrimaryTextField(
                                                labelText: "Confirm Password",
                                                isPassword: true,
                                                callback: (value) =>
                                                    newConfirmedPassword =
                                                        value,
                                              ),
                                              const SizedBox(height: 16.0),
                                              Row(
                                                children: [
                                                  const Spacer(),
                                                  SecondaryButton(
                                                    buttonText: "Update",
                                                    outline: true,
                                                    callback:
                                                        onTapPasswordChange,
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
                                child: SvgPicture.asset(
                                    "assets/icons/ic_square.and.pencil.svg"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 23.3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 14.0),
                    child: Text(
                      "Listed On",
                      style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 21.0,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  PrimaryCard(
                    minHeight: 231.0,
                    child: listedOn == null
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accentColor,
                            ),
                          )
                        : listedOn!.isEmpty
                            ? const Center(
                                child: Text(
                                  "No Listings",
                                  style: TextStyle(
                                    color: AppColors.primaryGray,
                                    fontSize: 21.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  ListView.separated(
                                    itemBuilder: (context, index) {
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Text(
                                                  "${(index + 1).toString()}.",
                                                  style: const TextStyle(
                                                      fontSize: 16.0,
                                                      color: AppColors
                                                          .primaryGray),
                                                ),
                                                const SizedBox(width: 4.0),
                                                SlAvatar(
                                                  imageUrl:
                                                      listedOn?[index].imageUrl,
                                                  dimensions: 30.0,
                                                ),
                                                const SizedBox(width: 5.0),
                                                Expanded(
                                                  child: Text(
                                                    "${listedOn?[index].username}",
                                                    style: const TextStyle(
                                                      fontSize: 16.0,
                                                      color:
                                                          AppColors.primaryGray,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          getListedOnAction(listedOn![index]),
                                        ],
                                      );
                                    },
                                    separatorBuilder: (content, index) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        child: Divider(
                                          height: 20,
                                          thickness: 1.0,
                                          color: AppColors.primaryGray
                                              .withOpacity(0.25),
                                        ),
                                      );
                                    },
                                    itemCount: listedOn?.length ?? 0,
                                    padding:
                                        const EdgeInsets.only(bottom: 10.0),
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                  ),
                                ],
                              ),
                  ),
                ],
              ),
              const SizedBox(height: 23.3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 14.0),
                    child: Text(
                      "Permissions",
                      style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 21.0,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  PrimaryCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: 10.0),
                                child: Text(
                                  "Precise Location",
                                  style: TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    fontSize: 16.0,
                                    color: AppColors.primaryGray,
                                  ),
                                ),
                              ),
                            ),
                            Switch(
                              activeTrackColor: AppColors.accentColor,
                              inactiveTrackColor: AppColors.tertiaryGray,
                              thumbColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
                              value: preciseLocationPermission,
                              onChanged: (value) =>
                                  togglePermission(permissionType: 0),
                            ),
                          ],
                        ),
                        Divider(
                          thickness: 1.0,
                          height: 5.0,
                          color: AppColors.primaryGray.withOpacity(0.25),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: 10.0),
                                child: Text(
                                  "Notifications",
                                  style: TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    fontSize: 16.0,
                                    color: AppColors.primaryGray,
                                  ),
                                ),
                              ),
                            ),
                            Switch(
                              activeTrackColor: AppColors.accentColor,
                              inactiveTrackColor: AppColors.tertiaryGray,
                              thumbColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
                              value: notificationPermission,
                              onChanged: (value) =>
                                  togglePermission(permissionType: 1),
                            ),
                          ],
                        ),
                        Divider(
                          thickness: 1.0,
                          height: 5.0,
                          color: AppColors.primaryGray.withOpacity(0.25),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: 10.0),
                                child: Text(
                                  "Camera",
                                  style: TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    fontSize: 16.0,
                                    color: AppColors.primaryGray,
                                  ),
                                ),
                              ),
                            ),
                            Switch(
                              activeTrackColor: AppColors.accentColor,
                              inactiveTrackColor: AppColors.tertiaryGray,
                              thumbColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
                              value: cameraPermission,
                              onChanged: (value) =>
                                  togglePermission(permissionType: 2),
                            ),
                          ],
                        ),
                        Divider(
                          thickness: 1.0,
                          height: 5.0,
                          color: AppColors.primaryGray.withOpacity(0.25),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: 10.0),
                                child: Text(
                                  "Gallery",
                                  style: TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    fontSize: 16.0,
                                    color: AppColors.primaryGray,
                                  ),
                                ),
                              ),
                            ),
                            Switch(
                              activeTrackColor: AppColors.accentColor,
                              inactiveTrackColor: AppColors.tertiaryGray,
                              thumbColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
                              value: galleryPermission,
                              onChanged: (value) =>
                                  togglePermission(permissionType: 3),
                            ),
                          ],
                        ),
                        Divider(
                          thickness: 1.0,
                          height: 5.0,
                          color: AppColors.primaryGray.withOpacity(0.25),
                        ),
                        showBiometricsPermission
                            ? Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(right: 10.0),
                                          child: Text(
                                            "Biometrics",
                                            style: TextStyle(
                                              overflow: TextOverflow.ellipsis,
                                              fontSize: 16.0,
                                              color: AppColors.primaryGray,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Switch(
                                        activeTrackColor: AppColors.accentColor,
                                        inactiveTrackColor:
                                            AppColors.tertiaryGray,
                                        thumbColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.white),
                                        value: biometricsPermission,
                                        onChanged: (value) =>
                                            togglePermission(permissionType: 4),
                                      ),
                                    ],
                                  ),
                                  Divider(
                                    thickness: 1.0,
                                    height: 5.0,
                                    color:
                                        AppColors.primaryGray.withOpacity(0.25),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: 10.0),
                                child: Text(
                                  "Pin",
                                  style: TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    fontSize: 16.0,
                                    color: AppColors.primaryGray,
                                  ),
                                ),
                              ),
                            ),
                            Switch(
                              activeTrackColor: AppColors.accentColor,
                              inactiveTrackColor: AppColors.tertiaryGray,
                              thumbColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
                              value: pinPermission,
                              onChanged: (value) =>
                                  togglePermission(permissionType: 5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26.3),
              Padding(
                padding: const EdgeInsets.only(right: 206.0),
                child: SecondaryButton(
                  buttonText: "Log out",
                  outline: true,
                  callback: () async {
                    if (await AuthManager().signOut()) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const StagingScreen()),
                        (Route<dynamic> route) => false,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 40.0),
            ],
          ),
        ),
      ),
    );
  }
}
