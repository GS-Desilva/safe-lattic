import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:safelattice/data/models/event.dart';
import 'package:safelattice/presentation/utils/app_colors.dart';
import 'package:safelattice/presentation/utils/sl_alerts.dart';
import 'package:safelattice/presentation/widgets/custom_navbar.dart';
import 'package:safelattice/presentation/widgets/primary_button.dart';
import 'package:safelattice/presentation/widgets/primary_card.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart';
import 'package:safelattice/presentation/widgets/sl_avatar.dart';
import 'package:url_launcher/url_launcher.dart';

class EventScreen extends StatefulWidget {
  final Event event;

  const EventScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomNavbar(
        title: "Event",
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 25.0, vertical: 30.0),
            child: PrimaryCard(
              child: Row(
                children: [
                  SlAvatar(
                    imageUrl: widget.event.initiatedUser!.imageUrl,
                    dimensions: 76.0,
                  ),
                  const SizedBox(width: 5.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.event.initiatedUser.username,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 22.0,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        children: [
                          SvgPicture.asset("assets/icons/ic_clock.svg"),
                          const SizedBox(width: 5.0),
                          Text(
                            DateFormat("dd/MM/yyyy HH:mm")
                                .format(widget.event.dateTime),
                            style: const TextStyle(
                              color: AppColors.primaryGray,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        children: [
                          SvgPicture.asset(
                              "assets/icons/ic_mappin.and.ellipse.svg"),
                          const SizedBox(width: 5.0),
                          Text(
                            "${widget.event.latitude.toStringAsFixed(5)} , ${widget.event.longitude.toStringAsFixed(5)}",
                            style: const TextStyle(
                              color: AppColors.primaryGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                FlutterMap(
                  options: MapOptions(
                    interactiveFlags: InteractiveFlag.none,
                    center:
                        LatLng(widget.event.latitude, widget.event.longitude),
                    zoom: 15.2,
                  ),
                  nonRotatedChildren: [
                    AttributionWidget.defaultWidget(
                      source: 'OpenStreetMap contributors',
                      onSourceTapped: null,
                    ),
                  ],
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                  ],
                ),
                Container(
                  height: 135.0,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.accentColor,
                        Colors.white.withOpacity(0.0)
                      ],
                      stops: const [0.2, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(33.0),
                  child: PrimaryButton(
                    buttonText: "Get Directions",
                    height: 70.0,
                    callback: () async {
                      Uri googleUrl = Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=${widget.event.latitude},${widget.event.longitude}');
                      if (await canLaunchUrl(googleUrl)) {
                        SlAlert().showLoadingDialog(
                            context: context, dismissible: false);
                        await launchUrl(googleUrl);
                        SlAlert().hideLoadingDialog(context: context);
                      }
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Lottie.asset(
                    'assets/icons/ica_pin.json',
                    height: 150.0,
                    width: 150.0,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
