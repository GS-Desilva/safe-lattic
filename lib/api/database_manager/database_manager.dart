import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safelattice/api/notification_manager/notification_manager.dart';
import 'package:safelattice/data/models/event.dart';
import 'package:safelattice/data/models/user.dart';
import 'package:safelattice/data/utils/global_data.dart';
import 'package:safelattice/presentation/utils/sl_alerts.dart';
import 'package:uuid/uuid.dart';

class DatabaseManager {
  static final _instance = DatabaseManager.internal();
  final _db = FirebaseFirestore.instance;

  factory DatabaseManager() => _instance;

  DatabaseManager.internal();

  Future<void> createUser({required String userId}) async {
    var uuidString = const Uuid().v4();
    var uuidMod = uuidString.replaceAll(RegExp(r'[a-zA-Z\W-]'), "");
    var uuidInt = BigInt.parse(uuidMod) % BigInt.parse("10000000000");

    GlobalData().currentUser?.slUserId = uuidInt.toString();

    await _db.collection("users").doc(userId).set({
      "slUserId": uuidInt.toString(),
      "username": GlobalData().currentUser?.username,
      "imageUrl": GlobalData().currentUser?.imageUrl,
      "fcmToken": await NotificationManager().getFcmToken(),
      "biometrics": false,
      "pin": null,
    }).onError((e, _) {
      GlobalData().currentUser?.slUserId = "";
      SlAlert().showMessageDialog(
          context: GlobalData().navigatorKey.currentContext!,
          title: "Unexpected Error",
          message: e.toString());
    });
  }

  Future<dynamic> getPropertyForUserId({
    required String userId,
    required String property,
  }) async {
    return await _db.collection("users").doc(userId).get().then((snapshot) {
      return snapshot.data()?[property];
    }).onError(
      (error, stackTrace) {
        SlAlert().showMessageDialog(
          context: GlobalData().navigatorKey.currentContext!,
          title: "Unexpected Error",
          message: error.toString(),
        );
      },
    );
  }

  Future<List<Event>?> getEvents({
    required String userId,
  }) async {
    return await _db
        .collection("users")
        .doc(userId)
        .collection("events")
        .orderBy("datetime", descending: true)
        .get()
        .then(
      (snapshot) async {
        if (snapshot.size != 0) {
          List<Event> events = [];
          for (var doc in snapshot.docs) {
            Event? event = await Event.fromFireStore(doc: doc);

            if (event != null) events.add(event);
          }
          return events;
        } else {
          return null;
        }
      },
    ).onError((error, stackTrace) {
      SlAlert().showMessageDialog(
          context: GlobalData().navigatorKey.currentContext!,
          title: "Unexpected Error",
          message: error.toString());
    });
  }

  Future<SlUser?> getUserFromId({
    required String slUserId,
  }) async {
    SlAlert()
        .showLoadingDialog(context: GlobalData().navigatorKey.currentContext!);

    return await _db
        .collection("users")
        .where("slUserId", isEqualTo: slUserId)
        .get()
        .then(
      (snapshot) {
        SlAlert().hideLoadingDialog(
            context: GlobalData().navigatorKey.currentContext!);

        if (snapshot.size != 0) {
          QueryDocumentSnapshot<Map<String, dynamic>> doc = snapshot.docs.first;

          return SlUser.fromFireStore(doc: doc);
        } else {
          return null;
        }
      },
    ).onError((error, stackTrace) {
      SlAlert().hideLoadingDialog(
          context: GlobalData().navigatorKey.currentContext!);

      SlAlert().showMessageDialog(
          context: GlobalData().navigatorKey.currentContext!,
          title: "Unexpected Error",
          message: error.toString());
    });
  }

  Future<SlUser?> getSlUserFromDoc({
    required DocumentReference doc,
  }) async {
    return await doc.get().then((snapshot) {
      return SlUser.fromFireStore(doc: snapshot);
    }).catchError(
      (error, stackTrace) {
        SlAlert().showMessageDialog(
          context: GlobalData().navigatorKey.currentContext!,
          title: "Unexpected Error",
          message: error.toString(),
        );
      },
    );
  }

