import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:acumacum/ui/HomePage.dart';

class BlockPage extends StatelessWidget {
  final String currentUserId;

  const BlockPage({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    Future<bool> willPopCallback() async {
      // await showDialog or Show add banners or whatever
      // then
      return false; // return true if the route to be popped
    }

    return WillPopScope(
      onWillPop: willPopCallback,
      child: Scaffold(
        body: Container(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    color: Colors.blue,
                    child: Image.asset('assets/images/iconapp.jpg'),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.blue,
                    child: const Icon(
                      FontAwesomeIcons.lock,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.blue,
                    child: const Center(
                      child: Text(
                        'Your Account is disabled!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(45),
                    color: Colors.blue,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('Users').doc(currentUserId).update({
                          'disabled': false,
                        }).then((value) => {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const Homepage()),
                              )
                            });
                      },
                      child: const Text(
                        'Enable Your Account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
