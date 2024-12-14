import 'dart:developer';
import 'dart:io';

import 'package:acumacum/notifications_setup/push_notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:acumacum/ui/HomePage.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:rxdart/rxdart.dart';

import 'dart:async' show unawaited;
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  final String serviceProviderId;
  final String avatarUrl;
  final String userName;
  final String price;
  final String? serviceName;
  final String? initialBookingDateTime;
  final bool isServiceMessage;
  final String? serviceId;
  final String? photoUrl;
  final String? description;
  final bool showConfirmation;
  final bool directBooking;

  const ChatScreen({
    super.key,
    required this.serviceProviderId,
    required this.userName,
    required this.avatarUrl,
    required this.price,
    this.serviceId,
    this.serviceName,
    this.initialBookingDateTime,
    this.isServiceMessage = false,
    this.photoUrl,
    this.description,
    this.showConfirmation = false,
    this.directBooking = false,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? currentUserId;
  String? currentName;
  bool isOffer = false;
  bool isOfferCreated = false;

  String? onlineStatus;
  Message? eachMessage;

  String userAvatar = 'https://toppng.com/uploads/preview/roger-berry-avatar-placeholder-11562991561rbrfzlng6h.png';

  String serviceName = 'Service Not Found';
  String description = 'Not description yet';

  CollectionReference messageColl = FirebaseFirestore.instance.collection('ChatRoom');

  TextEditingController messageController = TextEditingController();
  TextEditingController offerController = TextEditingController();

  DateTime? selectedDate;
  String? selectedTime;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedService;
  List<String> _services = []; // Will store the user's services

  TextEditingController dateController = TextEditingController();
  TextEditingController timeController = TextEditingController();

  // Add these getters
  bool get isServiceProvider => currentUserId == widget.serviceProviderId;

  bool get isClient => currentUserId != widget.serviceProviderId;

  bool get isPending => true; // You might want to modify this based on your logic

  bool get isRescheduled => false; // You might want to modify this based on your logic

  // Add ScrollController
  final ScrollController _scrollController = ScrollController();

  // Add this variable to track message count
  int _previousMessageCount = 0;

  // Add this variable at the top of your class
  final bool _isStatusUpdating = false;

  @override
  void initState() {
    super.initState();
    log('ChatScreen initialized with:');
    log('Current User ID: ${FirebaseAuth.instance.currentUser?.uid}');
    log('Service Provider ID: ${widget.serviceProviderId}');

    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    currentName = FirebaseAuth.instance.currentUser!.displayName ?? 'User';

    // Add keyboard visibility listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleKeyboardVisibility();
    });

    _getUserAvatar();
    description = widget.description ?? 'No description yet';
    fetchUserServices();
    markMessagesAsRead();

    // Add this to scroll to bottom after initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Update FCM token when chat screen opens
    updateFCMToken();
  }

  Future<void> updateFCMToken() async {
    PushNotificationService pushNotificationService = PushNotificationService();
    final token = await pushNotificationService.getAndroidToken();
    if (token != null && currentUserId != null) {
      await FirebaseFirestore.instance.collection('Users').doc(currentUserId).update({
        'fcmToken': token,
      });
      log('FCM Token updated: $token');
    }
  }

  // Update the sendMessage method to include FCM notification
  void sendMessage() {
    final messageText = messageController.text.trim();
    if (messageText.isEmpty) return;

    messageController.clear();

    Future(() async {
      try {
        final chatRoomId = getChatRoomId();
        final messageDoc = messageColl.doc(chatRoomId).collection("chats").doc();

        // Send the message
        await messageDoc.set({
          'sender': currentUserId,
          'time': DateTime.now(),
          'type': 'text',
          'message': messageText,
          'unread': true,
        });

        // Get recipient's FCM token
        final recipientDoc = await FirebaseFirestore.instance.collection('Users').doc(widget.serviceProviderId).get();

        final recipientToken = recipientDoc.data()?['fcmToken'];

        if (recipientToken != null) {
          // Send FCM notification using Cloud Functions
          await FirebaseFirestore.instance.collection('notifications').add({
            'token': recipientToken,
            'title': currentName ?? 'New Message',
            'body': messageText,
            'data': {
              'chatRoomId': chatRoomId,
              'type': 'chat_message',
              'senderId': currentUserId,
            },
            'timestamp': FieldValue.serverTimestamp(),
          });
        }

        // Update chat room metadata
        await messageColl.doc(chatRoomId).set({
          "users": [currentUserId, widget.serviceProviderId],
          "chatRoomId": chatRoomId,
          "lastMessage": messageText,
          "lastMessageTime": DateTime.now(),
          "unreadCount": FieldValue.increment(1),
        }, SetOptions(merge: true));

        _scrollToBottom();
      } catch (e) {
        print('Error sending message: $e');
      }
    });
  }

  bool _dialogShown = false;

  void onYesPressed() {
    showBookingDialog();
    setState(() {
      _dialogShown = true;
    });
  }

  void onNoPressed() {
    Navigator.of(context).pop();
  }

  Future<void> fetchServiceName() async {
    if (widget.serviceName != null && widget.serviceName!.isNotEmpty) {
      setState(() {
        serviceName = widget.serviceName!;
        description = widget.description ?? 'No description yet';
      });
      print("Using passed service name and description: $serviceName, $description");
      return;
    }

    // Jika `widget.serviceId` tersedia, fetch dari Firestore
    if (widget.serviceId != null) {
      final serviceRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.serviceProviderId)
          .collection('Services')
          .doc(widget.serviceId);

      try {
        final docSnapshot = await serviceRef.get();
        if (docSnapshot.exists) {
          setState(() {
            serviceName = docSnapshot.data()?['name'] ?? 'Service Not Found';
            description = docSnapshot.data()?['description'] ?? 'No description yet';
            print("Service name and description fetched from Firestore: $serviceName, $description");
          });
        } else {
          setState(() {
            serviceName = 'Service Not Found';
            description = 'No description yet';
          });
          print("Service document does not exist.");
        }
      } catch (e) {
        print("Error fetching service name and description: $e");
        setState(() {
          serviceName = 'Service Not Found';
          description = 'Description not found';
        });
      }
    } else {
      print("serviceId is null, cannot fetch service name and description.");
    }
  }

  void _getUserAvatar() async {
    final userDoc = await FirebaseFirestore.instance.collection('Users').doc(currentUserId).get();
    if (userDoc.exists) {
      setState(() {
        userAvatar = userDoc.data()?['avatarUrl'] ?? userAvatar;
      });
    }
  }

  void _selectBookingDateTime() async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );

    if (selectedDate != null) {
      TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (selectedTime != null) {
        String formattedDateTime = "${selectedDate.toLocal()} ${selectedTime.format(context)}";
        sendBookingDateTime(formattedDateTime);
      }
    }
  }

  void sendBookingDateTime(String dateTime) {
    final docId = DateTime.now().millisecondsSinceEpoch.toString();
    messageColl.doc('$currentName&${widget.userName}').collection("chats").doc(docId).set({
      'sender': currentUserId,
      'type': 'booking_date_time',
      'dateTime': dateTime,
      'accepted': false,
      'declined': false,
      'time': DateTime.now(),
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    FirebaseFirestore.instance.collection('Users').doc(currentUserId).get().then((value) {
      if (value.exists) {
        setState(() {
          currentName = (value.data() as Map<String, dynamic>)['name'];
          onlineStatus = (value.data() as Map<String, dynamic>)['status'];
        });
      }
    });

    // Only show booking dialog if directBooking is true
    if (widget.directBooking && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showBookingDialog();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: false,
        titleSpacing: 0,
        title: RichText(
          textAlign: TextAlign.left,
          text: TextSpan(
            children: [
              TextSpan(
                  text: widget.userName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black)),
              const TextSpan(text: '\n'),
              TextSpan(text: onlineStatus, style: const TextStyle(color: Colors.black))
            ],
          ),
        ),
        actions: [
          if (widget.initialBookingDateTime == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(50, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: () {
                    showBookingDialog();
                  },
                  child: const Text(
                    'Create Booking',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(
                top: 10,
                bottom: 16,
                right: 16,
                left: 20,
              ),
              child: Text(
                "Give details to the business about the date and time\n you are interested to reserve their service.",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, wordSpacing: 0.3),
                textAlign: TextAlign.center,
              ),
            ),

            // Chat Messages StreamBuilder
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    messageColl.doc(getChatRoomId()).collection('chats').orderBy('time', descending: false).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print('Error in StreamBuilder: ${snapshot.error}');
                    return const Center(child: Text('Error loading messages'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Check for new messages
                  if (snapshot.hasData && snapshot.data != null) {
                    for (var change in snapshot.data!.docChanges) {
                      if (change.type == DocumentChangeType.added) {
                        final messageData = change.doc.data() as Map<String, dynamic>;
                        checkAndSendNotification(messageData);
                      }
                    }
                  }

                  print('Number of messages: ${snapshot.data!.docs.length}');

                  // Add this check for new messages
                  if (snapshot.hasData && snapshot.data!.docs.length > _previousMessageCount) {
                    _previousMessageCount = snapshot.data!.docs.length;
                    _scrollToBottom();
                  }

                  if (snapshot.hasData) {
                    // Scroll to bottom when data is first loaded
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: snapshot.data!.docs.length,
                    physics: const ClampingScrollPhysics(),
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      var messageData = doc.data() as Map<String, dynamic>;
                      messageData['docId'] = doc.id;

                      print('Message ${index + 1}:');
                      print('Type: ${messageData['type']}');
                      print('Sender: ${messageData['sender']}');

                      return buildMessageItem(messageData);
                    },
                  );
                },
              ),
            ),

            // Message Input Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        hintText: 'Enter message here',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                      keyboardType: TextInputType.text,
                      maxLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: sendMessage,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Are you sure this is the service you want?",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onYesPressed();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: const Text(
                          "YES",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "OR",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onNoPressed();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: const Text(
                          "NO",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 95),
                    child: OfferCard(
                      isMe: true,
                      price: widget.price,
                      serviceName: widget.serviceName ?? 'Service Not Found',
                      docId: '',
                      currentName: currentName ?? 'User',
                      userName: widget.userName,
                      isAccepted: false,
                      email: '',
                      phoneNumber: '',
                      declined: false,
                      bookingDate: widget.initialBookingDateTime ?? '',
                      photoUrl: widget.photoUrl ?? 'https://example.com/default-image.jpg',
                      description: description,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void sendOffer(String dateTime) async {
    List<String> userMap = ['$currentName($currentUserId)', '${widget.userName}(${widget.serviceProviderId})'];

    String serviceNameToSend = widget.serviceName ?? serviceName;
    String docId = DateTime.now().millisecondsSinceEpoch.toString();

    await messageColl
        .doc('$currentName&${widget.userName}')
        .set({"users": userMap, "chatRoomId": '$currentName&${widget.userName}'});

    messageColl.doc('$currentName&${widget.userName}').collection("chats").doc(docId).set({
      'sender': "$currentName",
      'time': DateTime.now(),
      'type': 'offer',
      'serviceProviderId': widget.serviceProviderId,
      'avatarUrl': widget.avatarUrl,
      'price': widget.price,
      'message': 'Booking Offer',
      'declined': false,
      'accepted': false,
      'unread': true,
      'bookingDate': dateTime,
      'serviceName': serviceNameToSend,
    });
  }

  void fetchUserServices() async {
    try {
      print('Fetching services for provider: ${widget.serviceProviderId}');

      final servicesSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.serviceProviderId)
          .collection('Services')
          .get();

      if (servicesSnapshot.docs.isEmpty) {
        print('No services found for this provider');
        return;
      }

      setState(() {
        _services = servicesSnapshot.docs.map((doc) {
          final data = doc.data();
          print('Service found: ${data['name']}');
          return data['name'] as String;
        }).toList();

        // If we have services and no service is selected, select the first one
        if (_services.isNotEmpty && _selectedService == null) {
          _selectedService = _services[0];
        }
      });

      print('Total services fetched: ${_services.length}');
      print('Services list: $_services');
    } catch (e) {
      print('Error fetching services: $e');
    }
  }

  void showBookingDialog() {
    // Reset selected service if needed
    if (!_services.contains(_selectedService)) {
      _selectedService = _services.isNotEmpty ? _services[0] : null;
    }

    // Initialize variables for dropdowns
    String? selectedHour;
    String? selectedMinute;

    // Create lists for hours and minutes
    final List<String> hours = List.generate(24, (index) => index.toString().padLeft(2, '0'));
    final List<String> minutes = List.generate(60, (index) => index.toString().padLeft(2, '0'));

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            print('Building dialog. Available services: $_services');
            print('Currently selected service: $_selectedService');

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Choose date & time available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Service Selection
                      if (_services.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedService,
                          hint: const Text('Select Service'),
                          decoration: InputDecoration(
                            labelText: 'Select Service',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          dropdownColor: Colors.white,
                          items: _services.map((String service) {
                            return DropdownMenuItem<String>(
                              value: service,
                              child: Text(
                                service,
                                style: const TextStyle(color: Colors.black),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            print('Service selected: $newValue');
                            setState(() {
                              _selectedService = newValue;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'No services available',
                            style: TextStyle(
                              color: Colors.red,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Date Selection
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(DateTime.now().year + 1),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Colors.blue,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: Colors.black,
                                  ),
                                  dialogBackgroundColor: Colors.white,
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (date != null) {
                            setState(() {
                              dateController.text = DateFormat('dd.MM.yyyy').format(date);
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dateController.text.isEmpty ? 'Select Date' : dateController.text,
                                  style: TextStyle(
                                    color: dateController.text.isEmpty ? Colors.grey[600] : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Time Selection using dropdowns
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Hour',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              dropdownColor: Colors.white,
                              value: selectedHour,
                              items: hours.map((String hour) {
                                return DropdownMenuItem<String>(
                                  value: hour,
                                  child: Text(
                                    hour,
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? value) {
                                setState(() {
                                  selectedHour = value;
                                  if (selectedHour != null && selectedMinute != null) {
                                    timeController.text = '$selectedHour:$selectedMinute';
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Minute',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              dropdownColor: Colors.white,
                              value: selectedMinute,
                              items: minutes.map((String minute) {
                                return DropdownMenuItem<String>(
                                  value: minute,
                                  child: Text(
                                    minute,
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? value) {
                                setState(() {
                                  selectedMinute = value;
                                  if (selectedHour != null && selectedMinute != null) {
                                    timeController.text = '$selectedHour:$selectedMinute';
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (dateController.text.isNotEmpty &&
                                  timeController.text.isNotEmpty &&
                                  _selectedService != null) {
                                String dateTimeString = '${dateController.text} ${timeController.text}';
                                Navigator.of(context).pop();
                                Future.delayed(const Duration(milliseconds: 100), () {
                                  sendBookingRequest(dateTimeString, _selectedService!);
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please fill in all fields'),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue,
                              side: const BorderSide(color: Colors.blue),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            child: const Text(
                              'Confirm',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Don't forget to dispose
    dateController.dispose();
    timeController.dispose();
    super.dispose();
  }

  // 1. First, add this method to get the correct chat room ID
  String getChatRoomId() {
    // Sort IDs to ensure consistent chat room ID regardless of sender/receiver
    List<String> ids = [currentUserId!, widget.serviceProviderId];
    ids.sort(); // Sort alphabetically
    return ids.join('_');
  }

  // 2. Update the getBookingRequests method
  Stream<QuerySnapshot> getBookingRequests() {
    try {
      String chatRoomId = getChatRoomId();
      print('Getting booking requests for chat room: $chatRoomId');

      return messageColl
          .doc(chatRoomId)
          .collection('chats')
          .where('type', isEqualTo: 'booking_request')
          .snapshots(); // Remove orderBy temporarily until index is created
    } catch (error) {
      print('Error in getBookingRequests: $error');
      // Return an empty stream in case of error
      return Stream.value(null as QuerySnapshot);
    }
  }

  // 3. Update the sendBookingRequest method to use the same chat room ID
  void sendBookingRequest(String dateTime, String serviceName) async {
    try {
      print('=== START: Sending Booking Request ===');

      final docId = DateTime.now().millisecondsSinceEpoch.toString();
      String chatRoomId = getChatRoomId();

      print('Chat Room ID: $chatRoomId');
      print('Current User ID: $currentUserId');
      print('Service Provider ID: ${widget.serviceProviderId}');

      // First, ensure the chat room exists
      await messageColl.doc(chatRoomId).set({
        "users": [currentUserId, widget.serviceProviderId],
        "chatRoomId": chatRoomId,
        "lastMessage": "Booking Request",
        "lastMessageTime": DateTime.now(),
      }, SetOptions(merge: true));

      // Get service details
      final serviceSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.serviceProviderId)
          .collection('Services')
          .where('name', isEqualTo: serviceName)
          .limit(1)
          .get();

      if (serviceSnapshot.docs.isEmpty) {
        print('Error: Service not found');
        return;
      }

      final serviceId = serviceSnapshot.docs.first.id;
      final serviceData = serviceSnapshot.docs.first.data();

      print('Service found:');
      print('Service ID: $serviceId');
      print('Service Data: $serviceData');

      // Create booking request message
      final bookingData = {
        'sender': currentUserId,
        'clientName': currentName,
        'time': DateTime.now(),
        'type': 'booking_request',
        'serviceProviderId': widget.serviceProviderId,
        'serviceId': serviceId,
        'serviceName': serviceName,
        'bookingDateTime': dateTime,
        'status': 'pending',
        'docId': docId,
        'price': serviceData['price'],
        'photoUrl': serviceData['photoUrl'],
        'description': serviceData['description'],
        'unread': true,
      };

      print('Sending booking request with data:');
      print(bookingData);

      // Send booking request
      await messageColl.doc(chatRoomId).collection('chats').doc(docId).set(bookingData);

      print('Booking request sent successfully');

      // Scroll to bottom after sending booking request
      _scrollToBottom();
    } catch (error) {
      print('Error sending booking request: $error');
    }
  }

  Widget buildBookingRequestCard(Map<String, dynamic> bookingData, String bookingId) {
    bool isTimeUpdated = bookingData['isTimeUpdated'] == true;
    bool needsResponse = bookingData['needsResponse'] == true;
    bool isOriginalSender = bookingData['originalSender'] == currentUserId;
    String status = bookingData['status'] ?? 'pending';

    return Column(
      children: [
        // Your existing card UI...

        // Show accept/decline buttons only to original sender when time is updated
        if (isTimeUpdated && needsResponse && isOriginalSender && status == 'pending')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => handleBookingResponse(bookingId, true),
                  icon: const Icon(Icons.check_circle, size: 16),
                  label: const Text('Accept Time'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => handleBookingResponse(bookingId, false),
                  icon: const Icon(Icons.cancel, size: 16),
                  label: const Text('Decline Time'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Add this method to handle the booking response
  void handleBookingResponse(String bookingId, bool accepted) async {
    try {
      String chatRoomId = getChatRoomId();

      await messageColl.doc(chatRoomId).collection('chats').doc(bookingId).update({
        'status': accepted ? 'accepted' : 'declined',
        'needsResponse': false,
        'isTimeUpdated': false,
        'respondedAt': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accepted ? 'New time accepted' : 'New time declined'),
          backgroundColor: accepted ? Colors.green : Colors.red,
        ),
      );
    } catch (error) {
      print('Error handling booking response: $error');
      print(error);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating booking response'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void showRescheduleDialog(String bookingId) {
    // Initialize variables for dropdowns
    String? selectedHour;
    String? selectedMinute;

    // Create lists for hours and minutes
    final List<String> hours = List.generate(24, (index) => index.toString().padLeft(2, '0'));
    final List<String> minutes = List.generate(60, (index) => index.toString().padLeft(2, '0'));

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Reschedule Booking',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Date Selection
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(DateTime.now().year + 1),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Colors.blue,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black,
                              ),
                              dialogBackgroundColor: Colors.white,
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        setState(() {
                          dateController.text = DateFormat('dd.MM.yyyy').format(date);
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dateController.text.isEmpty ? 'Select Date' : dateController.text,
                              style: TextStyle(
                                color: dateController.text.isEmpty ? Colors.grey[600] : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Time Selection using dropdowns
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Hour',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          dropdownColor: Colors.white,
                          value: selectedHour,
                          items: hours.map((String hour) {
                            return DropdownMenuItem<String>(
                              value: hour,
                              child: Text(
                                hour,
                                style: const TextStyle(color: Colors.black),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              selectedHour = value;
                              if (selectedHour != null && selectedMinute != null) {
                                timeController.text = '$selectedHour:$selectedMinute';
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Minute',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          dropdownColor: Colors.white,
                          value: selectedMinute,
                          items: minutes.map((String minute) {
                            return DropdownMenuItem<String>(
                              value: minute,
                              child: Text(
                                minute,
                                style: const TextStyle(color: Colors.black),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              selectedMinute = value;
                              if (selectedHour != null && selectedMinute != null) {
                                timeController.text = '$selectedHour:$selectedMinute';
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (dateController.text.isNotEmpty && timeController.text.isNotEmpty) {
                            String dateTimeString = '${dateController.text} ${timeController.text}';
                            Navigator.of(context).pop();
                            try {
                              String chatRoomId = getChatRoomId();
                              messageColl.doc(chatRoomId).collection('chats').doc(bookingId).update({
                                'bookingDateTime': dateTimeString,
                                'status': 'pending',
                                'isTimeUpdated': true,
                                'needsResponse': true,
                                'rescheduledBy': currentUserId,
                                'updatedAt': DateTime.now(),
                              });
                            } catch (error) {
                              print('Error updating booking time: $error');
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select both date and time'),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showDeleteDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Delete Request',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Are you sure you want to delete this booking request?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () async {
                    try {
                      String chatRoomId = getChatRoomId();

                      await messageColl.doc(chatRoomId).collection('chats').doc(bookingId).delete();

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Request deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      print('Error deleting request: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error deleting request'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.red),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Future<void> markMessagesAsRead() async {
    try {
      // First, check if we have the correct IDs
      print('Current User ID: $currentUserId');
      print('Service Provider ID: ${widget.serviceProviderId}');

      // Get both possible combinations of the chat room ID
      String chatRoomId1 = '${widget.serviceProviderId}_$currentUserId';
      String chatRoomId2 = '${currentUserId}_${widget.serviceProviderId}';

      print('Trying chat room IDs: $chatRoomId1 or $chatRoomId2');

      // Check which chat room exists
      final chatRoom1 = await FirebaseFirestore.instance.collection('ChatRoom').doc(chatRoomId1).get();

      final chatRoom2 = await FirebaseFirestore.instance.collection('ChatRoom').doc(chatRoomId2).get();

      // Use the existing chat room ID
      final chatRoomId = chatRoom1.exists ? chatRoomId1 : chatRoomId2;
      print('Found existing chat room: $chatRoomId');

      // Get all unread messages
      final unreadMessages = await FirebaseFirestore.instance
          .collection('ChatRoom')
          .doc(chatRoomId)
          .collection('chats')
          .where('unread', isEqualTo: true)
          .get();

      print('Found ${unreadMessages.docs.length} unread messages');

      // Print each message for debugging
      for (var doc in unreadMessages.docs) {
        final data = doc.data();
        print('Message ID: ${doc.id}');
        print('Message Data: $data');
      }

      // Create a batch write
      final batch = FirebaseFirestore.instance.batch();

      // Add each update to the batch
      for (var doc in unreadMessages.docs) {
        print('Marking message ${doc.id} as read');
        batch.update(doc.reference, {
          'unread': false,
          'readAt': FieldValue.serverTimestamp(), // Optional: track when it was read
        });
      }

      // Commit the batch
      await batch.commit();
      print('Successfully committed batch update');
    } catch (e) {
      print('Error marking messages as read: $e');
      print(e);
    }
  }

  // Add this method to scroll to bottom
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      // If controller isn't ready yet, try again after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _scrollToBottom();
        }
      });
    }
  }

  // Add this method to properly handle scroll position
  void _maintainScrollPosition(VoidCallback callback) {
    if (_scrollController.hasClients) {
      final currentPosition = _scrollController.position.pixels;
      callback();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(currentPosition);
        }
      });
    } else {
      callback();
    }
  }

  // Add this method to handle keyboard visibility
  void _handleKeyboardVisibility() {
    if (mounted) {
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;
      if (bottomInset > 0 && _scrollController.hasClients) {
        // Delay the scroll to ensure the keyboard is fully shown
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollToBottom();
        });
      }
    }
  }

  Widget buildMessageItem(Map<String, dynamic> messageData) {
    bool isMe = messageData['sender'] == currentUserId;

    if (messageData['type'] == 'booking_request') {
      bool isTimeUpdated = messageData['isTimeUpdated'] == true;
      bool needsResponse = messageData['needsResponse'] == true;
      bool isOriginalSender = messageData['sender'] == currentUserId;
      String status = messageData['status'] ?? 'pending';

      return Column(
        children: [
          BookingCard(bookingData: messageData),

          // Show accept/decline buttons only when status is pending AND time is updated AND needs response
          if (isTimeUpdated && needsResponse && isOriginalSender && status == 'pending')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: () => handleRescheduleResponse(messageData['docId'], true),
                      icon: const Icon(Icons.check_circle, color: Colors.white, size: 16),
                      label: const Text(
                        'Accept Time',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: () => handleRescheduleResponse(messageData['docId'], false),
                      icon: const Icon(Icons.cancel, color: Colors.white, size: 16),
                      label: const Text(
                        'Decline Time',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Show provider buttons only if not updated and is service provider
          if (!isTimeUpdated && messageData['serviceProviderId'] == currentUserId && status == 'pending')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: () => handleRescheduleResponse(messageData['docId'], true),
                      icon: const Icon(Icons.check_circle, color: Colors.white, size: 16),
                      label: const Text(
                        'Accept',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: () => showRescheduleDialog(messageData['docId']),
                      icon: const Icon(Icons.schedule, color: Colors.white, size: 16),
                      label: const Text(
                        'Reschedule',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: () => handleRescheduleResponse(messageData['docId'], false),
                      icon: const Icon(Icons.cancel, color: Colors.white, size: 16),
                      label: const Text(
                        'Decline',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    } else {
      return buildTextMessage(messageData, isMe);
    }
  }

  Widget buildTextMessage(Map<String, dynamic> messageData, bool isMe) {
    final timestamp = messageData['time'];
    String timeString = '';

    if (timestamp != null) {
      if (timestamp is Timestamp) {
        timeString = timeago.format(timestamp.toDate());
      } else if (timestamp is DateTime) {
        timeString = timeago.format(timestamp);
      }
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 64 : 16,
          right: isMe ? 16 : 64,
          top: 8,
          bottom: 8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe) ...[
              Text(
                messageData['sender'] ?? 'Unknown',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              messageData['message'] ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              timeString,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return '';
    }

    return timeago.format(dateTime, locale: 'en_short');
  }

  void handleRescheduleResponse(String bookingId, bool accepted) async {
    try {
      String chatRoomId = getChatRoomId();

      // Get the booking request data first
      final bookingDoc = await messageColl.doc(chatRoomId).collection('chats').doc(bookingId).get();

      final bookingData = bookingDoc.data() as Map<String, dynamic>;

      // Update the chat message status
      await messageColl.doc(chatRoomId).collection('chats').doc(bookingId).update({
        'status': accepted ? 'accepted' : 'declined',
        'needsResponse': false,
        'isTimeUpdated': false,
        'respondedAt': DateTime.now(),
      });

      // If accepted, create a booking in the user's Bookings subcollection
      if (accepted) {
        // Get service details
        final serviceDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(bookingData['serviceProviderId'])
            .collection('Services')
            .doc(bookingData['serviceId'])
            .get();

        final serviceData = serviceDoc.data() ?? {};

        // Create the booking in the user's Bookings subcollection
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(bookingData['sender']) // client's ID
            .collection('Bookings')
            .add({
          'serviceProviderId': bookingData['serviceProviderId'],
          'clientId': bookingData['sender'],
          'serviceId': bookingData['serviceId'],
          'serviceName': bookingData['serviceName'],
          'bookingDateTime': bookingData['bookingDateTime'],
          'status': 'accepted', // Changed from 'confirmed' to match your query
          'price': serviceData['price'] ?? bookingData['price'],
          'createdAt': DateTime.now(),
          'chatRoomId': chatRoomId,
          'bookingId': bookingId,
          'photoUrl': serviceData['photoUrl'],
          'clientName': bookingData['clientName'] ?? 'Unknown Client',
        });

        // Also create the booking for the service provider
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(bookingData['serviceProviderId'])
            .collection('Bookings')
            .add({
          'serviceProviderId': bookingData['serviceProviderId'],
          'clientId': bookingData['sender'],
          'serviceId': bookingData['serviceId'],
          'serviceName': bookingData['serviceName'],
          'bookingDateTime': bookingData['bookingDateTime'],
          'status': 'accepted',
          'price': serviceData['price'] ?? bookingData['price'],
          'createdAt': DateTime.now(),
          'chatRoomId': chatRoomId,
          'bookingId': bookingId,
          'photoUrl': serviceData['photoUrl'],
          'clientName': bookingData['clientName'] ?? 'Unknown Client',
        });

        print('Booking created for both user and service provider');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accepted ? 'Booking accepted' : 'Booking declined'),
          backgroundColor: accepted ? Colors.green : Colors.red,
        ),
      );
    } catch (error) {
      print('Error handling booking response: $error');
      print(error);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating booking response'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Add this method to check and send notifications for unread messages
  void checkAndSendNotification(Map<String, dynamic> messageData) async {
    print('Checking notification for message: $messageData');

    // Only send notification if message is unread and current user is not the sender
    if (messageData['unread'] == true && messageData['sender'] != currentUserId) {
      print('Message qualifies for notification');
      print('Sender ID: ${messageData['sender']}');
      print('Current User ID: $currentUserId');

      try {
        // Get sender's name
        final senderDoc = await FirebaseFirestore.instance.collection('Users').doc(messageData['sender']).get();

        final senderName = senderDoc.data()?['name'] ?? 'Someone';
        print('Sender Name: $senderName');

        // Get recipient's FCM token
        final recipientId =
            currentUserId == widget.serviceProviderId ? messageData['sender'] : widget.serviceProviderId;

        print('Recipient ID: $recipientId');

        final recipientDoc = await FirebaseFirestore.instance.collection('Users').doc(recipientId).get();

        final recipientToken = recipientDoc.data()?['fcmToken'];
        print('Recipient Token: $recipientToken');

        if (recipientToken != null) {
          // Send FCM notification using Cloud Functions
          await FirebaseFirestore.instance.collection('notifications').add({
            'token': recipientToken,
            'title': currentName ?? 'New Message',
            'body': messageData['message'] ?? 'New message',
            'data': {
              'chatRoomId': getChatRoomId(),
              'type': 'chat_message',
              'senderId': messageData['sender'],
            },
            'timestamp': FieldValue.serverTimestamp(),
          });
        } else {
          print('No FCM Token found for recipient');
        }
      } catch (e, stackTrace) {
        print('Error sending notification: $e');
        print('Stack trace: $stackTrace');
      }
    } else {
      print('Message does not qualify for notification');
    }
  }
}

// ignore: must_be_immutable
class OfferCard extends StatefulWidget {
  const OfferCard({
    super.key,
    required this.isMe,
    required this.price,
    required this.serviceName,
    required this.docId,
    required this.currentName,
    required this.userName,
    required this.isAccepted,
    required this.email,
    required this.phoneNumber,
    required this.declined,
    required this.bookingDate,
    required this.photoUrl,
    required this.description,
  });

  final String price;
  final String serviceName;
  final bool isMe;
  final String docId;
  final String currentName;
  final String userName;
  final bool isAccepted;
  final bool declined;
  final String email;
  final String phoneNumber;
  final String bookingDate;
  final String photoUrl;
  final String description;

  @override
  _OfferCardState createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> {
  CollectionReference messageColl = FirebaseFirestore.instance.collection('ChatRoom');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10, right: 10, left: 10, bottom: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.photoUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.image_not_supported, size: 30);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.serviceName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      "${widget.price} RON",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ],
                ),
                Text(
                  widget.description,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 1.0),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        minimumSize: const Size(10, 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'BOOK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTime) {
    try {
      DateTime parsedDate = DateTime.parse(dateTime);
      return DateFormat('dd-MM-yyyy HH:mm').format(parsedDate);
    } catch (e) {
      return dateTime;
    }
  }

  void acceptOffer(DateTime? date, String? time) async {
    // Assuming you have a Firestore collection for bookings
    CollectionReference bookings = FirebaseFirestore.instance.collection('bookings');

    // Create a new booking entry
    await bookings.add({
      'userName': widget.userName, // The user who sent the booking offer
      'date': date?.toIso8601String(), // Convert DateTime to String
      'time': time, // The time of the booking
      'serviceName': widget.serviceName, // The name of the service
      'status': 'accepted', // Status of the booking
    });

    // Optionally, you can show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking accepted!')),
    );
  }
}

class ServiceRequestCard extends StatelessWidget {
  final String serviceName;
  final String description;
  final String price;
  final String photoUrl;

  const ServiceRequestCard({
    super.key,
    required this.serviceName,
    required this.description,
    required this.price,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    photoUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Price:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '$price RON',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const BookingCard({super.key, required this.bookingData});

  @override
  Widget build(BuildContext context) {
    // Debug prints to verify the data we're receiving
    print('Booking Data received:');
    print('Service Provider ID: ${bookingData['serviceProviderId']}');
    print('Service ID: ${bookingData['serviceId']}');

    return FutureBuilder<DocumentSnapshot>(
      // Using Future instead of Stream since we don't need real-time updates
      future: FirebaseFirestore.instance
          .collection('Users')
          .doc(bookingData['serviceProviderId'])
          .collection('Services')
          .doc(bookingData['serviceId'])
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('Error fetching service data: ${snapshot.error}');
          return const Center(child: Text('Error loading service details'));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          print('No service data found');
          return const Center(child: Text('Service not found'));
        }

        final serviceData = snapshot.data!.data() as Map<String, dynamic>;

        // Debug print the service data
        print('Fetched Service Data: $serviceData');

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.75,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: serviceData['photoUrl'] != null
                        ? Image.network(
                            serviceData['photoUrl'],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading image: $error');
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported),
                              );
                            },
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported),
                          ),
                  ),

                  const SizedBox(width: 12),

                  // Service Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Service Name and Price
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                serviceData['name'] ?? 'Service Name Not Found',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${serviceData['price'] ?? 'N/A'} RON',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Description (optional)
                        if (serviceData['description'] != null)
                          Text(
                            serviceData['description'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                        const SizedBox(height: 8),

                        // Booking DateTime
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                bookingData['bookingDateTime'] ?? 'Not specified',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(bookingData['status']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            (bookingData['status'] ?? 'PENDING').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'rescheduled':
        return Colors.orange;
      case 'pending':
      default:
        return Colors.blue;
    }
  }
}
