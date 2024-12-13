import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:acumacum/ui/UserProfiles.dart';
import 'package:acumacum/ui/story_model.dart';

import 'StoryScreen.dart';

class StoryProfiles extends StatefulWidget {
  final UserProfiles profileWidget;
  final String currentUserId;

  const StoryProfiles(this.profileWidget, this.currentUserId, {super.key});

  @override
  _StoryProfileState createState() => _StoryProfileState();
}

class _StoryProfileState extends State<StoryProfiles> {
  Color bgColor = Colors.transparent;
  PanelState panelState = PanelState.CLOSED;

  PanelController panelController = PanelController();
  final List<Story> _list = [];

  @override
  void initState() {
    super.initState();
    getData();
  }

  void getData() {
    FirebaseFirestore.instance
        .collection('Users/${widget.profileWidget.serviceProviderId}/Story')
        .doc()
        .snapshots()
        .listen((event) {
      if (event.exists) {
        _list.add(Story(
          url: (event.data() as Map<String, dynamic>)['url'] ?? "",
          media: (event.data() as Map<String, dynamic>)['media'] ?? "",
          id: event.id,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // getBusinessProviderStoryData();

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('Users')
              .doc(widget.profileWidget.serviceProviderId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Container();
            }
            final data = snapshot.data?.data() as Map<String, dynamic>;
            return data['disabled'] == true
                ? Center(
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
                              'This Account is disabled!',
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
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Go Back',
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
                )
                : SlidingUpPanel(
                    color: bgColor,
                    defaultPanelState: panelState,
                    onPanelOpened: () => setState(() => bgColor = Colors.white),
                    onPanelClosed: () =>
                        setState(() => bgColor = Colors.transparent),
                    panelBuilder: (ScrollController sc) {
                      return widget.profileWidget;
                    },
                    collapsed: Container(
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.keyboard_arrow_up,
                              color: Colors.white,
                            ),
                            Text(
                              "SwipeUp pentru mai multe informatii",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    //body: Stack(children: <Widget>[StoryScreen(stories: stories)]),
                    body: _list.isNotEmpty
                        ? StoryScreen(
                            stories: _list,
                            uid: widget.profileWidget.serviceProviderId,
                            currentUserID: widget.currentUserId,
                          )
                        : Container(
                            child: const Center(
                              child: Text(
                                  'Utilizatorul nu are story-uri adaugate'),
                            ),
                          ));
          }),
    );
  }
}
