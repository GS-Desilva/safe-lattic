import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:safelattice/presentation/utils/app_colors.dart';
import 'package:safelattice/presentation/utils/sl_alerts.dart';

class SlCamera extends StatefulWidget {
  const SlCamera({
    Key? key,
  }) : super(key: key);

  @override
  State<SlCamera> createState() => _SlCameraState();
}

class _SlCameraState extends State<SlCamera> with WidgetsBindingObserver {
  CameraController? controller;
  late List<CameraDescription> _cameras;
  XFile? recorderVideo;
  bool videoStarted = false;
  bool savingVideo = false;

  Future<void> getCameras() async {
    _cameras = await availableCameras();
    controller = CameraController(_cameras[0], ResolutionPreset.max);
    controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
      startStopVideo();
    }).catchError((Object e) {
      if (e is CameraException) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> startStopVideo() async {
    if (!videoStarted) {
      if (controller!.value.isRecordingVideo) return;
      try {
        await controller?.prepareForVideoRecording();
        await controller?.setFlashMode(FlashMode.torch);
        await controller?.startVideoRecording();
        setState(() {
          videoStarted = true;
        });
      } on CameraException catch (e) {
        SlAlert().showMessageDialog(
            context: context,
            title: "Error",
            message: 'Error starting video recording: $e');
      }
    } else {
      if (!controller!.value.isRecordingVideo) return;
      try {
        await controller?.setFlashMode(FlashMode.off);
        recorderVideo = await controller!.stopVideoRecording();
        setState(() {
          videoStarted = false;
        });

        if (recorderVideo != null) {
          setState(() {
            savingVideo = true;
          });
          await ImageGallerySaver.saveFile(recorderVideo!.path);
          setState(() {
            savingVideo = false;
          });
          Navigator.pop(context, true);
        }
      } on CameraException catch (e) {
        SlAlert().showMessageDialog(
            context: context,
            title: "Error",
            message: 'Error stopping video recording: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getCameras();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      getCameras();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.accentColor,
          ),
        ),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Stack(
        children: [
          CameraPreview(controller!),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: GestureDetector(
                onTap: startStopVideo,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: videoStarted ? Colors.red : Colors.white,
                            width: 5,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: videoStarted ? 45 : 70,
                        width: videoStarted ? 45 : 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: videoStarted ? Colors.red : Colors.white,
                          border: Border.all(
                            color: videoStarted
                                ? Colors.transparent
                                : AppColors.accentColor,
                            width: 5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          savingVideo
              ? Container(
                  color: Colors.black.withOpacity(0.60),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentColor,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