  Future<SlUser?> sendRequest({
    required SlUser user,
  }) async {
    SlAlert()
        .showLoadingDialog(context: GlobalData().navigatorKey.currentContext!);

    WriteBatch batch = _db.batch();
    SlUser currentUser = GlobalData().currentUser!;

    DocumentReference? requestedDoc = _db
        .collection("users")
        .doc(currentUser.fbUserId)
        .collection("requested")
        .doc(user.slUserId);

    DocumentReference? requestDoc;

    await _db
        .collection("users")
        .where("slUserId", isEqualTo: user.slUserId)
        .get()
        .then(
      (snapshot) {
        SlAlert().hideLoadingDialog(
            context: GlobalData().navigatorKey.currentContext!);

        if (snapshot.size != 0) {
          requestDoc = snapshot.docs.first.reference
              .collection("requests")
              .doc(currentUser.slUserId);

          batch.set(requestedDoc, {"user": snapshot.docs.first.reference});

          batch.set(requestDoc!,
              {"user": _db.collection("users").doc(currentUser.fbUserId)});
        }
      },
    ).onError(
      (error, stackTrace) {
        SlAlert().hideLoadingDialog(
            context: GlobalData().navigatorKey.currentContext!);

        SlAlert().showMessageDialog(
            context: GlobalData().navigatorKey.currentContext!,
            title: "Unexpected Error",
            message: error.toString());
      },
    );

    if (requestedDoc != null && requestDoc != null) {
      return await batch.commit().then((value) {
        SlAlert().hideLoadingDialog(
            context: GlobalData().navigatorKey.currentContext!);
        return user;
      }).catchError((error) {
        SlAlert().hideLoadingDialog(
            context: GlobalData().navigatorKey.currentContext!);

        SlAlert().showMessageDialog(
            context: GlobalData().navigatorKey.currentContext!,
            title: "Unexpected Error",
            message: error.toString());
      });
    } else {
      return null;
    }
  }

  Future<bool?> respondRequest({
    required String userID,
    required bool acceptRequest,
  }) async {
    SlAlert()
        .showLoadingDialog(context: GlobalData().navigatorKey.currentContext!);

    WriteBatch batch = _db.batch();
    SlUser currentUser = GlobalData().currentUser!;

    DocumentReference? requestDoc = _db
        .collection("users")
        .doc(currentUser.fbUserId)
        .collection("requests")
        .doc(userID);

    DocumentReference? requestedDoc;
    DocumentReference? contactDoc;

    await _db
        .collection("users")
        .where("slUserId", isEqualTo: userID)
        .get()
        .then(
      (snapshot) {
        if (snapshot.size != 0) {
          contactDoc = snapshot.docs.first.reference
              .collection("emergencyContacts")
              .doc(currentUser.slUserId);

          requestedDoc = snapshot.docs.first.reference
              .collection("requested")
              .doc(currentUser.slUserId);

          if (requestedDoc != null &&
              requestDoc != null &&
              contactDoc != null) {
            batch.delete(requestedDoc!);
            batch.delete(requestDoc);
            if (acceptRequest) {
              DocumentReference listedDoc = _db
                  .collection("users")
                  .doc(currentUser.fbUserId)
                  .collection("listedOn")
                  .doc(userID);

              batch.set(listedDoc, {"user": snapshot.docs.first.reference});
              batch.set(contactDoc!,
                  {"user": _db.collection("users").doc(currentUser.fbUserId)});
            }
          } else {
            return null;
          }
        }
      },
    ).onError((error, stackTrace) {
      SlAlert().hideLoadingDialog(
          context: GlobalData().navigatorKey.currentContext!);

      SlAlert().showMessageDialog(
          context: GlobalData().navigatorKey.currentContext!,
          title: "Unexpected Error",
          message: error.toString());
      return;
    });

    if (requestedDoc != null && requestDoc != null && contactDoc != null) {
      return await batch.commit().then((value) {
        SlAlert().hideLoadingDialog(
            context: GlobalData().navigatorKey.currentContext!);
        return true;
      }).catchError((error) {
        SlAlert().hideLoadingDialog(
            context: GlobalData().navigatorKey.currentContext!);

        SlAlert().showMessageDialog(
            context: GlobalData().navigatorKey.currentContext!,
            title: "Unexpected Error",
            message: error.toString());
      });
    }
  }

