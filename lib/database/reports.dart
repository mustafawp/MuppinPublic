import 'package:cloud_firestore/cloud_firestore.dart';

// ignore: camel_case_types
class reports {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('Reports');

  Future<bool> addReport(Map<String, dynamic> fields) async {
    try {
      String newDocumentId = usersCollection.doc().id;
      await usersCollection.doc(newDocumentId).set({
        'documentId': newDocumentId,
        ...fields,
      });
      return true;
    } catch (error) {
      // ignore: avoid_print
      print('Hata: $error');
      return false;
    }
  }

  Future<bool> deleteReport(String documentId) async {
    try {
      await usersCollection.doc(documentId).delete();
      return true;
    } catch (error) {
      // ignore: avoid_print
      print('Hata: $error');
      return false;
    }
  }
}
