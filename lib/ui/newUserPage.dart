import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:acumacum/ui/BookingCalendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:share_plus/share_plus.dart';
import 'package:acumacum/model/User.dart';
import 'package:acumacum/ui/settingsPage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/working_days_util.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:acumacum/ui/SubscriptionPlanPost.dart';
import 'package:acumacum/ui/addService.dart';
import 'package:acumacum/ui/addProduct.dart';

// Define a constant for the dark blue color
const Color darkBlueColor =
    Color(0xFF1A237E); // This is a dark blue color, you can adjust it as needed

class NewUserPage extends StatefulWidget {
  late ScrollController scrollController;

  NewUserPage({super.key});

  @override
  State<NewUserPage> createState() => NewUserProfile();

  static Future<Map<String, dynamic>> getReviewsData(String userId) async {
    try {
      var reviewsSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('reviews')
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        return {'average': 0.0, 'count': 0};
      }

      double sum = 0;
      int count = reviewsSnapshot.docs.length;

      for (var doc in reviewsSnapshot.docs) {
        sum += doc['rating'] as double;
      }

      double average = sum / count;
      return {'average': average, 'count': count};
    } catch (e) {
      print("Error fetching reviews: $e");
      return {'average': 0.0, 'count': 0};
    }
  }
}

class NewUserProfile extends State<NewUserPage>
    with SingleTickerProviderStateMixin {
  bool isFileImage = false;
  late User user;
  late File pickedFile;
  String? userImage;
  String? address;
  String? precise_address;
  String? userName;
  String? facebookUrl;
  String? instagramUrl;
  String? tikTokUrl;
  TextEditingController facebookController = TextEditingController();
  TextEditingController instagramController = TextEditingController();
  TextEditingController tiktokController = TextEditingController();
  late String userId;
  Random randomGenerator = Random();

  String? searchString;
  String? country;
  QuerySnapshot? querySnapshot;
  Stream<QuerySnapshot<Map>>? stream;
  late TabController _tabController;
  late Future<void> _initializationFuture;
  String? workSchedule;
  String? workTime;

  TextEditingController workScheduleController = TextEditingController();
  TextEditingController workTimeController = TextEditingController();
  String? coverPhotoUrl;

  double _averageRating = 0.0;
  int _numberOfReviews = 0;

  final StreamController<double> _averageRatingController =
      StreamController<double>.broadcast();

  Map<String, dynamic>? scheduleData;

  TextEditingController openTimeController = TextEditingController();
  TextEditingController closeTimeController = TextEditingController();
  TextEditingController workingDaysController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeData();
    _fetchSocialLinks();
  }

  Future<void> _initializeData() async {
    await initUser(); // Ensure userId is initialized
    await _initializeTabController();
    await _fetchInitialReviewData();
    await fetchScheduleData(); // Add this line
  }

  Future<void> _initializeTabController() async {
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _fetchInitialReviewData() async {
    try {
      final QuerySnapshot reviewsSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Reviews')
          .get();

      double totalRating = 0;
      int numberOfReviews = reviewsSnapshot.docs.length;

      for (var doc in reviewsSnapshot.docs) {
        totalRating += (doc['rating'] as num?)?.toDouble() ?? 0;
      }

      setState(() {
        _averageRating =
            numberOfReviews > 0 ? totalRating / numberOfReviews : 0;
        _numberOfReviews = numberOfReviews;
      });
    } catch (e) {
      print("Error fetching initial review data: $e");
    }
    }

  @override
  void dispose() {
    _averageRatingController.close();
    _tabController.dispose();
    openTimeController.dispose();
    closeTimeController.dispose();
    workingDaysController.dispose();
    super.dispose();
  }

  initUser() async {
    user = FirebaseAuth.instance.currentUser!;
    userId = user.uid;
    print("initUser called with userId: $userId"); // Debug log
    getSocialData();
    getData();
  }

  final TextEditingController _userNameController = TextEditingController();

  late File _image;
  final picker = ImagePicker();

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      Reference storageReference = FirebaseStorage.instance.ref();
      Uint8List imageData = _image.readAsBytesSync();
      
      try {
        // Upload image to Firebase Storage
        final uploadTask = await storageReference
            .child("Users Profile")
            .child(userId)
            .putData(imageData);
            
        // Get download URL
        final url = await uploadTask.ref.getDownloadURL();

        // Update Firestore document directly
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .update({'avatarUrl': url});
            
      } catch (e) {
        print('Error updating profile image: $e');
        // Optionally show error message to user
      }
    }
  }

  Widget _buildCircleButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Share Button
          GestureDetector(
            onTap: () async {
              Share.share(
                '${userName ?? "A user"} located in ${address ?? "an unknown location"} invites you to their AcumAcum business profile with the following app link https://acumacum.page.link/29hQ.',
              );
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, size: 24, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Share',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              _showSocialBottomSheet(context);
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.people_outline, size: 24, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Add Social',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () async {
              if (precise_address != null && precise_address!.isNotEmpty) {
                // Show bottom sheet with options
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (BuildContext context) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Business Location',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Current address: $precise_address',
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: darkBlueColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _showAddLocationDialog(context);
                            },
                            child: const Text(
                              'Change Address',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    );
                  },
                );
              } else {
                _showAddLocationDialog(context);
              }
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.directions, size: 24, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Directions',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () async {
              print("Settings button tapped");
              try {
                DocumentSnapshot snapshot = await FirebaseFirestore.instance
                    .collection('Users')
                    .doc(userId)
                    .get();
                UserModel user = UserModel.fromDocument(snapshot);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SettingsPage(user: user)),
                );
              } catch (e) {
                print("Error occurred: $e");
              }
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.settings, size: 24, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Settings',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        // Handle button tap
        print('$label tapped');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Photo
              Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      image: coverPhotoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(coverPhotoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: coverPhotoUrl == null
                        ? const Center(child: Text("Add Cover Photo"))
                        : null,
                  ),
                  // Add back button here
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10, // Adjust for status bar
                    left: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () => _changeCoverPhoto(),
                    ),
                  ),
                  // Add a safe area padding at the top
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Container(),
                    ),
                  ),
                ],
              ),
              // Rest of the content wrapped in SafeArea
              Expanded(
                child: SafeArea(
                  top: false, // Don't add padding at the top
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Average Rating
                        StatefulBuilder(
                          builder:
                              (BuildContext context, StateSetter setState) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: _buildAverageRating(),
                            );
                          },
                        ),
                        // Username
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Text(
                            userName ?? "Username not available",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        _buildCircleButtons(), // Add the circle buttons here

                        // Location
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 20, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  address ?? "Location not specified",
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Work Schedule
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month,
                                  color: Colors.grey, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Work Schedule",
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatWorkInfo(),
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Edit Profile Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: ElevatedButton(
                            onPressed: () {
                              _userEditBottomSheet(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  darkBlueColor, // Changed to dark blue
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text("Edit Profile"),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tab Bar
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Services'),
                            Tab(text: 'Products'),
                            Tab(text: 'Reviews'),
                          ],
                        ),

                        // Tab Bar View
                        SizedBox(
                          height: 300, // Adjust this height as needed
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              ServicesTab(userId: userId),
                              ProductsTab(userId: userId),
                              ReviewsTab(
                                  userId: userId,
                                  averageRatingController:
                                      _averageRatingController),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _userEditBottomSheet(BuildContext context) {
    // First fetch the current data and initialize controllers
    FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('BusinessAccount')
        .doc('detail')
        .get()
        .then((doc) {
      if (doc.exists) {
        var data = doc.data() ?? {};
        openTimeController.text = data['openTime'] ?? data['timeOpen'] ?? '';
        closeTimeController.text = data['closeTime'] ?? data['timeClosed'] ?? '';
        workingDaysController.text = data['workDays'] ?? data['workingDays'] ?? '';
      }

      // Now show the bottom sheet with pre-filled data
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext bc) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: _userNameController,
                      decoration: const InputDecoration(
                        labelText: "Username",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: openTimeController,
                      decoration: const InputDecoration(
                        labelText: "Opening Time",
                        hintText: "e.g., 09:00",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: closeTimeController,
                      decoration: const InputDecoration(
                        labelText: "Closing Time",
                        hintText: "e.g., 17:00",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: workingDaysController,
                      decoration: const InputDecoration(
                        labelText: "Working Days",
                        hintText: "e.g., Monday-Friday",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkBlueColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        _saveChanges();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  void _saveChanges() async {
    try {
      // Update username in Users collection
      if (_userNameController.text.isNotEmpty) {
        await FirebaseFirestore.instance.collection('Users').doc(userId).update({
          'name': _userNameController.text,
        });
      }

      // Update business hours in both main Users collection and BusinessAccount/detail
      final updatedData = {
        'openTime': openTimeController.text,
        'closeTime': closeTimeController.text,
        'workDays': workingDaysController.text,
      };

      // Update in main Users collection
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .update(updatedData);

      // Update in BusinessAccount/detail
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('BusinessAccount')
          .doc('detail')
          .set(updatedData, SetOptions(merge: true));

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Changes saved successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Add debug prints
      print('Updated data in both locations:');
      print('Main collection data: $updatedData');
      
      // Refresh the data
      getData();
      fetchScheduleData();
    } catch (e) {
      print('Error saving changes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving changes. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void getData() {
    FirebaseFirestore.instance
        .collection("Users")
        .doc(userId)
        .snapshots()
        .listen((event) {
      if (mounted) {
        setState(() {
          var data = event.data();
          userImage = data?['avatarUrl'] as String?;
          userName = data?['name'] as String?;
          address = data?['address'] as String?;
          precise_address = data?['precise_address'] as String?;
          workSchedule = data?['workSchedule'] as String?;
          workTime = data?['workTime'] as String?;
          coverPhotoUrl = data?['coverPhotoUrl'] as String?;

          // Set controller values
          _userNameController.text = userName ?? '';
          workScheduleController.text = workSchedule ?? '';
          workTimeController.text = workTime ?? '';
        });
      }
    });

    // Fetch social data
    FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('Social')
        .doc('detail')
        .get()
        .then((doc) {
      if (doc.exists && mounted) {
        setState(() {
          var data = doc.data();
          instagramUrl = data?['instagram'] as String?;
          tikTokUrl = data?['tiktok'] as String?;
          facebookUrl = data?['facebook'] as String?;

          // Set controller values
          instagramController.text = instagramUrl ?? '';
          tiktokController.text = tikTokUrl ?? '';
          facebookController.text = facebookUrl ?? '';
        });
      }
    });
  }

  void getSocialData() {
    DocumentReference reference = FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('Social')
        .doc('detail');
    print(reference.path);
    reference.snapshots().listen((event) {
      if (mounted) {
        setState(() {
          facebookUrl =
              event.data() == null ? null : (event.data() as Map)['facebook'];
          instagramUrl =
              event.data() == null ? null : (event.data() as Map)['instagram'];
          tikTokUrl =
              event.data() == null ? null : (event.data() as Map)['tiktok'];
        });
      }
    });
  }

  Future<void> _launchUrl(String url, BuildContext context) async {
    if (url.isEmpty) {
      await Alert(
        context: context,
        type: AlertType.warning,
        title: "Social Link error",
        desc: "You have not provided social link",
        buttons: [
          DialogButton(
            onPressed: () => Navigator.pop(context),
            color: const Color.fromRGBO(0, 179, 134, 1.0),
            child: const Text(
              "Close",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ],
      ).show();
    } else {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        await Alert(
          context: context,
          type: AlertType.warning,
          title: "Social Link error",
          desc: "Cannot Launch Url",
          buttons: [
            DialogButton(
              onPressed: () => Navigator.pop(context),
              color: const Color.fromRGBO(0, 179, 134, 1.0),
              child: const Text(
                "Close",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ],
        ).show();
      }
    }
  }

  String _formatWorkInfo() {
    if (scheduleData == null || scheduleData!.isEmpty) {
      return 'Schedule not available';
    }

    String openTime = scheduleData!['openTime'] ??
        scheduleData!['timeOpen'] ??
        'Not specified';
    String closeTime = scheduleData!['closeTime'] ??
        scheduleData!['timeClosed'] ??
        'Not specified';
    String workDays = scheduleData!['workDays'] ??
        scheduleData!['workingDays'] ??
        'Not specified';

    return 'Working Hours: $openTime - $closeTime\nWorking Days: $workDays';
  }

  Future<void> _changeCoverPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File imageFile = File(image.path);
      String fileName =
          'cover_photos/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      try {
        // Upload to Firebase Storage
        TaskSnapshot uploadTask =
            await FirebaseStorage.instance.ref(fileName).putFile(imageFile);

        String downloadUrl = await uploadTask.ref.getDownloadURL();

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .update({'coverPhotoUrl': downloadUrl});

        // Update local state
        setState(() {
          coverPhotoUrl = downloadUrl;
        });
      } catch (e) {
        print("Error uploading cover photo: $e");
        // Show an error message to the user
      }
    }
  }

  Future<void> fetchScheduleData() async {
    try {
      DocumentSnapshot scheduleDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('BusinessAccount')
          .doc('detail')
          .get();

      if (scheduleDoc.exists) {
        setState(() {
          scheduleData = scheduleDoc.data() as Map<String, dynamic>?;
        });
      } else {
        print('No schedule data found');
      }
    } catch (e) {
      print('Error fetching schedule data: $e');
    }
  }

  void _addService(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddService(userId: userId)),
    );
  }

  Widget _buildAverageRating() {
    return StreamBuilder<double>(
      stream: _averageRatingController.stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text('No reviews yet', style: TextStyle(fontSize: 14));
        }

        double averageRating = snapshot.data!;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 18),
            const SizedBox(width: 4),
            Text(
              averageRating.toStringAsFixed(1),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
    );
  }

  void _updateAverageRating(double avgRating, int numReviews) {
    if (_averageRating != avgRating || _numberOfReviews != numReviews) {
      _averageRating = avgRating;
      _numberOfReviews = numReviews;
      if (mounted) {
        setState(() {});
      }
    }
  }

  Widget _buildWorkingDays(Map<String, dynamic> workingDays) {
    return WorkingDaysUtil.buildWorkingDays(workingDays);
  }

  void _showSocialBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Social Media Links',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: instagramController,
                decoration: const InputDecoration(
                  labelText: 'Instagram Profile Link',
                  prefixIcon: Icon(Icons.camera_alt_outlined),
                  hintText: 'https://instagram.com/yourusername',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tiktokController,
                decoration: const InputDecoration(
                  labelText: 'TikTok Profile Link',
                  prefixIcon: Icon(Icons.music_note),
                  hintText: 'https://tiktok.com/@yourusername',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: facebookController,
                decoration: const InputDecoration(
                  labelText: 'Facebook Profile Link',
                  prefixIcon: Icon(Icons.facebook),
                  hintText: 'https://facebook.com/yourusername',
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                      try {
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      );

                      // Validate and clean URLs
                      final socialData = {
                        'instagram': _cleanUrl(instagramController.text.trim()),
                        'tiktok': _cleanUrl(tiktokController.text.trim()),
                        'facebook': _cleanUrl(facebookController.text.trim()),
                      };

                      // Save to Firestore
                      await FirebaseFirestore.instance
                          .collection('Users')
                          .doc(userId)
                          .collection('Social')
                          .doc('detail')
                          .set(socialData, SetOptions(merge: true));

                      // Close loading indicator
                      Navigator.pop(context);
                      // Close bottom sheet
                      Navigator.pop(context);

                      // Show success message
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Social media links updated successfully'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      // Close loading indicator if there's an error
                      Navigator.pop(context);
                      
                      print('Error saving social media links: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error updating social media links: ${e.toString()}'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Add this helper method to clean URLs
  String _cleanUrl(String url) {
    if (url.isEmpty) return '';
    
    // Remove trailing slashes
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    
    return url;
  }

  // Add this method to fetch social links
  void _fetchSocialLinks() {
    FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('Social')
        .doc('detail')
        .get()
        .then((doc) {
      if (doc.exists) {
        setState(() {
          instagramController.text = doc.data()?['instagram'] ?? '';
          tiktokController.text = doc.data()?['tiktok'] ?? '';
          facebookController.text = doc.data()?['facebook'] ?? '';
        });
      }
    });
  }

  void _showAddLocationDialog(BuildContext context) {
    final TextEditingController locationController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Business Location',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please enter your precise business address',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  hintText: 'Str, nr, localitate , judet, tara',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkBlueColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (locationController.text.isNotEmpty) {
                      try {
                        await FirebaseFirestore.instance
                            .collection('Users')
                            .doc(userId)
                            .update({
                          'precise_address': locationController.text,
                        });
                        
                        setState(() {
                          precise_address = locationController.text;
                        });
                        
                        Navigator.pop(context);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Business location updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        print('Error updating location: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error updating location. Please try again.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Save Location',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

enum uploadTypes {
  GALLERY,
  STORY,
  VIDEO,
  IMAGE,
}

Text _buildRatingStars(int rating) {
  String stars = '';
  for (int i = 0; i < rating; i++) {
    stars += '⭐ ';
  }
  stars.trim();
  return Text(stars);
}

Future<bool> checkActiveSubscription(String userId) async {
  try {
    print('Checking subscription for user: $userId'); // Debug print
    
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .get();

    if (!userDoc.exists) {
      print('User document does not exist'); // Debug print
      return false;
    }

    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
    
    // Debug prints
    print('User data: $userData');
    print('Subscription data: ${userData['subscription']}');

    // Check the nested subscription structure
    if (userData['subscription'] != null && 
        userData['subscription'] is Map<String, dynamic>) {
      Map<String, dynamic> subscription = userData['subscription'] as Map<String, dynamic>;
      
      // Check if status is active
      bool isActive = subscription['status'] == 'active';
      print('Subscription status is active: $isActive'); // Debug print
      
      return isActive;
    }

    print('No valid subscription found'); // Debug print
    return false;
  } catch (e) {
    print('Error checking subscription: $e');
    return false;
  }
}

class ServicesTab extends StatelessWidget {
  final String userId;

  const ServicesTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Users')
                .doc(userId)
                .collection('Services')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No services added yet'));
              }

              return ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot document = snapshot.data!.docs[index];
                  Map<String, dynamic> data =
                      document.data()! as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    color: Colors.white,
                    child: SizedBox(
                      height: 150,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
                            if (data['photoUrl'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  data['photoUrl'],
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(width: 16),
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _showFullDescription(
                                          context, data['name'], data['description']),
                                      child: Text(
                                        data['description'],
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w400,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Price and Action buttons
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${data['price'].toInt()} RON',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: darkBlueColor,
                                  ),
                                ),
                                Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => _editService(
                                          context, document.id, data),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: darkBlueColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      child: const Text(
                                        'Edit',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _deleteService(document.id),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
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
          ),
        ),
        // Modified Add Service Button
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Users')
                .doc(userId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                print('Error checking subscription: ${snapshot.error}');
                return const SizedBox();
              }

              bool hasActiveSubscription = false;
              if (snapshot.hasData && snapshot.data != null) {
                Map<String, dynamic>? userData = 
                    snapshot.data!.data() as Map<String, dynamic>?;
                
                if (userData != null && 
                    userData['subscription'] != null &&
                    userData['subscription'] is Map) {
                  hasActiveSubscription = 
                      userData['subscription']['status'] == 'active';
                }
              }

              return Stack(
                children: [
                  ElevatedButton(
                    onPressed: hasActiveSubscription 
                        ? () => _addService(context)
                        : () => _showSubscriptionDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkBlueColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      hasActiveSubscription ? "Add Service" : "Subscribe to Add Service",
                      style: const TextStyle(fontSize: 14)
                    ),
                  ),
                  if (!hasActiveSubscription)
                    Positioned(
                      right: 12,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Icon(
                          Icons.lock,
                          color: Colors.white.withOpacity(0.8),
                          size: 20,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _addService(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddService(userId: userId)),
    );
  }

  void _editService(BuildContext context, String serviceId,
      Map<String, dynamic> currentData) {
    String name = currentData['name'];
    String description = currentData['description'];
    double price = currentData['price'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Edit Service'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(hintText: 'Service Name'),
                  onChanged: (value) => name = value,
                  controller: TextEditingController(text: name),
                ),
                TextField(
                  decoration: const InputDecoration(hintText: 'Description'),
                  onChanged: (value) => description = value,
                  controller: TextEditingController(text: description),
                ),
                TextField(
                  decoration: const InputDecoration(hintText: 'Price'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => price = double.tryParse(value) ?? price,
                  controller: TextEditingController(text: price.toString()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                if (name.isNotEmpty && description.isNotEmpty && price > 0) {
                  FirebaseFirestore.instance
                      .collection('Users')
                      .doc(userId)
                      .collection('Services')
                      .doc(serviceId)
                      .update({
                    'name': name,
                    'description': description,
                    'price': price,
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Service updated successfully")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteService(String serviceId) {
    FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('Services')
        .doc(serviceId)
        .delete()
        .then((value) => print("Service Deleted"))
        .catchError((error) => print('Failed to delete service: $error'));
  }

  void _showFullDescription(
      BuildContext context, String title, String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(description),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Close',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Subscription Required'),
          backgroundColor: Colors.white,
          content: const Text(
            'You need an active subscription to add services. Would you like to subscribe now?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Not Now'),
            ),
            TextButton(
              onPressed: () {
                        Navigator.pop(context);
                // Navigate to SubscriptionPlanPost
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SubscriptionPlanPost()),
                );
              },
              child: const Text('Subscribe'),
            ),
          ],
        );
      },
    );
  }
}

class ProductsTab extends StatelessWidget {
  final String userId;

  const ProductsTab({super.key, required this.userId});

  void _addProduct(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProduct(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Users')
                .doc(userId)
                .collection('Products')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No products added yet'));
              }

              return ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot document = snapshot.data!.docs[index];
                  Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
                  print('Product data: $data'); // Debug print

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    color: Colors.white,
                    child: SizedBox(
                      height: 150,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
                            FutureBuilder(
                              future: _getImageWidget(data['photoUrl']),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Container(
                                    height: 100,
                                    width: 100,
                                    color: Colors.grey[300],
                                    child: const Center(child: CircularProgressIndicator()),
                                  );
                                } else if (snapshot.hasError) {
                                  print('Error loading image: ${snapshot.error}');
                                  return Container(
                                    height: 100,
                                    width: 100,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.error),
                                  );
                                } else {
                                  return snapshot.data as Widget;
                                }
                              },
                            ),
                            const SizedBox(width: 16),
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] ?? 'No name',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _showFullDescription(context,
                                          data['name'] ?? 'No name', data['description'] ?? 'No description'),
                                      child: Text(
                                        data['description'] ?? 'No description',
                                        style: const TextStyle(fontSize: 14),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Price and Action buttons
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Price: ${data['price'].toInt()} RON',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: darkBlueColor),
                                ),
                                Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => _editProduct(
                                          context, document.id, data),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: darkBlueColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                      ),
                                      child: const Text('Edit',
                                          style: TextStyle(fontSize: 12)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _deleteProduct(document.id),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                      ),
                                      child: const Text('Delete',
                                          style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
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
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Users')
                .doc(userId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                print('Error checking subscription: ${snapshot.error}');
                return const SizedBox();
              }

              bool hasActiveSubscription = false;
              if (snapshot.hasData && snapshot.data != null) {
                Map<String, dynamic>? userData = 
                    snapshot.data!.data() as Map<String, dynamic>?;
                
                if (userData != null && 
                    userData['subscription'] != null &&
                    userData['subscription'] is Map) {
                  hasActiveSubscription = 
                      userData['subscription']['status'] == 'active';
                }
              }

              return Stack(
                children: [
                  ElevatedButton(
                    onPressed: hasActiveSubscription 
                        ? () => _addProduct(context)
                        : () => _showSubscriptionDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkBlueColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      hasActiveSubscription ? "Add Product" : "Subscribe to Add Product",
                      style: const TextStyle(fontSize: 14)
                    ),
                  ),
                  if (!hasActiveSubscription)
                    Positioned(
                      right: 12,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Icon(
                          Icons.lock,
                          color: Colors.white.withOpacity(0.8),
                          size: 20,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _editProduct(BuildContext context, String productId, Map<String, dynamic> currentData) {
    String name = currentData['name'];
    String description = currentData['description'];
    double price = currentData['price'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(hintText: 'Product Name'),
                  onChanged: (value) => name = value,
                  controller: TextEditingController(text: name),
                ),
                TextField(
                  decoration: const InputDecoration(hintText: 'Description'),
                  onChanged: (value) => description = value,
                  controller: TextEditingController(text: description),
                ),
                TextField(
                  decoration: const InputDecoration(hintText: 'Price'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => price = double.tryParse(value) ?? price,
                  controller: TextEditingController(text: price.toString()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                if (name.isNotEmpty && description.isNotEmpty && price > 0) {
                  FirebaseFirestore.instance
                      .collection('Users')
                      .doc(userId)
                      .collection('Products')
                      .doc(productId)
                      .update({
                    'name': name,
                    'description': description,
                    'price': price,
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Product updated successfully")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteProduct(String productId) {
    FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('Products')
        .doc(productId)
        .delete()
        .then((value) => print("Product Deleted"))
        .catchError((error) => print('Failed to delete product: $error'));
  }

  void _showFullDescription(BuildContext context, String title, String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(description),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  int _getWordCount(String text) {
    return text.split(' ').where((word) => word.isNotEmpty).length;
  }

  String? _getWordCountError(String text) {
    int wordCount = _getWordCount(text);
    if (wordCount > 55) {
      return 'Description should not exceed 55 words. Current: $wordCount';
    }
    return null;
  }

  Future<Widget> _getImageWidget(String? photoUrl) async {
    print('PhotoUrl: $photoUrl'); // Debug print
    if (photoUrl == null || photoUrl.isEmpty) {
      return Container(
        height: 100,
        width: 100,
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported),
      );
    }

    try {
      final response = await http.get(Uri.parse(photoUrl));
      if (response.statusCode == 200) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            response.bodyBytes,
            height: 100,
            width: 100,
            fit: BoxFit.cover,
          ),
        );
      } else {
        print('Failed to load image. Status code: ${response.statusCode}');
        return Container(
          height: 100,
          width: 100,
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        );
      }
                      } catch (e) {
      print('Error loading image: $e');
      return Container(
        height: 100,
        width: 100,
        color: Colors.grey[300],
        child: const Icon(Icons.error),
      );
    }
  }

  void _showSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Subscription Required'),
          backgroundColor: Colors.white,
          content: const Text(
            'You need an active subscription to add products. Would you like to subscribe now?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Not Now'),
            ),
            TextButton(
              onPressed: () {
                        Navigator.pop(context);
                // Navigate to SubscriptionPlanPost
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SubscriptionPlanPost()),
                );
              },
              child: const Text('Subscribe'),
            ),
          ],
        );
      },
    );
  }
}

class ReviewsTab extends StatelessWidget {
  final String userId;
  final StreamController<double> averageRatingController;

  const ReviewsTab({super.key, required this.userId, required this.averageRatingController});

  Stream<QuerySnapshot> get reviewsStream => FirebaseFirestore.instance
      .collection("Users")
      .doc(userId)
      .collection("BusinessAccount")
      .doc("detail")
      .collection("reviews")
      .orderBy("timestamp", descending: true)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: reviewsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          averageRatingController.add(0);
          return const Center(child: Text('No reviews yet'));
        }

        double totalRating = 0;
        int reviewCount = snapshot.data!.docs.length;

        for (var doc in snapshot.data!.docs) {
          totalRating += (doc['rating'] as num).toDouble();
        }

        double averageRating = totalRating / reviewCount;
        averageRatingController.add(averageRating);

        return ListView.builder(
          padding: EdgeInsets.zero, // Remove default padding
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var review = snapshot.data!.docs[index];
            return _buildReviewItem(review);
          },
        );
      },
    );
  }

  Widget _buildReviewItem(DocumentSnapshot review) {
    var data = review.data() as Map<String, dynamic>;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.white, // Set the card color to white
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(data['avatarUrl'] ?? ''),
                  radius: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['reviewerName'] ?? 'Anonymous',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        data['timestamp']?.toDate().toString().split(' ')[0] ??
                            'No date',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${data['rating']?.toStringAsFixed(1) ?? 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(data['comment'] ?? 'No comment'),
          ],
        ),
      ),
    );
  }
}

