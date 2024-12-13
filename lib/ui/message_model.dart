import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String message;
  final Timestamp time;
  final bool unread;
  final String senderId;
  final bool isBookingOffer;

  Message({
    required this.message,
    required this.time,
    required this.unread,
    required this.senderId,
    this.isBookingOffer = false,
  });

  factory Message.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Message(
      message: data['message'] ?? '',
      time: data['time'] ?? Timestamp.now(),
      unread: data['unread'] ?? false,
      senderId: data['senderId'] ?? '',
      isBookingOffer: data['type'] == 'booking_offer',
    );
  }
}
