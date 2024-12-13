import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:acumacum/ui/chatScreen.dart';

class ReadPostScreen extends StatefulWidget {
  final String currentUser;
  final String username;
  final DateTime dateTime;
  final String description;
  final String postID;
  final String postUser;

  const ReadPostScreen(
      {super.key,
      required this.username,
      required this.dateTime,
      required this.description,
      required this.currentUser,
      required this.postID,
      required this.postUser});

  @override
  _ReadPostScreenState createState() => _ReadPostScreenState();
}

class _ReadPostScreenState extends State<ReadPostScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.username,
                          textScaleFactor: 1.2,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat.yMMMMd().format(widget.dateTime),
                          textScaleFactor: 1.1,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.50,
                      child: SingleChildScrollView(
                        child: Text(
                          widget.description,
                          textScaleFactor: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                DocumentSnapshot snapshot;
                snapshot = await FirebaseFirestore.instance.collection('Users').doc(widget.postUser).get();
                Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                  return ChatScreen(
                    price: 'N/A',
                    serviceProviderId: snapshot.id,
                    userName: (snapshot.data() as Map)['name'],
                    avatarUrl: (snapshot.data() as Map)['avatarUrl'],
                  );
                }));
              },
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Colors.black,
              ),
              child: const Padding(
                padding: EdgeInsets.only(left: 20, right: 20),
                child: Text(
                  "Message",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            Visibility(
              visible: widget.currentUser == widget.postUser ? true : false,
              child: ElevatedButton(
                onPressed: () {
                  FirebaseFirestore.instance.collection("post").doc(widget.postID).delete();
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: Colors.red[800],
                ),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Colors.transparent,
              ),
              child: const Text("Back"),
            ),
          ],
        ),
      ),
    );
  }
}
