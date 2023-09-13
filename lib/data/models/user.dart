import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safelattice/api/database_manager/database_manager.dart';
import 'package:safelattice/data/models/event.dart';
import 'package:safelattice/data/utils/global_data.dart';

class SlUser {
  String slUserId;
  String username;
  String email;
  String? imageUrl;
  String? fbUserId;
  String? fcmToken;
  String? pin;
  bool? biometrics;

  SlUser({
    required this.slUserId,
    required this.username,
    required this.email,
    this.fcmToken,
    this.imageUrl,
    this.fbUserId,
    this.pin,
    this.biometrics,
  });

  factory SlUser.fromFireStore({required DocumentSnapshot doc}) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SlUser(
      slUserId: data["slUserId"],
      username: data["username"],
      email: data["email"] ?? "N/A",
      imageUrl: data["imageUrl"] ?? "N/A",
      fbUserId: data["fbUserId"] ?? "N/A",
      fcmToken: data["fcmToken"],
      pin: data["pin"],
      biometrics: data["biometrics"],
    );
  }

  factory SlUser.fromJson({required Map json}) {
    return SlUser(
      slUserId: json["slUserId"],
      fbUserId: json["fbUserId"],
      fcmToken: json["fcmToken"],
      username: json["username"],
      email: json["email"],
      imageUrl: json["imageUrl"],
      pin: json["pin"],
      biometrics: json["biometrics"],
    );
  }

  Map toJson() {
    return {
      "slUserId": slUserId,
      "username": username,
      "email": email,
      "imageUrl": imageUrl,
      "fbUserId": fbUserId,
      "fcmToken": fcmToken,
      "biometrics": biometrics,
      "pin": pin,
    };
  }

  static Future<SlUser?> getUserFromDocRef(
      {required DocumentReference doc}) async {
    return await DatabaseManager().getSlUserFromDoc(doc: doc);
  }

  Future<List<Event>?> getEvents() async {
    return await DatabaseManager()
        .getEvents(userId: GlobalData().currentUser!.fbUserId!);
  }

  Stream<QuerySnapshot> emergencyContactsStream() {
    return DatabaseManager()
        .emergencyContactsSnapshot(userId: GlobalData().currentUser!.fbUserId!);
  }

  Stream<QuerySnapshot> requestedContactsStream() {
    return DatabaseManager()
        .requestedContactsSnapshot(userId: GlobalData().currentUser!.fbUserId!);
  }

  Stream<QuerySnapshot> getEventsStream() {
    return DatabaseManager()
        .eventsSnapshot(userId: GlobalData().currentUser!.fbUserId!);
  }

  Stream<QuerySnapshot> listRequestStream() {
    return DatabaseManager()
        .listRequestsSnapshot(userId: GlobalData().currentUser!.fbUserId!);
  }

  Stream<QuerySnapshot> listedOnStream() {
    return DatabaseManager()
        .listedOnSnapshot(userId: GlobalData().currentUser!.fbUserId!);
  }
}
