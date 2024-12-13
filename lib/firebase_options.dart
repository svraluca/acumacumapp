// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB5XcpQ_peK-c41Vpy6ipFU2t02QIcMoT4',
    appId: '1:422207793483:web:d0e1bf3612b628774220ce',
    messagingSenderId: '422207793483',
    projectId: 'acumacum-6ea24',
    authDomain: 'acumacum-6ea24.firebaseapp.com',
    databaseURL: 'https://acumacum-6ea24.firebaseio.com',
    storageBucket: 'acumacum-6ea24.appspot.com',
    measurementId: 'G-FS6DT03D60',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCz08Ho-wYZViOrYLsPRo-Cxva7cRglIXA',
    appId: '1:422207793483:android:afdfd5b684d3adcd4220ce',
    messagingSenderId: '422207793483',
    projectId: 'acumacum-6ea24',
    databaseURL: 'https://acumacum-6ea24.firebaseio.com',
    storageBucket: 'acumacum-6ea24.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBx1x1B8J2AYtmnKj2aurVzuAav3thWNOQ',
    appId: '1:422207793483:ios:35883169503fb7474220ce',
    messagingSenderId: '422207793483',
    projectId: 'acumacum-6ea24',
    databaseURL: 'https://acumacum-6ea24.firebaseio.com',
    storageBucket: 'acumacum-6ea24.appspot.com',
    androidClientId:
        '422207793483-6f07ts3llgb918qch4ncl60inmqpjvht.apps.googleusercontent.com',
    iosClientId:
        '422207793483-s60ds0j09t2kkaejv91aspenqfo0rr2p.apps.googleusercontent.com',
    iosBundleId: 'com.example.tarrifo',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBx1x1B8J2AYtmnKj2aurVzuAav3thWNOQ',
    appId: '1:422207793483:ios:35883169503fb7474220ce',
    messagingSenderId: '422207793483',
    projectId: 'acumacum-6ea24',
    databaseURL: 'https://acumacum-6ea24.firebaseio.com',
    storageBucket: 'acumacum-6ea24.appspot.com',
    androidClientId:
        '422207793483-6f07ts3llgb918qch4ncl60inmqpjvht.apps.googleusercontent.com',
    iosClientId:
        '422207793483-s60ds0j09t2kkaejv91aspenqfo0rr2p.apps.googleusercontent.com',
    iosBundleId: 'com.example.tarrifo',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB5XcpQ_peK-c41Vpy6ipFU2t02QIcMoT4',
    appId: '1:422207793483:web:23db8b1abc7a90384220ce',
    messagingSenderId: '422207793483',
    projectId: 'acumacum-6ea24',
    authDomain: 'acumacum-6ea24.firebaseapp.com',
    databaseURL: 'https://acumacum-6ea24.firebaseio.com',
    storageBucket: 'acumacum-6ea24.appspot.com',
    measurementId: 'G-Q2RBGTJDLD',
  );
}