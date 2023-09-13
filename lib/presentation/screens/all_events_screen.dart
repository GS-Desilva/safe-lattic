import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:safelattice/data/models/event.dart';
import 'package:safelattice/data/utils/global_data.dart';
import 'package:safelattice/presentation/screens/event_screen.dart';
import 'package:safelattice/presentation/utils/app_colors.dart';
import 'package:safelattice/presentation/widgets/custom_navbar.dart';
import 'package:safelattice/presentation/widgets/sl_avatar.dart';
import 'package:safelattice/presentation/widgets/sl_floating_action_button.dart';

class AllEventsScreen extends StatefulWidget {
  const AllEventsScreen({Key? key}) : super(key: key);

  @override
  State<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen> {
  List<Event>? events;

  Future<void> fetchData() async {
    events = await GlobalData().currentUser?.getEvents() ?? [];
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const SlFloatingActionButton(),
      appBar: const CustomNavbar(
        title: "All Events",
      ),
      body: events == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(
                    color: AppColors.accentColor,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Loading",
                    style: TextStyle(color: AppColors.accentColor),
                  )
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(25.0, 25.0, 25.0, 0.0),
              child: ListView.separated(
                itemBuilder: (context, index) {
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                EventScreen(event: events![index]))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              SlAvatar(
                                imageUrl: events?[index].initiatedUser.imageUrl,
                                dimensions: 30.0,
                              ),
                              const SizedBox(width: 5.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${events?[index].initiatedUser.username}",
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        color: AppColors.primaryGray,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      DateFormat("dd/MM/yyyy").format(
                                          events?[index].dateTime ??
                                              DateTime.now()),
                                      style: const TextStyle(
                                        fontSize: 11.0,
                                        color: AppColors.secondaryGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SvgPicture.asset("assets/icons/ic_chevron.right.svg"),
                      ],
                    ),
                  );
                },
                separatorBuilder: (content, index) {
                  return Divider(
                    height: 20,
                    thickness: 1.0,
                    color: AppColors.primaryGray.withOpacity(0.25),
                  );
                },
                itemCount: events?.length ?? 0,
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
              ),
            ),
    );
  }
}
