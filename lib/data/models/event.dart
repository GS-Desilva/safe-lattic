import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safelattice/data/models/user.dart';

class Event {
  String eventId;
  double latitude;
  double longitude;
  DateTime dateTime;
  SlUser initiatedUser;

  Event({
    required this.eventId,
    required this.latitude,
    required this.longitude,
    required this.dateTime,
    required this.initiatedUser,
  });

  static Future<Event?> fromFireStore({required DocumentSnapshot doc}) async {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    SlUser? initiatedUser =
        await SlUser.getUserFromDocRef(doc: data["initiatedUser"]);
    return initiatedUser != null
        ? Event(
            eventId: data["eventId"],
            latitude: data["latitude"],
            longitude: data["longitude"],
            dateTime: DateTime.parse(data["datetime"]),
            initiatedUser: initiatedUser,
          )
        : null;
  }

  factory Event.fromJson({required Map json}) {
    return Event(
      eventId: json["eventId"],
      latitude: double.parse(json["latitude"]),
      longitude: double.parse(json["longitude"]),
      dateTime: DateTime.parse(json["dateTime"]),
      initiatedUser: SlUser.fromJson(
        json: jsonDecode(json["initiatedUser"]),
      ),
    );
  }

  Map toJson() {
    return {
      "eventId": eventId,
      "latitude": latitude,
      "longitude": longitude,
      "dateTime": dateTime.toString(),
      "initiatedUser": initiatedUser.toJson(),
    };
  }
}
