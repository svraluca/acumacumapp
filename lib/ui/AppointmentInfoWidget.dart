import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AppointmentInfo {
  final String appointmentId;
  final String serviceName;
  final String servicePrice;
  final DateTime appointmentDateTime;

  AppointmentInfo({
    required this.appointmentId,
    required this.serviceName,
    required this.servicePrice,
    required this.appointmentDateTime,
  });
}

class AppointmentInfoWidget extends StatelessWidget {
  final AppointmentInfo appointmentInfo;
  final String currentUserId;
  final String peerId;

  const AppointmentInfoWidget({super.key, 
    required this.appointmentInfo,
    required this.currentUserId,
    required this.peerId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Appointment Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Service: ${appointmentInfo.serviceName}'),
            Text('Price: \$${appointmentInfo.servicePrice}'),
            Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(appointmentInfo.appointmentDateTime)}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _updateAppointmentStatus(context, 'accepted'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Accept'),
                ),
                ElevatedButton(
                  onPressed: () => _updateAppointmentStatus(context, 'declined'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Decline'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateAppointmentStatus(BuildContext context, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentInfo.appointmentId)
          .update({'status': status});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment ${status.capitalize()}')),
      );
    } catch (e) {
      print('Error updating appointment status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update appointment status. Please try again.')),
      );
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}