import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_geocoder/fl_geocoder.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:acumacum/screens/read_post_screen.dart';
import 'package:acumacum/ui/HomePage.dart';
import 'package:acumacum/utils/constants.dart';
import 'package:translator/translator.dart';

class CustomerPosts extends StatefulWidget {
  const CustomerPosts({super.key});

  @override
  State<CustomerPosts> createState() => CustomerPostsState();
}

class CustomerPostsState extends State<CustomerPosts> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  Stream<QuerySnapshot<Map>>? stream;

  String? userId;
  String? userName;
  String? userCity;

  // late Post newPost;
  bool showFab = true;
  late PersistentBottomSheetController bottomSheetController;
  TextEditingController descriptionController = TextEditingController();
  DateTime currentDateTime = DateTime.now();
  late DateTime thirdDay;
  Timestamp? thirdTimestamps;
  String? country;
  bool check = false;

  @override
  void initState() {
    thirdDay = currentDateTime.subtract(const Duration(days: 3));
    thirdTimestamps = Timestamp.fromDate(thirdDay);
    userId = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance
        .collection("Users")
        .doc(userId)
        .get()
        .then((value) {
      userName = (value.data() as Map<String, dynamic>)["name"];
      userCity = (value.data() as Map<String, dynamic>)["address"];
    });
    stream = FirebaseFirestore.instance
        .collection("post")
        .orderBy("createdOn", descending: true)
        .where('createdOn', isGreaterThan: thirdTimestamps)
        .snapshots();
    getLocation();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      floatingActionButton: _floatingActionButton(),
      backgroundColor: Colors.blue,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
        actions: const [],
        elevation: 0.0,
      ),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                  ),
                  height: MediaQuery.of(context).size.height * 0.12,
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.02,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 15),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.circle,
                              color: Colors.white,
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Welcome,",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "Find someone to help you or \noffer your services",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(top: 40, left: 15, right: 15),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                  ),
                  height: MediaQuery.of(context).size.height * .70,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Text(
                        "Real Time",
                        style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                      const Text(
                        "You can post any need you have and someone will come with an offer",
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Expanded(child: _postBuilder()),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _postBuilder() {
    return StreamBuilder(
      stream: stream,
      builder: (context, AsyncSnapshot<QuerySnapshot<Map>?> snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (!snapshot.hasData) {
            return const LinearProgressIndicator();
          } else if (snapshot.hasError) {
            return Text("error${snapshot.error}");
          } else {
            return Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: ListView.builder(
                itemCount: snapshot.data?.docs.length,
                itemBuilder: (BuildContext context, int index) {
                  DocumentSnapshot<Map>? postSnapshot =
                      snapshot.data?.docs[index];
                  return FutureBuilder(
                    future: FirebaseFirestore.instance
                        .collection('Users')
                        .doc((postSnapshot?.data()
                            as Map<String, dynamic>)['userID'])
                        .get(),
                    builder: (BuildContext context,
                        AsyncSnapshot<DocumentSnapshot> snapshot2) {
                      if (!snapshot2.hasData) {
                        return const LinearProgressIndicator();
                      } else {
                        if ((snapshot2.data?.data()
                                    as Map<String, dynamic>)['country'] ==
                                country ||
                            (snapshot2.data?.data()
                                    as Map<String, dynamic>)['userRole'] ==
                                'Customer') {
                          return _postUI(postSnapshot!);
                        } else {
                          return Container();
                        }
                      }
                    },
                  );
                },
              ),
            );
          }
        } else {
          return Container();
        }
        /* if (!snapshot.hasData) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text("error" + snapshot.error);
        } else {
          return ListView.builder(
            itemCount: snapshot.data.documents.length,
            itemBuilder: (BuildContext context, int index) {
              DocumentSnapshot postSnapshot = snapshot.data.documents[index];
              return _postUI(postSnapshot);
            },
          );
        } */
      },
    );
  }

  Widget _postUI(DocumentSnapshot<Map> postSnapshot) {
    return SizedBox(
      height: 140,
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 5.0,
        child: Padding(
          padding:
              const EdgeInsets.only(top: 10, bottom: 0, right: 10, left: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (postSnapshot.data() as Map)['username'] ?? "",
                    textScaleFactor: 1.2,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    (postSnapshot.data() as Map)['createdOn'] == null
                        ? ""
                        : _timestampConversion(
                            (postSnapshot.data() as Map)['createdOn'].toDate()),
                    textScaleFactor: 1.1,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[600],
                    ),
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 30),
                child: Text(
                  (postSnapshot.data() as Map)['description'] ?? "",
                  textScaleFactor: 1.1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(
                color: Colors.grey,
              ),
              Align(
                child: TextButton(
                  child: const Text(
                    "Read more",
                    style: TextStyle(color: Colors.black),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return ReadPostScreen(
                            username: (postSnapshot.data() as Map)['username'],
                            dateTime: (postSnapshot.data() as Map)['createdOn']
                                .toDate(),
                            description:
                                (postSnapshot.data() as Map)['description'],
                            postUser: (postSnapshot.data() as Map)['userID'],
                            currentUser: userId!,
                            postID: postSnapshot.id,
                          );
                        },
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  String _timestampConversion(DateTime dateTime) {
    return ("${dateTime.day}/${dateTime.month}");
  }

  Widget _floatingActionButton() {
    return showFab
        ? FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              bottomSheetController = scaffoldKey.currentState!
                  .showBottomSheet((BuildContext context) => Container(
                        color: Colors.grey[200],
                        height: 250,
                        child: Stack(
                          children: [
                            const Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Text(
                                  "Ready to create post",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    top: 20, right: 20, left: 20, bottom: 5),
                                child: TextField(
                                  controller: descriptionController,
                                  onEditingComplete: () {},
                                  keyboardType: TextInputType.multiline,
                                  maxLines: 5,
                                  decoration: InputDecoration(
                                    fillColor: Colors.white,
                                    filled: true,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                  ),
                                  onPressed: () {
                                    if (descriptionController.text == "") {
                                      _alertNoText(context);
                                    } else {
                                      print("post pressed");
                                      showFoatingActionButton(false);
                                      bottomSheetController.close.call();
                                      FirebaseFirestore.instance
                                          .collection("post")
                                          .doc()
                                          .set({
                                        'userID': userId,
                                        'description':
                                            descriptionController.text,
                                        'username': userName,
                                        'city': userCity,
                                        'createdOn':
                                            FieldValue.serverTimestamp()
                                      });
                                      setState(() {
                                        descriptionController.clear();
                                      });
                                    }
                                  },
                                  child: const Padding(
                                    padding:
                                        EdgeInsets.only(left: 20, right: 20),
                                    child: Text(
                                      "Post",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ));
              showFoatingActionButton(false);
              bottomSheetController.closed.then((value) {
                showFoatingActionButton(true);
              });
            },
          )
        : Container();
  }

  void showFoatingActionButton(bool value) {
    setState(() {
      showFab = value;
    });
  }

  void _alertNoText(BuildContext context) {
    Alert(
      context: context,
      type: AlertType.warning,
      title: "Post",
      desc: "You have not written any text",
      buttons: [
        DialogButton(
          onPressed: () => Navigator.pop(context),
          width: 120,
          child: const Text(
            "Close",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        )
      ],
    ).show();
  }

  getLocation() async {
    LocationPermission permission;
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      try {
        final translator = GoogleTranslator();
        logger.e("Requesting permission 1");
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);

        final coordinates = Location(position.latitude, position.longitude);
        logger.e("Requesting permission 2");

        final addresses = await FlGeocoder(Constants.googlePlaceKey)
            .findAddressesFromLocationCoordinates(location: coordinates);
        logger.e("here is country: ${addresses.first.country!.longName}");
        setState(() {
          country = addresses.first.country!.longName;
          translator.translate(country!, to: 'en').then((value) {
            country = value.text;
          });
        });
        await Future.delayed(const Duration(seconds: 1), () {
          setState(() {});
        });
      } on GeocodeFailure catch (e) {
        if (e is PermissionDeniedException) {
          logger.e(e);
        }
        logger.e(e.message);
        return null;
      }
    } else {
      logger.e("Not Requesting permission");
    }
  }
}

/*class MyFloatingActionButton extends StatefulWidget {
  final String userName;
  final String userCity;

  const MyFloatingActionButton(
      {Key key, @required this.userName, @required this.userCity})
      : super(key: key);
  @override
  _MyFloatingActionButtonState createState() => _MyFloatingActionButtonState();
}

class _MyFloatingActionButtonState extends State<MyFloatingActionButton> {
  bool showFab = true;

  @override
  Widget build(BuildContext context) {
    PersistentBottomSheetController bottomSheetController;
    TextEditingController descriptionController = TextEditingController();
    return showFab
        ? FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () {
              print(widget.userName);
              bottomSheetController = showBottomSheet(
                  context: context,
                  builder: (context) => Container(
                        color: Colors.grey[200],
                        height: 250,
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  "Ready to create post",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    top: 20, right: 20, left: 20, bottom: 5),
                                child: TextField(
                                  controller: descriptionController,
                                  onEditingComplete: () {},
                                  keyboardType: TextInputType.multiline,
                                  maxLines: 5,
                                  decoration: InputDecoration(
                                    fillColor: Colors.white,
                                    filled: true,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: ElevatedButton(
                                  color: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  onPressed: () {
                                    if (descriptionController.text == null ||
                                        descriptionController.text == "") {
                                      _alertNoText(context);
                                    } else {
                                      print("post pressed");
                                      print(widget.userName);
                                      showFoatingActionButton(false);
                                      bottomSheetController.close.call();
                                      Firestore.instance
                                          .collection("post")
                                          .document()
                                          .setData({
                                        'description':
                                            descriptionController.text,
                                        'username': widget.userName,
                                        'city': widget.userCity,
                                        'createdOn':
                                            FieldValue.serverTimestamp()
                                      });
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 20, right: 20),
                                    child: Text(
                                      "Post",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ));
              showFoatingActionButton(false);
              bottomSheetController.closed.then((value) {
                showFoatingActionButton(true);
              });
            },
          )
        : Container();
  }

  void showFoatingActionButton(bool value) {
    setState(() {
      showFab = value;
    });
  }

  void _alertNoText(BuildContext context) {
    Alert(
      context: context,
      type: AlertType.warning,
      title: "Post",
      desc: "You have not written any text",
      buttons: [
        DialogButton(
          child: Text(
            "Close",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () => Navigator.pop(context),
          width: 120,
        )
      ],
    ).show();
  }
} */
/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flappy_search_bar/flappy_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:acumacum/google_nav_bar.dart';
import 'package:acumacum/post_detail.dart';
import 'package:acumacum/post_model.dart';
import 'UserProfiles.dart';
import 'viewProfiles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String userId;
String userName;
String userCity;
Post newPost;

class CustomerPosts extends StatefulWidget {
  @override
  CustomerPostsState createState() => CustomerPostsState();
}

class CustomerPostsState extends State<CustomerPosts> {
  TextEditingController textEditingController = TextEditingController();
  final database = Firestore.instance;
  String searchString;

  String post;
  final myController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    FirebaseAuth.instance.currentUser().then((value) {
      userId = value.uid;
      Firestore.instance
          .collection("Users")
          .document(userId)
          .get()
          .then((value) {
        userName = value.data["name"];
        userCity = value.data["address"];
        print(userName + "     City ===" + userCity);
        //newPost=new Post(username: userName,city: userCity,description: "");
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Container(
              child: Column(children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 60, left: 20, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "Hey there,\n customers are needing you👀 ",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Helvetica',
                        fontSize: 23),
                  ),
                  SizedBox(height: 15),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 200,
                        width: 360,
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: TextField(
                            controller: myController,
                            maxLines: 7,
                            decoration: InputDecoration.collapsed(
                                hintText: "Enter your text here"),
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(60),
                              topRight: Radius.circular(60),
                              bottomLeft: Radius.circular(60),
                              bottomRight: Radius.circular(60)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset: Offset(0, 3),
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height / 3.4),
                        child: ElevatedButton(
                            onPressed: () {
                              print(post);
                              if (myController.text == null) {
                                print("post description is null");
                              } else {
                                Firestore.instance
                                    .collection("post")
                                    .document()
                                    .setData({
                                  'description': myController.text,
                                  'username': userName,
                                  'city': userCity,
                                  'createdOn': FieldValue.serverTimestamp()
                                });
                              }
                            },
                            child: Text(
                              "POST",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: new BorderRadius.circular(18.0),
                            ),
                            color: Colors.lightBlueAccent),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Center(
                    child: Text("REAL TIME",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ],
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height / 2.3,
              child: StreamBuilder(
                stream: Firestore.instance
                    .collection("post")
                    .orderBy("createdOn", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  print(snapshot.data);
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  } else {
                    return ListView.builder(
                        itemCount: snapshot.data.documents.length,
                        itemBuilder: (BuildContext ctx, int index) {
                          DocumentSnapshot myPosts =
                              snapshot.data.documents[index];

                          return Padding(
                            padding: EdgeInsets.only(
                                bottom: 4, top: 4, left: 10, right: 10),
                            child: Container(
                              width: MediaQuery.of(context).size.width / 1.8,
                              height: MediaQuery.of(context).size.height / 5.1,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                        top: 10, bottom: 10, left: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          myPosts["username"],
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(
                                          height: 8,
                                        ),
                                        Container(
                                          width: 250,
                                          child: Text(
                                            myPosts["description"],
                                            overflow: TextOverflow.clip,
                                            maxLines: 2,
                                          ),
                                        ),
                                        Visibility(
                                          visible:
                                              myPosts["username"] == userName
                                                  ? true
                                                  : false,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              print(myPosts.documentID);
                                              Firestore.instance
                                                  .collection("post")
                                                  .document(myPosts.documentID)
                                                  .delete();
                                            },
                                            child: Text("Delete"),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (context) => PostDetail(
                                                  myPosts["username"],
                                                  myPosts["description"])));
                                    },
                                    child: Container(
                                      width:
                                          MediaQuery.of(context).size.width / 5,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.lightBlueAccent,
                                        borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(20),
                                            topRight: Radius.circular(20),
                                            bottomLeft: Radius.circular(20),
                                            bottomRight: Radius.circular(20)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.5),
                                            spreadRadius: 5,
                                            blurRadius: 7,
                                            offset: Offset(0, 3),
                                          )
                                        ],
                                      ),
                                      child: Padding(
                                          padding: EdgeInsets.only(
                                              top: 25, left: 12),
                                          child: Text(
                                            "Read More",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20),
                                          )),
                                    ),
                                  )
                                ],
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 5,
                                    blurRadius: 7,
                                    offset: Offset(0, 3),
                                  )
                                ],
                              ),
                            ),
                          );
                        });
                  }
                  if (snapshot.hasError) {
                    print("err:${snapshot.error}");
                  }
                },
              ),
            )
          ])),
        ));
  }
}

class TopText extends StatelessWidget {
  String post;
  final myController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 60, left: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "Hey there,\n customers are needing you👀 ",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Helvetica',
                fontSize: 23),
          ),
          SizedBox(height: 15),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 200,
                width: 360,
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: TextField(
                    controller: myController,
                    maxLines: 8,
                    decoration: InputDecoration.collapsed(
                        hintText: "Enter your text here"),
                  ),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(60),
                      topRight: Radius.circular(60),
                      bottomLeft: Radius.circular(60),
                      bottomRight: Radius.circular(60)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    )
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                child: ElevatedButton(
                    onPressed: () {
                      print(post);
                      if (myController.text == null) {
                        print("post description is null");
                      } else {
                        Firestore.instance
                            .collection("post")
                            .document()
                            .setData({
                          'description': myController.text,
                          'username': userName,
                          'city': userCity
                        });
                      }
                    },
                    child: Text(
                      "POST",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(18.0),
                    ),
                    color: Colors.blueAccent),
              ),
            ],
          ),
          SizedBox(
            height: 15,
          ),
          Center(
            child: Text("REAL TIME",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}*/
