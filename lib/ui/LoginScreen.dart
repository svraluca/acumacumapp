import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart' hide CarouselController;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acumacum/ui/auth.dart';

import 'LoginPage.dart';
import 'SignUp.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var email = prefs.getString('email');
  print(email);
  runApp(const MaterialApp(home: LoginPage()));
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

final Authentication authentication = Authentication();

class _LoginPageState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              const Expanded(child: Logo()),

              Expanded(
                flex: 2,
                child: CarouselDemoState(),
              ),

              const SignUpButton(),
              const SizedBox(
                height: 20,
              ),
              const LoginButton(),

              // <-- Built with StreamBuilder
            ],
          )),
    );
  }
}

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  UserProfileState createState() => UserProfileState();
}

class UserProfileState extends State<UserProfile> {
  Map<String, dynamic>? _profile;
  final bool _loading = false;

  @override
  initState() {
    super.initState();

    // Subscriptions are created here
    //  authService.profile.listen((state) => setState(() => _profile = state));

    //authService.loading.listen((state) => setState(() => _loading = state));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Container(padding: const EdgeInsets.all(20), child: Text(_profile.toString())),
      Text(_loading.toString())
    ]);
  }
}

class LoginButton extends StatelessWidget {
  const LoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 50,
        width: 300,
        child: ElevatedButton(
          child: const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.email,
                  color: Colors.blue,
                ),
                Text('        Am deja cont creat')
              ]),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
            // Navigate to second route when tapped.
          },
        ));
  }
}

class SignUpButton extends StatelessWidget {
  const SignUpButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 50,
        width: 300,
        child: ElevatedButton(
          child: const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.email,
                  color: Colors.blue,
                ),
                Text('               Creeaza cont')
              ]),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignupPage()),
            );
            // Navigate to second route when tapped.
          },
        ));
  }
}

class Logo extends StatelessWidget {
  const Logo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'acumacum',
            style: TextStyle(
                color: Colors.blue, fontFamily: 'SignPainter', fontSize: 60),
          ),
        ]);
  }
}

class CarouselDemoState extends StatelessWidget {
  final int _current = 0;
  List imgList = [
    'https://www.freepnglogos.com/uploads/box-png/box-new-used-gaylord-boxes-for-sale-reliable-industries-llc-22.png',
    'https://www.chefmarcsmealprep.com/wp-content/uploads/2018/03/kisspng-health-food-healthy-diet-meal-delivery-service-weight-loss-5b649d89de2764.36415564153332058591.png',
    'https://freepngimg.com/thumb/air_pump/49352-8-garden-tools-free-download-png-hq.png',
  ];

  CarouselDemoState({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        CarouselSlider(
          options: CarouselOptions(
              height: 200.0, enableInfiniteScroll: true, autoPlay: true),
          items: imgList.map((imgUrl) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: const BoxDecoration(color: Colors.white10),
                  child: Image.network(imgUrl, fit: BoxFit.fill),
                );
              },
            );
          }).toList(),
        )
      ],
    );
  }
}