  Future<bool?> deleteContact({
    bool? contactPending,
    required String userID,
    required bool deleteFromListed,
  }) async {
    SlAlert()
        .showLoadingDialog(context: GlobalData().navigatorKey.currentContext!);

    WriteBatch batch = _db.batch();
    SlUser currentUser = GlobalData().currentUser!;

    if (deleteFromListed) {
      await _db
          .collection("users")
          .where("slUserId", isEqualTo: userID)
          .get()
          .then(
        (snapshot) {
          if (snapshot.size != 0) {
            DocumentReference emergencyContactDoc = snapshot
                .docs.first.reference
                .collection("emergencyContacts")
                .doc(currentUser.slUserId);

            DocumentReference listedOnDoc = _db
                .collection("users")
                .doc(currentUser.fbUserId)
                .collection("listedOn")
                .doc(userID);

            batch.delete(listedOnDoc);
            batch.delete(emergencyContactDoc);
          }
        },
      ).onError(
        (error, stackTrace) {
          SlAlert().hideLoadingDialog(
              context: GlobalData().navigatorKey.currentContext!);

          SlAlert().showMessageDialog(
              context: GlobalData().navigatorKey.currentContext!,
              title: "Unexpected Error",
              message: error.toString());
          return;
        },
      );
    } else {
      await _db
          .collection("users")
          .where("slUserId", isEqualTo: userID)
          .get()
          .then(
        (snapshot) {
          if (snapshot.size != 0) {
            if (contactPending ?? false) {
              DocumentReference requestsDoc = snapshot.docs.first.reference
                  .collection("requests")
                  .doc(currentUser.slUserId);

              DocumentReference requestedDoc = _db
                  .collection("users")
                  .doc(currentUser.fbUserId)
                  .collection("requested")
                  .doc(userID);

              batch.delete(requestsDoc);
              batch.delete(requestedDoc);
            } else {
              DocumentReference listedOnDoc = snapshot.docs.first.reference
                  .collection("listedOn")
                  .doc(currentUser.slUserId);

              DocumentReference emergencyContactDoc = _db
                  .collection("users")
                  .doc(currentUser.fbUserId)
                  .collection("emergencyContacts")
                  .doc(userID);

              batch.delete(listedOnDoc);
              batch.delete(emergencyContactDoc);
            }
          }
        },
      ).onError(
        (error, stackTrace) {
          SlAlert().hideLoadingDialog(
              context: GlobalData().navigatorKey.currentContext!);

          SlAlert().showMessageDialog(
              context: GlobalData().navigatorKey.currentContext!,
              title: "Unexpected Error",
              message: error.toString());
          return;
        },
      );
    }

    return await batch.commit().then((value) {
      SlAlert().hideLoadingDialog(
          context: GlobalData().navigatorKey.currentContext!);
      return true;
    }).catchError((error) {
      SlAlert().hideLoadingDialog(
          context: GlobalData().navigatorKey.currentContext!);

      SlAlert().showMessageDialog(
          context: GlobalData().navigatorKey.currentContext!,
          title: "Unexpected Error",
          message: error.toString());
    });
  }

