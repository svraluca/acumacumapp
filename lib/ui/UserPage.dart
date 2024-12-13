import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:algolia/algolia.dart';
import 'package:acumacum/ui/addProductScreen.dart';
import 'package:acumacum/ui/addServiceScreen.dart';
import 'package:acumacum/utils/AlgoliaApplication.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fl_geocoder/fl_geocoder.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:acumacum/model/User.dart';
import 'package:acumacum/ui/HomePage.dart';
import 'package:acumacum/ui/settingsPage.dart';
import 'package:acumacum/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add_search_tags.dart';

class UserPage extends StatefulWidget {
  late ScrollController scrollController;

  UserPage({super.key});

  @override
  State<UserPage> createState() => UserProfile();
}

class UserProfile extends State<UserPage> with SingleTickerProviderStateMixin {
  bool isFileImage = false;
  late User user;
  late ScrollController scrollController;
  late File pickedFile;
  String? userImage;
  String? address;
  String? userName;
  String? facebookUrl;
  String? instagramUrl;
  String? tikTokUrl;

  TextEditingController facebookController = TextEditingController();
  TextEditingController instagramController = TextEditingController();
  TextEditingController tiktokController = TextEditingController();
  late String userId;
  Random randomGenerator = Random();

  QuerySnapshot? querySnapshot;
  Stream<QuerySnapshot<Map>>? stream;
  TabController? tabController;

  @override
  void initState() {
    // add this line of code
    scrollController = ScrollController();

    tabController = TabController(
      length: 3,
      vsync: this,
    );
    tabController?.addListener(() {
      setState(() {});
    });
    initUser();
  }

  final Algolia _algoliaApp = AlgoliaApplication.algolia;

  String? serviceProviderId;
  Future<List<AlgoliaObjectSnapshot>> _operation(String input) async {
    AlgoliaQuery query = _algoliaApp.instance.index("users").search(input);
    AlgoliaQuerySnapshot querySnap = await query.getObjects();
    List<AlgoliaObjectSnapshot> results = querySnap.hits;
    return results;
  }

