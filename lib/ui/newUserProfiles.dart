// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:fl_geocoder/fl_geocoder.dart';
// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:acumacum/ui/other_users_map.dart';
// import 'package:acumacum/utils/constants.dart';
// import 'package:url_launcher/url_launcher.dart';

// class NewUserProfiles extends StatefulWidget {
//   late ScrollController scrollController;
//   final String serviceProviderId;
//   final String userName;
//   final String? avatarUrl;
//   final String address;
//   final String? categoryName;

//   NewUserProfiles(this.serviceProviderId, this.userName, this.avatarUrl,
//       this.address, this.categoryName,
//       {super.key});

//   @override
//   State<NewUserProfiles> createState() => NewUserProfilesState();
// }

// class NewUserProfilesState extends State<NewUserProfiles> {
//   bool _isFavorite = false;
//   late String facebookUrl;
//   late String instagramUrl;
//   late String tikTokUrl;
//   late String myId;
//   var addresses;
//   var first;
//   late double lat;
//   late double long;
//   String? precise_address;
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   Widget _buildRatingStars(int rating) {
//     // rating conversion (stars)
//     String stars = '';
//     for (int i = 0; i < rating; i++) {
//       stars += '⭐ ';
//     }
//     // delete addition space
//     stars.trim();
//     return Text(
//       stars,
//       style: const TextStyle(fontSize: 12.0),
//     );
//   }

//   Future<void> _launchUrl(String url, BuildContext context) async {
//     if (url.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('URL is empty or not provided')),
//       );
//       return;
//     }

//     try {
//       final uri = Uri.parse(url);
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri, mode: LaunchMode.externalApplication);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not launch URL')),
//         );
//       }
//     } catch (e) {
//       print("Error launching URL: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Failed to open URL')),
//       );
//     }
//   }

//   void getSocialData() {
//     DocumentReference reference = FirebaseFirestore.instance
//         .collection('Users')
//         .doc(widget.serviceProviderId)
//         .collection('Social')
//         .doc('detail');

//     reference.snapshots().listen((event) {
//       if (mounted) {
//         setState(() {
//           facebookUrl =
//               event.data() == null ? null : (event.data() as Map)['facebook'];
//           instagramUrl =
//               event.data() == null ? null : (event.data() as Map)['instagram'];
//           tikTokUrl =
//               event.data() == null ? null : (event.data() as Map)['tiktok'];
//         });
//       }
//     });
//   }

//   @override
//   void initState() {
//     super.initState();
//     myId = FirebaseAuth.instance.currentUser!.uid;
//     FirebaseFirestore.instance
//         .collection("Users")
//         .doc(myId)
//         .collection("favorites")
//         .get()
//         .then(
//       (value) {
//         for (DocumentSnapshot doc in value.docs) {
//           if ((doc.data() as Map<String, dynamic>)["id"] ==
//               widget.serviceProviderId) {
//             setState(() {
//               _isFavorite = true;
//             });
//           }
//         }
//         return value.docs;
//       },
//     );

//     getSocialData();
//   }

