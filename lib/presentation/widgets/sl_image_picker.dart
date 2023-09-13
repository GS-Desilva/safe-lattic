import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safelattice/api/auth_manager/auth_manager.dart';
import 'package:safelattice/api/database_manager/database_manager.dart';
import 'package:safelattice/api/storage_manager/storage_manager.dart';
import 'package:safelattice/data/utils/global_data.dart';
import 'package:safelattice/presentation/utils/app_colors.dart';
import 'package:safelattice/presentation/utils/sl_alerts.dart';
import 'package:safelattice/presentation/widgets/secondary_button.dart';
import 'package:device_info_plus/device_info_plus.dart';

class SlImagePicker extends StatefulWidget {
  const SlImagePicker({
    Key? key,
  }) : super(key: key);

  @override
  State<SlImagePicker> createState() => _SlImagePickerState();
}

class _SlImagePickerState extends State<SlImagePicker> {
  XFile? pickedImage;
  CroppedFile? croppedImage;
  String? networkImage;

  @override
  void initState() {
    super.initState();
    if (GlobalData().currentUser!.imageUrl != null &&
        GlobalData().currentUser!.imageUrl != "N/A") {
      setState(() {
        networkImage = GlobalData().currentUser!.imageUrl;
      });
    }
  }

  Widget imageToDisplay() {
    if (pickedImage == null && networkImage == null) {
      return SvgPicture.asset(
        "assets/icons/ic_person.crop.circle.svg",
        height: 150.0,
        width: 150.0,
      );
    } else if (croppedImage != null) {
      return Stack(
        children: [
          Container(
            height: 150.0,
            width: 150.0,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Image.file(
              File(croppedImage!.path),
              fit: BoxFit.cover,
            ),
          ),
          Container(
            height: 150.0,
            width: 150.0,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.accentColor, width: 2.0),
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
          ),
        ],
      );
    } else if (pickedImage != null) {
      return Stack(
        children: [
          Container(
            height: 150.0,
            width: 150.0,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Image.file(
              File(pickedImage!.path),
              fit: BoxFit.cover,
            ),
          ),
          Container(
            height: 150.0,
            width: 150.0,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.accentColor, width: 2.0),
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
          ),
        ],
      );
    } else {
      return Stack(
        children: [
          Container(
            height: 150.0,
            width: 150.0,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Image.network(
              networkImage!,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            height: 150.0,
            width: 150.0,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.accentColor, width: 2.0),
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Update Avatar",
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 35.0,
          ),
        ),
        const SizedBox(height: 20.0),
        Stack(
          alignment: Alignment.center,
          children: [
            pickedImage != null
                ? Positioned(
                    bottom: 10,
                    right: MediaQuery.of(context).size.width * 0.14,
                    child: GestureDetector(
                      onTap: () async {
                        CroppedFile? croppedFile =
                            await ImageCropper().cropImage(
                          sourcePath: pickedImage!.path,
                          aspectRatioPresets: [
                            CropAspectRatioPreset.square,
                          ],
                          uiSettings: [
                            AndroidUiSettings(
                                toolbarTitle: 'Edit Image',
                                toolbarColor: AppColors.primaryColor,
                                toolbarWidgetColor: Colors.white,
                                activeControlsWidgetColor:
                                    AppColors.accentColor,
                                initAspectRatio: CropAspectRatioPreset.original,
                                lockAspectRatio: true),
                            IOSUiSettings(
                              title: 'Edit Image',
                              aspectRatioLockEnabled: true,
                            ),
                          ],
                        );

                        setState(() {
                          croppedImage = croppedFile;
                        });
                      },
                      child: SvgPicture.asset(
                        "assets/icons/ic_crop.rotate.svg",
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            pickedImage != null
                ? Positioned(
                    bottom: 10,
                    left: MediaQuery.of(context).size.width * 0.14,
                    child: GestureDetector(
                      onTap: () async {
                        if (pickedImage != null) {
                          String? imageDownloadUrl = await StorageManager()
                              .uploadProfilePic(
                                  file: File(
                                      croppedImage?.path ?? pickedImage!.path));

                          if (imageDownloadUrl != null) {
                            if (await DatabaseManager().updateImageUrl(
                                fbId: GlobalData().currentUser!.fbUserId!,
                                imageUrl: imageDownloadUrl)) {
                              if (await AuthManager()
                                  .updatePhotoUrl(imageUrl: imageDownloadUrl)) {
                                Navigator.pop(context);
                                setState(() {
                                  GlobalData().currentUser!.imageUrl =
                                      imageDownloadUrl;
                                });
                              }
                            }
                          }
                        }
                      },
                      child: SvgPicture.asset(
                          "assets/icons/ic_checkmark.circle.svg"),
                    ),
                  )
                : const SizedBox.shrink(),
            imageToDisplay(),
          ],
        ),
        const SizedBox(height: 22.0),
        SecondaryButton(
          buttonText: "Open Camera",
          callback: () async {
            if (await Permission.camera.request().isGranted) {
              final XFile? photo = await ImagePicker().pickImage(
                source: ImageSource.camera,
                preferredCameraDevice: CameraDevice.front,
              );

              if (photo != null) {
                setState(() {
                  croppedImage = null;
                  pickedImage = photo;
                });
              }
            } else {
              SlAlert().showActionDialog(
                context: context,
                title: "Permission required",
                message:
                    "App needs camera permission in order to open the camera.",
                button1Text: "Settings",
                button2Text: "Dismiss",
                button1Callback: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
              );
            }
          },
        ),
        const SizedBox(height: 10.0),
        SecondaryButton(
          buttonText: "Open Gallery",
          outline: true,
          callback: () async {
            if (Platform.isAndroid) {
              final androidVersion = await DeviceInfoPlugin()
                  .androidInfo
                  .then((value) => value.version.sdkInt);
              if (androidVersion <= 32
                  ? await Permission.storage.request().isGranted
                  : await Permission.photos.request().isGranted) {
                final XFile? photo = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                );

                if (photo != null) {
                  setState(() {
                    croppedImage = null;
                    pickedImage = photo;
                  });
                }
                return;
              }
            } else {
              if (await Permission.photos.request().isGranted) {
                final XFile? photo = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                );

                if (photo != null) {
                  setState(() {
                    croppedImage = null;
                    pickedImage = photo;
                  });
                }
                return;
              }
            }

            SlAlert().showActionDialog(
              context: context,
              title: "Permission required",
              message:
                  "App needs gallery permission in order to access the photo gallery of this device.",
              button1Text: "Settings",
              button2Text: "Dismiss",
              button1Callback: () {
                Navigator.pop(context);
                openAppSettings();
              },
            );
          },
        ),
        const SizedBox(height: 26.0),
      ],
    );
  }
}
