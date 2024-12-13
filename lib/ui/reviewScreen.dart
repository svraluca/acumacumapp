import 'package:flutter/material.dart';

class Reviewscreen extends StatefulWidget {
  const Reviewscreen({super.key});

  @override
  _ReviewscreenState createState() => _ReviewscreenState();
}

class _ReviewscreenState extends State<Reviewscreen> {
  @override
  void initState() {
    super.initState();
  }

  void viewReview(var ratings, String name, String review, String avatarUrl) {
    showGeneralDialog(
        context: context,
        barrierDismissible: false,
        transitionDuration: const Duration(
          milliseconds: 400,
        ), // how long it takes to popup dialog after button click
        pageBuilder: (_, __, ___) {
          // your widget implementation
          return Container(
              color: Colors.black.withOpacity(0.4),
              child: ListView(children: [
                Container(
                    // width: 200,
                    // margin: EdgeInsets.only(
                    //     top: 8, bottom: 8, right: 12),
                    margin: const EdgeInsets.only(right: 12, top: 8, bottom: 0),
                    padding: const EdgeInsets.all(11),
                    // width: MediaQuery.of(context)
                    //         .size
                    //         .width -
                    //     140,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              spreadRadius: 1)
                        ],
                        borderRadius: BorderRadius.circular(8)),
                    child: Column(children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(avatarUrl),
                          ),
                          const SizedBox(width: 4),
                          Text(name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.0,
                                  color: Colors.black)),
                          const SizedBox(width: 45),
                          _buildRatingStars(ratings)
                        ],
                      )
                    ]))
              ]));
        });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

Text _buildRatingStars(int rating) {
  String stars = '';
  for (int i = 0; i < rating; i++) {
    stars += '⭐ ';
  }
  stars.trim();
  return Text(
    stars,
    style: const TextStyle(fontSize: 12.0),
  );
}
