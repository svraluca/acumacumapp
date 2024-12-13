import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingCard extends StatelessWidget {
  final String bookingId;
  final String currentUserId;
  final String peerId;

  const BookingCard({
    super.key,
    required this.bookingId,
    required this.currentUserId,
    required this.peerId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').doc(bookingId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        var bookingData = snapshot.data!.data() as Map<String, dynamic>;
        DateTime appointmentDateTime = (bookingData['appointmentDateTime'] as Timestamp).toDate();

        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Booking Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Service: ${bookingData['serviceName']}'),
                Text('Price: \$${bookingData['servicePrice']}'),
                Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(appointmentDateTime)}'),
                Text('Status: ${bookingData['status']}'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (bookingData['customerId'] == currentUserId && bookingData['status'] == 'pending')
                      ElevatedButton(
                        onPressed: () => _withdrawBooking(context),
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
                        ),
                        child: const Text('Withdraw'),
                      ),
                    if (bookingData['serviceProviderId'] == currentUserId && bookingData['status'] == 'pending')
                      ...[
                        ElevatedButton(
                          onPressed: () => _updateBookingStatus(context, 'accepted'),
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all<Color>(Colors.green),
                          ),
                          child: const Text('Accept'),
                        ),
                        ElevatedButton(
                          onPressed: () => _updateBookingStatus(context, 'declined'),
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
                          ),
                          child: const Text('Decline'),
                        ),
                      ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _withdrawBooking(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
        'status': 'withdrawn',
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking withdrawn successfully')));
    } catch (e) {
      print('Error withdrawing booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to withdraw booking')));
    }
  }

  void _updateBookingStatus(BuildContext context, String status) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
        'status': status,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking $status successfully')));
    } catch (e) {
      print('Error updating booking status: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update booking status')));
    }
  }
}