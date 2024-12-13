import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:acumacum/Screens/business_user_search_screen.dart';
import 'package:acumacum/ui/bookings_orders.dart';
import 'package:acumacum/ui/LoginPage.dart';
import 'package:acumacum/ui/UserProfiles.dart';
import 'package:acumacum/ui/block_page.dart';
import 'package:acumacum/ui/categoriesScroller.dart';
import 'package:acumacum/ui/chatScreen.dart';
import 'package:acumacum/ui/favoriteProviders.dart';
import 'package:acumacum/ui/messages_list.dart';
import 'package:acumacum/ui/viewProfiles.dart';
import 'package:translator/translator.dart';
import 'SearchPage.dart';
import 'newUserPage.dart';
import 'NotificationScreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:acumacum/ui/ClientUserPage.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await setupFlutterNotifications();
  showFlutterNotification(message);
  print('Handling a background message ${message.messageId}');
}

late AndroidNotificationChannel channel;

bool isFlutterLocalNotificationsInitialized = false;

Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }
  channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  isFlutterLocalNotificationsInitialized = true;
}

void showFlutterNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
  if (notification != null && android != null && !kIsWeb) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: 'launch_background',
        ),
      ),
    );
  }
}

late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (!kIsWeb) {
    await setupFlutterNotifications();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      ),
      home: const Homepage(),
    );
  }
}

class Post {
  final String title;
  final String body;

  Post(this.title, this.body);
}

class Homepage extends StatefulWidget {
  final int currentIndex;
  const Homepage({Key? key, this.currentIndex = 0}) : super(key: key);

  @override
  HomepageState createState() => HomepageState();
}

Logger logger = Logger();

class HomepageState extends State<Homepage> with WidgetsBindingObserver {
  String qrResult = "Not yet Scanned";
  String? country;
  bool check = false;
  int checkIndex = 0;
  int count = 0;
  bool loadingQrUser = false;
  String? searchString = '';
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  int _currentIndex = 0;
  late PageController _pageController;
  int _refreshKey = 0;
  int _promotedRefreshKey = 0;
  int _recentRefreshKey = 0;

  Future<void> _onRefresh() async {
    setState(() {
      _refreshKey++;
      checkIndex = 0;
      count = 0;
    });
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    return Future<void>.value();
  }

  Future<void> _onPromotedRefresh() async {
    setState(() {
      _promotedRefreshKey++;
      checkIndex = 0;
      count = 0;
    });
    
    await Future.delayed(const Duration(milliseconds: 800));
    return Future<void>.value();
  }

