import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OtherUsersMap extends StatefulWidget {
  final String userId;
  const OtherUsersMap({Key? key, required this.userId}) : super(key: key);

  @override
  State<OtherUsersMap> createState() => _OtherUsersMapState();
}

class _OtherUsersMapState extends State<OtherUsersMap> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location'),
        backgroundColor: Colors.blue[900],
      ),
      body: Center(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Users')
              .doc(widget.userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>?;
            final address = userData?['address'] as String? ?? 'No address available';

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 50,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Business Location',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    address,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
