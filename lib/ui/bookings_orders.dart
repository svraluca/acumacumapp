import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:rxdart/rxdart.dart';

class BookingOrdersScreen extends StatefulWidget {
  const BookingOrdersScreen({super.key});

  @override
  State<BookingOrdersScreen> createState() => _BookingOrdersScreenState();
}

class _BookingOrdersScreenState extends State<BookingOrdersScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  late String currentUserID;
  TabController? tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    currentUserID = FirebaseAuth.instance.currentUser!.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFDA291C),
        title: const SizedBox(
          width: 140,
          height: 140,
          child: Center(
            child: Text(
              'Manage',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          TabBar(
            controller: tabController,
            tabs: const [
              Tab(
                icon: Icon(
                  Icons.calendar_month,
                  color: Color.fromARGB(255, 3, 59, 161),
                ),
              ),
              Tab(
                icon: Icon(
                  Icons.shopping_basket,
                  color: Color.fromARGB(255, 3, 59, 161),
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                // First Tab - Bookings
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Users')
                      .doc(currentUserID)
                      .collection('Bookings')
                      .where('status', isEqualTo: 'accepted')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      print('Error: ${snapshot.error}');
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('No bookings found'),
                      );
                    }

                    final docs = snapshot.data!.docs;
                    print('Found ${docs.length} bookings');
                    
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final bookingData = doc.data() as Map<String, dynamic>;
                        bookingData['docRef'] = doc.reference;
                        
                        // Debug print
                        print('Booking ${index + 1}: ${bookingData}');
                        
                        return BookingCard(bookingData: bookingData);
                      },
                    );
                  },
                ),

                // Second Tab - Orders
                StreamBuilder<List<QuerySnapshot>>(
                  stream: CombineLatestStream.list([
                    // Query for orders where user is seller
                    FirebaseFirestore.instance
                        .collection('orders')
                        .where('sellerId', isEqualTo: currentUserID)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    // Query for orders where user is buyer
                    FirebaseFirestore.instance
                        .collection('orders')
                        .where('buyerId', isEqualTo: currentUserID)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                  ]),
                  builder: (context, snapshot) {
                    // Debug prints
                    print('Current User ID: $currentUserID');
                    print('Connection State: ${snapshot.connectionState}');
                    print('Has Error: ${snapshot.hasError}');
                    if (snapshot.hasError) print('Error: ${snapshot.error}');

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: Text('No orders found'),
                      );
                    }

                    // Combine docs from both queries
                    final List<QueryDocumentSnapshot> allDocs = [];
                    snapshot.data?.forEach((querySnapshot) {
                      allDocs.addAll(querySnapshot.docs);
                    });

                    // Sort combined results by timestamp
                    allDocs.sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>;
                      final bData = b.data() as Map<String, dynamic>;
                      return (bData['timestamp'] as Timestamp)
                          .compareTo(aData['timestamp'] as Timestamp);
                    });

                    if (allDocs.isEmpty) {
                      return const Center(
                        child: Text('No orders found'),
                      );
                    }

                    return ListView.builder(
                      itemCount: allDocs.length,
                      itemBuilder: (context, index) {
                        final doc = allDocs[index];
                        final orderData = doc.data() as Map<String, dynamic>;
                        orderData['docRef'] = doc.reference;
                        
                        return OrderCard(orderData: orderData);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const BookingCard({
    Key? key,
    required this.bookingData,
  }) : super(key: key);

  void _handleDelete(BuildContext context) async {
    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Booking'),
        content: const Text('Are you sure you want to delete this booking?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.black87),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        // Get the document reference and delete it
        // Note: You'll need to store the document reference in bookingData
        if (bookingData['docRef'] != null) {
          await bookingData['docRef'].delete();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking deleted successfully')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting booking: $e')),
        );
      }
    }
  }

  void _handleCancel(BuildContext context) async {
    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'No',
              style: TextStyle(color: Colors.black87),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Yes',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        // Update the status to 'canceled'
        if (bookingData['docRef'] != null) {
          await bookingData['docRef'].update({'status': 'canceled'});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking canceled successfully')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error canceling booking: $e')),
        );
      }
    }
  }

  void _addToCalendar(BuildContext context) async {
    try {
      print('Original DateTime String: ${bookingData['bookingDateTime']}');
      
      // Fetch service provider's details
      DocumentSnapshot providerDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(bookingData['serviceProviderId'])
          .get();
      
      String providerAddress = '';
      if (providerDoc.exists) {
        Map<String, dynamic> providerData = providerDoc.data() as Map<String, dynamic>;
        providerAddress = providerData['precise_address'] ?? 'No precise address found';
      }
      
      // Parse the date string "DD.MM.YYYY HH:mm"
      String dateTimeStr = bookingData['bookingDateTime'];
      List<String> dateAndTime = dateTimeStr.split(' ');
      List<String> dateParts = dateAndTime[0].split('.');
      String time = dateAndTime[1];
      
      // Ensure proper formatting of date parts
      String day = dateParts[0].padLeft(2, '0');
      String month = dateParts[1].padLeft(2, '0');
      String year = dateParts[2];
      
      // Create ISO format string (YYYY-MM-DD HH:mm)
      String isoDateTime = '$year-$month-$day $time:00';
      print('Formatted DateTime: $isoDateTime');
      
      final DateTime bookingDateTime = DateTime.parse(isoDateTime);
      print('Parsed DateTime: $bookingDateTime');
      
      // Create description with address
      String description = 'Appointment for ${bookingData['serviceName']}\n';
      description += 'Address: $providerAddress';
      
      // Create calendar event
      final Event event = Event(
        title: bookingData['serviceName'] ?? 'Booking Appointment',
        description: description,
        location: providerAddress,
        startDate: bookingDateTime,
        endDate: bookingDateTime.add(const Duration(hours: 1)),
        timeZone: 'Europe/Bucharest',
      );

      Add2Calendar.addEvent2Cal(event).then((success) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event added to calendar successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add event to calendar')),
          );
        }
      });
    } catch (e) {
      print('Error adding to calendar: $e');
      print('Booking data: ${bookingData['bookingDateTime']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add event to calendar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug print
    print('Building card with data: $bookingData');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: bookingData['photoUrl'] != null
                      ? Image.network(
                          bookingData['photoUrl'],
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading image: $error');
                            return Container(
                              height: 80,
                              width: 80,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        )
                      : Container(
                          height: 80,
                          width: 80,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported),
                        ),
                ),
                const SizedBox(width: 12),
                
                // Booking Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bookingData['serviceName'] ?? 'Service Name',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date & Time: ${bookingData['bookingDateTime'] ?? 'Not specified'}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        'Price: ${bookingData['price'] ?? '0'} RON',
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (bookingData['clientName'] != null)
                        Text(
                          'Client: ${bookingData['clientName']}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      const SizedBox(height: 8),
                      // Status and Calendar Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(bookingData['status'] ?? 'pending'),
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
                          if (bookingData['status']?.toLowerCase() == 'accepted')
                            IconButton(
                              icon: const Icon(
                                Icons.calendar_today,
                                size: 20,
                                color:  const Color(0xFF000080),
                              ),
                              onPressed: () => _addToCalendar(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Add the PopupMenuButton
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _handleDelete(context);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Container(
                        color: Colors.white,
                        child: const Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  color: Colors.white,
                ),
              ],
            ),
          ),
          
          // Add Divider
          const Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey,
          ),
          
          // Add Cancel Button if status is 'accepted'
          if (bookingData['status']?.toLowerCase() == 'accepted')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleCancel(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.grey[600],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'declined':
      case 'canceled':  // Add color for canceled status
        return Colors.red;
      case 'rescheduled':
        return Colors.orange;
      case 'pending':
      default:
        return Colors.blue;
    }
  }
}

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderCard({
    Key? key,
    required this.orderData,
  }) : super(key: key);

  // Add methods to handle order status updates
  Future<void> _updateOrderStatus(BuildContext context, String status) async {
    try {
      await orderData['docRef'].update({
        'status': status,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order $status successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating order: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserID = FirebaseAuth.instance.currentUser?.uid;
    final isSeller = currentUserID == orderData['sellerId'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        orderData['productName'] ?? 'Product Name',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${orderData['price']} RON',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isSeller ? 'Customer Details:' : 'Your Details:',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Name: ${orderData['buyerName']}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Email: ${orderData['email']}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Phone: ${orderData['phoneNumber']}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Address: ${orderData['deliveryAddress']}',
                  style: const TextStyle(fontSize: 14),
                ),
                if (orderData['notes']?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Notes: ${orderData['notes']}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(orderData['status'] ?? 'pending'),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (orderData['status'] ?? 'PENDING').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      'Order Date: ${_formatTimestamp(orderData['timestamp'])}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                
                // Show action buttons only for seller and pending orders
                if (isSeller && (orderData['status'] == 'pending')) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => _updateOrderStatus(context, 'accepted'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: const Text('Accept'),
                      ),
                      ElevatedButton(
                        onPressed: () => _updateOrderStatus(context, 'declined'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: const Text('Decline'),
                      ),
                    ],
                  ),
                ],
                
                // Show mark as completed button for accepted orders (seller only)
                if (isSeller && orderData['status'] == 'accepted') ...[
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => _updateOrderStatus(context, 'completed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: const Text('Mark as Completed'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return '${date.day}.${date.month}.${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'declined':
      case 'cancelled':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }
}
