import 'package:cloud_firestore/cloud_firestore.dart';

class messageModel {
  final String receiverDocId;
  final String senderDocId;
  final String message;
  final Timestamp time;
  final bool seenState;

  messageModel(
      {required this.receiverDocId,
      required this.senderDocId,
      required this.message,
      required this.time,
      required this.seenState});

  Map<String, dynamic> toMap() {
    return {
      "receiverId": receiverDocId,
      "senderId": senderDocId,
      "message": message,
      "time": time,
      "seenState": seenState
    };
  }
}
