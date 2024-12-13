import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:acumacum/model/User.dart' as acumacum;
import 'package:acumacum/ui/HomePage.dart';
import 'package:acumacum/ui/LoginPage.dart';
import 'package:acumacum/ui/choosedBusinessUser.dart';

class BusinessUserCheck extends StatefulWidget {
  final String uid;

  const BusinessUserCheck({super.key, required this.uid});

  @override
  _UserHandlingState createState() => _UserHandlingState();
}

class _UserHandlingState extends State<BusinessUserCheck> {
  String? userId;

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    userId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.uid)
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
            final data = snapshot.data?.data();
            return data == null
                ? const LoginPage()
                : Center(
                    child: FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection('Users')
                          .doc(widget.uid)
                          .get(),
                      builder: (BuildContext context,
                          AsyncSnapshot<DocumentSnapshot> snapshot) {
                        if (snapshot.hasData) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          acumacum.UserModel user =
                              acumacum.UserModel.fromDocument(snapshot.data!);
                          if (user.userRole == 'Business') {
                            if (user.country == null || user.country == "") {
                              return const BusinessPage();
                            } else {
                              return const Homepage();
                            }
                          } else {
                            return const Homepage();
                          }
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              snapshot.error.toString(),
                              style: const TextStyle(fontSize: 18.0),
                            ),
                          );
                        } else {
                          return const CircularProgressIndicator();
                        }
                      },
                    ),
                  );
          }),
    );
  }
}
