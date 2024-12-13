import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:acumacum/ui/viewProfiles.dart' as view_profiles;
import 'package:translator/translator.dart';
import 'HomePage.dart';
import 'UserProfiles.dart';
import 'package:acumacum/ui/viewProfiles.dart';  // For StoryProfiles
import 'package:google_fonts/google_fonts.dart';

class TransportScreen extends StatefulWidget {
  final String serviceName;
  final List<String> location;
  final String image;

  const TransportScreen(this.serviceName, this.location, this.image,
      {super.key});

  @override
  TransportState createState() => TransportState();
}

class TransportState extends State<TransportScreen> {
  String? userId;
  var categorySplit;
  int checkIndex = 0;
  bool load = false;
  int count = 0;
  bool check = false;
  bool loadingQrUser = false;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  List<DocumentSnapshot<Map<String, dynamic>>> usersList = [];
  bool loadingUsers = true;

  var now;
  var date;
  bool subscriptionExpired = false;
  var diff;

  String? selectedCity;
  bool isFilterVisible = false;
  TextEditingController cityFilterController = TextEditingController();

  final List<String> romanianCities = [
    "Adjud", "Alba Iulia", "Alexandria", "Arad", "Avrig",
    "București", "Cluj-Napoca", "Timișoara", "Iași", "Constanța",
    "Craiova", "Brașov", "Galați", "Ploiești", "Oradea",
    "Brăila", "Pitești", "Sibiu", "Bacău",
    // Add more Romanian cities as needed...
  ];

  bool isSearching = false;
  TextEditingController searchController = TextEditingController();

  String? selectedSubcategory;
  List<String> subcategories = [];

  Future<void> loadSubcategories() async {
    try {
      print("Loading subcollections for: ${widget.serviceName}");
      
      // Get the subcollections directly from the main collection
      var mainCollectionRef = FirebaseFirestore.instance.collection(widget.serviceName);
      var mainCollectionDocs = await mainCollectionRef.get();
      
      Set<String> uniqueSubcategories = {};
      
      // Add each document's subcategory field value
      for (var doc in mainCollectionDocs.docs) {
        var data = doc.data();
        if (data.containsKey('subcategory')) {
          String? subcategory = data['subcategory'] as String?;
          if (subcategory != null && subcategory.isNotEmpty) {
            uniqueSubcategories.add(subcategory);
          }
        }
      }

      print("Found subcategories: $uniqueSubcategories");

      setState(() {
        subcategories = uniqueSubcategories.toList()..sort();
      });
    } catch (e) {
      print("Error loading subcategories: $e");
    }
  }

  void showSubcategoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar at the top
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              const Padding(
                padding: EdgeInsets.only(left: 16, bottom: 16),
                child: Text(
                  'Select Subcategory',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              // Divider
              const Divider(height: 1),
              // List of subcategories
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: subcategories.length,
                  itemBuilder: (context, index) {
                    final subcategory = subcategories[index];
                    final isSelected = selectedSubcategory == subcategory;
                    
                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedSubcategory = subcategory;
                        });
                        Navigator.pop(context);
                        getServiceProviderProfile();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black.withOpacity(0.1) : null,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Radio dot
                            Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.black : Colors.grey,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            // Subcategory name
                            Expanded(
                              child: Text(
                                subcategory,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isSelected ? Colors.black : Colors.black87,
                                  fontWeight: isSelected 
                                      ? FontWeight.w600 
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Bottom buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (selectedSubcategory != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedSubcategory = null;
                          });
                          Navigator.pop(context);
                          getServiceProviderProfile();
                        },
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
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

  void _onRefresh() async {
    // monitor network fetch
    checkIndex = 0;
    count += 7;
    print(count);
    if (usersList.length < count) {
      setState(() {
        count = 0;
      });
    }
    await getServiceProviderProfile();
    // if failed,use refreshFailed()
    _refreshController.refreshCompleted();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    // Initialize userId from FirebaseAuth
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      userId = currentUser.uid;
      print("User ID from FirebaseAuth: $userId");
    } else {
      print("User is not logged in or FirebaseAuth did not return a user.");
    }

    loadSubcategories();
    getServiceProviderProfile();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    count = 0;
    updatePromo();
    FirebaseFirestore.instance
        .collection("Category SuperUser")
        .doc('$userId')
        .get()
        .then((value) {
      if (value.exists) {
        subscriptionExpired =
            (value.data() as Map<String, dynamic>)['expired'] ?? "";
        if (subscriptionExpired == true) {
        } else {
          checkSubscription();
        }
      }
    });
  }

