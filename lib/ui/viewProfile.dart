import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:acumacum/ui/story_model.dart';

import 'UserPage.dart';

class StoryProfile extends StatefulWidget {
  final String uid;
  final String currentUserID;

  const StoryProfile({
    super.key,
    required this.uid,
    required this.currentUserID,
  });

  @override
  State<StoryProfile> createState() => StoryProfileState();
}

class StoryProfileState extends State<StoryProfile> {
  List<Story> storiesList = [];
  PanelController panelController = PanelController();
  Color bgColor = Colors.transparent;

  late String currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance
        .collection('Users/${widget.uid}/Story')
        .get()
        .then((value) {
      if (value.docs.isEmpty) {
        panelController.close();
      }
      for (var element in value.docs) {
        storiesList.add(Story(
          url: (element.data() as Map)['url'],
          media: (element.data() as Map)['media'],
          id: element.id,
        ));
      }
      setState(() {});
      getStoryData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SlidingUpPanel(
        color: bgColor,
        controller: panelController,
        onPanelOpened: () => setState(() => bgColor = Colors.white),
        onPanelClosed: () => setState(() => bgColor = Colors.transparent),
        panelBuilder: (ScrollController sc) {
          UserPage pg = UserPage();
          pg.scrollController = sc;
          return pg;
        },
      ),
    );
  }

  void getStoryData() async {
    QuerySnapshot<Map<String, dynamic>> query = await FirebaseFirestore.instance
        .collection('Users/$currentUser/Story')
        .get();
    storiesList.clear();
    if (query.docs.isNotEmpty) {
      for (DocumentSnapshot<Map> doc in query.docs) {
        setState(() {
          storiesList.add(Story.fromDocument(doc));
        });
      }
    }
  }
}
