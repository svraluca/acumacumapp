import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:share_plus/share_plus.dart';
import 'package:acumacum/ui/chatScreen.dart';
import 'package:acumacum/ui/other_users_map.dart';
import 'package:acumacum/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart';
import 'package:acumacum/ui/OrderPage.dart';

class UserProfiles extends StatefulWidget {
  final String serviceProviderId;
  final String userName;
  final String? avatarUrl;
  final String address;
  final String? categoryName;
  final ScrollController? scrollController;

  const UserProfiles(this.serviceProviderId, this.userName, this.avatarUrl,
      this.address, this.categoryName,
      {this.scrollController, super.key});

  @override
  State<UserProfiles> createState() => UserProfilesState();
}

class UserProfilesState extends State<UserProfiles>
    with TickerProviderStateMixin {
  bool _isFavorite = false;
  late String facebookUrl;
  late String instagramUrl;
  late String tikTokUrl;
  late String myId;
  var addresses;
  var first;
  late double lat;
  late double long;
  String? precise_address;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ScrollController? _scrollController;
  late TabController _tabController;
  Map<String, dynamic>? scheduleData;
  double averageRating = 0.0;
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    myId = FirebaseAuth.instance.currentUser!.uid;
    _tabController = TabController(length: 3, vsync: this);
    FirebaseFirestore.instance
        .collection("Users")
        .doc(myId)
        .collection("favorites")
        .get()
        .then(
      (value) {
        for (DocumentSnapshot doc in value.docs) {
          if ((doc.data() as Map<String, dynamic>)["id"] ==
              widget.serviceProviderId) {
            setState(() {
              _isFavorite = true;
            });
          }
        }
        return value.docs;
      },
    );

    getSocialData();
    _scrollController = widget.scrollController ?? ScrollController();
    fetchScheduleData();
    fetchAverageRating();
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (widget.scrollController == null) {
      _scrollController?.dispose();
    }
    super.dispose();
  }

  void viewReview(var ratings, String name, String review, String avatarUrl) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: const Duration(
        milliseconds: 400,
      ), // how long it takes to popup dialog after button click
      pageBuilder: (_, __, ___) {
        // your widget implementation
        return Container(
          color: Colors.black.withOpacity(0.4),
          child: ListView(
            children: [
              Container(
                // width: 200,
                // margin: EdgeInsets.only(
                //     top: 8, bottom: 8, right: 12),
                margin: const EdgeInsets.only(right: 12, top: 8, bottom: 0),
                padding: const EdgeInsets.all(11),
                // width: MediaQuery.of(context)
                //         .size
                //         .width -
                //     140,
                decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                          spreadRadius: 1)
                    ],
                    borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(avatarUrl),
                        ),
                        const SizedBox(width: 4),
                        Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.0,
                                color: Colors.black)),
                        const SizedBox(width: 45),
                        _buildRatingStars(ratings)
                      ],
                    ),
                    // Row(
                    //   children: [
                    //     _buildRatingStars(snapshot
                    //         .data
                    //         .documents[index]
                    //         .data["rating"]),
                    //   ],
                    // ),
                    // Text(
                    //     snapshot
                    //         .data
                    //         .documents[index]
                    //         .data["text"],
                    //     overflow:
                    //         TextOverflow.ellipsis,
                    //     textScaleFactor: 1.1),
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: MediaQuery.of(context).size.width - 140,
                      child: Text(
                        review,
                        textScaleFactor: 1.1,
                        style: const TextStyle(
                            fontSize: 12.0, color: Colors.black),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        shape: const StadiumBorder(),
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewItem(DocumentSnapshot review) {
    var data = review.data() as Map<String, dynamic>;
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    String reviewerId = data['reviewerId'] ?? '';

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('Users').doc(reviewerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        String reviewerName = snapshot.data!.get('name') ?? 'Anonymous';

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reviewerName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            data['timestamp']?.toDate().toString() ?? 'No date',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
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
                    if (currentUserId == reviewerId)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteReview(review.id),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(data['comment'] ?? 'No comment'),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteReview(String reviewId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Review"),
          content: const Text("Are you sure you want to delete this review?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Delete"),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  DocumentSnapshot reviewDoc = await FirebaseFirestore.instance
                      .collection("Users")
                      .doc(widget.serviceProviderId)
                      .collection("BusinessAccount")
                      .doc("detail")
                      .collection("reviews")
                      .doc(reviewId)
                      .get();

                  if (reviewDoc.exists) {
                    Map<String, dynamic> reviewData =
                        reviewDoc.data() as Map<String, dynamic>;
                    String currentUserId =
                        FirebaseAuth.instance.currentUser?.uid ?? '';

                    if (currentUserId == reviewData['reviewerId']) {
                      await reviewDoc.reference.delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Review deleted successfully")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                "You don't have permission to delete this review")),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Review not found")),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to delete review: $e")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildServiceItem(QueryDocumentSnapshot service, bool isFirstItem) {
    String serviceId = service.id;
    String serviceName =
        (service.data() as Map<String, dynamic>)['name'] ?? 'Unnamed Service';
    String servicePrice = (service.data() as Map<String, dynamic>)['price']?.toString().split('.')[0] ?? 'N/A';
    String serviceDescription =
        (service.data() as Map<String, dynamic>)['description'] ??
            'No description available';
    String photoUrl =
        (service.data() as Map<String, dynamic>)['photoUrl'] ?? '';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
            ),
            child: photoUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image: $error');
                        return const Icon(Icons.error, size: 40);
                      },
                    ),
                  )
                : const Icon(Icons.image_not_supported, size: 40),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _showDescriptionDialog(
                      context, serviceName, serviceDescription),
                  child: Text(
                    serviceDescription,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${servicePrice}RON',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  if (currentUserId != widget.serviceProviderId) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          serviceProviderId: widget.serviceProviderId,
                          userName: widget.userName,
                          avatarUrl: widget.avatarUrl ?? '',
                          price: servicePrice,
                          serviceName: serviceName,
                          serviceId: serviceId,
                          photoUrl: photoUrl,
                          directBooking: true,
                          isServiceMessage: false,
                          showConfirmation: false,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Booking hanya tersedia untuk client.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text(
                  'BOOK',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  // Function to display booking pop-up
  void _showCupertinoBookingPopup(
      BuildContext context,
      String serviceProviderId,
      String serviceId,
      String serviceName,
      String servicePrice) {
    print("Service Name di Cupertino Booking Popup: $serviceName"); // Debug
    print("serviceId: $serviceId, serviceName: $serviceName");
    DateTime selectedDateTime = DateTime.now();

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  "Select Date & Time",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  initialDateTime: DateTime.now(),
                  mode: CupertinoDatePickerMode.dateAndTime,
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime newDateTime) {
                    selectedDateTime = newDateTime;
                  },
                ),
              ),
              CupertinoButton(
                child: const Text("Confirm"),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Tambahkan parameter serviceId dan serviceName saat membuka ChatScreen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        serviceProviderId: serviceProviderId,
                        userName: widget.userName,
                        avatarUrl: widget.avatarUrl ?? '',
                        price: servicePrice,
                        serviceName:
                            serviceName, // Pastikan serviceName diteruskan
                        serviceId: serviceId, // Pastikan serviceId diteruskan
                        initialBookingDateTime: selectedDateTime.toString(),
                        directBooking: true,
                      ),
                    ),
                  );
                },
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductItem(QueryDocumentSnapshot product, bool isFirstItem) {
    String productName =
        (product.data() as Map<String, dynamic>)['name'] ?? 'Unnamed Product';
    String productPrice = (product.data() as Map<String, dynamic>)['price']?.toString().split('.')[0] ?? 'N/A';
    String productDescription =
        (product.data() as Map<String, dynamic>)['description'] ??
            'No description available';
    String imageUrl =
        (product.data() as Map<String, dynamic>)['photoUrl'] ?? '';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
            ),
            child: imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image: $error');
                        return const Icon(Icons.error, size: 40);
                      },
                    ),
                  )
                : const Icon(Icons.image_not_supported, size: 40),
          ),
          const SizedBox(width: 16),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _showDescriptionDialog(
                      context, productName, productDescription),
                  child: Text(
                    productDescription,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Price and Order Button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${productPrice}RON',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderPage(
                        productName: productName,
                        productPrice: productPrice,
                        productId: product.id,
                        sellerId: widget.serviceProviderId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text(
                  'ORDER',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDescriptionDialog(
      BuildContext context, String serviceName, String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(serviceName),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: ListView(
        controller: _scrollController,
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Cover Photo with Message and Favorite buttons
          Stack(
            children: <Widget>[
              Container(
                height: MediaQuery.of(context).size.height * 0.3,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      (widget.avatarUrl != null &&
                              widget.avatarUrl != 'default')
                          ? widget.avatarUrl!
                          : "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png",
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              // Back button
              Positioned(
                left: 8,
                top: 48,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
              // Favorite button
              Positioned(
                right: 8,
                top: 48,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: () async {
                      if (_isFavorite) {
                        QuerySnapshot snapshot = await FirebaseFirestore
                            .instance
                            .collection("Users")
                            .doc(myId)
                            .collection("favorites")
                            .get();
                        for (DocumentSnapshot snpsht in snapshot.docs) {
                          if ((snpsht.data() as Map<String, dynamic>)["id"] ==
                              widget.serviceProviderId) {
                            snpsht.reference.delete();
                          }
                        }
                      } else {
                        FirebaseFirestore.instance
                            .collection("Users")
                            .doc(myId)
                            .collection("favorites")
                            .add({"id": widget.serviceProviderId});
                      }
                      setState(() {
                        _isFavorite = !_isFavorite;
                      });
                    },
                  ),
                ),
              ),
              // Message button
              Positioned(
                right: 8,
                bottom: 16,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          serviceProviderId: widget.serviceProviderId,
                          userName: widget.userName,
                          avatarUrl: widget.avatarUrl ?? '',
                          price: 'N/A',
                          directBooking: false,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.5),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.message, size: 18),
                      SizedBox(width: 4),
                      Text(
                        "Message",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Rest of the content
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            child: Column(
              children: [
                // Social media icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSocialButton('assets/images/tiktok.png',
                        () => _launchUrl(tikTokUrl, context)),
                    _buildSocialButton('assets/images/instagram.png',
                        () => _launchUrl(instagramUrl, context)),
                    _buildSocialButton('assets/images/facebook.png',
                        () => _launchUrl(facebookUrl, context)),
                    _buildSocialButton(
                        'assets/images/googlemap.png', () => _openMap(context)),
                    _buildShareButton(),
                  ],
                ),
                const SizedBox(height: 16),
                // Username, address, and schedule
                Container(
                  padding: const EdgeInsets.fromLTRB(
                      12, 25, 12, 25), // Reduced right padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.userName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          if (averageRating > 0)
                            Row(
                              mainAxisSize: MainAxisSize
                                  .min, // Added to minimize row width
                              children: [
                                _buildRatingStars(averageRating),
                                const SizedBox(width: 2), // Reduced from 4 to 2
                                Text(
                                  averageRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.address == "default"
                            ? "No Address yet"
                            : widget.address,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      buildScheduleDisplay(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                // TabBar
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Services'),
                    Tab(text: 'Products'),
                    Tab(text: 'Reviews'),
                  ],
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                ),
                // TabBarView
                SizedBox(
                  height: MediaQuery.of(context).size.height *
                      0.5, // Adjust this value as needed
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Services Tab
                      Padding(
                        padding: EdgeInsets.zero,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("Users")
                              .doc(widget.serviceProviderId)
                              .collection("Services")
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                  child: Text('No services available'));
                            }
                            return ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: snapshot.data!.docs.length,
                              separatorBuilder: (context, index) =>
                                  Divider(height: 1, color: Colors.grey[300]),
                              itemBuilder: (context, index) {
                                var service = snapshot.data!.docs[index];
                                return _buildServiceItem(service, index == 0);
                              },
                            );
                          },
                        ),
                      ),
                      // Products Tab
                      Padding(
                        padding: EdgeInsets.zero,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("Users")
                              .doc(widget.serviceProviderId)
                              .collection("Products")
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                  child: Text('No products available'));
                            }
                            return ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: snapshot.data!.docs.length,
                              separatorBuilder: (context, index) =>
                                  Divider(height: 1, color: Colors.grey[300]),
                              itemBuilder: (context, index) {
                                var product = snapshot.data!.docs[index];
                                return _buildProductItem(product, index == 0);
                              },
                            );
                          },
                        ),
                      ),
                      // Reviews Tab
                      Container(
                        color: Colors.white,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Reviews",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _addReviewBottomSheet(context);
                                    },
                                    child: const Text("Add Review"),
                                  )
                                ],
                              ),
                            ),
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection("Users")
                                    .doc(widget.serviceProviderId)
                                    .collection("BusinessAccount")
                                    .doc("detail")
                                    .collection("reviews")
                                    .orderBy("timestamp", descending: true)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }
                                  if (snapshot.hasError) {
                                    return Center(
                                        child:
                                            Text('Error: ${snapshot.error}'));
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty) {
                                    return const Center(
                                        child: Text('No reviews yet'));
                                  }
                                  return ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: snapshot.data!.docs.length,
                                    itemBuilder: (context, index) {
                                      return _buildReviewItem(
                                          snapshot.data!.docs[index]);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addReviewBottomSheet(BuildContext context) {
    String reviewerName =
        FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous';
    String? reviewerAvatarUrl = FirebaseAuth.instance.currentUser?.photoURL;
    TextEditingController reviewController = TextEditingController();
    int rating = 1;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return StatefulBuilder(
          builder: (context, setState) => SizedBox(
            height: MediaQuery.of(context).size.height * .60,
            child: Padding(
              padding: const EdgeInsets.only(left: 15.0, top: 10.0),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Text("Add review"),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.cancel),
                        color: Colors.orange,
                        iconSize: 25,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      )
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 15.0),
                          child: TextField(
                            controller: reviewController,
                            decoration: const InputDecoration(
                              helperText: "Review",
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Expanded(flex: 4, child: Text("Stars given: ")),
                      Expanded(
                        flex: 6,
                        child: DropdownButton<int>(
                          value: rating,
                          items: List<DropdownMenuItem<int>>.generate(
                            5,
                            (index) => DropdownMenuItem<int>(
                              value: index + 1,
                              child: _buildRatingStars(index + 1),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() => rating = value!);
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          if (widget.serviceProviderId == 'defaultId') {
                            // Jika ID tidak valid, cetak pesan error dan keluar
                            print(
                                "Invalid serviceProviderId, cannot add review.");
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Error: Invalid service provider ID.")));
                            return;
                          }

                          print(
                              'Adding review for user: ${widget.serviceProviderId}');

                          // Menambahkan review ke Firestore di bawah ID yang benar
                          await FirebaseFirestore.instance
                              .collection("Users")
                              .doc(widget.serviceProviderId)
                              .collection("BusinessAccount")
                              .doc("detail")
                              .collection("reviews")
                              .add({
                            "reviewerName": reviewerName,
                            "reviewerId":
                                FirebaseAuth.instance.currentUser?.uid,
                            "rating": rating,
                            "comment": reviewController.text,
                            "timestamp": FieldValue.serverTimestamp(),
                            "avatarUrl": reviewerAvatarUrl,
                          });

                          print('Review added successfully');
                          Navigator.of(context).pop();
                        },
                        child: const Text('Save'),
                      )
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

  void getSocialData() {
    DocumentReference reference = FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.serviceProviderId)
        .collection('Social')
        .doc('detail');
    reference.snapshots().listen((event) {
      setState(() {
        facebookUrl = event.data() == null
            ? ""
            : (event.data() as Map<String, dynamic>)['facebook'];
        instagramUrl = event.data() == null
            ? ""
            : (event.data() as Map<String, dynamic>)['instagram'];
        tikTokUrl = event.data() == null
            ? ""
            : (event.data() as Map<String, dynamic>)['tiktok'];
      });
    });
    DocumentReference reference1 = FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.serviceProviderId);
    reference1.snapshots().listen((event) {
      setState(() {
        precise_address = event.data() == null
            ? null
            : (event.data() as Map<String, dynamic>)['precise_location'];
      });
    });
  }

  Future<void> _launchUrl(String? url, BuildContext context) async {
    if (url == null || url.isEmpty) {
      await Alert(
        context: context,
        type: AlertType.warning,
        title: "Social Link error",
        desc: "User have not provided social link",
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

  void fetchScheduleData() {
    print(
        "Fetching schedule for user ID: ${widget.serviceProviderId}"); // Debug print
    FirebaseFirestore.instance
        .collection("Users")
        .doc(widget.serviceProviderId)
        .get()
        .then((docSnapshot) {
      if (docSnapshot.exists) {
        print(
            "Document data: ${docSnapshot.data()}"); // Debug print of entire document
        var data = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          scheduleData = data['schedule'] as Map<String, dynamic>?;
          print("Fetched schedule data: $scheduleData"); // Debug print

          // Check for schedule data in different locations
          if (scheduleData == null) {
            print(
                "Schedule data not found in 'schedule' field. Checking other locations...");
            scheduleData = data['BusinessAccount'] as Map<String, dynamic>?;
            print("BusinessAccount data: $scheduleData");
            if (scheduleData != null && scheduleData!.containsKey('detail')) {
              scheduleData = scheduleData!['detail'] as Map<String, dynamic>?;
              print("BusinessAccount detail data: $scheduleData");
            }
          }

          // If still null, check for individual fields
          if (scheduleData == null) {
            print("Checking for individual schedule fields...");
            var openTime = data['openTime'] ?? data['timeOpen'];
            var closeTime = data['closeTime'] ?? data['timeClosed'];
            var workDays = data['workDays'] ?? data['workingDays'];
            if (openTime != null && closeTime != null) {
              scheduleData = {
                'openTime': openTime,
                'closeTime': closeTime,
                'workDays': workDays
              };
              print(
                  "Constructed schedule data from individual fields: $scheduleData");
            }
          }
        });
      } else {
        print("Document does not exist"); // Debug print
      }
    }).catchError((error) {
      print("Error fetching schedule data: $error");
    });
  }

  Widget buildScheduleDisplay() {
    if (scheduleData == null || scheduleData!.isEmpty) {
      return Text('Schedule not available',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]));
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Working Schedule:',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800]),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Working Hours:$openTime - $closeTime',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Working days: $workDays',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton(String assetPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Image.asset(
          assetPath,
          width: 24,
          height: 24,
        ),
      ),
    );
  }

  Widget _buildShareButton() {
    return GestureDetector(
      onTap: () async {
        Share.share(
          '${widget.userName} located in ${widget.address} invites you to their acumacum business profile with the following app link https://acumacum.page.link/29hQ.',
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(FontAwesomeIcons.share, size: 24),
      ),
    );
  }

  void _openMap(BuildContext context) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.serviceProviderId)
          .get();

      // Check if the document exists and contains the 'precise_address' field
      if (!userDoc.exists || !userDoc.data().toString().contains('precise_address')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('There is no precise address added by the user'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.grey,
          ),
        );
        return;
      }

      String? preciseAddress = userDoc.get('precise_address') as String?;

      if (preciseAddress == null || preciseAddress.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('There is no precise address available'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.grey,
          ),
        );
        return;
      }

      Alert(
        context: context,
        type: AlertType.none,
        title: "Address",
        style: const AlertStyle(
          backgroundColor: Colors.white,
          titleStyle: TextStyle(color: Colors.black),
          isCloseButton: true,
          isOverlayTapDismiss: true,
        ),
        content: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                preciseAddress,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: preciseAddress));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Address copied to clipboard'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Address'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        buttons: [],
      ).show();

    } catch (e) {
      print('Error in _openMap: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('There is no precise address added by the user'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.grey,
          ),
        );
      }
    }
  }

  void fetchAverageRating() {
    print("Fetching average rating for user: ${widget.serviceProviderId}");
    FirebaseFirestore.instance
        .collection("Users")
        .doc(widget.serviceProviderId)
        .collection("BusinessAccount")
        .doc("detail")
        .collection("reviews")
        .get()
        .then((querySnapshot) {
      print("Number of reviews: ${querySnapshot.docs.length}");
      if (querySnapshot.docs.isNotEmpty) {
        double totalRating = 0;
        for (var doc in querySnapshot.docs) {
          var rating = doc.data()['rating'];
          print("Review rating: $rating");
          totalRating += (rating as num).toDouble();
        }
        setState(() {
          averageRating = totalRating / querySnapshot.docs.length;
          print("Calculated average rating: $averageRating");
        });
      } else {
        print("No reviews found");
      }
    }).catchError((error) {
      print("Error fetching reviews: $error");
    });
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor() ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }

  void _showAvailableSlots(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.serviceProviderId)
            .collection('availableSlots')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return const AlertDialog(
              title: Text('Error'),
              content: Text('Failed to load available slots'),
            );
          }

          List<QueryDocumentSnapshot> slots = snapshot.data?.docs ?? [];

          return AlertDialog(
            title: const Text('Available Slots'),
            content: slots.isEmpty
                ? const Text('No available slots')
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: slots.map((slot) {
                        DateTime date = (slot['date'] as Timestamp).toDate();
                        List<dynamic> slotList = slot['slots'];
                        return ExpansionTile(
                          title: Text(date.toString().split(' ')[0]),
                          children: slotList.map<Widget>((timeSlot) {
                            DateTime startTime =
                                (timeSlot['startTime'] as Timestamp).toDate();
                            DateTime endTime =
                                (timeSlot['endTime'] as Timestamp).toDate();
                            return ListTile(
                              title: Text(
                                  '${_formatTime(startTime)} - ${_formatTime(endTime)}'),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

Text _buildRatingStars(int rating) {
  String stars = '';
  for (int i = 0; i < rating; i++) {
    stars += '⭐ ';
  }
  stars.trim();
  return Text(
    stars,
    style: const TextStyle(fontSize: 12.0),
  );
}