  Future<void> updatePromo() async {
    FirebaseFirestore.instance
        .collection('Users')
        .get()
        .then((QuerySnapshot<Map<String, dynamic>> querySnapshot) async {
      for (var doc in querySnapshot.docs) {
        var value = await FirebaseFirestore.instance
            .collection('Category SuperUser')
            .doc(doc.id)
            .get();
            
        if (value.exists) {
          subscriptionExpired = value.data()?['expired'] ?? "";
          now = DateTime.now();
          date = DateTime.fromMillisecondsSinceEpoch(
              (value.data() as Map<String, dynamic>)['expired_on']);
          diff = date.difference(now);

          if (diff.inDays >= 0 && diff.inHours >= 0) {
            logger.e("updatePromo ${value.data()!['expired']}");
            await FirebaseFirestore.instance
                .collection('Category SuperUser')
                .doc(doc.id)
                .update({
                  "expired": false,
                  "notified": false,
                });
          } else {
            await FirebaseFirestore.instance
                .collection('Category SuperUser')
                .doc(doc.id)
                .update({
                  "expired": true,
                  "plan": "",
                  "notified": true,
                });
          }
        }
      }
    });
  }

  Future<void> checkSubscription() async {
    var value = await FirebaseFirestore.instance
        .collection('Category SuperUser')
        .doc('$userId')
        .get();
        
    if (value.exists) {
      setState(() {
        subscriptionExpired = (value.data() as Map)['expired'];
        now = DateTime.now();
        date = DateTime.fromMillisecondsSinceEpoch(
            (value.data as Map)['expired_on']);
        diff = date.difference(now);
      });
      
      if (subscriptionExpired == true) {
      } else {
        if ((diff.inHours - (diff.inDays * 24)) <= 0 && diff.inDays < 0) {
          await FirebaseFirestore.instance
              .collection('Category SuperUser')
              .doc('$userId')
              .update({
                "expired": true,
                "plan": "",
                "notified": true,
              });
        }
      }
    }
  }

  List<DocumentSnapshot<Map<String, dynamic>>> filterUsersByCity(List<DocumentSnapshot<Map<String, dynamic>>> users) {
    if (selectedCity == null || selectedCity!.isEmpty) {
      return users;
    }
    return users.where((user) {
      final userData = user.data();
      if (userData == null) return false;
      final userAddress = userData['address'] as String?;
      if (userAddress == null) return false;
      return userAddress.toLowerCase().contains(selectedCity!.toLowerCase());
    }).toList();
  }