  Future<bool> updateUsername(
      {required String fbId, required String newUsername}) async {
    bool success = false;

    SlAlert().showLoadingDialog(
        context: GlobalData().navigatorKey.currentContext!, dismissible: false);

    await _db
        .collection("users")
        .doc(fbId)
        .update({"username": newUsername}).then((value) {
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

  Future<bool> updateFcmToken({
    required String fbId,
    required String newToken,
  }) async {
    bool success = false;

    await _db
        .collection("users")
        .doc(fbId)
        .update({"fcmToken": newToken}).then((value) {
      success = true;
    }).onError((error, stackTrace) {
      SlAlert().showMessageDialog(
          context: GlobalData().navigatorKey.currentContext!,
          title: "Unexpected Error",
          message: error.toString());
    });

    return success;
  }

  Future<bool> updateImageUrl(
      {required String fbId, required String imageUrl}) async {
    bool success = false;

    SlAlert().showLoadingDialog(
        context: GlobalData().navigatorKey.currentContext!, dismissible: false);

    await _db
        .collection("users")
        .doc(fbId)
        .update({"imageUrl": imageUrl}).then((value) {
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

  Future<bool> updateBiometric({
    required String fbId,
    required bool status,
  }) async {
    bool success = false;

    SlAlert().showLoadingDialog(
        context: GlobalData().navigatorKey.currentContext!, dismissible: false);

    await _db
        .collection("users")
        .doc(fbId)
        .update({"biometrics": status}).then((value) {
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

  Future<bool> updatePin({
    required String fbId,
    required String? pin,
  }) async {
    bool success = false;

    SlAlert().showLoadingDialog(
        context: GlobalData().navigatorKey.currentContext!, dismissible: false);

    await _db.collection("users").doc(fbId).update({"pin": pin}).then((value) {
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

  Future<bool> createEvent(
      {required List<SlUser> users, required Event event}) async {
    SlAlert()
        .showLoadingDialog(context: GlobalData().navigatorKey.currentContext!);

    WriteBatch batch = _db.batch();

    for (SlUser contact in users) {
      await _db
          .collection("users")
          .where("slUserId", isEqualTo: contact.slUserId)
          .get()
          .then(
        (snapshot) {
          if (snapshot.size != 0) {
            DocumentReference eventDoc = snapshot.docs.first.reference
                .collection("events")
                .doc(event.eventId);

            batch.set(eventDoc, {
              "eventId": event.eventId,
              "latitude": event.latitude,
              "longitude": event.longitude,
              "datetime": event.dateTime.toString(),
              "initiatedUser":
                  _db.collection("users").doc(event.initiatedUser.fbUserId!),
            });
          }
        },
      ).onError(
        (error, stackTrace) {
          SlAlert().hideLoadingDialog(
              context: GlobalData().navigatorKey.currentContext!);

          SlAlert().showMessageDialog(
              context: GlobalData().navigatorKey.currentContext!,
              title: "Unexpected Error",
              message: error.toString());
          return;
        },
      );
    }

    return await batch.commit().then((value) {
      SlAlert().hideLoadingDialog(
          context: GlobalData().navigatorKey.currentContext!);
      return true;
    }).catchError((error) {
      SlAlert().hideLoadingDialog(
          context: GlobalData().navigatorKey.currentContext!);

      SlAlert().showMessageDialog(
          context: GlobalData().navigatorKey.currentContext!,
          title: "Unexpected Error",
          message: error.toString());
    });
  }

  Stream<QuerySnapshot> emergencyContactsSnapshot({
    required String userId,
  }) {
    return _db
        .collection("users")
        .doc(userId)
        .collection("emergencyContacts")
        .snapshots();
  }

  Stream<QuerySnapshot> requestedContactsSnapshot({
    required String userId,
  }) {
    return _db
        .collection("users")
        .doc(userId)
        .collection("requested")
        .snapshots();
  }

  Stream<QuerySnapshot> eventsSnapshot({
    required String userId,
  }) {
    return _db
        .collection("users")
        .doc(userId)
        .collection("events")
        .orderBy("datetime", descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> listedOnSnapshot({
    required String userId,
  }) {
    return _db
        .collection("users")
        .doc(userId)
        .collection("listedOn")
        .snapshots();
  }

  Stream<QuerySnapshot> listRequestsSnapshot({
    required String userId,
  }) {
    return _db
        .collection("users")
        .doc(userId)
        .collection("requests")
        .snapshots();
  }

  Future<List<String>> getFcmTokensForUsers({
    required List<SlUser> users,
  }) async {
    List<String> tokens = [];
    List<String?> userIds = users.map((user) => user.slUserId).toList();

    await _db
        .collection("users")
        .where("slUserId", whereIn: userIds)
        .get()
        .then(
      (snapshot) {
        if (snapshot.size != 0) {
          for (QueryDocumentSnapshot<Map<String, dynamic>> doc
              in snapshot.docs) {
            tokens.add(doc.data()["fcmToken"]);
          }
        }
      },
    ).onError((error, stackTrace) {
      SlAlert().showMessageDialog(
          context: GlobalData().navigatorKey.currentContext!,
          title: "Unexpected Error",
          message: error.toString());
    });

    return tokens;
  }
}
