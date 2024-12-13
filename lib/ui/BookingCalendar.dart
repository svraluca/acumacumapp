import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingCalendar extends StatefulWidget {
  final String userId;
  final String serviceProviderId;

  const BookingCalendar({
    Key? key,
    required this.userId,
    required this.serviceProviderId,
  }) : super(key: key);

  @override
  _BookingCalendarState createState() => _BookingCalendarState();
}

class _BookingCalendarState extends State<BookingCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<TimeSlot>> _availableSlots = {};
  Map<DateTime, List<BookedSlot>> _bookedSlots = {};
  Map<DateTime, List<BookedSlot>> _serviceProviderBookedSlots = {};
  late String userId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid;
    _fetchAvailableSlots();
    _fetchBookedSlots();
    _fetchServiceProviderBookedSlots();
  }

  void _fetchAvailableSlots() async {
    setState(() {
      _isLoading = true;
    });

    final slotsSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('availableSlots')
        .get();

    setState(() {
      _availableSlots = {};
      for (var doc in slotsSnapshot.docs) {
        DateTime date = (doc['date'] as Timestamp).toDate();
        List<TimeSlot> slots = (doc['slots'] as List)
            .map((slot) => TimeSlot(
                  TimeOfDay.fromDateTime(
                      (slot['startTime'] as Timestamp).toDate()),
                  TimeOfDay.fromDateTime((slot['endTime'] as Timestamp).toDate()),
                ))
            .toList();
        _availableSlots[DateTime(date.year, date.month, date.day)] = slots;
      }
      _isLoading = false;
    });
  }

  void _fetchBookedSlots() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('=== FETCHING BOOKED SLOTS ===');
      print('User ID: $userId');
      
      // First, verify the user document exists
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();
      
      print('User document exists: ${userDoc.exists}');
      
      // Get all documents in the bookedSlots subcollection
      final QuerySnapshot bookedSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('bookedSlots')
          .get();

      print('Number of booked slots found: ${bookedSnapshot.docs.length}');
      print('Collection path: Users/${userId}/bookedSlots');

      // Print all documents
      for (var doc in bookedSnapshot.docs) {
        print('Document ID: ${doc.id}');
        print('Document data: ${doc.data()}');
      }

      Map<DateTime, List<BookedSlot>> newBookedSlots = {};

      for (var doc in bookedSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        DateTime date = (data['date'] as Timestamp).toDate();
        DateTime startTime = (data['startTime'] as Timestamp).toDate();
        DateTime endTime = (data['endTime'] as Timestamp).toDate();
        String description = data['description'] ?? '';

        final dateKey = DateTime(date.year, date.month, date.day);
        
        if (!newBookedSlots.containsKey(dateKey)) {
          newBookedSlots[dateKey] = [];
        }

        newBookedSlots[dateKey]!.add(
          BookedSlot(
            startTime: TimeOfDay.fromDateTime(startTime),
            endTime: TimeOfDay.fromDateTime(endTime),
            description: description,
          ),
        );
      }

      setState(() {
        _bookedSlots = newBookedSlots;
        _isLoading = false;
      });

      // Print final processed slots
      print('=== PROCESSED BOOKED SLOTS ===');
      _bookedSlots.forEach((date, slots) {
        print('Date: $date');
        for (var slot in slots) {
          print('Slot: ${slot.startTime.format(context)} - ${slot.endTime.format(context)}');
        }
      });

    } catch (e, stackTrace) {
      print('Error fetching booked slots: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchServiceProviderBookedSlots() async {
    try {
      print('=== FETCHING SERVICE PROVIDER BOOKED SLOTS ===');
      print('Service Provider ID: ${widget.serviceProviderId}');

      final QuerySnapshot bookedSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.serviceProviderId)
          .collection('bookedSlots')
          .get();

      print('Found ${bookedSnapshot.docs.length} booked slots for service provider');

      Map<DateTime, List<BookedSlot>> newBookedSlots = {};

      for (var doc in bookedSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        if (data['slots'] != null) {
          // Handle array of slots
          List<dynamic> slots = data['slots'] as List<dynamic>;
          DateTime date = (data['date'] as Timestamp).toDate();
          final dateKey = DateTime(date.year, date.month, date.day);

          for (var slot in slots) {
            DateTime startTime = (slot['startTime'] as Timestamp).toDate();
            DateTime endTime = (slot['endTime'] as Timestamp).toDate();

            if (!newBookedSlots.containsKey(dateKey)) {
              newBookedSlots[dateKey] = [];
            }

            newBookedSlots[dateKey]!.add(
              BookedSlot(
                startTime: TimeOfDay.fromDateTime(startTime),
                endTime: TimeOfDay.fromDateTime(endTime),
                description: slot['description'] ?? '',
              ),
            );
          }
        } else {
          // Handle single slot
          DateTime date = (data['date'] as Timestamp).toDate();
          DateTime startTime = (data['startTime'] as Timestamp).toDate();
          DateTime endTime = (data['endTime'] as Timestamp).toDate();
          
          final dateKey = DateTime(date.year, date.month, date.day);
          
          if (!newBookedSlots.containsKey(dateKey)) {
            newBookedSlots[dateKey] = [];
          }

          newBookedSlots[dateKey]!.add(
            BookedSlot(
              startTime: TimeOfDay.fromDateTime(startTime),
              endTime: TimeOfDay.fromDateTime(endTime),
              description: data['description'] ?? '',
            ),
          );
        }
      }

      setState(() {
        _serviceProviderBookedSlots = newBookedSlots;
      });

      print('=== SERVICE PROVIDER BOOKED SLOTS ===');
      _serviceProviderBookedSlots.forEach((date, slots) {
        print('Date: $date');
        for (var slot in slots) {
          print('Slot: ${slot.startTime.format(context)} - ${slot.endTime.format(context)}');
        }
      });

    } catch (e, stackTrace) {
      print('Error fetching service provider booked slots: $e');
      print('Stack trace: $stackTrace');
    }
  }

  bool _isSlotAvailable(DateTime date, TimeOfDay startTime, TimeOfDay endTime) {
    // Convert date and times to comparable format
    final dateKey = DateTime(date.year, date.month, date.day);
    
    // Check if the date has any booked slots
    if (_serviceProviderBookedSlots.containsKey(dateKey)) {
      // Get all booked slots for this date
      final bookedSlots = _serviceProviderBookedSlots[dateKey]!;
      
      // Convert times to minutes for easier comparison
      int startMinutes = startTime.hour * 60 + startTime.minute;
      int endMinutes = endTime.hour * 60 + endTime.minute;
      
      // Check each booked slot for overlap
      for (var bookedSlot in bookedSlots) {
        int bookedStartMinutes = bookedSlot.startTime.hour * 60 + bookedSlot.startTime.minute;
        int bookedEndMinutes = bookedSlot.endTime.hour * 60 + bookedSlot.endTime.minute;
        
        // Check for overlap
        if (!(endMinutes <= bookedStartMinutes || startMinutes >= bookedEndMinutes)) {
          return false; // Slot overlaps with a booked slot
        }
      }
    }
    
    return true; // No overlap found
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Calendar'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ElevatedButton(
              onPressed: _saveAllSlots,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E), // Dark blue background (Indigo 900)
                foregroundColor: Colors.white, // White text
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // Rounded borders
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 0, // No shadow
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2023, 1, 1),
                  lastDay: DateTime.utc(2024, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: _onDaySelected,
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _selectedDay == null
                      ? const Center(child: Text('Please select a day'))
                      : _buildTimeSlotsList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTimeSlotDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
      _focusedDay = focusedDay;
    });
  }

  Widget _buildTimeSlotsList() {
    List<TimeSlot> availableSlots = _availableSlots[_selectedDay!] ?? [];
    List<BookedSlot> bookedSlots = _bookedSlots[_selectedDay!] ?? [];

    return Column(
      children: [
        if (availableSlots.isNotEmpty) ...[
          const Text('Available Slots', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: availableSlots.length,
              itemBuilder: (context, index) {
                TimeSlot slot = availableSlots[index];
                return ListTile(
                  title: Text('${slot.startTime.format(context)} - ${slot.endTime.format(context)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.book),
                        onPressed: () => _showBookSlotDialog(slot),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeTimeSlot(slot),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
        if (bookedSlots.isNotEmpty) ...[
          const Text('Booked Slots', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: bookedSlots.length,
              itemBuilder: (context, index) {
                BookedSlot slot = bookedSlots[index];
                return ListTile(
                  title: Text('${slot.startTime.format(context)} - ${slot.endTime.format(context)}'),
                  subtitle: Text(slot.description),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeBookedSlot(slot),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  void _showAddTimeSlotDialog() {
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Add Time Schedule',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Start Time'),
                  TimeInputWidget(
                    initialTime: startTime,
                    onChanged: (time) => startTime = time,
                  ),
                  const SizedBox(height: 16),
                  const Text('End Time'),
                  TimeInputWidget(
                    initialTime: endTime,
                    onChanged: (time) => endTime = time,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        child: const Text('Add'),
                        onPressed: () {
                          _addTimeSlot(startTime, endTime);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _addTimeSlot(TimeOfDay startTime, TimeOfDay endTime) {
    if (_selectedDay == null) return;

    setState(() {
      _availableSlots.update(
        _selectedDay!,
        (value) => [...value, TimeSlot(startTime, endTime)],
        ifAbsent: () => [TimeSlot(startTime, endTime)],
      );
    });
  }

  void _removeTimeSlot(TimeSlot slot) {
    setState(() {
      _availableSlots[_selectedDay!]?.remove(slot);
    });
  }

  void _saveAllSlots() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('=== SAVING ALL SLOTS ===');
      print('User ID: $userId');

      for (var entry in _availableSlots.entries) {
        final date = entry.key;
        final slots = entry.value;

        print('Saving slots for date: $date');
        print('Number of slots: ${slots.length}');

        final docRef = FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .collection('bookedSlots')
            .doc(date.toIso8601String().split('T')[0]);

        if (slots.isEmpty) {
          print('No slots for this date, deleting document');
          await docRef.delete();
        } else {
          final slotsData = slots.map((slot) => {
            'startTime': Timestamp.fromDate(DateTime(
                date.year, date.month, date.day, slot.startTime.hour, slot.startTime.minute)),
            'endTime': Timestamp.fromDate(DateTime(
                date.year, date.month, date.day, slot.endTime.hour, slot.endTime.minute)),
            'date': Timestamp.fromDate(date),
            'status': 'booked',
            'userId': userId,
          }).toList();

          print('Saving slots data: $slotsData');
          
          await docRef.set({
            'date': Timestamp.fromDate(date),
            'slots': slotsData,
            'lastUpdated': FieldValue.serverTimestamp(),
          });

          print('Successfully saved slots for date: $date');
        }
      }

      // Verify the save by fetching slots
      _fetchBookedSlots();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All slots saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stackTrace) {
      print('Error saving slots: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving slots: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showBookSlotDialog(TimeSlot slot) {
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Book Time Slot'),
        content: TextField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'Booking Description',
            hintText: 'Enter booking details',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _bookTimeSlot(slot, descriptionController.text);
              Navigator.pop(context);
            },
            child: const Text('Book'),
          ),
        ],
      ),
    );
  }

  void _bookTimeSlot(TimeSlot slot, String description) async {
    if (_selectedDay == null) return;

    try {
      print('=== BOOKING NEW SLOT ===');
      print('User ID: $userId');
      print('Selected day: $_selectedDay');
      print('Start time: ${slot.startTime.format(context)}');
      print('End time: ${slot.endTime.format(context)}');
      print('Description: $description');

      final startDateTime = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        slot.startTime.hour,
        slot.startTime.minute,
      );

      final endDateTime = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        slot.endTime.hour,
        slot.endTime.minute,
      );

      final bookingData = {
        'date': Timestamp.fromDate(_selectedDay!),
        'startTime': Timestamp.fromDate(startDateTime),
        'endTime': Timestamp.fromDate(endDateTime),
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'booked',
        'userId': userId,
      };

      print('Booking data to save: $bookingData');

      final DocumentReference bookingRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('bookedSlots')
          .doc();

      print('Attempting to save at path: Users/${userId}/bookedSlots/${bookingRef.id}');

      await bookingRef.set(bookingData);

      print('Successfully saved booking with ID: ${bookingRef.id}');

      // Verify the save
      final savedDoc = await bookingRef.get();
      print('Verification - Document exists: ${savedDoc.exists}');
      if (savedDoc.exists) {
        print('Saved document data: ${savedDoc.data()}');
      }

      setState(() {
        if (!_bookedSlots.containsKey(_selectedDay!)) {
          _bookedSlots[_selectedDay!] = [];
        }
        _bookedSlots[_selectedDay!]!.add(
          BookedSlot(
            startTime: slot.startTime,
            endTime: slot.endTime,
            description: description,
          ),
        );
        _availableSlots[_selectedDay!]?.remove(slot);
      });

      _fetchBookedSlots();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Slot booked successfully'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e, stackTrace) {
      print('Error booking slot: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error booking slot: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeBookedSlot(BookedSlot slot) async {
    if (_selectedDay == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('bookedSlots')
          .where('date', isEqualTo: Timestamp.fromDate(_selectedDay!))
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      setState(() {
        _bookedSlots[_selectedDay!]?.remove(slot);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking removed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error removing booking')),
      );
    }
  }
}

class TimeSlot {
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  TimeSlot(this.startTime, this.endTime);
}

class TimeInputWidget extends StatefulWidget {
  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onChanged;

  const TimeInputWidget({super.key, required this.initialTime, required this.onChanged});

  @override
  _TimeInputWidgetState createState() => _TimeInputWidgetState();
}

class _TimeInputWidgetState extends State<TimeInputWidget> {
  late TextEditingController _hourController;
  late TextEditingController _minuteController;

  @override
  void initState() {
    super.initState();
    _hourController = TextEditingController(text: widget.initialTime.hour.toString().padLeft(2, '0'));
    _minuteController = TextEditingController(text: widget.initialTime.minute.toString().padLeft(2, '0'));
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _updateTime() {
    int hour = int.tryParse(_hourController.text) ?? 0;
    int minute = int.tryParse(_minuteController.text) ?? 0;
    widget.onChanged(TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59)));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 50,
          child: TextField(
            controller: _hourController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            onChanged: (value) => _updateTime(),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            ),
          ),
        ),
        const Text(' : ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(
          width: 50,
          child: TextField(
            controller: _minuteController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            onChanged: (value) => _updateTime(),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            ),
          ),
        ),
      ],
    );
  }
}

class BookedSlot extends TimeSlot {
  final String description;

  BookedSlot({
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required this.description,
  }) : super(startTime, endTime);
}