  initUser() async {
    user = FirebaseAuth.instance.currentUser!;
    userId = user.uid;
    logger.e("user id at init user =$userId");
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
      storageReference
          .child("Users Profile")
          .child(userId)
          .putData(imageData)
          .then((uploadTask) async {
        var dowurl = await uploadTask.ref.getDownloadURL();
        String url = dowurl.toString();

        Map<String, dynamic> urlNull = {
          'avatarUrl': url,
        };
        
        // Replace transaction with direct update
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .update(urlNull);
      });
    }
  }

  // Future<void> _createDynamicLink(bool short) async {
  //   setState(() {
  //     _isCreatingLink = true;
  //   });

  //   final DynamicLinkParameters parameters = DynamicLinkParameters(
  //     uriPrefix: 'https://cx4k7.app.goo.gl',
  //     link: Uri.parse('https://acumacum.page.link/homepage'),
  //     androidParameters: AndroidParameters(
  //       packageName: 'com.svapps.acumacum',
  //       minimumVersion: 0,
  //     ),
  //     dynamicLinkParametersOptions: DynamicLinkParametersOptions(
  //       shortDynamicLinkPathLength: ShortDynamicLinkPathLength.short,
  //     ),
  //     iosParameters: IosParameters(
  //       bundleId: 'com.google.FirebaseCppDynamicLinksTestApp.dev',
  //       minimumVersion: '0',
  //     ),
  //   );

  //   Uri url;
  //   if (short) {
  //     final ShortDynamicLink shortLink = await parameters.buildShortLink();
  //     url = shortLink.shortUrl;
  //   } else {
  //     url = await parameters.buildUrl();
  //   }

  //   setState(() {
  //     _linkMessage = url.toString();
  //     _isCreatingLink = false;
  //   });
  // }

  var addresses;
  var first;
  double lat = 0.0;
  double long = 0.0;

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
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
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              body: SafeArea(
                // top: false,
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    // color: Colors.white,
                    // height: MediaQuery.of(context).size.height * 0.9,
                    // width: MediaQuery.of(context).size.width * 1,
                    child: ListView(
                      children: [
                        Container(
                          // width: 200,
                          // margin: EdgeInsets.only(
                          //     top: 8, bottom: 8, right: 12),
                          margin: const EdgeInsets.only(right: 12, bottom: 0),
                          //     padding: const EdgeInsets.all(11),
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
                                    backgroundImage: const AssetImage(
                                        'assets/images/profilepic.png'),
                                    child: Image.network(avatarUrl),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 50),
                                  Row(
                                    children: [
                                      _buildRatingStars(ratings),
                                    ],
                                  )
                                ],
                              ),
                              // Row(
                              //   children: [
                              //     _buildRatingStars(snapshot
                              //         .data
                              //         .docs[index]
                              //         .data["rating"]),
                              //   ],
                              // ),
                              // Text(
                              //     snapshot
                              //         .data
                              //         .docs[index]
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
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  shape: const StadiumBorder(),
                                  backgroundColor: Colors.black,
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
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return ListView(
        controller: widget.scrollController,
        padding: EdgeInsets.zero,
        children: <Widget>[
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.32,
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.06,
                  left: MediaQuery.of(context).size.width * 0.09,
                  child: const Row(
                    children: [
                      // GestureDetector(
                      //   onTap: () async {
                      //     if (tikTokUrl != null) {
                      //       await _launchUrl(tikTokUrl ?? "", context);
                      //     }
                      //   },
                      //   child: Image.asset(
                      //     'assets/images/tiktok.png',
                      //     width: 50,
                      //     height: 50,
                      //   ),
                      // ),
                      // const SizedBox(
                      //   width: 15,
                      // ),
                      // GestureDetector(
                      //   onTap: () async {
                      //     if (instagramUrl != null) {
                      //       await _launchUrl(instagramUrl ?? "", context);
                      //     }
                      //   },
                      //   child: Image.asset(
                      //     'assets/images/instagram.png',
                      //     width: 50,
                      //     height: 50,
                      //   ),
                      // ),
                      // const SizedBox(
                      //   width: 15,
                      // ),
                      // GestureDetector(
                      //   onTap: () async {
                      //     if (facebookUrl != null) {
                      //       await _launchUrl(facebookUrl ?? "", context);
                      //     }
                      //   },
                      //   child: Image.asset(
                      //     'assets/images/facebook.png',
                      //     width: 50,
                      //     height: 50,
                      //   ),
                      // ),
                      // const SizedBox(
                      //   width: 15,
                      // ),
                      // GestureDetector(
                      //   onTap: () async {
                      //     addresses = await FlGeocoder(Constants.googlePlaceKey)
                      //         .findAddressesFromAddress(precise_address ?? "");
                      //     first = addresses.first;
                      //     // print("this is the location coord ${first.coordinates.latitude}");
                      //     lat = first.coordinates.latitude;
                      //     long = first.coordinates.longitude;
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (_) => MapPage(
                      //           loc: precise_address,
                      //           lat: lat,
                      //           long: long,
                      //         ),
                      //       ),
                      //     );
                      //   },
                      //   child: ClipRRect(
                      //     borderRadius: BorderRadius.circular(30),
                      //     child: Image.asset(
                      //       'assets/images/googlemap.png',
                      //       width: 50,
                      //       height: 50,
                      //     ),
                      //   ),
                      // ),
                      // const SizedBox(
                      //   width: 15,
                      // ),
                      // GestureDetector(
                      //   onTap: () async {
                      //     Share.share(
                      //         '${userName} located in ${address} envites you to his acumacum\'s business profile with the following app link https://acumacum.page.link/29hQ.');
                      //   },
                      //   child: const CircleAvatar(
                      //     radius: 25,
                      //     child: Icon(FontAwesomeIcons.share),
                      //   ),
                      // )
                    ],
                  ),
                ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.start,
                //   crossAxisAlignment: CrossAxisAlignment.center,
                //   children: [
                // Padding(
                //   padding: const EdgeInsets.only(top: 18.0, left: 20),
                //   child: SizedBox(
                //     height: 84,
                //     width: 84,

                //     //profilepic

                //     child: userImage != 'default'
                //         ? CircleAvatar(
                //             radius: 10,
                //             backgroundImage: NetworkImage(userImage ?? ""))
                //         : const CircleAvatar(
                //             radius: 10,
                //             backgroundImage:
                //                 AssetImage('assets/images/profilepic.png'),
                //           ),
                //   ),
                // ),
                //   ],
                // ),
                Positioned(
                  right: 24,
                  top: MediaQuery.of(context).size.height * 0.12,
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 0.0),
                        child: Row(children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // StreamBuilder<QuerySnapshot<Map>>(
                              //     stream: FirebaseFirestore.instance
                              //         .collection('Users')
                              //         .doc(data['id'])
                              //         .collection('BusinessAccount')
                              //         .doc('detail')
                              //         .collection('reviews')
                              //         .snapshots(),
                              //     builder: (context, snapshot) {
                              //       if (!snapshot.hasData) {
                              //         return const CircularProgressIndicator();
                              //       }
                              //       final data = snapshot.data?.docs;
                              //       double average = 0;
                              //       num sum = 0;
                              //       for (var star in data!) {
                              //         sum = sum + star['rating'];
                              //       }
                              //       average = sum / data.length;
                              //       return Row(
                              //         children: [
                              //           data.isNotEmpty
                              //               ? Text(
                              //                   average.toString(),
                              //                   style: const TextStyle(
                              //                       color: Colors.blue),
                              //                 )
                              //               : const Text(
                              //                   'No Reviews',
                              //                   style: TextStyle(
                              //                       color: Colors.blue),
                              //                 ),
                              //           data.isNotEmpty
                              //               ? _buildRatingStars(1)
                              //               : const SizedBox(),
                              //         ],
                              //       );
                              //     }),
                              SizedBox(
                                width: MediaQuery.of(context).size.width - 40,
                                child: Text("$userName",
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 3,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    )),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_pin,
                                    color: Colors.grey,
                                    size: 18,
                                  ),
                                  Text(
                                    address == "default"
                                        ? "Location not added"
                                        : address ?? "",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              const Row(
                                children: [
                                  Icon(Icons.calendar_month,
                                      color: Colors.grey, size: 18)
                                ],
                              ),
                              const SizedBox(
                                height: 13,
                              ),
                              ButtonTheme(
                                  minWidth: 40.0,
                                  height: 20.0,
                                  buttonColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(30.0)),
                                  child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black),
                                      child: const Text(
                                        "Edit",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      onPressed: () {
                                        instagramController.text =
                                            instagramUrl ?? "";
                                        tiktokController.text = tikTokUrl ?? "";
                                        facebookController.text =
                                            facebookUrl ?? "";
                                        _userEditBottomSheet(context);
                                      })),
                              GestureDetector(
                                onTap: () async {
                                  DocumentSnapshot snapshot =
                                      await FirebaseFirestore.instance
                                          .collection('Users')
                                          .doc(userId)
                                          .get();
                                  UserModel user =
                                      UserModel.fromDocument(snapshot);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            SettingsPage(user: user)),
                                  );
                                },
                                child: Container(
                                  height: 32,
                                  width: 32,
                                  decoration: const BoxDecoration(
                                      image: DecorationImage(
                                          image: AssetImage(
                                              "assets/images/settings.png"),
                                          fit: BoxFit.cover),
                                      shape: BoxShape.circle,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(children: [
            TabBar(
              unselectedLabelColor: Colors.black,
              labelColor: const Color.fromARGB(255, 3, 59, 161),
              tabs: const [
                Tab(
                  text: 'Services',
                ),
                Tab(text: 'Products'),
                Tab(
                  text: 'Reviews',
                ),
              ],
              controller: tabController,
              indicatorSize: TabBarIndicatorSize.tab,
            ),
          ]),
          const SizedBox(
            height: 8,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                "Recomandari",
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 150,
                width: MediaQuery.of(context).size.width - 30,
                child: FutureBuilder<QuerySnapshot<Map>>(
                    future: FirebaseFirestore.instance
                        .collection("Users")
                        .doc(userId)
                        .collection("BusinessAccount")
                        .doc("detail")
                        .collection("reviews")
                        .get(),
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot<Map>> snapshot) {
                      if (snapshot.hasData) {
                        return ListView.builder(
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            itemCount: snapshot.data?.docs.length,
                            itemBuilder: (context, index) {
                              var data =
                                  snapshot.data?.docs[index].data() as Map;
                              return GestureDetector(
                                onTap: () {
                                  viewReview(
                                    data["rating"],
                                    data["name"],
                                    data["text"],
                                    data["avatarUrl"],
                                  );
                                },
                                child: Container(
                                  // width: 200,
                                  // margin: EdgeInsets.only(
                                  //     top: 8, bottom: 8, right: 12),
                                  margin: const EdgeInsets.only(
                                      right: 12, top: 8, bottom: 0),
                                  padding: const EdgeInsets.all(11),
                                  // width: MediaQuery.of(context)
                                  //         .size
                                  //         .width -
                                  //     140,
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 2,
                                            spreadRadius: 1)
                                      ],
                                      borderRadius: BorderRadius.circular(4)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            backgroundImage: const AssetImage(
                                                'assets/images/profilepic.png'),
                                            child: Image.network(
                                                data["avatarUrl"]),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(data["name"],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              _buildRatingStars(data["rating"]),
                                            ],
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 1),
                                      // Row(
                                      //   children: [
                                      //     _buildRatingStars(snapshot
                                      //         .data
                                      //         .docs[index]
                                      //         .data["rating"]),
                                      //   ],
                                      // ),
                                      // Text(
                                      //     snapshot
                                      //         .data
                                      //         .docs[index]
                                      //         .data["text"],
                                      //     overflow:
                                      //         TextOverflow.ellipsis,
                                      //     textScaleFactor: 1.1),
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        width:
                                            MediaQuery.of(context).size.width -
                                                140,
                                        child: Text(
                                          data["text"],
                                          overflow: TextOverflow.ellipsis,
                                          textScaleFactor: 1.1,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            });
                      } else {
                        return const CircularProgressIndicator();
                      }
                    }),
              )
            ],
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
              backgroundColor: const Color.fromARGB(255, 3, 16, 133),
              tooltip: 'Increment',
              onPressed: () {
                showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return Container(
                          width: MediaQuery.of(context).size.width,
                          height: 300.0,
                          color: Colors.white12,
                          child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(20.0),
                                    topLeft: Radius.circular(20.0)),
                              ),
                              child: Center(
                                  child: Column(children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.05,
                                ),
                                Container(
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 30,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'What do you want to add?',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.01,
                                          ),
                                          Container(
                                              child: Center(
                                            child: ButtonTheme(
                                                minWidth: 150,
                                                height: 40,
                                                child: TextButton(
                                                  style: TextButton.styleFrom(
                                                    backgroundColor:
                                                        const Color.fromARGB(
                                                            255, 3, 16, 133),
                                                    shape:
                                                        const StadiumBorder(),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              const AddServiceScreen()),
                                                    );
                                                  },
                                                  child: const Text(
                                                    'Service',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                )),
                                          )),
                                          SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.01,
                                          ),
                                          Container(
                                            child: const Center(
                                              child: Text(
                                                'or',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 17,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.01,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                    child: Center(
                                  child: ButtonTheme(
                                      minWidth: 150,
                                      height: 40,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(
                                              255, 3, 16, 133),
                                          shape: const StadiumBorder(),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const AddProductScreen()),
                                          );
                                        },
                                        child: const Text(
                                          'Product',
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      )),
                                )),
                              ]))));
                    });
              },
              child: const Text(
                'Add services/product',
                style: TextStyle(
                    color: Colors.yellow, fontWeight: FontWeight.bold),
              )),
        ]);
  }

  void _userEditBottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * .90,
              child: Padding(
                padding: const EdgeInsets.only(left: 15.0, top: 15.0),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Text("Schimba nume profil"),
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
                            controller: _userNameController,
                            decoration: const InputDecoration(
                              helperText: "username",
                            ),
                          ),
                        )),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        ElevatedButton(
                            child: const Text('Salveaza nume'),
                            onPressed: () async {
                              String userName = _userNameController.text;
                              Map<String, dynamic> data = {
                                'name': userName,
                              };
                              
                              // Replace transaction with direct update
                              await FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(userId)
                                  .update(data);

                              Navigator.of(context).pop();
                            })
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/tiktok.png',
                            width: 50,
                            height: 50,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Expanded(
                            child: TextField(
                              controller: tiktokController,
                              decoration: const InputDecoration(
                                  hintText: "Paste your link here"),
                              onChanged: (str) {
                                FirebaseFirestore.instance
                                    .collection('Users')
                                    .doc(userId)
                                    .collection('Social')
                                    .doc('detail')
                                    .set({"tiktok": str},
                                        SetOptions(merge: true));
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/instagram.png',
                            width: 50,
                            height: 50,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Expanded(
                            child: TextField(
                              controller: instagramController,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                  hintText: "Paste your link here"),
                              onChanged: (str) {
                                FirebaseFirestore.instance
                                    .collection('Users')
                                    .doc(userId)
                                    .collection('Social')
                                    .doc('detail')
                                    .set({"instagram": str},
                                        SetOptions(merge: true));
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/facebook.png',
                            width: 50,
                            height: 50,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Expanded(
                            child: TextField(
                              controller: facebookController,
                              decoration: const InputDecoration(
                                  hintText: "Paste your link here"),
                              onChanged: (str) {
                                FirebaseFirestore.instance
                                    .collection('Users')
                                    .doc(userId)
                                    .collection('Social')
                                    .doc('detail')
                                    .set({"facebook": str},
                                        SetOptions(merge: true));
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.0),
                          ),
                          padding: const EdgeInsets.all(10.0),
                          backgroundColor: Colors.blue,
                          textStyle: const TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          getImage();
                        },
                        child: const Text("Adauga poza profil"))
                  ],
                ),
              ),
            ),
          );
        });
  }

  void addPicture(uploadTypes type, uploadTypes types, context) async {
    CollectionReference galleryReference;
    try {
      galleryReference = FirebaseFirestore.instance
          .collection("Users")
          .doc(userId)
          .collection(type == uploadTypes.GALLERY ? "Gallery" : "Story");
    } catch (e) {
      logger.e(
          "Gallery/story collection can't be accessed or instantiated\n${e.toString()}");
      rethrow;
    }
    Reference storageFolderReference;
    try {
      storageFolderReference = FirebaseStorage.instance
          .ref()
          .child(type == uploadTypes.GALLERY ? "Galleries" : "Stories")
          .child(userId);
    } catch (e) {
      logger.e(
          "Gallery/story storage reference can't be accessed or instantiated\n${e.toString()}");
      rethrow;
    }
    final pickedFile = types == uploadTypes.IMAGE
        ? await picker.pickImage(source: ImageSource.gallery)
        : await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      _image = File(pickedFile.path);
      DocumentReference docRef =
          await galleryReference.add({"url": "", "media": ""});
      Reference imgRef = storageFolderReference.child("image_${docRef.id}");
      try {
        Uint8List imageData = File(pickedFile.path).readAsBytesSync();
        imgRef.putData(imageData).then((snapshot) {
          snapshot.ref.getDownloadURL().then((value) {
            galleryReference.doc(docRef.id).set({
              "url": value.toString(),
              "media": types == uploadTypes.IMAGE ? "image" : "video"
            });
            setState(() {});
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddSearchTags(id: userId),
              ),
            );
          });
        });
      } on FirebaseException catch (error) {
        logger.e(error.toString());
      }
    }
  }

  createChatroomAndStartConversation(String userName) {
    // authentication.createChatRoom()
  }

  void getData() {
    FirebaseFirestore.instance
        .collection("Users")
        .doc(userId)
        .snapshots()
        .listen((event) {
      setState(() {
        userImage = (event.data() as Map)['avatarUrl'] ?? "";
        address = (event.data() as Map)['address'] ?? "";
        userName = (event.data() as Map)['name'] ?? "";
      });
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
      setState(() {
        facebookUrl =
            event.data() == null ? null : (event.data() as Map)['facebook'];
        instagramUrl =
            event.data() == null ? null : (event.data() as Map)['instagram'];
        tikTokUrl =
            event.data() == null ? null : (event.data() as Map)['tiktok'];
      });
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
