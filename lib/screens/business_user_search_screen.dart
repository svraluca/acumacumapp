import 'package:algolia/algolia.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:acumacum/ui/HomePage.dart';
import 'package:acumacum/ui/UserProfiles.dart';
import 'package:acumacum/ui/viewProfiles.dart';
import 'package:acumacum/utils/AlgoliaApplication.dart';

class BusinessUserSearchScreen extends StatefulWidget {
  final String currentUserID;

  const BusinessUserSearchScreen(this.currentUserID, {super.key});

  @override
  BusinessUserSearchState createState() => BusinessUserSearchState();
}

class BusinessUserSearchState extends State<BusinessUserSearchScreen> {
  var categorySplit;
  TextEditingController searchController = TextEditingController();
  final Algolia _algoliaApp = AlgoliaApplication.algolia;

  String? serviceProviderId;

  Future<List<AlgoliaObjectSnapshot>> _operation(String input) async {
    AlgoliaQuery query = _algoliaApp.instance.index("users").search(input);
    AlgoliaQuerySnapshot querySnap = await query.getObjects();
    List<AlgoliaObjectSnapshot> results = querySnap.hits;
    return results;
  }

  Text _buildRatingStars(double rating) {
    String stars = '';
    for (int i = 0; i < rating.floor(); i++) {
      stars += '⭐ ';
    }
    return Text(stars.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Business User"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: const InputDecoration(hintText: "Enter username"),
              controller: searchController,
              onChanged: (str) {
                setState(() {});
              },
            ),
          ),
          searchController.text.isEmpty
              ? getAllUsersBuilder()
              : StreamBuilder<List<AlgoliaObjectSnapshot>>(
                  stream: Stream.fromFuture(_operation(searchController.text)),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return getAllUsersBuilder();
                    } else {
                      switch (snapshot.connectionState) {
                        case ConnectionState.waiting:
                          return Container();
                        default:
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else if (snapshot.hasData) {
                            return Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.only(
                                    top: 10.0, bottom: 15.0),
                                //itemCount: widget.destination.activities.length,
                                itemCount: snapshot.data!.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return getUsersCategoryBuilder(
                                      snapshot.data!, index);
                                },
                              ),
                            );
                          } else {
                            return Container();
                          }
                      }
                    }
                  },
                )
        ],
      ),
    );
  }

  FutureBuilder<QuerySnapshot> getAllUsersBuilder() {
    return FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('Users')
            .where('userRole', isEqualTo: 'Business')
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
            logger.e("Data:- ${snapshot.data?.docs}");
            return Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10.0, bottom: 15.0),
                //itemCount: widget.destination.activities.length,
                itemCount: snapshot.data?.docs.length,
                itemBuilder: (BuildContext context, int index) {
                  return getUsersCategoryBuildernormal(snapshot, index);
                },
              ),
            );
          }
        });
  }

  FutureBuilder<DocumentSnapshot?> getUsersCategoryBuilder(
      List<AlgoliaObjectSnapshot> snapshot, int index) {
    logger.e("Data:${snapshot[index].data} ");
    return FutureBuilder(
        future: getUsersCategory(snapshot[index].objectID),
        builder: (context, AsyncSnapshot<DocumentSnapshot?> snaps) {
          if (snaps.hasData) {
            logger.e("Data:${snaps.data?.data()} ");
            return getUserCategoryDetailsBuilder(snapshot, index, snaps);
          } else {
            return Container();
          }
          // print("avatarUrl       \n $avatarUrl");
        });
  }

  FutureBuilder<DocumentSnapshot> getUserCategoryDetailsBuilder(
    List<AlgoliaObjectSnapshot> snapshot,
    int index,
    AsyncSnapshot<DocumentSnapshot?> snaps,
  ) {
    String category = (snaps.data?.data() as Map<String, dynamic>)['category'];
    return FutureBuilder(
        future: getUserCategoryDetails(snapshot[index].objectID, category),
        builder: (BuildContext context, AsyncSnapshot snaps2) {
          if (!snaps2.hasData) {
            return Container();
          } else {
            return noLocationUser(
                snapshot,
                snaps,
                index,
                snaps2.data['openTime'],
                snaps2.data['closeTime'],
                snaps2.data['id'],
                'search');
          }
          // print("avatarUrl       \n $avatarUrl");
        });
  }

  Future<DocumentSnapshot?> getUsersCategory(String data) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(data)
        .collection('BusinessAccount')
        .doc('detail')
        .get();
    return snapshot.exists ? snapshot : null;
  }

  Future<DocumentSnapshot> getUserCategoryDetails(
      String id, String collection) async {
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection(collection).doc(id).get();
    return snapshot;
  }

  Widget noLocationUsers(
    List<DocumentSnapshot> snapshot,
    AsyncSnapshot snaps,
    int index,
    String? startTime,
    String closeTime,
    String id,
    String type,
  ) {
    return startTime == null
        ? Container()
        : GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => StoryProfiles(
                          UserProfiles(
                              id,
                              (snapshot[index].data()!
                                  as Map<String, dynamic>)['name'],
                              (snapshot[index].data()!
                                  as Map<String, dynamic>)['avatarUrl'],
                              (snapshot[index].data()!
                                  as Map<String, dynamic>)['address'],
                              snaps.data['category'] ?? ""),
                          widget.currentUserID)));
            },
            child: Stack(
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.fromLTRB(40.0, 5.0, 20.0, 5.0),
                  height: 170.0,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(100.0, 20.0, 20.0, 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: SizedBox(
                              width: 120.0,
                              child: Text(
                                (snapshot[index].data()
                                    as Map<String, dynamic>)['name'],
                                // activity.name,
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: SizedBox(
                              width: 120.0,
                              child: Text(
                                (snapshot[index].data()!
                                    as Map<String, dynamic>)['address'],
                                // activity.name,
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          snaps.data['category'] ?? "",
                          // activity.type,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        StreamBuilder<QuerySnapshot<Map>>(
                            stream: FirebaseFirestore.instance
                                .collection('Users')
                                .doc(id) // Gunakan id dari parameter fungsi
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
                                              color: Colors.blue),
                                        )
                                      : const Text(
                                          'No Reviews',
                                          style: TextStyle(color: Colors.blue),
                                        ),
                                  data.isNotEmpty
                                      ? _buildRatingStars(1)
                                      : const SizedBox(),
                                ],
                              );
                            }),
                        const SizedBox(height: 10.0),
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.all(5.0),
                              width: 70.0,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                startTime,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Container(
                              padding: const EdgeInsets.all(5.0),
                              width: 70.0,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                closeTime,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 20.0,
                  top: 15.0,
                  bottom: 15.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.0),
                    child: Image(
                      width: 110.0,
                      image: (snapshot[index].data()
                                  as Map<String, dynamic>)['avatarUrl'] ==
                              'default'
                          ? const NetworkImage(
                              "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png"

                              //  activity.imageUrl,

                              )
                          : NetworkImage((snapshot[index].data()
                              as Map<String, dynamic>)['avatarUrl']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  Widget noLocationUser(
    var snapshot,
    AsyncSnapshot snaps,
    int index,
    String? startTime,
    String closeTime,
    String id,
    String type,
  ) {
    return startTime == null
        ? Container()
        : GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => StoryProfiles(
                          UserProfiles(
                              id,
                              type == 'search'
                                  ? (snapshot[index].data()
                                      as Map<String, dynamic>)['name']
                                  : (snapshot.data[index].data()
                                      as Map<String, dynamic>)['name'],
                              type == 'search'
                                  ? (snapshot[index].data()
                                      as Map<String, dynamic>)['avatarUrl']
                                  : (snapshot.data[index].data()
                                      as Map<String, dynamic>)['avatarUrl'],
                              type == 'search'
                                  ? (snapshot[index].data()
                                      as Map<String, dynamic>)['address']
                                  : (snapshot.data[index].data()
                                      as Map<String, dynamic>)['address'],
                              snaps.data['category'] ?? ""),
                          widget.currentUserID)));
            },
            child: Stack(
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.fromLTRB(40.0, 5.0, 20.0, 5.0),
                  height: 170.0,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(100.0, 20.0, 20.0, 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: SizedBox(
                              width: 120.0,
                              child: Text(
                                type == 'search'
                                    ? snapshot[index].data['name']
                                    : snapshot.data[index]['name'],
                                // activity.name,
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: SizedBox(
                              width: 120.0,
                              child: Text(
                                type == 'search'
                                    ? snapshot[index].data['address']
                                    : snapshot.data[index]['address'],
                                // activity.name,
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          snaps.data['category'] ?? "",
                          // activity.type,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        _buildRatingStars(3),
                        const SizedBox(height: 10.0),
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.all(5.0),
                              width: 70.0,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                startTime,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Container(
                              padding: const EdgeInsets.all(5.0),
                              width: 70.0,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                closeTime,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 20.0,
                  top: 15.0,
                  bottom: 15.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.0),
                    child: Image(
                      width: 110.0,
                      image: (type == 'search'
                              ? snapshot[index].data['avatarUrl'] == 'default'
                              : snapshot.data[index]['avatarUrl'] == 'default')
                          ? const NetworkImage(
                              "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png"

                              //  activity.imageUrl,

                              )
                          : NetworkImage(type == 'search'
                              ? snapshot[index].data['avatarUrl']
                              : snapshot.data[index]['avatarUrl']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  FutureBuilder<DocumentSnapshot?> getUsersCategoryBuildernormal(
      AsyncSnapshot<QuerySnapshot?> snapshot, int index) {
    return FutureBuilder(
        future: getUsersCategory(snapshot.data!.docs[index].id.toString()),
        builder: (context, AsyncSnapshot<DocumentSnapshot?>? snaps) {
          if (snaps != null && snaps.hasData) {
            return getUserCategoryDetailsBuildernormal(snapshot, index, snaps);
          } else {
            return Container();
          }
        });
  }

  FutureBuilder<DocumentSnapshot> getUserCategoryDetailsBuildernormal(
      AsyncSnapshot<QuerySnapshot?> snapshot,
      int index,
      AsyncSnapshot<DocumentSnapshot?> snaps) {
    String category = (snaps.data?.data() as Map<String, dynamic>)['category'];
    return FutureBuilder(
        future: getUserCategoryDetails(snapshot.data!.docs[index].id, category),
        builder: (BuildContext context, AsyncSnapshot snaps2) {
          if (!snaps2.hasData) {
            return Container();
          } else {
            return noLocationUsers(
                snapshot.data!.docs,
                snaps,
                index,
                snaps2.data['openTime'],
                snaps2.data['closeTime'],
                snaps2.data['id'],
                'not');
          }
          // print("avatarUrl       \n $avatarUrl");
        });
  }
}

/*import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:acumacum/User.dart';
import 'package:acumacum/blocs/business_user_search_bloc/business_user_search_bloc.dart';

class BusinessUserSearchScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BusinessUserSearchBloc(),
      child: BusinessUserSearchBody(),
    );
  }
}

class BusinessUserSearchBody extends StatefulWidget {
  @override
  _BusinessUserSearchBodyState createState() => _BusinessUserSearchBodyState();
}

class _BusinessUserSearchBodyState extends State<BusinessUserSearchBody> {
  TextEditingController _searchController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Business User'),
      ),
      body: Column(
        children: [
          textField(),
          BlocListener<BusinessUserSearchBloc, BusinessUserSearchState>(
            listener: (context, state) {},
            child: BlocBuilder<BusinessUserSearchBloc, BusinessUserSearchState>(
              builder: (context, state) {
                if (state is BusinessUserSearchInitial) {
                  return Container();
                } else if (state is BusinessUserSearchLoadingState) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (state is ShowAllUserState) {
                  return _showAllUsersBuilder(state.users,
                      state.usersCategories, state.getCategoriesDetails);
                }
                return Container();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _blocStateManagment() {
    return BlocListener<BusinessUserSearchBloc, BusinessUserSearchState>(
      listener: (context, state) {},
      child: BlocBuilder<BusinessUserSearchBloc, BusinessUserSearchState>(
        builder: (context, state) {
          if (state is BusinessUserSearchInitial) {
            return Container();
          } else if (state is BusinessUserSearchLoadingState) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is ShowAllUserState) {
            return _showAllUsersBuilder(
                state.users, state.usersCategories, state.getCategoriesDetails);
          }
          return Container();
        },
      ),
    );
  }

  Widget _showAllUsersBuilder(List<User> users, List<String> usersCategories,
      List<Map> getCategoriesDetails) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (BuildContext context, int index) {
        return _userUI(
            users[index], usersCategories[index], getCategoriesDetails[index]);
      },
    );
  }

  Widget textField() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TextField(
        onChanged: (str) {},
        onEditingComplete: () {
          print('search event');
          BlocProvider.of<BusinessUserSearchBloc>(context)
              .add(SearchUserEvent(query: _searchController.text));
        },
        controller: _searchController,
      ),
    );
  }

  Widget _userUI(User user, String usersCategori, Map categoriesDetail) {
    return Container(
      margin: EdgeInsets.fromLTRB(40.0, 5.0, 20.0, 5.0),
      height: 170.0,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(100.0, 20.0, 20.0, 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width,
                child: Container(
                  width: 120.0,
                  child: Text(
                    user.name,
                    // activity.name,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ),
            ),
            user.adress == null
                ? Container()
                : Expanded(
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      child: Container(
                        width: 120.0,
                        child: Text(
                          user.adress,
                          // activity.name,
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ),
                  ),
            Text(
              usersCategori,
              // activity.type,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            // _buildRatingStars(3),
            categoriesDetail == null ? Container() : SizedBox(height: 10.0),
            Row(
              children: <Widget>[
                categoriesDetail == null
                    ? Container()
                    : Container(
                        padding: EdgeInsets.all(5.0),
                        width: 70.0,
                        decoration: BoxDecoration(
                          color: Theme.of(context).accentColor,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          categoriesDetail['openTime'].toString(),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                categoriesDetail == null ? Container() : SizedBox(width: 10.0),
                categoriesDetail == null
                    ? Container()
                    : Container(
                        padding: EdgeInsets.all(5.0),
                        width: 70.0,
                        decoration: BoxDecoration(
                          color: Theme.of(context).accentColor,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          categoriesDetail['closeTime'].toString(),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
*/