  Future<void> _onRecentRefresh() async {
    setState(() {
      _recentRefreshKey++;
    });
    
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 800));
    return Future<void>.value();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool isReplay = false;

  var now;
  var date;
  bool subscriptionExpired = false;
  var diff;
  String? userId;

  List<DocumentSnapshot<Map>> usersList = [];
  bool loadingUsers = true;
  int perPageLimit = 5;
  late DocumentSnapshot lastDocument;
  final ScrollController _scrollController = ScrollController();
  late String serviceProviderId;
  List<String> categoryList = [];

  Future<List<Post>> _getALlPosts(String text) async {
    await Future.delayed(Duration(seconds: text.length == 4 ? 10 : 1));
    if (isReplay) return [Post("Replaying !", "Replaying body")];
    if (text.length == 2) throw Error();
    if (text.length == 6) return [];
    List<Post> posts = [];

    var random = Random();
    for (int i = 0; i < 10; i++) {
      posts
          .add(Post("$text $i", "body random number : ${random.nextInt(100)}"));
    }
    return posts;
  }

  @override
  void initState() {
    super.initState();
    
    // Add try-catch block around Firebase token retrieval
    Future<void> initFirebaseMessaging() async {
      try {
        final messaging = FirebaseMessaging.instance;
        final token = await messaging.getToken();
        if (token != null && userId != null) {
          await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .update({'notificationToken': token});
        }
      } catch (e) {
        print('Error getting Firebase token: $e');
        // Handle error appropriately
      }
    }
    
    initFirebaseMessaging();
    
    userId = FirebaseAuth.instance.currentUser?.uid;
    count = 0;
    _currentIndex = widget.currentIndex ?? 0;
    _pageController = PageController(initialPage: _currentIndex);

    _firebaseMessaging.getInitialMessage().then((message) {
      FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .update({'newChat': true});
      if (message != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              avatarUrl: message.data['data']['avatarUrl'],
              serviceProviderId: message.data['data']['serviceProviderId'],
              userName: message.data['data']['sender'],
              price: 'N/A',
            ),
          ),
        );
        final snackBar = SnackBar(
          content: Text(message.data['notification']['body']),
          action: SnackBarAction(label: 'Go', onPressed: () {}),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        print(message);
        return;
      }
    });

    FirebaseMessaging.onMessage.listen((message) {
      FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .update({'newChat': true});
      final snackBar = SnackBar(
        content: Text(message.data['notification']['body']),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      print(message);
      print(message.data['data']['serviceProviderId']);
      return;
    });

    getServiceProviderProfile();
    WidgetsBinding.instance.addObserver(this);

    _scrollController.addListener(() {
      double maxScroll = _scrollController.position.maxScrollExtent;
      double scrollPixels = _scrollController.position.pixels;
      double delta = MediaQuery.of(context).size.width * 0.9;
      if (maxScroll - scrollPixels <= delta) {}
    });
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    count = 0;
    await updatePromo();

    FirebaseFirestore.instance
        .collection("Homepage SuperUser")
        .doc('$userId')
        .get()
        .then((value) {
      if (value.exists) {
        subscriptionExpired = (value.data() as Map)['expired'];
        if (subscriptionExpired == true) {
        } else {
          checkSubscription();
        }
      }
    });
    await update();
    await checkBlock();
  }

  Future update() async {
    FirebaseFirestore.instance
        .collection('Users')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) async {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(doc.id)
            .set(doc.data() as Map<String, dynamic>);
      });
    });
  }

  Future updatePromo() async {
    FirebaseFirestore.instance
      .collection('Users')
      .get()
      .then((QuerySnapshot querySnapshot) {
        querySnapshot.docs.forEach((doc) async {
          await FirebaseFirestore.instance
            .collection('Homepage SuperUser')
            .doc(doc.id)
            .get()
            .then((value) async {
              if (value.exists) {
                subscriptionExpired = (value.data() as Map<String, dynamic>)['expired'];
                now = DateTime.now();
                date = DateTime.fromMillisecondsSinceEpoch(
                  (value.data() as Map<String, dynamic>)['expired_on']);
                diff = date.difference(now);
                if (diff.inDays >= 0 && diff.inHours >= 0) {
                  await FirebaseFirestore.instance
                    .collection('Homepage SuperUser')
                    .doc(doc.id)
                    .update({
                      "expired": false,
                      "notified": false,
                    });
                } else {
                  await FirebaseFirestore.instance
                    .collection('Homepage SuperUser')
                    .doc(doc.id)
                    .update({
                      "expired": true,
                      "plan": "",
                      "notified": true,
                    });
                }
              }
            });
        });
      });
  }

  Future checkBlock() async {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .get()
        .then((value) {
      if (value.data() != null) {
        if ((value.data() as Map<String, dynamic>)['disabled'] == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => BlockPage(currentUserId: userId!)),
          );
        }
      }
    });
  }

  Future<bool> _willPopCallback() async {
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return const LoginPage();
          }
          return (snapshot.data as DocumentSnapshot<Map>?) == null
              ? WillPopScope(
                  onWillPop: _willPopCallback,
                  child: const LoginPage(),
                )
              : WillPopScope(
                  onWillPop: _willPopCallback,
                  child: Scaffold(
                    body: SizedBox.expand(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() => _currentIndex = index);
                        },
                        children: [
                          _homePage(),
                          const FavoriteProviders(),
                          const BookingOrdersScreen(),
                          const MessageList(),
                        ],
                      ),
                    ),
                    bottomNavigationBar: StreamBuilder<bool>(
                      stream: getUnreadMessageStatus(),
                      builder: (context, snapshot) {
                        final hasUnread = snapshot.data ?? false;
                        print('BottomNav hasUnread: $hasUnread');
                        
                        return BottomNavigationBar(
                          backgroundColor: Colors.white,
                          currentIndex: _currentIndex,
                          showSelectedLabels: true,
                          showUnselectedLabels: true,
                          elevation: 4.0,
                          type: BottomNavigationBarType.fixed,
                          onTap: (index) async {
                            setState(() => _currentIndex = index);
                            if (index == 4) {
                              // Messages tab
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MessageList(),
                                ),
                              );
                              setState(() {
                                _currentIndex = 4;
                              });
                            } else if (index == 3) {  // Profile tab
                              // Check if user has a business account
                              final userDoc = await FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(userId)
                                  .get();
                                
                              final hasBusinessAccount = userDoc.data()?['userRole'] == 'Business';

                              if (!mounted) return;  // Check if widget is still mounted
                              
                              if (hasBusinessAccount) {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NewUserPage(),
                                  ),
                                );
                              } else {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ClientUserPage(userId: userId!),
                                  ),
                                );
                              }
                              
                              setState(() {
                                _currentIndex = 3;
                              });
                            } else {
                              _pageController.jumpToPage(index);
                            }
                          },
                          items: <BottomNavigationBarItem>[
                            const BottomNavigationBarItem(
                              label: 'Home',
                              icon: Icon(Icons.home, color: Colors.black),
                              activeIcon: Icon(Icons.home, color: Color.fromARGB(255, 3, 59, 161)),
                            ),
                            const BottomNavigationBarItem(
                              label: 'Saved',
                              icon: Icon(Icons.favorite_border, color: Colors.black),
                              activeIcon: Icon(Icons.favorite_border, color: Color.fromARGB(255, 3, 59, 161)),
                            ),
                            const BottomNavigationBarItem(
                              label: 'Bookings',
                              icon: Icon(Icons.calendar_month_rounded, color: Colors.black),
                              activeIcon: Icon(Icons.calendar_month, color: Color.fromARGB(255, 3, 59, 161)),
                            ),
                            const BottomNavigationBarItem(
                              label: 'My Profile',
                              icon: Icon(Icons.person, color: Colors.black),
                              activeIcon: Icon(Icons.person, color: Color.fromARGB(255, 3, 59, 161)),
                            ),
                            BottomNavigationBarItem(
                              icon: Stack(
                                children: [
                                  const Icon(Icons.send, color: Colors.black),
                                  if (hasUnread)
                                    Positioned(
                                      right: 2,
                                      top: 2,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              activeIcon: Stack(
                                children: [
                                  const Icon(Icons.send, color: Color.fromARGB(255, 3, 59, 161)),
                                  if (hasUnread)
                                    Positioned(
                                      right: 2,
                                      top: 2,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              label: 'Messages',
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
        });
  }

  Widget _buildSearchTrigger() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SearchPage(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.all(18.0),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Search for a service',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
                letterSpacing: -0.3,
              ),
            ),
            Icon(Icons.search, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _homePage() {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return loadingUsers == true
        ? SizedBox(
            height: height,
            width: width,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          )
        : Scaffold(
            backgroundColor: const Color(0xFFFAFAFA),
            appBar: AppBar(
                backgroundColor: Colors.white,
                   surfaceTintColor: Colors.white,
             
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.pin_drop, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          country ?? 'Current Location',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/acum_logo.png',
                          height: 80,
                        ),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('Users')
                              .doc(userId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Icon(Icons.notifications_outlined);
                            }
                            
                            final userData = snapshot.data?.data() as Map<String, dynamic>?;
                            final unreadCount = userData?['unreadNotifications'] ?? 0;
                            
                            return Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.notifications_outlined,
                                    size: 24,
                                    color: Colors.black87,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => NotificationScreen(userId: userId!),
                                      ),
                                    );
                                  },
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 14,
                                        minHeight: 14,
                                      ),
                                      child: Text(
                                        unreadCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),
                automaticallyImplyLeading: false),
            body: Container(
              color: const Color(0xFFFAFAFA),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      child: Column(
                        children: [
                          _buildSearchTrigger(),
                          Container(
                            alignment: Alignment.centerLeft,
                            margin: const EdgeInsets.only(left: 10.0, bottom: 16.0),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/red-envelope.png',
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  "Exploreaza cele mai populare categorii",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.black87,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const CategoriesScroller(),
                          const SizedBox(height: 30),
                          const TopText(),
                          showAnotherData(),
                          const SizedBox(height: 20),
                          _buildPreviousBookingsSection(),
                          const SizedBox(height: 20),
                          // Container(
                          //   margin: const EdgeInsets.symmetric(horizontal: 16.0),
                          //   decoration: BoxDecoration(
                          //     borderRadius: BorderRadius.circular(15),
                          //     boxShadow: [
                          //       BoxShadow(
                          //         color: Colors.grey.withOpacity(0.3),
                          //         spreadRadius: 2,
                          //         blurRadius: 5,
                          //         offset: const Offset(0, 3),
                          //       ),
                          //     ],
                          //   ),
                            // child: ClipRRect(
                            //   borderRadius: BorderRadius.circular(15),
                            //   child: Image.asset(
                            //     'assets/images/OFF-2.png',
                            //     fit: BoxFit.cover,
                            //     width: double.infinity,
                            //   ),
                            // ),
                         // ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: [
                                        Image.asset(
                                          'assets/images/red-flag.png',
                                          width: 24,
                                          height: 24,
                                        ),
                                        const SizedBox(width: 2),
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: "Vrem sa te ",
                                                style: GoogleFonts.inter(
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                  letterSpacing: -0.5,
                                                ),
                                              ),
                                              TextSpan(
                                                text: "AJUTAM",
                                                style: GoogleFonts.inter(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                  letterSpacing: -0.5,
                                                ),
                                              ),
                                              TextSpan(
                                                text: " de astazi,",
                                                style: GoogleFonts.inter(
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                  letterSpacing: -0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Descopera noile business-uri",
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 13,
                                        color: Colors.black54,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          showRecentBusinesses(),
                          const SizedBox(height: 20),
                          BannerSlideshow(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  Widget showAnotherData() {
    final ScrollController scrollController = ScrollController();

    return SizedBox(
      height: 220,
      child: LiquidPullToRefresh(
        onRefresh: _onPromotedRefresh,
        showChildOpacityTransition: false,
        color: Colors.red,
        backgroundColor: Colors.red[50],
        animSpeedFactor: 2,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          key: ValueKey(_promotedRefreshKey),
          stream: FirebaseFirestore.instance
              .collection('Users')
              .where('userRole', isEqualTo: 'Business')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('Error'));
            if (!snapshot.hasData) return const CircularProgressIndicator();

            final now = DateTime.now();
            
            // Filter users with active homepage promotions
            final validDocs = snapshot.data!.docs.where((doc) {
              final data = doc.data();
              final promotions = data['homepage_promotions'] as List?;
              
              if (promotions == null || promotions.isEmpty) return false;

              return promotions.any((promo) {
                if (promo['status'] != 'active') return false;
                
                final startDate = (promo['startDate'] as Timestamp).toDate();
                final endDate = (promo['endDate'] as Timestamp).toDate();
                
                return now.isAfter(startDate) && now.isBefore(endDate);
              });
            }).toList();

            if (validDocs.isEmpty) {
              return const Center(
                child: Text('No promoted businesses available.'),
              );
            }

            // Create a new shuffled list and limit to 8 items
            final shuffledDocs = List.from(validDocs)..shuffle();
            final limitedDocs = shuffledDocs.take(8).toList();

            return SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...List.generate(
                    (limitedDocs.length / 2).ceil(),
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 100,
                            child: FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(limitedDocs[i * 2].id)
                                  .collection('BusinessAccount')
                                  .doc('detail')
                                  .get(),
                              builder: (context, businessSnapshot) {
                                if (!businessSnapshot.hasData) {
                                  return const SizedBox.shrink();
                                }

                                final businessData = businessSnapshot.data?.data() as Map<String, dynamic>?;
                                final userData = limitedDocs[i * 2].data() as Map<String, dynamic>;
                                
                                final combinedData = <String, dynamic>{
                                  ...userData,
                                  'category': businessData?['category'] ?? '',
                                };

                                return _buildPromotedUserContainer(limitedDocs[i * 2].id, combinedData);
                              },
                            ),
                          ),
                          if ((i * 2 + 1) < limitedDocs.length) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 100,
                              child: FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('Users')
                                    .doc(limitedDocs[i * 2 + 1].id)
                                    .collection('BusinessAccount')
                                    .doc('detail')
                                    .get(),
                                builder: (context, businessSnapshot) {
                                  if (!businessSnapshot.hasData) {
                                    return const SizedBox.shrink();
                                  }

                                  final businessData = businessSnapshot.data?.data() as Map<String, dynamic>?;
                                  final userData = limitedDocs[i * 2 + 1].data() as Map<String, dynamic>;
                                  
                                  final combinedData = <String, dynamic>{
                                    ...userData,
                                    'category': businessData?['category'] ?? '',
                                  };

                                  return _buildPromotedUserContainer(limitedDocs[i * 2 + 1].id, combinedData);
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Refresh indicator
                  GestureDetector(
                    onTap: _onPromotedRefresh,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.refresh,
                            color: Colors.grey,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPromotedUserContainer(String userId, Map<String, dynamic> data) {
    return Container(
      width: 320,
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfiles(
                    userId,
                    data['name'] ?? 'Unknown',
                    data['coverPhotoUrl'] ?? 'default',
                    data['address'] ?? 'No address',
                    data['category'] ?? '',
                  ),
                ),
              );
            },
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                  ),
                  child: Image(
                    width: 100,
                    height: 100,
                    image: data['coverPhotoUrl'] != null
                        ? NetworkImage(data['coverPhotoUrl'])
                        : const NetworkImage(
                            "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png"),
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 12.0,
                      right: 12.0,
                      top: 12.0,
                      bottom: 8.0
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          data['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 10.0,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data['address'] ?? 'No address',
                          style: const TextStyle(
                            fontSize: 9.0,
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('Users')
                              .doc(userId)
                              .collection('BusinessAccount')
                              .doc('detail')
                              .collection('reviews')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 12,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    '0.0',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            }

                            final ratings = snapshot.data!.docs;
                            if (ratings.isEmpty) {
                              return const Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 12,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    '0.0',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            }

                            double sum = ratings.fold(
                                0, (prev, element) => prev + (element['rating'] ?? 0));
                            double averageRating = sum / ratings.length;

                            return Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  averageRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data['category'] ?? '',
                          style: const TextStyle(
                            fontSize: 8.0,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
              ),
              child: const Text(
                'Promoted',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget showRecentBusinesses() {
    final DateTime oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    final Timestamp oneWeekAgoTimestamp = Timestamp.fromDate(oneWeekAgo);
    final ScrollController scrollController = ScrollController();

    return Container(
      height: 220,
      color: Colors.transparent,
      child: StreamBuilder<QuerySnapshot>(
        key: ValueKey(_recentRefreshKey),
        stream: FirebaseFirestore.instance
            .collection('Users')
            .where('userRole', isEqualTo: 'Business')
            .where('createdAt', isGreaterThanOrEqualTo: oneWeekAgoTimestamp)
            .orderBy('createdAt', descending: true)
            .limit(12)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('StreamBuilder error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No new businesses this week',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          // Create a shuffled copy of the docs
          final shuffledDocs = List.from(docs)..shuffle();
          // Take only the first 12
          final limitedDocs = shuffledDocs.take(12).toList();

          return SingleChildScrollView(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                ...List.generate(limitedDocs.length, (index) {
                  final doc = limitedDocs[index];
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('Users')
                        .doc(doc.id)
                        .collection('BusinessAccount')
                        .doc('detail')
                        .get(),
                    builder: (context, businessSnapshot) {
                      if (!businessSnapshot.hasData) {
                        return const SizedBox.shrink();
                      }

                      final businessData = businessSnapshot.data?.data() as Map<String, dynamic>?;
                      final userData = doc.data() as Map<String, dynamic>;
                      
                      final combinedData = <String, dynamic>{
                        ...userData,
                        'category': businessData?['category'] ?? '',
                      };

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: _buildVerticalUserContainer(
                          doc.id, 
                          combinedData,
                          isFirst: index == 0,
                        ),
                      );
                    },
                  );
                }),
                // Modified refresh indicator
                GestureDetector(
                  onTap: _onRecentRefresh,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.refresh,
                            color: Colors.grey,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Refresh',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerticalUserContainer(String userId, Map<String, dynamic> data, {bool isFirst = false}) {
    return SizedBox(
      width: 300,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserProfiles(
                userId,
                data['name'] ?? 'Unknown',
                data['coverPhotoUrl'] ?? 'default',
                data['address'] ?? 'No address',
                data['category'] ?? '',
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image(
                      width: double.infinity,
                      image: data['coverPhotoUrl'] != null
                          ? NetworkImage(data['coverPhotoUrl'])
                          : const NetworkImage(
                              "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (isFirst) ...[
                  Positioned(
                    left: 0,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A237E),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Nou',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 4.0, right: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          data['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('Users')
                            .doc(userId)
                            .collection('BusinessAccount')
                            .doc('detail')
                            .collection('reviews')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '0.0',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          }

                          final ratings = snapshot.data!.docs;
                          if (ratings.isEmpty) {
                            return const Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '0.0',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          }

                          double sum = ratings.fold(
                              0, (prev, element) => prev + (element['rating'] ?? 0));
                          double averageRating = sum / ratings.length;

                          return Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                averageRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data['address'] ?? 'No address',
                    style: const TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data['category'] ?? '',
                    style: const TextStyle(
                      fontSize: 11.0,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget showData2() {
    return FutureBuilder(
      future: FirebaseFirestore.instance
          .collection('Users')
          .doc(serviceProviderId)
          .get(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snaps) {
        if (snaps.hasError) {
          return Container();
        }
        if (!snaps.hasData) {
          return Container();
        } else {
          if ((snaps.data?.data() as Map)['country'] == country) {
            String? id = snaps.data?.id;
            return FutureBuilder(
              future: FirebaseFirestore.instance
                  .collection('Users/$id/BusinessAccount')
                  .doc('detail')
                  .get(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot2) {
                if (!snapshot2.hasData) {
                  return Container();
                } else {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoryProfiles(
                              UserProfiles(
                                  '$id',
                                  (snaps.data?.data()
                                      as Map<String, dynamic>)['name'],
                                  (snaps.data?.data() as Map<String, dynamic>)[
                                          'coverPhotoUrl'] ??
                                      'default',
                                  (snaps.data?.data()
                                      as Map<String, dynamic>)['address'],
                                  (snapshot2.data?.data()
                                      as Map<String, dynamic>)['category']),
                              userId!),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                bottomLeft: Radius.circular(15),
                              ),
                              child: Image(
                                width: 140,
                                height: 140,
                                image: ((snaps.data?.data()
                                            as Map)['coverPhotoUrl'] ==
                                        null)
                                    ? const NetworkImage(
                                        "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png")
                                    : NetworkImage((snaps.data?.data()
                                        as Map)['coverPhotoUrl']),
                                fit: BoxFit.cover,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      (snaps.data?.data() as Map)['name'],
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      (snaps.data?.data() as Map)['address'],
                                      style: const TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      (snapshot2.data?.data()
                                          as Map)['category'],
                                      style: const TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(15),
                                bottomLeft: Radius.circular(15),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: const Text(
                              'Promoted',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            );
          } else {
            return Container();
          }
        }
      },
    );
  }

  checkSubscription() async {
    await FirebaseFirestore.instance
        .collection('Homepage SuperUser')
        .doc('$userId')
        .get()
        .then((value) {
      if (value.exists) {
        setState(() {
          subscriptionExpired = (value.data() as Map)['expired'];
          now = DateTime.now();
          date = DateTime.fromMillisecondsSinceEpoch(
              (value.data() as Map)['expired_on']);
          diff = date.difference(now);
        });
        if (subscriptionExpired == true) {
        } else {
          if ((diff.inHours - (diff.inDays * 24)) <= 0 && diff.inDays < 0) {
            FirebaseFirestore.instance
              .collection('Homepage SuperUser')
              .doc('$userId')
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (userId == null) return;
    
    if (state == AppLifecycleState.resumed) {
      FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .update({'status': 'Online'});
    } else {
      FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .update({'status': 'Offline'});
    }
  }

  getServiceProviderProfile() async {
    QuerySnapshot<Map> allSuperUsers = await FirebaseFirestore.instance
        .collection('Homepage SuperUser')
        .where("expired", isEqualTo: false)
        .get();
    setState(() {
      loadingUsers = true;
    });

    if (!check) {
      await getLocation();
    }

    setState(() {
      loadingUsers = false;
      usersList = allSuperUsers.docs;
      usersList.shuffle();
    });
    await Future.delayed(const Duration(seconds: 2), () {
      setState(() {});
    });
  }

  getLocation() async {
    try {
      LocationPermission permission;
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
            
        // Simply set a default country or get it from your backend
        setState(() {
          country = 'Romania'; // Or get this from your backend/settings
          check = true;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  void navigateToSearchPage(String currentUserID) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return BusinessUserSearchScreen(currentUserID);
    }));
  }

  Widget _bottomBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      currentIndex: _currentIndex,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      elevation: 4.0,
      type: BottomNavigationBarType.fixed,
      onTap: (index) async {
        setState(() => _currentIndex = index);
        if (index == 4) {
          // Messages tab
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MessageList(),
            ),
          );
          setState(() {
            _currentIndex = 4;
          });
        } else if (index == 3) {  // Profile tab
          // Check if user has a business account
          final userDoc = await FirebaseFirestore.instance
              .collection('Users')
              .doc(userId)
              .get();
            
          final hasBusinessAccount = userDoc.data()?['userRole'] == 'Business';

          if (!mounted) return;  // Check if widget is still mounted
          
          if (hasBusinessAccount) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NewUserPage(),
              ),
            );
          } else {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ClientUserPage(userId: userId!),
              ),
            );
          }
          
          setState(() {
            _currentIndex = 3;
          });
        } else {
          _pageController.jumpToPage(index);
        }
      },
      items: <BottomNavigationBarItem>[
        const BottomNavigationBarItem(
          label: 'Home',
          icon: Icon(Icons.home, color: Colors.black),
          activeIcon: Icon(Icons.home, color: Color.fromARGB(255, 3, 59, 161)),
        ),
        const BottomNavigationBarItem(
          label: 'Saved',
          icon: Icon(Icons.favorite_border, color: Colors.black),
          activeIcon: Icon(Icons.favorite_border, color: Color.fromARGB(255, 3, 59, 161)),
        ),
        const BottomNavigationBarItem(
          label: 'Bookings',
          icon: Icon(Icons.calendar_month_rounded, color: Colors.black),
          activeIcon: Icon(Icons.calendar_month, color: Color.fromARGB(255, 3, 59, 161)),
        ),
        const BottomNavigationBarItem(
          label: 'My Profile',
          icon: Icon(Icons.person, color: Colors.black),
          activeIcon: Icon(Icons.person, color: Color.fromARGB(255, 3, 59, 161)),
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.send, color: Colors.black),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Users')
                    .doc(userId)
                    .collection('chats')
                    .where('unread', isEqualTo: true)
                    .snapshots(),
                builder: (context, chatSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('UserBookings')
                        .where('serviceProviderId', isEqualTo: userId)
                        .where('status', isEqualTo: 'pending')
                        .snapshots(),
                    builder: (context, bookingSnapshot) {
                      bool hasUnreadMessages = chatSnapshot.hasData && 
                          chatSnapshot.data!.docs.isNotEmpty;
                      bool hasNewBookings = bookingSnapshot.hasData && 
                          bookingSnapshot.data!.docs.isNotEmpty;

                      if (hasUnreadMessages || hasNewBookings) {
                        return Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 10,
                              minHeight: 10,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  );
                },
              ),
            ],
          ),
          activeIcon: Stack(
            children: [
              const Icon(Icons.send, color: Color.fromARGB(255, 3, 59, 161)),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Users')
                    .doc(userId)
                    .collection('chats')
                    .where('unread', isEqualTo: true)
                    .snapshots(),
                builder: (context, chatSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('UserBookings')
                        .where('serviceProviderId', isEqualTo: userId)
                        .where('status', isEqualTo: 'pending')
                        .snapshots(),
                    builder: (context, bookingSnapshot) {
                      bool hasUnreadMessages = chatSnapshot.hasData && 
                          chatSnapshot.data!.docs.isNotEmpty;
                      bool hasNewBookings = bookingSnapshot.hasData && 
                          bookingSnapshot.data!.docs.isNotEmpty;

                      if (hasUnreadMessages || hasNewBookings) {
                        return Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 10,
                              minHeight: 10,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  );
                },
              ),
            ],
          ),
          label: 'Messages',
        ),
      ],
    );
  }

  void navigateToUserProfilePage(
    DocumentSnapshot snapshot,
    BuildContext context,
    String userId,
    DocumentSnapshot snapshot2,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryProfiles(
          UserProfiles(
            snapshot.id,
            (snapshot.data() as Map)['name'],
            (snapshot.data() as Map)['coverPhotoUrl'] ?? 'default',
            (snapshot.data() as Map)['address'],
            (snapshot2.data() as Map)['category'],
          ),
          userId,
        ),
      ),
    );
  }

  Stream<bool> getUnreadMessageStatus() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value(false);

    print('Checking messages for user: $userId');

    return FirebaseFirestore.instance
        .collection('ChatRoom')
        .where('users', arrayContains: userId)
        .snapshots()
        .asyncMap((chatRooms) async {
      print('Found ${chatRooms.docs.length} chat rooms');
      
      for (var room in chatRooms.docs) {
        print('Checking chat room: ${room.id}');
        
        final messages = await FirebaseFirestore.instance
            .collection('ChatRoom')
            .doc(room.id)
            .collection('chats')
            .orderBy('time', descending: true)  // Add ordering
            .get();

        print('Room ${room.id} has ${messages.docs.length} total messages');
        
        for (var doc in messages.docs) {
          final messageData = doc.data();
          print('Message ID: ${doc.id}');
          print('Message data: ${messageData.toString()}');
          
          if (messageData['sender'] != userId && 
              messageData['unread'] == true) {
            print('Found unread message with ID: ${doc.id}');
            return true;
          }
        }
      }
      
      print('No unread messages found');
      return false;
    });
  }

  Widget _buildPreviousBookingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: [
                   
                      const SizedBox(width: 2),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Ti-a placut? ",
                              style: GoogleFonts.inter(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: "Incearca din nou",
                              style: GoogleFonts.inter(
                                color: Colors.red,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Servicii pe care le-ai mai folosit",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                      color: Colors.black54,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Users')
                .doc(userId)
                .collection('Bookings')
                .where('status', isEqualTo: 'accepted')
                .orderBy('createdAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              // Add debug prints
              print('Bookings Stream Status: ${snapshot.connectionState}');
              print('Has Data: ${snapshot.hasData}');
              print('Has Error: ${snapshot.hasError}');
              
              if (snapshot.hasError) {
                print('Error: ${snapshot.error}');
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final bookings = snapshot.data!.docs;
              print('Number of bookings found: ${bookings.length}');
              
              if (bookings.isEmpty) {
                return Center(
                  child: Text(
                    'No previous bookings found',
                    style: GoogleFonts.inter(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index].data() as Map<String, dynamic>;
                  final serviceProviderId = booking['serviceProviderId'];
                  print('Building item for provider ID: $serviceProviderId');

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('Users')
                        .doc(serviceProviderId)
                        .get(),
                    builder: (context, providerSnapshot) {
                      if (!providerSnapshot.hasData) {
                        return const SizedBox(
                          width: 100,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final providerData = providerSnapshot.data!.data() as Map<String, dynamic>;
                      print('Provider data found: ${providerData['name']}');

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('Users')
                            .doc(serviceProviderId)
                            .collection('BusinessAccount')
                            .doc('detail')
                            .get(),
                        builder: (context, businessSnapshot) {
                          if (!businessSnapshot.hasData) {
                            return const SizedBox(
                              width: 100,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final businessData = businessSnapshot.data!.data() as Map<String, dynamic>;
                          final combinedData = {
                            ...providerData,
                            'category': businessData['category'] ?? '',
                          };

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: _buildVerticalUserContainer(
                              serviceProviderId,
                              combinedData,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class TopText extends StatelessWidget {
  const TopText({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  Image.asset(
                    'assets/images/money-bag.png',  // Make sure this image exists in your assets
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 2),  // Small spacing
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Ofertele",
                          style: GoogleFonts.inter(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: " momentului",
                          style: GoogleFonts.inter(
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: " in aceasta saptamana,",
                          style: GoogleFonts.inter(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Vezi recomandarile noastre",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  color: Colors.black54,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class Appbar extends StatelessWidget {
  const Appbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
        offset: const Offset(0.0, -10),
        child: Container(
            height: 50,
            margin: const EdgeInsets.only(left: 20, right: 20),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(
                Radius.circular(80),
              ),
              child: BottomAppBar(
                color: Colors.white24,
                elevation: 200,
                shape: const CircularNotchedRectangle(),
                notchMargin: 20.0,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.favorite_border),
                      iconSize: 30,
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const FavoriteProviders()));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_month),
                      iconSize: 30,
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const BookingOrdersScreen()));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.person),
                      iconSize: 30,
                      onPressed: () {
                        User? user = FirebaseAuth.instance.currentUser;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewUserPage(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      iconSize: 30,
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MessageList()));
                      },
                    ),
                  ],
                ),
              ),
            )));
  }
}

class BannerSlideshow extends StatefulWidget {
  @override
  _BannerSlideshowState createState() => _BannerSlideshowState();
}

class _BannerSlideshowState extends State<BannerSlideshow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> banners = [
    'assets/images/banner1.png',
    'assets/images/banner2.png',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: banners.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onHorizontalDragUpdate: (details) {
                  // Add resistance to the drag
                  _pageController.position.moveTo(
                    _pageController.offset - details.delta.dx,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      banners[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
          // Page indicators
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                banners.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Colors.red
                        : Colors.grey.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
