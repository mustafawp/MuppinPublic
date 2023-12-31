import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ignore: camel_case_types
class followersDb {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('Followers');

  Future<int> getFieldCount(String documentId) async {
    try {
      DocumentSnapshot documentSnapshot =
          await usersCollection.doc(documentId).get();

      if (!documentSnapshot.exists) {
        return 0;
      }

      Map<String, dynamic>? data =
          documentSnapshot.data() as Map<String, dynamic>?;
      if (data != null) {
        return data.length;
      } else {
        return 0;
      }
    } catch (e) {
      if (kDebugMode) {
        print("FollowersDB | getFieldCount | Hata: $e");
      }
      return 0;
    }
  }

  Future<bool> deleteField(String otherUserId, String viewerId) async {
    try {
      // Dokümanı al
      DocumentSnapshot documentSnapshot =
          await usersCollection.doc(otherUserId).get();
      if (documentSnapshot.exists) {
        Map<String, dynamic>? data =
            documentSnapshot.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey(viewerId)) {
          Map<String, dynamic> updateData = {
            viewerId: FieldValue.delete(),
          };
          await usersCollection.doc(otherUserId).update(updateData);
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print("FollowersDb | deleteField | Hata: $e");
      }
      return false;
    }
  }

  Future<List<String>> getFollowersIds(String documentId) async {
    try {
      DocumentSnapshot documentSnapshot =
          await usersCollection.doc(documentId).get();

      if (documentSnapshot.exists) {
        Map<String, dynamic>? data =
            documentSnapshot.data() as Map<String, dynamic>?;

        if (data != null) {
          List<String> fieldNames = data.keys.toList();
          return fieldNames.take(100).toList();
        }
      }

      return <String>[];
    } catch (e) {
      print("FollowersDb | getFollowersIds | Hata: $e");
      return <String>[];
    }
  }

  Future<bool> containsField(String viewerDocId, String otherUserDocId) async {
    try {
      DocumentSnapshot viewerDocSnapshot =
          await usersCollection.doc(viewerDocId).get();

      if (!viewerDocSnapshot.exists) {
        return false;
      }

      Map<String, dynamic>? viewerData =
          viewerDocSnapshot.data() as Map<String, dynamic>?;
      if (viewerData != null) {
        return viewerData.containsKey(otherUserDocId);
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print("followRequests | containsField | Hata: $e");
      }
      return false;
    }
  }

  Future<bool> addFollower(String userDocId, String viewerId) async {
    try {
      DocumentSnapshot documentSnapshot =
          await usersCollection.doc(userDocId).get();

      if (documentSnapshot.exists) {
        await usersCollection.doc(userDocId).update({
          viewerId: FieldValue.serverTimestamp(),
        });
        return true;
      } else {
        Map<String, dynamic> data = {viewerId: FieldValue.serverTimestamp()};
        await usersCollection.doc(userDocId).set(data);
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print("FollowersDb | addFollower | Hata: $e");
      }
      return false;
    }
  }
}
