import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingCalendarWidget extends StatefulWidget {
  final String serviceProviderId;
  final String serviceName;
  final String servicePrice;

  const BookingCalendarWidget({super.key, 
    required this.serviceProviderId,
    required this.serviceName,
    required this.servicePrice,
  });

  @override
  _BookingCalendarWidgetState createState() => _BookingCalendarWidgetState();
}

class _BookingCalendarWidgetState extends State<BookingCalendarWidget> {
  late Future<Map<DateTime, List<TimeSlot>>> _availableSlotsFuture; // Future to hold the available slots

  @override
  void initState() {
    super.initState();
    _availableSlotsFuture = _fetchAvailableSlots(); // Initialize the future
  }

  Future<Map<DateTime, List<TimeSlot>>> _fetchAvailableSlots() async {
    Map<DateTime, List<TimeSlot>> slots = {};
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("Users")
          .doc(widget.serviceProviderId)
          .get();

      if (!userDoc.exists) {
        throw Exception("Service provider not found");
      }

      final snapshot = await FirebaseFirestore.instance
          .collection("Users")
          .doc(widget.serviceProviderId)
          .collection("availableSlots")
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = DateTime.parse(doc.id);
        final List<dynamic> slotsData = data['slots'] ?? [];

        print("Date: $date, Slots Data: $slotsData"); // Debug statement

        if (slotsData.isNotEmpty) {
          slots[date] = slotsData.map((slot) {
            final start = (slot['start'] as Timestamp).toDate();
            final end = (slot['end'] as Timestamp).toDate();
            return TimeSlot(
              start: start,
              end: end,
              serviceName: widget.serviceName,
              servicePrice: widget.servicePrice,
            );
          }).toList();
        }
      }
    } catch (e) {
      print("Error fetching available slots: $e");
      rethrow; // Rethrow the error to be caught by FutureBuilder
    }
    print("Fetched Slots: $slots"); // Debug statement
    return slots; // Return the fetched slots
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book ${widget.serviceName}'),
      ),
      body: FutureBuilder<Map<DateTime, List<TimeSlot>>>(
        future: _availableSlotsFuture, // Use the future created in initState
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Show loading indicator
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}')); // Show error message
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No available slots found.')); // No slots available
          }

          final availableSlots = snapshot.data!; // Get the available slots

          return Column(
            children: [
              // Your existing TableCalendar and slot display logic
              // For example, you can use availableSlots to populate the calendar
              TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: DateTime.now(),
                eventLoader: (day) {
                  return availableSlots[day] ?? []; // Load events for the calendar
                },
                // Add other necessary properties and callbacks
              ),
              // Additional UI for displaying available slots
              if (availableSlots.isNotEmpty) ...[
                for (var entry in availableSlots.entries)
                  Text('Date: ${entry.key}, Slots: ${entry.value.length}'), // Displaying the number of slots
              ],
            ],
          );
        },
      ),
    );
  }
}

class TimeSlot {
  final DateTime start;
  final DateTime end;
  final String serviceName;
  final String servicePrice;

  TimeSlot({
    required this.start,
    required this.end,
    required this.serviceName,
    required this.servicePrice,
  });
}