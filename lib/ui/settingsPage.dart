import 'package:acumacum/notifications_setup/push_notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:acumacum/model/User.dart';
import 'package:acumacum/ui/PrivacyAndSecurity.dart';
import 'package:acumacum/ui/TermsAndConditions.dart';
import 'package:acumacum/ui/add_search_tags.dart';
import 'package:acumacum/ui/block_page.dart';
import 'package:acumacum/ui/splash_screen.dart';
import 'package:acumacum/ui/MyPanel.dart';

import 'LoginScreen.dart';
import 'auth.dart';
import 'package:acumacum/ui/SubscriptionPlanPost.dart';

class SettingsPage extends StatefulWidget {
  final UserModel user;

  const SettingsPage({super.key, required this.user});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String curretnUserId;
  late String userRole;
  bool values = false;

  var dateDifference;
  var dateDifferences;

  var date;
  var now;
  var diff;
  var diff1;

  var noOfDays;
  var noOfHours;

  @override
  void initState() {
    super.initState();
    curretnUserId = widget.user.uid;
    userRole = widget.user.userRole;
    print(curretnUserId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Colors.transparent,
                width: 0,
              ),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.only(left: 16, top: 25, right: 16),
        child: ListView(
          children: [
            const Text(
              "Setari",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                fontFamily: '.SF UI Display',
              ),
            ),
            const SizedBox(
              height: 40,
            ),
            const Row(
              children: [
                Icon(
                  Icons.person,
                  color: Colors.red,
                ),
                SizedBox(
                  width: 8,
                ),
                Text(
                  "Cont",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    fontFamily: '.SF UI Display',
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const Divider(
              height: 15,
              thickness: 2,
            ),
            const SizedBox(
              height: 10,
            ),
            myPanel(context, "Vezi statistici"),
            buttonResetPass(context, "Reseteaza parola"),
            disableAccount(context, "Dezactiveaza contul"),
            deleteAccount(context, "Sterge contul"),
            widget.user.userRole == 'Customer' ? Container() : promoteAccount(context, "Promovare"),
            termsAndConditions(context, "Termeni & Conditii"),
            privacyAndSecurity(context, "Confidentialitate & Securitate"),
            generateQR(context, "Genereaza QR-Code"),
            const SizedBox(
              height: 40,
            ),
            const Row(
              children: [
                Icon(
                  Icons.volume_up,
                  color: Colors.red,
                ),
                SizedBox(
                  width: 8,
                ),
                Text(
                  "Notificari",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    fontFamily: '.SF UI Display',
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const Divider(
              height: 15,
              thickness: 2,
            ),
            const SizedBox(
              height: 10,
            ),
            buildNotificationOptionRow("New for you", true),
            widget.user.userRole == 'Customer' ? Container() : buildNotificationOptionRow("Opportunity", true),
            const SizedBox(
              height: 50,
            ),
            Center(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  PushNotificationService messagingService = PushNotificationService();
                  messagingService.deleteFCMToken();
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GetstartedScreen()));
                },
                child: const Text("Delogheaza-te",
                    style: TextStyle(fontSize: 16, letterSpacing: 2.2, color: Colors.black)),
              ),
            ),
            const SizedBox(height: 48),
            Container(
                alignment: Alignment.bottomCenter,
                child: const Text(
                  'Pentru orice problema: support@acumacum-app.com',
                  style: TextStyle(fontSize: 10),
                )),
          ],
        ),
      ),
    );
  }

  Row buildNotificationOptionRow(String title, bool isActive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w400, fontFamily: '.SF UI Display', color: Colors.black87),
        ),
        Transform.scale(
            scale: 0.7,
            child: CupertinoSwitch(
              value: isActive,
              onChanged: (bool val) {},
            ))
      ],
    );
  }

  GestureDetector promoteAccount(BuildContext contexts, String title) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SubscriptionPlanPost(),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                fontFamily: '.SF UI Display',
                color: Colors.black87,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  GestureDetector buttonResetPass(BuildContext context, String title) {
    return GestureDetector(
      onTap: () {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(title),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Reset your password by email"),
                    TextFormField(
                      validator: (val) => val!.isEmpty ? 'Enter Email' : null,
                      onChanged: (val) {
                        setState(() => email = val);
                      },
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                          hintText: 'Enter email',
                          hintStyle: TextStyle(fontFamily: 'Antra', fontSize: 12.0, color: Colors.black)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      child: const Text(
                        "Reset",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                      },
                    )
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Close")),
                ],
              );
            });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                fontFamily: '.SF UI Display',
                color: Colors.black87,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  GestureDetector disableAccount(BuildContext context, String title) {
    return GestureDetector(
      onTap: () {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(title),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Esti sigur ca vrei sa iti dezactivezi contul?"),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('Users').doc(curretnUserId).update({
                              'disabled': true,
                            }).then((value) => {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => BlockPage(currentUserId: curretnUserId)),
                                  )
                                });
                          },
                          child: const Text(
                            "Yes",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "No",
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Close")),
                ],
              );
            });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                fontFamily: '.SF UI Display',
                color: Colors.black87,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  GestureDetector deleteAccount(BuildContext context, String title) {
    return GestureDetector(
      onTap: () {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(title),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Esti sigur ca vrei sa iti stergi contul?"),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection("Users")
                                .doc(curretnUserId)
                                .collection('BusinessAccount')
                                .doc('detail')
                                .get()
                                .then((value) async {
                              if (value.exists) {
                                String cat = (value.data() as Map<String, dynamic>)['category'];
                                await FirebaseFirestore.instance.collection(cat).doc(curretnUserId).delete();
                                await FirebaseFirestore.instance.collection('dusers').doc(curretnUserId).delete();
                                await FirebaseFirestore.instance
                                    .collection("Users")
                                    .doc(curretnUserId)
                                    .get()
                                    .then((value) async {
                                  var name = (value.data() as Map<String, dynamic>)['name'];
                                  await FirebaseFirestore.instance
                                      .collection('ChatRoom')
                                      .where("users", arrayContains: '$name($curretnUserId)')
                                      .get()
                                      .then((snapshot) {
                                    for (DocumentSnapshot ds in snapshot.docs) {
                                      ds.reference.delete();
                                    }
                                  });
                                });

                                FirebaseAuth.instance.signOut();
                                Navigator.pop(context);
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                              } else {
                                await FirebaseFirestore.instance.collection('dusers').doc(curretnUserId).delete();
                                await FirebaseFirestore.instance
                                    .collection("Users")
                                    .doc(curretnUserId)
                                    .get()
                                    .then((value) async {
                                  var name = (value.data() as Map<String, dynamic>)['name'];
                                  await FirebaseFirestore.instance
                                      .collection('ChatRoom')
                                      .where("users", arrayContains: '$name($curretnUserId)')
                                      .get()
                                      .then((snapshot) {
                                    for (DocumentSnapshot ds in snapshot.docs) {
                                      ds.reference.delete();
                                    }
                                  });
                                });

                                FirebaseAuth.instance.signOut();
                                Navigator.pop(context);
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                              }
                            });
                          },
                          child: const Text(
                            "Yes",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                          child: const Text(
                            "No",
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Close")),
                ],
              );
            });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                fontFamily: '.SF UI Display',
                color: Colors.black87,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  GestureDetector termsAndConditions(BuildContext context, String title) {
    return GestureDetector(
      onTap: () {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(title),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Read the terms and conditions"),
                    const SizedBox(
                      height: 20,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const Terms()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text(
                        "Read",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Close")),
                ],
              );
            });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                fontFamily: '.SF UI Display',
                color: Colors.black87,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  GestureDetector privacyAndSecurity(BuildContext context, String title) {
    return GestureDetector(
      onTap: () {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(title),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Read Privacy and Security Doc"),
                    const SizedBox(
                      height: 20,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const Privacy()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text(
                        "Read",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Close")),
                ],
              );
            });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                fontFamily: '.SF UI Display',
                color: Colors.black87,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  GestureDetector generateQR(BuildContext context, String title) {
    return GestureDetector(
      onTap: () {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(title),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 200,
                      width: 200,
                      child: QrImageView(data: widget.user.uid),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Close")),
                ],
              );
            });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                fontFamily: '.SF UI Display',
                color: Colors.black87,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  GestureDetector myPanel(BuildContext context, String title) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyPanel()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                fontFamily: '.SF UI Display',
                color: Colors.black87,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
