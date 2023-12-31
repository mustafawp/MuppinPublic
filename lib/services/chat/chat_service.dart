import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:muppin_app/models/message_model.dart';
import 'package:muppin_app/transactions/shareds.dart';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore fireStore = FirebaseFirestore.instance;

  Future<bool> sendMessage(String receiverDocId, String message) async {
    try {
      final String currentUserId = await Shareds.sharedCek("docId");
      final Timestamp timestamp = Timestamp.now();

      messageModel newMessage = messageModel(
          receiverDocId: receiverDocId,
          senderDocId: currentUserId,
          message: message,
          time: timestamp,
          seenState: false);

      List<String> ids = [currentUserId, receiverDocId];
      ids.sort();
      String chatRoomId = ids.join("_");

      await fireStore
          .collection("chat-rooms")
          .doc(chatRoomId)
          .collection("messages")
          .add(newMessage.toMap());

      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    return fireStore
        .collection("chat-rooms")
        .doc(chatRoomId)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .limit(600)
        .snapshots();
  }
}
