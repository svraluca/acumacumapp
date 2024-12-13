import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:acumacum/ui/viewProfiles.dart';

import 'UserProfiles.dart';

class FavoriteProviders extends StatefulWidget {
  const FavoriteProviders({super.key});

  @override
  _FavoriteProvidersState createState() => _FavoriteProvidersState();
}

class _FavoriteProvidersState extends State<FavoriteProviders> {
  late String currentUserID;

  @override
  void initState() {
    super.initState();
    currentUserID = FirebaseAuth.instance.currentUser!.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFDA291C),
        title: const Text(
          "Favorites",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        elevation: 0,
      ),
      body: Builder(
        builder: (context) {
          return FutureBuilder<QuerySnapshot<Map>>(
            future: FirebaseFirestore.instance
                .collection("Users")
                .doc(currentUserID)
                .collection("favorites")
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else {
                List<String> favIds = [];
                snapshot.data?.docs.forEach((element) {
                  favIds.add((element.data() as Map<String, dynamic>)["id"]);
                });
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 10.0, bottom: 15.0),
                  itemCount: favIds.length,
                  itemBuilder: (BuildContext context, int index) {
                    String serviceProviderId = favIds[index];
                    return FutureBuilder(
                        future: FirebaseFirestore.instance
                            .collection('Users')
                            .doc(serviceProviderId)
                            .get(),
                        builder: (BuildContext context,
                            AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snaps) {
                          if (snaps.hasError || !snaps.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          String avatarUrl = (snaps.data?.data() as Map<String, dynamic>)['coverPhotoUrl'] ?? 'default';
                          String address = (snaps.data?.data() as Map<String, dynamic>)['address'] ?? 'No address';
                          String name = (snaps.data?.data() as Map<String, dynamic>)['name'] ?? 'No name';

                          return GestureDetector(
                            onTap: () async {
                              String categoryName = ((await snaps.data?.reference
                                      .collection("BusinessAccount")
                                      .doc("detail")
                                      .get())
                                  ?.data() as Map)["category"] ?? 'No category';
                              
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserProfiles(
                                    serviceProviderId,
                                    name,
                                    avatarUrl,
                                    address,
                                    categoryName,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 5.0),
                              height: 100.0,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    offset: Offset(0, 2),
                                    blurRadius: 4.0,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: <Widget>[
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12.0),
                                      bottomLeft: Radius.circular(12.0),
                                    ),
                                    child: Image(
                                      width: 100.0,
                                      height: 100.0,
                                      image: (avatarUrl != 'default' && avatarUrl.isNotEmpty)
                                          ? NetworkImage(avatarUrl)
                                          : const NetworkImage(
                                              "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png"),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  name,
                                                  style: const TextStyle(
                                                    fontSize: 15.0,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                              SizedBox(
                                                height: 24,
                                                child: TextButton(
                                                  style: TextButton.styleFrom(
                                                    padding: EdgeInsets.zero,
                                                    minimumSize: Size.zero,
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      snapshot.data?.docs.forEach((element) {
                                                        if ((element.data())["id"] == favIds[index]) {
                                                          element.reference.delete();
                                                        }
                                                      });
                                                    });
                                                  },
                                                  child: const Icon(
                                                    Icons.favorite,
                                                    color: Colors.red,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4.0),
                                          Text(
                                            address,
                                            style: const TextStyle(
                                              fontSize: 13.0,
                                              color: Colors.grey,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          const SizedBox(height: 4.0),
                                          StreamBuilder<QuerySnapshot<Map>>(
                                              stream: FirebaseFirestore.instance
                                                  .collection('Users')
                                                  .doc(serviceProviderId)
                                                  .collection('BusinessAccount')
                                                  .doc('detail')
                                                  .collection('reviews')
                                                  .snapshots(),
                                              builder: (context, snapshot) {
                                                if (!snapshot.hasData) {
                                                  return const CircularProgressIndicator();
                                                }
                                                final data = snapshot.data?.docs;
                                                double average = 0;
                                                num sum = 0;
                                                for (var star in data!) {
                                                  sum = sum + star['rating'];
                                                }
                                                average = sum / data.length;
                                                return Row(
                                                  children: [
                                                    data.isNotEmpty
                                                        ? Text(
                                                            num.parse(average.toStringAsFixed(1))
                                                                .toString(),
                                                            style: const TextStyle(
                                                              fontSize: 13.0,
                                                              color: Colors.blue,
                                                            ),
                                                          )
                                                        : const Text(
                                                            'No Reviews',
                                                            style: TextStyle(
                                                              fontSize: 13.0,
                                                              color: Colors.blue,
                                                            ),
                                                          ),
                                                    if (data.isNotEmpty) _buildRatingStars(1),
                                                  ],
                                                );
                                              }),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        });
                  },
                );
              }
            },
          );
        },
      ),
    );
  }

  Text _buildRatingStars(int rating) {
    String stars = '';
    for (int i = 0; i < rating; i++) {
      stars += '⭐ ';
    }
    stars.trim();
    return Text(stars);
  }
}
