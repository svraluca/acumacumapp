import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String userRole;
  final String avatarUrl;
  final String address;
  final String? country;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.userRole,
    required this.address,
    required this.avatarUrl,
    required this.country,
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      userRole: data['userRole'] ?? '',
      address: data['address'] ?? '',
      country: data['country'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'email': email,
        'userRole': userRole,
        'address': address,
        'country': country,
        'avatarUrl': avatarUrl
      };
}
