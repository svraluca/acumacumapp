import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../model/User.dart';

late String email, name, photoUrl;

class Authentication {
  String? userId;
  String? logUserId;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<String?> get onAuthStateChanged =>
      _firebaseAuth.authStateChanges().map((User? user) => user?.uid);

  // GET UID
  String? getCurrentUID() {
    return _firebaseAuth.currentUser?.uid;
  }

  // GET CURRENT USER
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  // Email & Password Sign Up
  Future<Response> createUserWithEmailAndPassword(
      String email, String password, String name, String userRole) async {
    try {
      await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password)
          .then((value) {
        if (value.user != null) {
          userId = value.user!.uid;
          print("User ID retrieved after registration: $userId");

          // Menggunakan UserModel untuk menyiapkan data user baru
          UserModel user = UserModel(
            uid: userId!,
            name: name,
            email: email,
            userRole: userRole,
            address: "default",
            avatarUrl: "default",
            country: "",
          );

          FirebaseFirestore.instance
              .collection('Users')
              .doc(userId)
              .set(user.toJson(), SetOptions(merge: true))
              .catchError((e) {
            print("Error saving user data: $e");
          });
        } else {
          print("Error: User registration failed or user ID is null.");
        }
      });
    } catch (e) {
      return Response(true, e.toString(), null);
    }

    return Response(false, 'Registration success', userId);
  }

  Future updateUserName(String name, User currentUser) async {
    await currentUser.updateDisplayName(name);
    await currentUser.reload();
  }

  // Email & Password Sign In
  Future<Response> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password)
          .then((value) {
        if (value.user != null) {
          logUserId = value.user!.uid;
          print("User ID retrieved after login: $logUserId");
        } else {
          print("Error: User login failed or user ID is null.");
        }
      });
    } catch (exception) {
      return Response(true, exception.toString(), null);
    }

    return Response(false, 'Login success', logUserId);
  }

  // Sign Out
  signOut() {
    return _firebaseAuth.signOut();
  }

  // Reset Password
  Future sendPasswordResetEmail(String email) async {
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  // Create Anonymous User
  Future signInAnonymously() {
    return _firebaseAuth.signInAnonymously();
  }

  Future convertUserWithEmail(
      String email, String password, String name) async {
    final currentUser = _firebaseAuth.currentUser;

    final credential =
        EmailAuthProvider.credential(email: email, password: password);
    await currentUser?.linkWithCredential(credential);
    await updateUserName(name, currentUser!);
  }

  Future convertWithGoogle() async {
    final currentUser = _firebaseAuth.currentUser;
    final GoogleSignInAccount? account = await _googleSignIn.signIn();
    final GoogleSignInAuthentication? googleAuth =
        await account?.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth?.idToken,
      accessToken: googleAuth?.accessToken,
    );
    await currentUser?.linkWithCredential(credential);
    await updateUserName(_googleSignIn.currentUser!.displayName!, currentUser!);
  }

  // GOOGLE
  Future<String> signInWithGoogle() async {
    final GoogleSignInAccount? account = await _googleSignIn.signIn();
    final GoogleSignInAuthentication? googleAuth =
        await account?.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth?.idToken,
      accessToken: googleAuth?.accessToken,
    );
    return (await _firebaseAuth.signInWithCredential(credential)).user!.uid;
  }
}

class NameValidator {
  static String? validate(String value) {
    if (value.isEmpty) {
      return "Name can't be empty";
    }
    if (value.length < 2) {
      return "Name must be at least 2 characters long";
    }
    if (value.length > 50) {
      return "Name must be less than 50 characters long";
    }
    return null;
  }
}

class EmailValidator {
  static String? validate(String value) {
    if (value.isEmpty) {
      return "Email can't be empty";
    }
    return null;
  }
}

class PasswordValidator {
  static String? validate(String value) {
    if (value.isEmpty) {
      return "Password can't be empty";
    }
    return null;
  }
}

createChatRoom(String charRoomId, chatRoomMap) {
  FirebaseFirestore.instance
      .collection("ChatRoom")
      .doc(charRoomId)
      .set(chatRoomMap)
      .catchError((e) {
    print(e.toString());
  });
}

class Response {
  bool error;
  String messages;
  String? data;

  Response(this.error, this.messages, this.data);
}
