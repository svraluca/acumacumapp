import 'package:bubble_bottom_bar/bubble_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:acumacum/ui/bookings_orders.dart';
import 'package:acumacum/ui/customer_posts.dart';
import 'package:acumacum/ui/favoriteProviders.dart';
import 'package:acumacum/ui/messages_list.dart';

class BarDetail extends StatefulWidget {
  const BarDetail({super.key});

  @override
  _BarDetailState createState() => _BarDetailState();
}

class _BarDetailState extends State<BarDetail> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    currentIndex = 0;
  }

  changePage(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
        offset: const Offset(0.0, -10),
        child: Container(
            height: 110,
            margin: const EdgeInsets.only(left: 15, right: 15),
            child: ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(40),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BubbleBottomBar(
                        opacity: 0.2,
                        backgroundColor: Colors.white12,
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(80.0)),
                        currentIndex: currentIndex,
                        hasInk: true,
                        inkColor: Colors.black12,
                        hasNotch: true,
                        onTap: (index) {
                          if (index == 1) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const FavoriteProviders()),
                            );
                          }
                          if (index == 2) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const CustomerPosts()),
                            );
                          }
                          if (index == 3) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const BookingOrdersScreen()),
                            );
                          }
                          if (index == 4) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const MessageList()),
                            );
                          }
                        },
                        elevation: 100,
                        items: const <BubbleBottomBarItem>[
                          BubbleBottomBarItem(
                            backgroundColor: Colors.blue,
                            icon: Icon(
                              Icons.dashboard,
                              color: Colors.black,
                              size: 20,
                            ),
                            activeIcon: Icon(Icons.dashboard,
                                color: Colors.blue, size: 20),
                            title: Text(
                              "Home",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                          BubbleBottomBarItem(
                              backgroundColor: Colors.red,
                              icon: Icon(Icons.favorite_border,
                                  color: Colors.black, size: 20),
                              activeIcon: Icon(Icons.dashboard,
                                  color: Colors.red, size: 20),
                              title: Text("Saved")),
                          BubbleBottomBarItem(
                              backgroundColor: Colors.red,
                              icon: Icon(Icons.favorite_border,
                                  color: Colors.black, size: 20),
                              activeIcon: Icon(Icons.dashboard,
                                  color: Colors.red, size: 20),
                              title: Text("Bookings")),
                          BubbleBottomBarItem(
                              backgroundColor: Colors.red,
                              icon: Icon(Icons.share_outlined,
                                  color: Colors.black, size: 20),
                              activeIcon: Icon(Icons.dashboard,
                                  color: Colors.red, size: 20),
                              title: Text("Search")),
                          BubbleBottomBarItem(
                              backgroundColor: Colors.red,
                              icon: Icon(Icons.send,
                                  color: Colors.black, size: 20),
                              activeIcon: Icon(Icons.dashboard,
                                  color: Colors.red, size: 20),
                              title: Text("Messages")),
                        ]),
                  ],
                ))));
  }
}