//   void viewReview(var ratings, String name, String review, String avatarUrl) {
//     showGeneralDialog(
//       context: context,
//       barrierDismissible: false,
//       transitionDuration: const Duration(
//         milliseconds: 400,
//       ), // how long it takes to popup dialog after button click
//       pageBuilder: (_, __, ___) {
//         // your widget implementation
//         return Container(
//           color: Colors.black.withOpacity(0.4),
//           child: ListView(
//             children: [
//               Container(
//                 // width: 200,
//                 // margin: EdgeInsets.only(
//                 //     top: 8, bottom: 8, right: 12),
//                 margin: const EdgeInsets.only(right: 12, top: 8, bottom: 0),
//                 padding: const EdgeInsets.all(11),
//                 // width: MediaQuery.of(context)
//                 //         .size
//                 //         .width -
//                 //     140,
//                 decoration: BoxDecoration(
//                     color: Colors.white,
//                     boxShadow: [
//                       BoxShadow(
//                           color: Colors.black.withOpacity(0.1),
//                           blurRadius: 2,
//                           spreadRadius: 1)
//                     ],
//                     borderRadius: BorderRadius.circular(8)),
//                 child: Column(
//                   children: [
//                     Row(
//                       children: [
//                         CircleAvatar(
//                           backgroundImage: NetworkImage(avatarUrl),
//                         ),
//                         const SizedBox(width: 4),
//                         Text(name,
//                             style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 12.0,
//                                 color: Colors.black)),
//                         const SizedBox(width: 45),
//                         _buildRatingStars(ratings)
//                       ],
//                     ),
//                     // Row(
//                     //   children: [
//                     //     _buildRatingStars(snapshot
//                     //         .data
//                     //         .documents[index]
//                     //         .data["rating"]),
//                     //   ],
//                     // ),
//                     // Text(
//                     //     snapshot
//                     //         .data
//                     //         .documents[index]
//                     //         .data["text"],
//                     //     overflow:
//                     //         TextOverflow.ellipsis,
//                     //     textScaleFactor: 1.1),
//                     Container(
//                       margin: const EdgeInsets.only(top: 8),
//                       width: MediaQuery.of(context).size.width - 140,
//                       child: Text(
//                         review,
//                         textScaleFactor: 1.1,
//                         style: const TextStyle(
//                             fontSize: 12.0, color: Colors.black),
//                       ),
//                     ),
//                     TextButton(
//                       style: TextButton.styleFrom(
//                         shape: const StadiumBorder(),
//                         backgroundColor: Colors.blue,
//                       ),
//                       onPressed: () {
//                         Navigator.pop(context);
//                       },
//                       child: const Text(
//                         'Close',
//                         style: TextStyle(
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildReviewItem(DocumentSnapshot review) {
//     var data = review.data() as Map<String, dynamic>;
//     String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 CircleAvatar(
//                   backgroundImage: NetworkImage(data['avatarUrl'] ?? ''),
//                   radius: 20,
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         data['reviewerName'] ?? 'Anonymous',
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       Text(
//                         data['timestamp']?.toDate().toString() ?? 'No date',
//                         style:
//                             const TextStyle(color: Colors.grey, fontSize: 12),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Row(
//                   children: [
//                     const Icon(Icons.star, color: Colors.amber, size: 18),
//                     const SizedBox(width: 4),
//                     Text(
//                       '${data['rating']?.toStringAsFixed(1) ?? 'N/A'}',
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                   ],
//                 ),
//                 if (currentUserId == data['reviewerId'])
//                   IconButton(
//                     icon: const Icon(Icons.delete, color: Colors.red),
//                     onPressed: () => _deleteReview(review.id),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(data['comment'] ?? 'No comment'),
//           ],
//         ),
//       ),
//     );
//   }

//   void _deleteReview(String reviewId) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text("Delete Review"),
//           content: const Text("Are you sure you want to delete this review?"),
//           actions: [
//             TextButton(
//               child: const Text("Cancel"),
//               onPressed: () => Navigator.of(context).pop(),
//             ),
//             TextButton(
//               child: const Text("Delete"),
//               onPressed: () async {
//                 Navigator.of(context).pop();
//                 try {
//                   DocumentSnapshot reviewDoc = await FirebaseFirestore.instance
//                       .collection("Users")
//                       .doc(widget.serviceProviderId)
//                       .collection("BusinessAccount")
//                       .doc("detail")
//                       .collection("reviews")
//                       .doc(reviewId)
//                       .get();

//                   if (reviewDoc.exists) {
//                     Map<String, dynamic> reviewData =
//                         reviewDoc.data() as Map<String, dynamic>;
//                     String currentUserId =
//                         FirebaseAuth.instance.currentUser?.uid ?? '';

//                     if (currentUserId == reviewData['reviewerId']) {
//                       await reviewDoc.reference.delete();
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                             content: Text("Review deleted successfully")),
//                       );
//                     } else {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                             content: Text(
//                                 "You don't have permission to delete this review")),
//                       );
//                     }
//                   } else {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text("Review not found")),
//                     );
//                   }
//                 } catch (e) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text("Failed to delete review: $e")),
//                   );
//                 }
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         key: _scaffoldKey,
//         backgroundColor: Colors.transparent,
//         body: ListView(
//             controller: widget.scrollController,
//             padding: EdgeInsets.zero,
//             children: <Widget>[
//               SizedBox(
//                   height: MediaQuery.of(context).size.height * 0.32,
//                   child: Stack(children: <Widget>[
//                     Positioned(
//                       top: MediaQuery.of(context).size.height * 0.06,
//                       left: MediaQuery.of(context).size.width * 0.09,
//                       child: Row(
//                         children: [
//                           GestureDetector(
//                             onTap: () async {
//                               await _launchUrl(tikTokUrl, context);
//                             },
//                             child: Image.asset(
//                               'assets/images/tiktok.png',
//                               width: 50,
//                               height: 50,
//                             ),
//                           ),
//                           const SizedBox(
//                             width: 15,
//                           ),
//                           GestureDetector(
//                             onTap: () async {
//                               await _launchUrl(instagramUrl, context);
//                             },
//                             child: Image.asset(
//                               'assets/images/instagram.png',
//                               width: 50,
//                               height: 50,
//                             ),
//                           ),
//                           const SizedBox(
//                             width: 15,
//                           ),
//                           GestureDetector(
//                             onTap: () async {
//                               await _launchUrl(facebookUrl, context);
//                             },
//                             child: Image.asset(
//                               'assets/images/facebook.png',
//                               width: 50,
//                               height: 50,
//                             ),
//                           ),
//                           const SizedBox(
//                             width: 15,
//                           ),
//                           GestureDetector(
//                             onTap: () async {
//                               if (precise_address != null) {
//                                 addresses =
//                                     await FlGeocoder(Constants.googlePlaceKey)
//                                         .findAddressesFromAddress(
//                                             precise_address ?? "");
//                                 first = addresses.first;
//                                 // print("this is the location coord ${first.coordinates.latitude}");
//                                 lat = first.coordinates.latitude;
//                                 long = first.coordinates.longitude;
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (_) => UsersMapPage(
//                                       loc: precise_address,
//                                       lat: lat,
//                                       long: long,
//                                     ),
//                                   ),
//                                 );
//                               } else {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                     const SnackBar(
//                                         content: Text(
//                                             'There is no precise location for this user')));
//                               }
//                             },
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(30),
//                               child: Image.asset(
//                                 'assets/images/googlemap.png',
//                                 width: 50,
//                                 height: 50,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(
//                             width: 15,
//                           ),
//                           GestureDetector(
//                             onTap: () async {
//                               Share.share(
//                                   '${widget.userName} located in ${widget.address} envites you to his acumacum\'s business profile with the following app link https://acumacum.page.link/29hQ.');
//                             },
//                             child: const CircleAvatar(
//                               radius: 25,
//                               child: Icon(FontAwesomeIcons.share),
//                             ),
//                           )
//                         ],
//                       ),
//                     ),
//                   ]))
//             ]));
//   }
// }
