import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fl_geocoder/fl_geocoder.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:acumacum/model/User.dart';
import 'package:acumacum/ui/settingsPage.dart';
import 'package:acumacum/utils/constants.dart';

class CustomerProfileScreen extends StatefulWidget {
  final String userID;

  const CustomerProfileScreen({
    super.key,
    required this.userID,
  });

  @override
  State<CustomerProfileScreen> createState() => CustomerProfileScreenState();
}

class CustomerProfileScreenState extends State<CustomerProfileScreen> {
  String? userImage;
  UserModel? user;
  String? address;

  @override
  void initState() {
    getLocation();
    getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Row(
            children: [
              Icon(
                Icons.arrow_back_ios,
                color: Colors.blue,
              ),
              Text("Back"),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 84,
            width: 84,
            child: GestureDetector(
              onTap: () async {
                await getImage();
              },
              child: userImage != null && userImage != "default"
                  ? CircleAvatar(
                      radius: 10,
                      backgroundImage: NetworkImage(userImage!),
                    )
                  : const CircleAvatar(
                      radius: 10,
                      backgroundImage:
                          AssetImage('assets/images/profilepic.png'),
                    ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Text(user == null ? "" : user!.name),
          const SizedBox(
            height: 30,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_outlined),
              const SizedBox(
                width: 5,
              ),
              Text(
                address == null ? "" : address!,
                overflow: TextOverflow.ellipsis,
              )
            ],
          ),
          const SizedBox(
            height: 30,
          ),
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.0),
              ),
              backgroundColor: Colors.black,
            ),
            child: const Padding(
              padding: EdgeInsets.only(left: 20, right: 20),
              child: Text(
                "Setting",
                style: TextStyle(color: Colors.white),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SettingsPage(user: user!)),
              );
            },
          ),
        ],
      ),
    );
  }

  late File _image;
  final picker = ImagePicker();

  Future<void> getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      print("user id at upload Picture =${widget.userID}");
      print('image path ${_image.path}');
      Reference storageReference = FirebaseStorage.instance.ref();
      UploadTask uploadTask = storageReference
          .child("Users Profile")
          .child(widget.userID)
          .putFile(_image);

      var dowurl = await uploadTask.snapshot.ref.getDownloadURL();
      String url = dowurl.toString();
      print('url is here $url');

      Map<String, dynamic> urlNull = {
        'avatarUrl': url,
      };
      DocumentReference<Map<String, dynamic>> prereference =
          FirebaseFirestore.instance.collection('Users').doc(widget.userID);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(prereference, urlNull);
      });
    }
  }

  void getData() {
    FirebaseFirestore.instance
        .collection("Users")
        .doc(widget.userID)
        .snapshots()
        .listen((event) {
      setState(() {
        user = UserModel.fromDocument(event);
        userImage = (event.data() as Map)['avatarUrl'];
      });
    });
  }

  getLocation() async {
    try {
      LocationPermission permission;
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
            .asStream()
            .listen((event) {
          final coordinates = Location(event.latitude, event.longitude);

          FlGeocoder(Constants.googlePlaceKey)
              .findAddressesFromLocationCoordinates(location: coordinates)
              .asStream()
              .listen((event2) {
            setState(() {
              address = event2.first.formattedAddress;
            });
          });
        });
      }
    } catch (e) {
      if (e is PermissionDeniedException) {
        print(e.message);
      }
    }
  }
}
