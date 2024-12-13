import 'package:flutter/material.dart';
import 'package:acumacum/ui/viewProfile.dart';

class UserHandling extends StatefulWidget {
  final String uid;

  const UserHandling({super.key, required this.uid});

  @override
  State<UserHandling> createState() => UserHandlingState();
}

class UserHandlingState extends State<UserHandling> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: StoryProfile(
          uid: widget.uid,
          currentUserID: widget.uid,
        ),
      ),
    );
  }
}
