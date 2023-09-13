import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safelattice/api/database_manager/database_manager.dart';
import 'package:safelattice/api/notification_manager/notification_manager.dart';
import 'package:safelattice/data/models/event.dart';
import 'package:safelattice/data/models/user.dart';
import 'package:safelattice/data/utils/global_data.dart';
import 'package:safelattice/presentation/screens/alert_screen.dart';
import 'package:safelattice/presentation/screens/all_events_screen.dart';
import 'package:safelattice/presentation/screens/event_screen.dart';
import 'package:safelattice/presentation/screens/profile_screen.dart';
import 'package:safelattice/presentation/utils/app_colors.dart';
import 'package:safelattice/presentation/utils/sl_alerts.dart';
import 'package:safelattice/presentation/widgets/logo_with_text.dart';
import 'package:safelattice/presentation/widgets/primary_card.dart';
import 'package:safelattice/presentation/widgets/primary_textfiled.dart';
import 'package:safelattice/presentation/widgets/secondary_button.dart';
import 'package:safelattice/presentation/widgets/sl_avatar.dart';
import 'package:safelattice/presentation/widgets/sl_floating_action_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription? emergencyContactsSubscription;
  StreamSubscription? requestedSubscription;
  StreamSubscription? eventsSubscription;
  List<SlUser>? emergencyContacts;
  List<SlUser>? requestedContacts;
  List<SlUser>? displayableContacts;
  List<Event>? events;
  String userSearchText = "";
  SlUser? searchedUser;
  PageController pageController = PageController();
  bool animateOnboardingButton = false;
  bool animateOnboardingButtonText = false;

  Future<void> fetchData() async {
    emergencyContactsSubscription = GlobalData()
        .currentUser
        ?.emergencyContactsStream()
        .listen((event) async {
      emergencyContacts ??= [];
      requestedContacts ??= [];
      displayableContacts ??= [];

      if (event.docChanges.isNotEmpty) {
        for (var change in event.docChanges) {
          switch (change.type) {
            case DocumentChangeType.added:
              SlUser? newUser = await SlUser.getUserFromDocRef(
                  doc: ((change.doc.data() as Map<String, dynamic>)["user"]
                      as DocumentReference));

              if (newUser != null) {
                emergencyContacts?.add(newUser);
                int? index = displayableContacts?.indexWhere((displayedUser) =>
                    displayedUser.slUserId == newUser.slUserId);

                if (index != null && index != -1) {
                  displayableContacts?[index] = newUser;
                } else {
                  displayableContacts?.add(newUser);
                }
              }
              break;

            case DocumentChangeType.removed:
              emergencyContacts
                  ?.removeWhere((element) => change.doc.id == element.slUserId);
              displayableContacts
                  ?.removeWhere((element) => change.doc.id == element.slUserId);
              setState(() {});
              break;

            default:
              break;
          }
        }
      }

      GlobalData().emergencyContacts = emergencyContacts;
      setState(() {});
    });

    requestedSubscription = GlobalData()
        .currentUser
        ?.requestedContactsStream()
        .listen((event) async {
      emergencyContacts ??= [];
      requestedContacts ??= [];
      displayableContacts ??= [];

      if (event.docChanges.isNotEmpty) {
        for (var change in event.docChanges) {
          switch (change.type) {
            case DocumentChangeType.added:
              SlUser? newUser = await SlUser.getUserFromDocRef(
                  doc: ((change.doc.data() as Map<String, dynamic>)["user"]
                      as DocumentReference));

              if (newUser != null) {
                requestedContacts?.add(newUser);
                displayableContacts?.add(newUser);
              }
              break;

            case DocumentChangeType.removed:
              requestedContacts?.removeWhere(
                  (element) => (change.doc.id == element.slUserId));
              displayableContacts?.removeWhere(
                  (element) => (change.doc.id == element.slUserId));
              break;
            default:
              break;
          }
        }
      }

      setState(() {});
    });

    eventsSubscription =
        GlobalData().currentUser?.getEventsStream().listen((event) async {
      events ??= [];
      List<DocumentChange<Object?>> docChanges = [];

      if (event.docChanges.length < 4) {
        docChanges = event.docChanges;
      } else {
        docChanges = event.docChanges.sublist(0, 4);
      }

      if (docChanges.isNotEmpty) {
        for (var change in docChanges) {
          switch (change.type) {
            case DocumentChangeType.added:
              Event? newEvent = await Event.fromFireStore(doc: change.doc);
              if (newEvent != null) events?.insert(0, newEvent);
              break;
            default:
              break;
          }
        }
        setState(() {});
      }
    });

    emergencyContactsSubscription?.onError(
      (error) => SlAlert().showMessageDialog(
        context: context,
        title: "Unexpected error",
        message: "Restart app and try again.",
      ),
    );

    requestedSubscription?.onError(
      (error) => SlAlert().showMessageDialog(
        context: context,
        title: "Unexpected error",
        message: "Restart app and try again.",
      ),
    );

    eventsSubscription?.onError(
      (error) => SlAlert().showMessageDialog(
        context: context,
        title: "Unexpected error",
        message: "Restart app and try again.",
      ),
    );
  }

  Future<void> checkPermission() async {
    if (!(await Permission.locationWhenInUse.isGranted)) {
      await Permission.locationWhenInUse.request();
    }
    if (!(await Permission.notification.isGranted)) {
      await Permission.notification.request();
    }
    if (!(await Permission.camera.isGranted)) {
      await Permission.camera.request();
    }
    if (!(await Permission.microphone.isGranted)) {
      await Permission.microphone.request();
    }
    if (!(await Permission.photos.isGranted)) {
      await Permission.photos.request();
    }

    if (Platform.isAndroid) {
      final androidVersion = await DeviceInfoPlugin()
          .androidInfo
          .then((value) => value.version.sdkInt);
      if (androidVersion <= 32) {
        if (!(await Permission.storage.isGranted)) {
          await Permission.storage.request();
        }
      } else {
        if (!(await Permission.photos.isGranted)) {
          await Permission.photos.request();
        }
      }
    } else {
      if (!(await Permission.photos.isGranted)) {
        await Permission.photos.request();
      }
    }
  }

  Future<void> checkOnboarding() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('onboarded') == true) {
      await checkPermission();
    } else {
      await SlAlert().showCustomDialog(
        dismissible: false,
        context: context,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatefulBuilder(
              builder: (context, setState) {
                return Dialog(
                  insetPadding: const EdgeInsets.all(29.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PrimaryCard(
                        height: 459.0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: PageView(
                                controller: pageController,
                                physics: const NeverScrollableScrollPhysics(),
                                onPageChanged: (value) async {
                                  if (value == 2) {
                                    setState(() {
                                      animateOnboardingButton = true;
                                    });
                                    Timer(const Duration(milliseconds: 500),
                                        () {
                                      setState(() {
                                        animateOnboardingButtonText = true;
                                      });
                                    });
                                  } else if (value == 1) {
                                    await checkPermission();
                                  }
                                },
                                children: [
                                  Column(
                                    children: [
                                      const Text(
                                        "Permission",
                                        style: TextStyle(
                                            color: AppColors.primaryColor,
                                            fontSize: 27.0,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 9.6),
                                      SvgPicture.asset(
                                          "assets/images/onboarding_illustration_1.svg"),
                                      const SizedBox(height: 14.0),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        child: Text(
                                          "Make sure to grant all requested permissions in order to get the full potential of the application",
                                          style: TextStyle(
                                              height: 0,
                                              color: AppColors.primaryGray,
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.normal),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Text(
                                        "Add Widget",
                                        style: TextStyle(
                                            color: AppColors.primaryColor,
                                            fontSize: 27.0,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 9.6),
                                      SvgPicture.asset(
                                          "assets/images/onboarding_illustration_2.svg"),
                                      const SizedBox(height: 14.0),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        child: Text(
                                          "Add home screen widget to access the app in case of an emergency",
                                          style: TextStyle(
                                              height: 0,
                                              color: AppColors.primaryGray,
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.normal),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Center(
                                        child: SvgPicture.asset(
                                            "assets/images/onboarding_illustration_3.svg"),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Center(
                              child: AnimatedOpacity(
                                opacity: animateOnboardingButton ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 900),
                                child: Center(
                                  child: SmoothPageIndicator(
                                    controller:
                                        pageController, // PageController
                                    count: 3,
                                    effect: const ExpandingDotsEffect(
                                      dotHeight: 7.0,
                                      dotWidth: 7.0,
                                      spacing: 3.0,
                                      dotColor: AppColors.secondaryGray,
                                      activeDotColor: AppColors.primaryGray,
                                    ), // your preferred effect
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12.0),
                            GestureDetector(
                              onTap: () async {
                                if (animateOnboardingButton) {
                                  await prefs.setBool('onboarded', true);
                                  Navigator.of(context).pop();
                                } else {
                                  pageController.nextPage(
                                    duration: const Duration(milliseconds: 900),
                                    curve: Curves.fastOutSlowIn,
                                  );
                                }
                              },
                              child: AnimatedContainer(
                                width: animateOnboardingButton
                                    ? MediaQuery.of(context).size.width * 0.8
                                    : 48.0,
                                height: 48.0,
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.fastOutSlowIn,
                                decoration: BoxDecoration(
                                  color: AppColors.accentColor,
                                  borderRadius: BorderRadius.circular(
                                    animateOnboardingButton ? 13.0 : 200.0,
                                  ),
                                ),
                                child: Center(
                                  child: AnimatedCrossFade(
                                    alignment: Alignment.center,
                                    firstChild: Center(
                                      child: SvgPicture.asset(
                                        "assets/icons/ic_chevron.right.svg",
                                        height: 25.0,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                    secondChild: const Center(
                                      child: Text(
                                        "Get Started",
                                        style: TextStyle(
                                            color: AppColors.primaryColor,
                                            fontSize: 27.0,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    crossFadeState: animateOnboardingButtonText
                                        ? CrossFadeState.showSecond
                                        : CrossFadeState.showFirst,
                                    duration: const Duration(milliseconds: 300),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    }
  }

  void onTapAddContact() async {
    searchedUser = null;
    userSearchText = "";

    if (emergencyContacts?.length == 5) {
      SlAlert().showMessageDialog(
        context: context,
        title: "Maximum emergency contacts added",
        message:
            "Maximum emergency contacts have been added. Please remove an existing contact to add more.",
      );
      return;
    }

    await SlAlert().showCustomDialog(
      context: context,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatefulBuilder(
            builder: (context, setState) {
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
                          const Text(
                            "Add Contact",
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          PrimaryTextField(
                            callback: (text) {
                              if (searchedUser != null) {
                                setState(() {
                                  searchedUser = null;
                                });
                              }
                              userSearchText = text;
                            },
                            keyboardType: TextInputType.number,
                            labelText: "User ID",
                            prefixContent: const Text(
                              "SL",
                              style: TextStyle(
                                color: AppColors.primaryGray,
                                fontSize: 19.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          Stack(
                            children: [
                              Row(
                                children: [
                                  const Spacer(),
                                  SecondaryButton(
                                    buttonText: "Search User",
                                    outline: true,
                                    callback: () async {
                                      String? alertMessage;

                                      if (userSearchText.isEmpty) {
                                        alertMessage =
                                            "Enter SL User ID to search user.";
                                      } else if (userSearchText ==
                                          GlobalData().currentUser?.slUserId) {
                                        alertMessage =
                                            "Cannot enter current user as an emergency contact.";
                                      } else if (requestedContacts!.any(
                                          (contact) =>
                                              contact.slUserId ==
                                              userSearchText)) {
                                        alertMessage =
                                            "The user has already been requested to be added on your emergency contacts.";
                                      } else if (emergencyContacts!.any(
                                          (contact) =>
                                              contact.slUserId ==
                                              userSearchText)) {
                                        alertMessage =
                                            "User is already on your emergency contacts.";
                                      }

                                      if (alertMessage != null) {
                                        SlAlert().showMessageDialog(
                                          context: context,
                                          title: "Invalid user ID",
                                          message: alertMessage,
                                        );
                                        return;
                                      } else {
                                        SlUser? user = await DatabaseManager()
                                            .getUserFromId(
                                                slUserId:
                                                    userSearchText.trim());

                                        setState(() {
                                          searchedUser = user;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                              searchedUser != null
                                  ? GestureDetector(
                                      onTap: () async {
                                        Navigator.pop(context);
                                        if (searchedUser != null) {
                                          searchedUser = await DatabaseManager()
                                              .sendRequest(user: searchedUser!);
                                        }
                                      },
                                      child: Container(
                                        height: 55.0,
                                        color: AppColors.tertiaryGray,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 9.0, horizontal: 11.0),
                                        child: Row(
                                          children: [
                                            SlAvatar(
                                              imageUrl: searchedUser!.imageUrl,
                                              dimensions: 45.0,
                                            ),
                                            const SizedBox(width: 5.0),
                                            Text(
                                              searchedUser!.username,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: AppColors.primaryColor,
                                                fontSize: 16.0,
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget getContactStatusWidget(SlUser? newContact) {
    if (requestedContacts!
        .any((contact) => contact.slUserId == newContact?.slUserId)) {
      return SvgPicture.asset("assets/icons/ic_person.fill.questionmark.svg");
    } else {
      return SvgPicture.asset("assets/icons/ic_person.fill.checkmark.svg");
    }
  }

  @override
  void initState() {
    super.initState();
    NotificationManager().initFcm();
    NotificationManager().initLocalNotifications();
    checkOnboarding();
    fetchData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (GlobalData().launchAlertScreenOnHome) {
        GlobalData().launchAlertScreenOnHome = false;
        pushAlertScreen(context: context);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    emergencyContactsSubscription?.cancel();
    requestedSubscription?.cancel();
    eventsSubscription?.cancel();
    NotificationManager().disposeFcm();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const SlFloatingActionButton(),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 29.0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 47.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const LogoWithText(),
                      GestureDetector(
                        onTap: () async {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ProfileScreen())).then((value) {
                            setState(() {});
                          });
                        },
                        child: SlAvatar(
                          imageUrl: GlobalData().currentUser?.imageUrl,
                          dimensions: 45.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 14.0),
                      child: Text(
                        "Emergency Contacts",
                        style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 21.0,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    PrimaryCard(
                      minHeight: 231.0,
                      child: displayableContacts == null
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.accentColor,
                              ),
                            )
                          : displayableContacts!.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        "Add Contact",
                                        style: TextStyle(
                                          color: AppColors.primaryGray,
                                          fontSize: 21.0,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4.5),
                                      GestureDetector(
                                        onTap: onTapAddContact,
                                        child: SvgPicture.asset(
                                            "assets/icons/ic_plus.circle.svg"),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  mainAxisSize: MainAxisSize.max,
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
                                                        displayableContacts?[
                                                                index]
                                                            .imageUrl,
                                                    dimensions: 30.0,
                                                  ),
                                                  const SizedBox(width: 5.0),
                                                  Expanded(
                                                    child: Text(
                                                      "${displayableContacts?[index].username}",
                                                      style: const TextStyle(
                                                        fontSize: 16.0,
                                                        color: AppColors
                                                            .primaryGray,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                getContactStatusWidget(
                                                    displayableContacts?[
                                                        index]),
                                                const SizedBox(width: 14.8),
                                                GestureDetector(
                                                  onTap: () {
                                                    SlAlert().showActionDialog(
                                                      context: context,
                                                      title: "Delete Contact?",
                                                      message:
                                                          "Are you sure you want to delete this contact from your emergency contact list?",
                                                      button1Callback:
                                                          () async {
                                                        Navigator.pop(context);
                                                        await DatabaseManager().deleteContact(
                                                            userID: displayableContacts![
                                                                    index]
                                                                .slUserId,
                                                            deleteFromListed:
                                                                false,
                                                            contactPending: requestedContacts!
                                                                .any((contact) =>
                                                                    contact
                                                                        .slUserId ==
                                                                    displayableContacts?[
                                                                            index]
                                                                        .slUserId));
                                                      },
                                                    );
                                                  },
                                                  child: SvgPicture.asset(
                                                      "assets/icons/ic_minus.circle.svg"),
                                                ),
                                              ],
                                            )
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
                                      itemCount:
                                          displayableContacts?.length ?? 0,
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                    ),
                                    const SizedBox(height: 20.0),
                                    GestureDetector(
                                      onTap: onTapAddContact,
                                      child: SvgPicture.asset(
                                          "assets/icons/ic_plus.circle.fill.svg"),
                                    ),
                                  ],
                                ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 14.0),
                      child: Text(
                        "Events",
                        style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 21.0,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    PrimaryCard(
                      minHeight: 231.0,
                      child: events == null
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.accentColor,
                              ),
                            )
                          : events!.isEmpty
                              ? const Center(
                                  child: Text(
                                    "No Events",
                                    style: TextStyle(
                                      color: AppColors.primaryGray,
                                      fontSize: 21.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ListView.separated(
                                      itemBuilder: (context, index) {
                                        return GestureDetector(
                                          behavior: HitTestBehavior.translucent,
                                          onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      EventScreen(
                                                          event:
                                                              events![index]))),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    SlAvatar(
                                                      imageUrl: events?[index]
                                                          .initiatedUser
                                                          .imageUrl,
                                                      dimensions: 30.0,
                                                    ),
                                                    const SizedBox(width: 5.0),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            "${events?[index].initiatedUser.username}",
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 16.0,
                                                              color: AppColors
                                                                  .primaryGray,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                          Text(
                                                            DateFormat(
                                                                    "dd/MM/yyyy")
                                                                .format(events?[
                                                                            index]
                                                                        .dateTime ??
                                                                    DateTime
                                                                        .now()),
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 11.0,
                                                              color: AppColors
                                                                  .secondaryGray,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SvgPicture.asset(
                                                  "assets/icons/ic_chevron.right.svg"),
                                            ],
                                          ),
                                        );
                                      },
                                      separatorBuilder: (content, index) {
                                        return Divider(
                                          height: 20,
                                          thickness: 1.0,
                                          color: AppColors.primaryGray
                                              .withOpacity(0.25),
                                        );
                                      },
                                      itemCount: events?.length ?? 0,
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                    ),
                                    const SizedBox(height: 20.0),
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const AllEventsScreen())),
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            const Text(
                                              "See All",
                                              style: TextStyle(
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.w400,
                                                color: AppColors.primaryColor,
                                              ),
                                            ),
                                            const SizedBox(width: 6.7),
                                            SvgPicture.asset(
                                              "assets/icons/ic_chevron.right.svg",
                                              width: 6.5,
                                              color: AppColors.primaryColor,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                    )
                  ],
                ),
                const SizedBox(height: 119.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