  String removeDiacritics(String str) {
    var withDia = 'ăâîșțĂÂÎȘȚ';
    var withoutDia = 'aaistzAAIST';
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }
    return str;
  }

  Future<void> getServiceProviderProfile() async {
    try {
      print("Starting getServiceProviderProfile...");
      print("Selected subcategory: $selectedSubcategory");
      print("Selected city: $selectedCity");
      print("Current category: ${widget.serviceName}");
      
      setState(() {
        loadingUsers = true;
      });

      // Get all business users from the specific category collection first
      var categorySnapshot = await FirebaseFirestore.instance
          .collection(widget.serviceName)
          .get();

      print("Found ${categorySnapshot.docs.length} documents in ${widget.serviceName}");

      List<DocumentSnapshot<Map<String, dynamic>>> allUsers = [];
      
      // For each document in the category
      for (var categoryDoc in categorySnapshot.docs) {
        var categoryData = categoryDoc.data();
        
        // Check subcategory filter first
        if (selectedSubcategory != null && selectedSubcategory!.isNotEmpty) {
          String? docSubcategory = categoryData['subcategory'] as String?;
          if (docSubcategory != selectedSubcategory) {
            continue; // Skip if subcategory doesn't match
          }
        }

        // Get the corresponding user document
        var userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(categoryDoc.id)
            .get();

        if (userDoc.exists) {
          var userData = userDoc.data();
          if (userData != null && userData['userRole'] == 'Business') {
            String? userAddress = userData['address'] as String?;
            String? userName = userData['name'] as String?;
            
            print("Found business user: $userName with address: $userAddress");
            
            // Apply city filter if selected
            if (selectedCity != null && selectedCity!.isNotEmpty) {
              if (userAddress != null) {
                // Remove diacritics from both the user's address and the selected city
                String normalizedAddress = removeDiacritics(userAddress.toLowerCase());
                String normalizedCity = removeDiacritics(selectedCity!.toLowerCase());
                
                bool cityMatches = normalizedAddress.contains(normalizedCity);
                
                if (cityMatches) {
                  print("Adding user $userName - matches city filter");
                  allUsers.add(userDoc);
                } else {
                  print("Skipping user $userName - doesn't match city filter");
                }
              }
            } else {
              // No city filter, add all business users that passed subcategory filter
              print("Adding user $userName - no city filter");
              allUsers.add(userDoc);
            }
          }
        }
      }

      print("\nTotal users found before promotion check: ${allUsers.length}");

      // Sort into promoted and regular users
      List<DocumentSnapshot<Map<String, dynamic>>> promotedUsers = [];
      List<DocumentSnapshot<Map<String, dynamic>>> regularUsers = [];

      DateTime now = DateTime.now();

      for (var doc in allUsers) {
        var userData = doc.data();
        bool isPromoted = false;

        if (userData != null && 
            userData['category_promotions'] != null && 
            userData['category_promotions'] is List) {
          List promotions = userData['category_promotions'];
          for (var promo in promotions) {
            DateTime? startDate = promo['startDate']?.toDate();
            DateTime? endDate = promo['endDate']?.toDate();
            
            if (startDate != null && 
                endDate != null && 
                promo['status'] == 'active' &&
                now.isAfter(startDate) && 
                now.isBefore(endDate)) {
              promotedUsers.add(doc);
              isPromoted = true;
              break;
            }
          }
        }

        if (!isPromoted) {
          regularUsers.add(doc);
        }
      }

      print("Promoted users: ${promotedUsers.length}");
      print("Regular users: ${regularUsers.length}");

      setState(() {
        usersList = [...promotedUsers, ...regularUsers];
        loadingUsers = false;
      });

    } catch (e, stackTrace) {
      print("Error in getServiceProviderProfile: $e");
      print("Stack trace: $stackTrace");
      setState(() {
        loadingUsers = false;
      });
    }
  }

  // Update the extractCity function to be more flexible
  String? extractCity(String? address) {
    if (address == null) return null;
    
    // Normalize the address: remove extra spaces, convert to lowercase
    String normalizedAddress = address.toLowerCase().trim();
    
    // Handle common variations
    if (normalizedAddress.contains('bucuresti') || 
        normalizedAddress.contains('bucurești') ||
        normalizedAddress.contains('bucharest')) {
      return 'București';
    }

    // Handle other cities similarly
    for (String city in romanianCities) {
      String normalizedCity = city.toLowerCase();
      if (normalizedAddress.contains(normalizedCity)) {
        return city;
      }
    }
    
    return null;
  }

  void _onLoading() async {
    // monitor network fetch
    // if failed,use loadFailed(),if no data return,use LoadNodata()

    if (mounted) setState(() {});
    _refreshController.loadComplete();
  }

  // @override
  // void didChangeDependencies() async {
  //   super.didChangeDependencies();
  //   await update();
  // }

  String? serviceProviderId;

  Text _buildRatingStars(int rating) {
    String stars = '';
    for (int i = 0; i < rating; i++) {
      stars += '⭐ ';
    }
    stars.trim();
    return Text(stars);
  }

  Future update() async {
    FirebaseFirestore.instance
        .collection(widget.serviceName)
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) async {
        print(doc["id"]);
        // var doc = await FirebaseFirestore.instance
        //     .collection('Users')
        //     .doc(doc["id"])
        //     .get();
        // var location = doc.data['address'];
        // var country = doc.data['country'];
        // await FirebaseFirestore.instance
        //     .collection(widget.serviceName)
        //     .doc(doc["id"])
        //     .updateData({
        //   'address': location,
        //   'country': country,
        // });
        // FirebaseFirestore.instance
        //     .collection('Home SuperUser')
        //     .doc(doc["id"])
        //     .setData({
        //   'user': doc["id"],
        //   'expired_on': new DateTime.now()
        //       .add(new Duration(days: 7))
        //       .millisecondsSinceEpoch,
        //   'plan': 'free',
        //   'notified': false,
        //   'expired': false,
        // });

        // FirebaseFirestore.instance
        //     .collection('Category SuperUser')
        //     .doc(doc["id"])
        //     .setData({
        //   'user': doc["id"],
        //   'expired_on': new DateTime.now()
        //       .add(new Duration(days: 7))
        //       .millisecondsSinceEpoch,
        //   'plan': 'free',
        //   'notified': false,
        //   'expired': false,
        // });
      });
    });
  }

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Widget searchWhenNull(AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const Center(
        child: Text(
          'No data available.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Use the filtered usersList instead of snapshot data
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => buildUserListItem(usersList[index]),
            childCount: usersList.length,  // Use usersList length
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leadingWidth: 40,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            iconSize: 20.0,
            color: Colors.black,
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          widget.serviceName,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isSearching = true;
                              });
                            },
                            child: isSearching
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.search,
                                      size: 16.0,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 5),
                                    SizedBox(
                                      width: 120,
                                      child: TextField(
                                        controller: searchController,
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                          fontSize: 13.0,
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: 'Enter city name',
                                          hintStyle: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13.0,
                                          ),
                                          contentPadding: EdgeInsets.zero,
                                          isDense: true,
                                        ),
                                        onSubmitted: (value) {
                                          setState(() {
                                            selectedCity = value;
                                            isSearching = false;
                                            searchController.clear();
                                          });
                                          getServiceProviderProfile();
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(Icons.close, size: 16, color: Colors.grey[600]),
                                      onPressed: () {
                                        setState(() {
                                          isSearching = false;
                                          searchController.clear();
                                        });
                                      },
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.filter_list,
                                      size: 16.0,
                                      color: selectedCity != null ? Colors.black : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      selectedCity ?? "Filter by city",
                                      style: TextStyle(
                                        color: selectedCity != null ? Colors.black : Colors.grey[600],
                                        fontSize: 13.0,
                                      ),
                                    ),
                                    if (selectedCity != null) ...[
                                      const SizedBox(width: 5),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedCity = null;
                                          });
                                          getServiceProviderProfile();
                                        },
                                        child: Icon(
                                          Icons.close,
                                          size: 16.0,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ],
                                  
                                ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: GestureDetector(
                            onTap: showSubcategoryBottomSheet,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.category,
                                  size: 16.0,
                                  color: selectedSubcategory != null ? Colors.black : Colors.grey[600],
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  selectedSubcategory ?? "Alege subcategoria",
                                  style: TextStyle(
                                    color: selectedSubcategory != null ? Colors.black : Colors.grey[600],
                                    fontSize: 13.0,
                                  ),
                                ),
                                if (selectedSubcategory != null) ...[
                                  const SizedBox(width: 5),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedSubcategory = null;
                                      });
                                      getServiceProviderProfile();
                                    },
                                    child: Icon(
                                      Icons.close,
                                      size: 16.0,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                height: 1.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey[300]!.withOpacity(0.8),
                      offset: const Offset(0, 2),
                      blurRadius: 6,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          
          // Main content
          load
              ? const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : Expanded(
                  child: SmartRefresher(
                    controller: _refreshController,
                    scrollController: _scrollController,
                    enablePullDown: true,
                    enablePullUp: true,
                    header: const WaterDropHeader(),
                    footer: const ClassicFooter(),
                    onRefresh: _onRefresh,
                    onLoading: _onLoading,
                    child: loadingUsers 
                      ? const Center(child: CircularProgressIndicator())
                      : usersList.isEmpty 
                        ? const Center(
                            child: Text(
                              'No users found for the selected filters',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          )
                        : CustomScrollView(
                            controller: _scrollController,
                            slivers: [
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => buildUserListItem(usersList[index]),
                                  childCount: usersList.length,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
        ],
      ),
    );
  }

  bool shouldDisplayUser(Map<String, dynamic> userData) {
    return userData.isNotEmpty;
  }

  Widget buildUserListItem(DocumentSnapshot<Map<String, dynamic>> dataDoc) {
    final String serviceProviderId = dataDoc.id;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('Users')
          .doc(serviceProviderId)
          .get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = userSnapshot.data?.data() ?? {};
        
        bool isPromoted = false;
        if (userData['category_promotions'] != null && 
            userData['category_promotions'] is List) {
          List promotions = userData['category_promotions'];
          isPromoted = promotions.any((promo) => 
            promo['status'] == 'active' && 
            promo['endDate']?.toDate().isAfter(DateTime.now()) == true
          );
        }
        
        return Column(
          children: [
            InkWell(
              onTap: () async {
                if (serviceProviderId.isEmpty) {
                  print("Error: Invalid or null serviceProviderId. Cannot navigate.");
                  return;
                }

                final String userName = userData['name'] ?? 'Unknown';
                final String coverPhotoUrl = userData['coverPhotoUrl'] ?? 'defaultCoverUrl';
                final String address = userData['address'] ?? 'No address';

                DocumentSnapshot<Map<String, dynamic>> businessDetail =
                    await FirebaseFirestore.instance
                        .collection('Users')
                        .doc(serviceProviderId)
                        .collection('BusinessAccount')
                        .doc('detail')
                        .get();

                String categoryName = '';
                if (businessDetail.exists) {
                  categoryName = businessDetail.data()?['categoryName'] ?? '';
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfiles(
                      serviceProviderId,
                      userName,
                      coverPhotoUrl,
                      address,
                      categoryName,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: userData['coverPhotoUrl'] != null &&
                              userData['coverPhotoUrl'].isNotEmpty
                          ? Image(
                              width: 100,
                              height: 100,
                              image: NetworkImage(userData['coverPhotoUrl']),
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey[600],
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  userData['name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isPromoted)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'PROMOTED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userData['address'] ?? 'No address',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 20,
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(serviceProviderId)
                                  .collection('BusinessAccount')
                                  .doc('detail')
                                  .collection('reviews')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                List<Map<String, dynamic>> ratings = [];
                                if (snapshot.hasData) {
                                  ratings = snapshot.data!.docs
                                      .map((doc) => doc.data() as Map<String, dynamic>)
                                      .toList();
                                }

                                double sum = ratings.fold(
                                    0, (prev, element) => prev + (element['rating'] ?? 0));
                                double averageRating = ratings.isEmpty ? 0.0 : sum / ratings.length;

                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.amber[600],
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      averageRating.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "(${ratings.length})",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                userData['categoryName'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(width: 4),
                              _buildOpenStatusIndicator(
                                openTime: userData['openTime'] as String?,
                                closeTime: userData['closeTime'] as String?,
                                workingDays: userData['workingDays'] as String?,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey[200],
              indent: 16,
              endIndent: 16,
            ),
          ],
        );
      },
    );
  }

  Widget _buildOpenStatusIndicator({String? openTime, String? closeTime, String? workingDays}) {
    // Add debug prints
    print('Checking open status:');
    print('openTime: $openTime');
    print('closeTime: $closeTime');
    print('workingDays: $workingDays');

    // Return empty widget if times are null or empty
    if (openTime == null || closeTime == null || 
        openTime.isEmpty || closeTime.isEmpty) {
      print('Missing time data');
      return const SizedBox.shrink();
    }

    try {
      // First check if today is a working day
      if (workingDays != null && workingDays.isNotEmpty) {
        final now = DateTime.now();
        final dayOfWeek = now.weekday; // 1 = Monday, 7 = Sunday
        
        // Map weekday numbers to possible abbreviations
        final dayAbbrevMap = {
          1: ['Mon', 'Lun', 'L', 'Luni', 'luni'],
          2: ['Tue', 'Mar', 'M', 'Marți', 'Marti', 'marti'],
          3: ['Wed', 'Mie', 'Mi', 'Miercuri', 'miercuri'],
          4: ['Thu', 'Joi', 'J', 'Joi', 'joi'],
          5: ['Fri', 'Vin', 'V', 'Vineri', 'vineri'],
          6: ['Sat', 'Sam', 'Sâm', 'S', 'Sâmbătă', 'Sambata', 'sambata'],
          7: ['Sun', 'Dum', 'Dun', 'D', 'Duminică', 'Duminica', 'duminica'],
        };

        final possibleAbbrevs = dayAbbrevMap[dayOfWeek] ?? [];
        
        // Check if any variation of today's abbreviation is in the working days
        bool isDayIncluded = possibleAbbrevs.any((abbrev) => 
          workingDays.toLowerCase().contains(abbrev.toLowerCase())
        );

        print('Current day: ${dayAbbrevMap[dayOfWeek]}');
        print('Is working day? $isDayIncluded');

        if (!isDayIncluded) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'ÎNCHIS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
      }

      // Parse current time and business hours
      final now = DateTime.now();
      final currentTime = TimeOfDay.fromDateTime(now);
      
      // Parse business hours
      final openTimeParts = openTime.split(':');
      final closeTimeParts = closeTime.split(':');
      
      final businessOpenTime = TimeOfDay(
        hour: int.parse(openTimeParts[0]),
        minute: int.parse(openTimeParts[1])
      );
      
      final businessCloseTime = TimeOfDay(
        hour: int.parse(closeTimeParts[0]),
        minute: int.parse(closeTimeParts[1])
      );

      // Convert to comparable minutes
      final currentMinutes = currentTime.hour * 60 + currentTime.minute;
      final openMinutes = businessOpenTime.hour * 60 + businessOpenTime.minute;
      final closeMinutes = businessCloseTime.hour * 60 + businessCloseTime.minute;

      print('Current time (minutes): $currentMinutes');
      print('Open time (minutes): $openMinutes');
      print('Close time (minutes): $closeMinutes');

      final isOpen = currentMinutes >= openMinutes && currentMinutes <= closeMinutes;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isOpen 
              ? Colors.green.withOpacity(0.8)
              : Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isOpen ? 'DESCHIS' : 'ÎNCHIS',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

    } catch (e) {
      print('Error in _buildOpenStatusIndicator: $e');
      return const SizedBox.shrink();
    }
  }
}
