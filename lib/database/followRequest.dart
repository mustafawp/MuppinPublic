// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ignore: camel_case_types
class followRequestsDb {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('FollowRequests');

  Future<dynamic> getFieldName(String documentId, String type) async {
    try {
      if (type == "A") {
        DocumentSnapshot documentSnapshot =
            await usersCollection.doc(documentId).get();

        if (!documentSnapshot.exists) {
          return <String>[];
        }

        Map<String, dynamic>? documentData =
            documentSnapshot.data() as Map<String, dynamic>?;
        if (documentData != null) {
          List<String> fieldNames = documentData.keys.toList();
          return fieldNames;
        }

        return <String>[];
      } else {
        DocumentSnapshot documentSnapshot =
            await usersCollection.doc(documentId).get();

        if (!documentSnapshot.exists) {
          return {};
        }

        Map<String, dynamic>? documentData =
            documentSnapshot.data() as Map<String, dynamic>?;
        if (documentData != null) {
          return documentData;
        }

        return {};
      }
    } catch (e) {
      if (kDebugMode) {
        print("FollowRequestDb | getFieldData | Hata: $e");
      }
      return {};
    }
  }

  Future<bool> createOrUpdateDocument(String userDocId, String viewerId) async {
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
        print("FollowRequestDb | createOrUpdateDocument | Hata: $e");
      }
      return false;
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
        print("FollowRequests | deleteField | Hata: $e");
      }
      return false;
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
        print("followRequests | getFieldCount | Hata: $e");
      }
      return 0;
    }
  }
}
