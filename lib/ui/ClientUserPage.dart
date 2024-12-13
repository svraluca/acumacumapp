import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../model/User.dart';  // Update this import to match your existing User model

import '../ui/accountInfo.dart'; // Update this with the correct path
import '../ui/ChangeEmail.dart';
import '../ui/ChangePassword.dart';
import '../ui/LoginPage.dart';  // Adjust the import path to match your project structure

class ClientUserPage extends StatefulWidget {
  final String userId;
  const ClientUserPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<ClientUserPage> createState() => _ClientUserPageState();
}

class _ClientUserPageState extends State<ClientUserPage> {
  UserModel? userData;
  bool isLoading = true;
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    setState(() => isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .get();
          
      if (doc.exists) {
        userData = UserModel(
          uid: widget.userId,
          name: doc.data()?['name'] ?? '',
          email: doc.data()?['email'] ?? '',
          userRole: doc.data()?['userRole'] ?? 'User',
          address: doc.data()?['address'] ?? '',
          avatarUrl: doc.data()?['avatarUrl'] ?? '',
          country: doc.data()?['country'] ?? '',
        );
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (userData == null) {
      return const Center(child: Text('User not found'));
    }

    // Get user's initials
    String getInitials() {
      if (userData?.name == null || userData!.name!.isEmpty) return '';
      List<String> nameParts = userData!.name!.split(' ');
      if (nameParts.length > 1) {
        return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      }
      return userData!.name![0].toUpperCase();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Existing header content wrapped in Container
          Container(
            padding: const EdgeInsets.only(top: 40),
            child: Stack(
              children: [
                // Main Profile Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 60, 20, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Back Button
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.black,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      // CircleAvatar with transparent red
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.red.withOpacity(0.2),
                        child: Text(
                          getInitials(),
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'IBMPlexSans',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Username and Location
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              userData!.name ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'IBMPlexSans',
                                color: Color(0xFF2E3333),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: const [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Color(0xFF808080),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Romania',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF808080),
                                    fontFamily: 'IBMPlexSans',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // New rows for account options
          const SizedBox(height: 30),
          
          // Account Info Row with navigation
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.grey),
            title: const Text(
              'Account Info',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'IBMPlexSans',
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AccountInfo(userId: widget.userId),
                ),
              );
              
              // Refresh user data if name was updated
              if (result == true) {
                loadUserData();  // Reload user data
              }
            },
          ),
          
          // Change Email Row with navigation
          ListTile(
            leading: const Icon(Icons.email_outlined, color: Colors.grey),
            title: const Text(
              'Change Email',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'IBMPlexSans',
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeEmail(userId: widget.userId),
                ),
              );
            },
          ),
          
          // Change Password Row
          ListTile(
            leading: const Icon(Icons.lock_outline, color: Colors.grey),
            title: const Text(
              'Change Password',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'IBMPlexSans',
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangePassword(userId: widget.userId),
                ),
              );
            },
          ),
          
          // Notifications Row
          ListTile(
            leading: const Icon(Icons.notifications_outlined, color: Colors.grey),
            title: const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'IBMPlexSans',
              ),
            ),
            trailing: Switch(
              value: notificationsEnabled,
              activeColor: Colors.red,
              onChanged: (bool value) {
                setState(() {
                  notificationsEnabled = value;
                });
              },
            ),
          ),

          // Log Out Row
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.grey),
            title: const Text(
              'Log Out',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'IBMPlexSans',
              ),
            ),
            onTap: () {
              // Replace named route with direct navigation
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
