import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class AddProductScreen extends StatefulWidget {
  final imageFile;
  const AddProductScreen({super.key, this.imageFile});

  @override
  ProductContentPageState createState() => ProductContentPageState();
}

class ProductContentPageState extends State<AddProductScreen> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  Stream<QuerySnapshot<Map>>? stream;
  String? userId;
  String? nameproduct;
  String? weightproduct;
  String? descriptionproduct;
  TextEditingController nameproductController = TextEditingController();
  TextEditingController weightproductController = TextEditingController();

  TextEditingController descriptionController = TextEditingController();

  XFile? image;

  Future pickImage() async {
    try {
      image = await ImagePicker().pickImage(source: ImageSource.gallery);
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  @override
  void initState() {
    userId = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance
        .collection("Users")
        .doc(userId)
        .get()
        .then((value) {
      var data = value.data() as Map<String, dynamic>;
      nameproduct = data["nameproduct"];
      weightproduct = data["weightproduct"];
      descriptionproduct = data["descriptionproduct"];

      // Populate TextEditingControllers with existing data
      nameproductController.text = nameproduct ?? '';
      weightproductController.text = weightproduct ?? '';
      descriptionController.text = descriptionproduct ?? '';
    });
    super.initState();
  }

  @override
  void dispose() {
    // Dispose of the controllers when the widget is disposed
    nameproductController.dispose();
    weightproductController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 193, 59),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 30,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Text(
                  'Publish a new product',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              Center(
                child: Column(children: [
                  const Text(
                    'Add details about the product you want to sell',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  TextField(
                    controller: nameproductController,
                    decoration: InputDecoration(
                      hintText: "Name of the product",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none),
                      fillColor: Colors.black.withOpacity(0.1),
                      filled: true,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  TextField(
                    controller: weightproductController,
                    decoration: InputDecoration(
                      hintText: "Weight product",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none),
                      fillColor: Colors.black.withOpacity(0.1),
                      filled: true,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  TextField(
                    controller: descriptionController,
                    onEditingComplete: () {},
                    keyboardType: TextInputType.multiline,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "Add description about the product",
                      fillColor: Colors.black.withOpacity(0.1),
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
                  const SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    width: 250,
                    height: 70,
                    child: ElevatedButton(
                      onPressed: () {
                        pickImage();
                      },
                      style: ElevatedButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color.fromARGB(255, 3, 16, 133),
                      ),
                      child: const Text(
                        "+Add photo",
                        style: TextStyle(fontSize: 15, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    width: 250,
                    height: 70,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AddProductScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color.fromARGB(255, 3, 16, 133),
                      ),
                      child: const Text(
                        "Set price",
                        style: TextStyle(fontSize: 15, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: Image.asset(
                          '/Users/mathtech/development/production/trff/assets/images/addimage.png'),
                    ),
                    widget.imageFile != null
                        ? Image.file(
                            widget.imageFile,
                            height: 80,
                            width: 80,
                          )
                        : const Text("No image selected"),
                  ])
                ]),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color.fromARGB(255, 240, 240, 240),
        child: SizedBox(
          width: 50,
          child: ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance.collection("Users").doc(userId).set({
                  "nameproduct": nameproductController.text,
                  "weightproduct": weightproductController.text,
                  "descriptionproduct": descriptionController.text,
                }).then((_) {
                  // Navigate to the user profile page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => UserProfilePage(
                              imageFile: File(image!.path),
                            )),
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color.fromARGB(255, 3, 16, 133),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )),
        ),
      ),
    );
    // ignore: dead_code
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
}

class UserProfilePage extends StatefulWidget {
  final imageFile;

  const UserProfilePage({super.key, this.imageFile});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future:
            FirebaseFirestore.instance.collection("Users").doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching data'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No data found'));
          }

          final data = snapshot.data!.data()!;
          final nameproduct = data["nameprogram"];
          final weightproduct = data["typeprogram"];
          final descriptionproduct = data["typeequipment"];

          return Padding(
              padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
              child: Container(
                  height: 135,
                  width: MediaQuery.of(context).size.width * 0.90,
                  decoration: ShapeDecoration(
                    shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.all(Radius.circular(10))),
                    color: Colors.white,
                    shadows: [
                      BoxShadow(
                        color: Colors.grey.shade400,
                        blurRadius: 5,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const SizedBox(
                      width: 10,
                    ),
                    widget.imageFile != null
                        ? Image.file(
                            widget.imageFile,
                            height: 80,
                            width: 80,
                          )
                        : const Text("No image selected"),

                    const SizedBox(width: 10), // space between image & Column
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      //  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(
                          height: 25,
                        ),
                        Text('$nameproduct',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(
                          height: 5,
                        ),
                        Text('weight: $weightproduct',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey)),
                        const SizedBox(
                          height: 5,
                        ),
                        Text('bio: $descriptionproduct',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey)),
                      ],
                    )),
                  ])));
        },
      ),
    );
  }
}
