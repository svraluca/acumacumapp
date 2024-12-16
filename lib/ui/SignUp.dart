import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:acumacum/ui/HomePage.dart';
import 'package:acumacum/ui/auth.dart';

import 'LoginPage.dart';
import 'choosedBusinessUser.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => SignupPageState();
}

class SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String error = '';
  final String _selectedRole = 'Select a User Role';

  String get selectedRole => _selectedRole;

  late int selectedValue;
  late String selectedString;

//  void setSelectedRole(String role) {
//    _selectedRole = role;
//  }

  bool loading = false;
  final Authentication authentication = Authentication();
  int selectedIndex1 = 0;

  var elements1 = [
    'User',
    'Business',
  ];
  String dropdownvalue = 'User';

  // var items =  ['Customer','Business'];

  // Add text controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    // Clean up controllers
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? Container(
            color: const Color(0xFFFF0000),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          )
        : Scaffold(
            backgroundColor: const Color(0xFFFF0000),
            resizeToAvoidBottomInset: false,
            body: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.only(left: 20.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Creeaza un cont nou',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Completeaza campurile de mai jos pentru\na crea un cont nou',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(50),
                          topRight: Radius.circular(50),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 20,
                            left: 20,
                            right: 20,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: <Widget>[
                                const SizedBox(height: 30),
                                TextFormField(
                                  controller: _nameController,
                                  keyboardType: TextInputType.text,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return 'Please enter name';
                                    }
                                    return null;
                                  },
                                  onChanged: (val) {
                                    try {
                                      setState(() => name = val.trim());
                                    } catch (e) {
                                      print('Error in name field: $e');
                                    }
                                  },
                                  style: const TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    errorStyle: const TextStyle(color: Colors.red),
                                    hintText: 'Business name/Client',
                                    hintStyle: const TextStyle(
                                      fontFamily: 'Antra',
                                      fontSize: 14.0,
                                      color: Colors.black54,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none,
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: const BorderSide(color: Colors.red),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: const BorderSide(color: Colors.red),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return 'Please enter email';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                  onChanged: (val) {
                                    try {
                                      setState(() => email = val.trim());
                                    } catch (e) {
                                      print('Error in email field: $e');
                                    }
                                  },
                                  style: const TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    errorStyle: const TextStyle(color: Colors.red),
                                    hintText: 'Email',
                                    hintStyle: const TextStyle(
                                      fontFamily: 'Antra',
                                      fontSize: 14.0,
                                      color: Colors.black54,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none,
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: const BorderSide(color: Colors.red),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: const BorderSide(color: Colors.red),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _passwordController,
                                  keyboardType: TextInputType.visiblePassword,
                                  obscureText: true,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return 'Please enter password';
                                    }
                                    if (val.length < 8) {
                                      return 'Password must be at least 8 characters';
                                    }
                                    return null;
                                  },
                                  onChanged: (val) {
                                    try {
                                      setState(() => password = val.trim());
                                    } catch (e) {
                                      print('Error in password field: $e');
                                    }
                                  },
                                  style: const TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    errorStyle: const TextStyle(color: Colors.red),
                                    hintText: 'Password',
                                    hintStyle: const TextStyle(
                                      fontFamily: 'Antra',
                                      fontSize: 14.0,
                                      color: Colors.black54,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none,
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: const BorderSide(color: Colors.red),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: const BorderSide(color: Colors.red),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: DropdownButton(
                                    isExpanded: true,
                                    value: dropdownvalue,
                                    icon: const Icon(Icons.keyboard_arrow_down),
                                    underline: Container(),
                                    dropdownColor: Colors.white,
                                    items: elements1.map((String items) {
                                      return DropdownMenuItem(
                                        value: items,
                                        child: Text(
                                          items,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 14.0,
                                            fontFamily: 'Antra',
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          dropdownvalue = newValue;
                                        });
                                      }
                                    },
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14.0,
                                      fontFamily: 'Antra',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                MaterialButton(
                                  color: Colors.black,
                                  height: 50,
                                  minWidth: double.infinity,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  onPressed: () async {
                                    try {
                                      if (_formKey.currentState!.validate()) {
                                        setState(() => loading = true);

                                        final trimmedEmail = email.trim();
                                        final trimmedPassword = password.trim();
                                        final trimmedName = name.trim();

                                        Response result = await authentication.createUserWithEmailAndPassword(
                                          trimmedEmail,
                                          trimmedPassword,
                                          trimmedName,
                                          dropdownvalue,
                                        );

                                        if (result.error == true) {
                                          setState(() {
                                            error = result.messages?.toString() ?? 'An error occurred';
                                            loading = false;
                                          });
                                          errorAlert();
                                        } else {
                                          try {
                                            print('User ID retrieved after registration: ${result.data}');
                                            String notificationToken = result.data ?? ''; // Handle nullable String

                                            // Try to get FCM token only for User role
                                            if (dropdownvalue == 'User') {
                                              try {
                                                print('Getting FCM token for User role...');
                                                await Firebase.initializeApp();
                                                
                                                // Request notification permissions
                                                NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
                                                  alert: true,
                                                  badge: true,
                                                  sound: true,
                                                  provisional: false,
                                                );

                                                if (settings.authorizationStatus == AuthorizationStatus.authorized) {
                                                  // Try to get token
                                                  String? fcmToken = await FirebaseMessaging.instance.getToken();
                                                  if (fcmToken != null && fcmToken.isNotEmpty) {
                                                    notificationToken = fcmToken;
                                                    print('FCM Token retrieved successfully: $fcmToken');
                                                  } else {
                                                    print('FCM Token was null, using UID instead: ${result.data}');
                                                  }
                                                } else {
                                                  print('Notification permissions not granted, using UID: ${result.data}');
                                                }
                                              } catch (e) {
                                                print('Error getting FCM token, using UID instead: ${result.data}');
                                              }
                                            }

                                            // Create user data with the determined notification token
                                            Map<String, dynamic> userData = {
                                              'email': trimmedEmail,
                                              'name': trimmedName,
                                              'userRole': dropdownvalue,
                                              'password': trimmedPassword,
                                              'uid': result.data ?? '',
                                              'createdAt': FieldValue.serverTimestamp(),
                                              'newChat': true,
                                              'notificationToken': notificationToken,
                                            };

                                            // Save to Firestore
                                            await FirebaseFirestore.instance
                                                .collection('Users')
                                                .doc(result.data)
                                                .set(userData);

                                            print('User data saved with notification token: $notificationToken');

                                            // Navigate based on role
                                            if (dropdownvalue == 'Business') {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(builder: (_) => const BusinessPage()),
                                              );
                                            } else {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(builder: (_) => const Homepage()),
                                              );
                                            }
                                          } catch (e) {
                                            print('Error in user creation process: $e');
                                            // Create user with UID as notification token if there was an error
                                            Map<String, dynamic> fallbackUserData = {
                                              'email': trimmedEmail,
                                              'name': trimmedName,
                                              'userRole': dropdownvalue,
                                              'password': trimmedPassword,
                                              'uid': result.data ?? '',
                                              'createdAt': FieldValue.serverTimestamp(),
                                              'newChat': true,
                                              'notificationToken': result.data ?? '',
                                            };

                                            await FirebaseFirestore.instance
                                                .collection('Users')
                                                .doc(result.data)
                                                .set(fallbackUserData);

                                            // Navigate even if there was an error
                                            if (dropdownvalue == 'Business') {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(builder: (_) => const BusinessPage()),
                                              );
                                            } else {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(builder: (_) => const Homepage()),
                                              );
                                            }
                                          }
                                        }
                                      }
                                    } catch (e) {
                                      print('Error in form submission: $e');
                                      setState(() {
                                        error = 'An unexpected error occurred. Please try again.';
                                        loading = false;
                                      });
                                      errorAlert();
                                    }
                                  },
                                  child: const Text(
                                    'Register',
                                    style: TextStyle(
                                      fontFamily: 'Antra',
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _createAccountLabel(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  errorAlert() {
    Alert(
      context: context,
      type: AlertType.error,
      title: "Registration Error",
      desc: error,
      buttons: [
        DialogButton(
          onPressed: () => Navigator.pop(context),
          width: 120,
          child: const Text(
            "Close",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        )
      ],
    ).show();
  }

  Widget _createAccountLabel() {
    return InkWell(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const LoginPage()));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.all(15),
        alignment: Alignment.bottomCenter,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You already have an account?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            SizedBox(
              width: 10,
            ),
            Text(
              'Login',
              style: TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _initializeAndGetToken() async {
    try {
      // Ensure Firebase is initialized
      if (!Firebase.apps.isNotEmpty) {
        await Firebase.initializeApp();
      }

      // Request permissions with all options
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      print('Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        // Configure FCM options
        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        try {
          print('Attempting to get FCM token...');
          String? token = await FirebaseMessaging.instance.getToken();
          
          if (token != null && token.isNotEmpty) {
            print('Successfully retrieved FCM token: $token');
            return token;
          } else {
            print('FCM token is null or empty');
            return null;
          }
        } catch (e) {
          print('Error getting FCM token: $e');
          return null;
        }
      } else {
        print('Notification permissions not granted');
        return null;
      }
    } catch (e) {
      print('Fatal error in getNotificationToken: $e');
      return null;
    }
  }
}

class MySelectionItem extends StatelessWidget {
  final String title;
  final bool isForList;

  const MySelectionItem({super.key, required this.title, this.isForList = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60.0,
      child: isForList
          ? Padding(
              child: _buildItem(context),
              padding: const EdgeInsets.all(10.0),
            )
          : Card(
              margin: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Stack(
                children: <Widget>[
                  _buildItem(context),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.arrow_drop_down),
                  )
                ],
              ),
            ),
    );
  }

  _buildItem(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      alignment: Alignment.center,
      child: Text(title),
    );
  }
}
