import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ChatScreen.dart'; // Add this import

class BookingDialog extends StatefulWidget {
  final String serviceName;
  final String servicePrice;
  final String serviceProviderId;
  final String userName;
  final String avatarUrl;

  const BookingDialog({
    super.key,
    required this.serviceName,
    required this.servicePrice,
    required this.serviceProviderId,
    required this.userName,
    required this.avatarUrl,
  });

  @override
  _BookingDialogState createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Book ${widget.serviceName}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('Price: \$${widget.servicePrice}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _selectDate(context),
                child: Text(_selectedDate == null
                    ? 'Select Date'
                    : 'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _selectTime(context),
                child: Text(_selectedTime == null
                    ? 'Select Time'
                    : 'Time: ${_selectedTime!.format(context)}'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _selectedDate != null && _selectedTime != null
                    ? () => _confirmBooking()
                    : null,
                child: const Text('Confirm Booking'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _confirmBooking() async {
    if (_selectedDate == null || _selectedTime == null) return;

    final DateTime appointmentDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    try {
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      DocumentReference bookingRef = await FirebaseFirestore.instance.collection('bookings').add({
        'serviceProviderId': widget.serviceProviderId,
        'customerId': currentUserId,
        'serviceName': widget.serviceName,
        'servicePrice': widget.servicePrice,
        'appointmentDateTime': Timestamp.fromDate(appointmentDateTime),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create a message with the booking details
      await FirebaseFirestore.instance.collection('messages').add({
        'senderId': currentUserId,
        'receiverId': widget.serviceProviderId,
        'type': 'booking',
        'bookingId': bookingRef.id,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop(); // Close the booking dialog
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            serviceProviderId: widget.serviceProviderId,
            userName: widget.userName,
            avatarUrl: widget.avatarUrl,
            price: 'N/A',
          ),
        ),
      );
    } catch (e) {
      print('Error creating booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create booking. Please try again.')),
      );
    }
  }
}