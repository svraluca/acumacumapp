import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acumacum/ui/HomePage.dart';
import 'package:acumacum/ui/auth.dart';
import 'package:acumacum/ui/choosedBusinessUser.dart';
import 'SignUp.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var email = prefs.getString('email');
  print(email);
  runApp(
      MaterialApp(home: email == null ? const LoginPage() : const Homepage()));
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.title});

  final String? title;

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String error = '';
  bool loading = false;
  final Authentication authentication = Authentication();

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.signOut();
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
            resizeToAvoidBottomInset: true,
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 200),
                  const Padding(
                    padding: EdgeInsets.only(left: 20.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Conecteaza-te la contul tau',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Conecteaza-te la contul tau folosind email-ul si parola\ncu care te-ai inregistrat',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 280,
                    ),
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
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: <Widget>[
                            const SizedBox(height: 30),
                            TextFormField(
                              validator: (val) => val!.isEmpty ? 'enter email' : null,
                              onChanged: (val) {
                                setState(() => email = val);
                              },
                              style: const TextStyle(color: Colors.black),
                              decoration: InputDecoration(
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
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            TextFormField(
                              validator: (val) =>
                                  val!.length < 8 ? 'enter password > 8 digits' : null,
                              onChanged: (val) {
                                setState(() => password = val);
                              },
                              style: const TextStyle(color: Colors.black),
                              decoration: InputDecoration(
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
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 40),
                            MaterialButton(
                              height: 50,
                              minWidth: double.infinity,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              color: Colors.black,
                              onPressed: () async {
                                try {
                                  SharedPreferences prefs = await SharedPreferences.getInstance();
                                  if (_formKey.currentState!.validate()) {
                                    setState(() => loading = true);
                                    
                                    Response result = await authentication.signInWithEmailAndPassword(email, password);
                                    
                                    if (!mounted) return; // Check if widget is still mounted
                                    
                                    print('result at login page ${result.messages.toString()}');
                                    if (result.error == true) {
                                      setState(() {
                                        error = result.messages.toString();
                                        loading = false; // Make sure to set loading to false
                                      });
                                      errorAlert();
                                    } else {
                                      await prefs.setString('email', email);
                                      await prefs.setString('userId', result.data ?? 'defaultUserId');

                                      if (!mounted) return; // Check again after async operation

                                      DocumentSnapshot<Map<String, dynamic>?> userData = 
                                          await FirebaseFirestore.instance
                                              .collection('Users')
                                              .doc(result.data)
                                              .get();

                                      if (!mounted) return; // Check again after Firebase call

                                      if (userData.exists) {
                                        Navigator.pushReplacement(context,
                                            MaterialPageRoute(builder: (context) => const Homepage()));
                                      } else {
                                        setState(() {
                                          error = 'User does not exist';
                                          loading = false;
                                        });
                                        errorAlert();
                                      }
                                    }
                                  }
                                } catch (e) {
                                  setState(() {
                                    error = e.toString();
                                    loading = false;
                                  });
                                  errorAlert();
                                }
                              },
                              child: const Text(
                                'Logheaza-te',
                                style: TextStyle(
                                  fontFamily: 'Antra',
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                                "Reset your password by email"),
                                            TextFormField(
                                              validator: (val) => val!.isEmpty
                                                  ? 'Enter Email'
                                                  : null,
                                              onChanged: (val) {
                                                setState(() => email = val);
                                              },
                                              style: const TextStyle(
                                                  color: Colors.white),
                                              decoration:
                                                  const InputDecoration(
                                                hintText: 'Email',
                                                hintStyle: TextStyle(
                                                  fontFamily: 'Antra',
                                                  fontSize: 12.0,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.black),
                                              onPressed: () {
                                                FirebaseAuth.instance
                                                    .sendPasswordResetEmail(
                                                        email: email);
                                              },
                                              child: const Text(
                                                "Reseteaza",
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            )
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text("Close")),
                                        ],
                                      );
                                    });
                              },
                              child: const Text(
                                'Forget password?',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            _createAccountLabel(),
                          ],
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
      title: "Login Error",
      desc: "This account doesn't exist or the password is wrong",
      style: AlertStyle(
        backgroundColor: Colors.white,
        titleStyle: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        descStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
        ),
        isCloseButton: false,
        isOverlayTapDismiss: true,
        animationDuration: const Duration(milliseconds: 400),
        alertBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        descPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      buttons: [
        DialogButton(
          onPressed: () => Navigator.pop(context),
          width: 120,
          color: Colors.black,
          radius: BorderRadius.circular(30),
          child: const Text(
            "Close",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        )
      ],
    ).show();
  }

  Widget _createAccountLabel() {
    return InkWell(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const SignupPage()));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.all(15),
        alignment: Alignment.bottomCenter,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "You don't have an account?",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            SizedBox(
              width: 10,
            ),
            Text(
              'Register',
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
}
