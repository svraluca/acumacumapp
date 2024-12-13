import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<void> storeNotification(String userId, String message) async {
  await FirebaseFirestore.instance.collection('notifications').add({
    'userId': userId,
    'message': message,
    'timestamp': FieldValue.serverTimestamp(),
    'read': false,
  });

  await FirebaseFirestore.instance
      .collection('Users')
      .doc(userId)
      .update({
    'unreadNotifications': FieldValue.increment(1),
  });
}

void displayNotification(String userId, String message) {
  // Store the notification in Firestore
  storeNotification(userId, message);
}

Future<void> incrementUnreadNotifications(String userId) async {
  await FirebaseFirestore.instance
      .collection('Users')
      .doc(userId)
      .update({
    'unreadNotifications': FieldValue.increment(1),
  });
}

class NotificationScreen extends StatefulWidget {
  final String userId;

  const NotificationScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const Color mcdonaldsRed = Color(0xFFDA291C);

  @override
  void initState() {
    super.initState();
    // Create unreadNotifications field if it doesn't exist and mark notifications as read
    FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.userId)
        .set({
      'unreadNotifications': 0,
    }, SetOptions(merge: true));

    // Reset unreadNotifications when viewing notifications
    FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.userId)
        .update({
      'unreadNotifications': 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'My Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: mcdonaldsRed,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No notifications'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final List<Widget> notifications = [];

          // Check subscription
          if (userData['subscription'] != null) {
            notifications.add(_buildSubscriptionNotification(userData['subscription']));
            notifications.add(const Divider(height: 1, thickness: 0.5));
          }

          // Check homepage promotions
          if (userData['homepage_promotions'] != null) {
            final homepagePromos = userData['homepage_promotions'] as List<dynamic>;
            for (var promo in homepagePromos) {
              notifications.add(_buildPromotionNotification(promo, 'Homepage'));
              notifications.add(const Divider(height: 1, thickness: 0.5));
            }
          }

          // Check category promotions
          if (userData['category_promotions'] != null) {
            final categoryPromos = userData['category_promotions'] as List<dynamic>;
            for (var promo in categoryPromos) {
              notifications.add(_buildPromotionNotification(promo, 'Category'));
              if (promo != categoryPromos.last) {
                notifications.add(const Divider(height: 1, thickness: 0.5));
              }
            }
          }

          if (notifications.isEmpty) {
            return const Center(child: Text('No active subscriptions or promotions'));
          }

          return ListView(
            children: notifications,
          );
        },
      ),
    );
  }

  Widget _buildSubscriptionNotification(Map<String, dynamic> subscription) {
    final startDate = (subscription['startDate'] as Timestamp).toDate();
    final endDate = (subscription['endDate'] as Timestamp).toDate();
    final duration = endDate.difference(startDate).inDays;
    String durationText;
    
    if (duration == 365) {
      durationText = '1 year';
    } else {
      durationText = '$duration days';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: mcdonaldsRed,
            child: const Icon(Icons.card_membership, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscription Purchase',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: mcdonaldsRed,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You purchased a ${subscription['planType']} subscription for $durationText',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Valid until: ${DateFormat('MMM d, y').format(endDate)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionNotification(Map<dynamic, dynamic> promotion, String type) {
    final startDate = (promotion['startDate'] as Timestamp).toDate();
    final endDate = (promotion['endDate'] as Timestamp).toDate();
    final duration = endDate.difference(startDate).inDays;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: mcdonaldsRed,
            child: const Icon(Icons.local_offer, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$type Promotion Purchase',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: mcdonaldsRed,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You purchased a $type promotion for $duration days',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Valid until: ${DateFormat('MMM d, y').format(endDate)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
